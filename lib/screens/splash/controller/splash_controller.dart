import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/controllers/preferences_controller.dart';
import 'package:chat_messenger/services/network_service.dart';
import 'package:chat_messenger/services/global_wallet_service.dart';
import 'package:chat_messenger/services/zego_call_service.dart';
import 'package:chat_messenger/services/firebase_messaging_service.dart';
import 'package:chat_messenger/api/user_api.dart';
import 'package:chat_messenger/firebase_options.dart';

class SplashController extends GetxController {
  // Auth controller: se instancia SOLO después de Firebase.initializeApp
  late final AuthController auth;

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Inicializa todo y navega sin animaciones
    try {
      // Firebase primero
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

      // Inicializar App Check para habilitar llamadas a Functions con enforceAppCheck
      await FirebaseAppCheck.instance.activate(
        appleProvider: AppleProvider.debug,
        androidProvider: AndroidProvider.debug,
        webProvider: ReCaptchaV3Provider('unused-for-mobile'),
      );
      // Auto refresh y log del token para registrar en Firebase Console (App Check > Debug tokens)
      await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
      try {
        final token = await FirebaseAppCheck.instance.getToken(true);
        // NOTA: Este no es el "debug token" mostrable por consola de nativo, pero ayuda a confirmar que AppCheck está activo
        // Si no llegan notificaciones y la Function exige AppCheck, registra el debug token nativo que imprime el SDK en logs
        // o añade el token manualmente en la consola de Firebase.
        // Ignorar en producción.
        debugPrint('🔥 AppCheck token (para verificación): ${token != null ? token.substring(0, 12) : 'null'}...');
      } catch (_) {}

      // Diagnóstico FCM token y permisos
      await FirebaseMessagingService.diagnoseFCMToken();

      // Registrar AuthController ahora que Firebase está listo
      auth = Get.put(AuthController(), permanent: true);

      // Servicios base en paralelo
      final prefsController = Get.put(PreferencesController(), permanent: true);
      final networkService = Get.put(NetworkService(), permanent: true);

      await Future.wait([
        prefsController.init(),
        networkService.init(),
        // Pre-registro del WalletService para evitar esperas luego
        Get.putAsync<GlobalWalletService>(
          () => GlobalWalletService().init(),
          permanent: true,
          tag: 'global_wallet_service',
        ),
        // Inicializar ZEGOCLOUD Call Service
        Get.putAsync<ZegoCallService>(
          () async {
            final service = ZegoCallService();
            service.onInit();
            return service;
          },
          permanent: true,
          tag: 'zego_call_service',
        ),
        // Configuración de Firebase Realtime DB
        Future(() => UserApi.configureRealtimeDatabase()),
      ]);

      // Inicializar Ads por separado para evitar problemas de tipo
      try {
        await MobileAds.instance.initialize();
      } catch (e) {
        debugPrint('Error inicializando MobileAds: $e');
      }

      // Autenticación y navegación
      await auth.checkUserAccount();
    } catch (_) {
      // En caso de error, intenta igualmente ir al flujo de auth
      try {
        auth = Get.put(AuthController(), permanent: true);
        await auth.checkUserAccount();
      } catch (e) {
        rethrow;
      }
    }
  }
}
