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
import 'package:chat_messenger/services/message_cleanup_service.dart';
import 'package:chat_messenger/api/user_api.dart';
import 'package:chat_messenger/firebase_options.dart';

const bool kEnableFirebaseAppCheck =
    bool.fromEnvironment('ENABLE_FIREBASE_APP_CHECK', defaultValue: false);
const bool kForceDebugAppCheckMode =
    bool.fromEnvironment('FORCE_DEBUG_APP_CHECK', defaultValue: false);

class SplashController extends GetxController {
  // Auth controller: se instancia SOLO después de Firebase.initializeApp
  AuthController get auth {
    if (Get.isRegistered<AuthController>()) {
      return Get.find<AuthController>();
    } else {
      return Get.put(AuthController(), permanent: true);
    }
  }

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Inicializa todo y navega sin animaciones
    try {
      // Firebase primero
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } else {
        Firebase.app();
      }

      if (kEnableFirebaseAppCheck) {
      await FirebaseAppCheck.instance.activate(
          appleProvider:
              kForceDebugAppCheckMode ? AppleProvider.debug : AppleProvider.appAttestWithDeviceCheckFallback,
          androidProvider:
              kForceDebugAppCheckMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        webProvider: ReCaptchaV3Provider('unused-for-mobile'),
      );
      await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
        if (kForceDebugAppCheckMode) {
      try {
        final token = await FirebaseAppCheck.instance.getToken(true);
            debugPrint(
              '🔥 AppCheck token (para verificación): ${token != null ? token.substring(0, 12) : 'null'}...',
            );
          } catch (e) {
            debugPrint('⚠️ Error obteniendo AppCheck token: $e');
          }
        }
      }

      // Diagnóstico FCM token y permisos
      await FirebaseMessagingService.diagnoseFCMToken();

      // Registrar AuthController ahora que Firebase está listo
      // El getter se encarga de obtener o crear la instancia
      final _ = auth;

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

      // Iniciar servicio de limpieza de mensajes temporales
      MessageCleanupService().start();

      // Autenticación y navegación
      await auth.checkUserAccount();
    } catch (_) {
      // En caso de error, intenta igualmente ir al flujo de auth
      try {
        // El getter se encarga de obtener o crear la instancia
        await auth.checkUserAccount();
      } catch (e) {
        rethrow;
      }
    }
  }
}
