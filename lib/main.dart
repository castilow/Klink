import 'package:chat_messenger/config/app_config.dart';
import 'package:chat_messenger/routes/app_pages.dart';
import 'package:chat_messenger/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';

import 'controllers/preferences_controller.dart';
import 'i18n/app_languages.dart';
import 'theme/app_theme.dart';
import 'widgets/wallet_service_initializer.dart';
import 'services/zego_call_service.dart';
import 'services/ai_assistant_initializer.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

// Global navigator key para ZEGOCLOUD
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _ensureFirebaseInitialized() async {
  if (Firebase.apps.isNotEmpty) {
    if (kDebugMode) {
      final existing = Firebase.app();
      debugPrint('Firebase ya inicializado (${existing.name})');
    }
    return;
  }
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) {
      final app = Firebase.app();
      debugPrint('Firebase inicializado: projectId=${app.options.projectId}');
    }
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      if (kDebugMode) {
        debugPrint('Firebase ya estaba inicializado (duplicate-app)');
      }
      Firebase.app();
    } else {
      rethrow;
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await _ensureFirebaseInitialized();
  
  if (kDebugMode) {
    debugPrint('📱 [BACKGROUND] Mensaje recibido en segundo plano: ${message.messageId}');
    debugPrint('📱 [BACKGROUND] Tipo: ${message.data['type']}');
    debugPrint('📱 [BACKGROUND] Datos: ${message.data}');
  }

  // Procesar notificación según su tipo
  final String type = message.data['type'] ?? '';
  
  if (type == 'call') {
    // Para llamadas, el sistema ya maneja la notificación push
    // pero podemos registrar que llegó
    if (kDebugMode) {
      debugPrint('📞 [BACKGROUND] Notificación de llamada recibida');
    }
  } else if (type == 'message' || type == 'group') {
    // Para mensajes, las notificaciones push del servidor ya se muestran
    // Solo registramos el log
    if (kDebugMode) {
      debugPrint('💬 [BACKGROUND] Notificación de mensaje recibida');
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Banner ASCII grande para los logs
  if (kDebugMode) {
    print('\n');
    print('╔═══════════════════════════════════════════════════════════════╗');
    print('║                                                               ║');
    print('║     ██╗  ██╗██╗     ██╗███╗   ██╗██╗  ██╗                     ║');
    print('║     ██║ ██╔╝██║     ██║████╗  ██║██║ ██╔╝                     ║');
    print('║     █████╔╝ ██║     ██║██╔██╗ ██║█████╔╝                      ║');
    print('║     ██╔═██╗ ██║     ██║██║╚██╗██║██╔═██╗                      ║');
    print('║     ██║  ██╗███████╗██║██║ ╚████║██║  ██╗                     ║');
    print('║     ╚═╝  ╚═╝╚══════╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝                     ║');
    print('║                                                               ║');
    print('║                    🚀 Iniciando aplicación...                 ║');
    print('║                                                               ║');
    print('╚═══════════════════════════════════════════════════════════════╝');
    print('\n');
  }

  await _ensureFirebaseInitialized();

  // App Check DESACTIVADO para producción - más simple y sin problemas
  // await FirebaseAppCheck.instance.activate(
  //   appleProvider: AppleProvider.appAttestWithDeviceCheckFallback,
  //   androidProvider: AndroidProvider.playIntegrity,
  // );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  final PreferencesController prefs =
      Get.put(PreferencesController(), permanent: true);
  await prefs.init();
  
  // Inicializar ZEGOCLOUD Call Service
  Get.put(ZegoCallService(), permanent: true);
  
  // Inicializar usuario del asistente IA en Firestore
  await AIAssistantInitializer.ensureAssistantExists();
  
  runApp(const MyApp());
}

class MyApp extends GetView<PreferencesController> {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WalletServiceInitializer(
      child: Obx(() => GetMaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey, // Navigator key para ZEGOCLOUD
        builder: (BuildContext context, Widget? child) {
          return Stack(
            children: [
              child!,
              ZegoUIKitPrebuiltCallMiniOverlayPage(
                contextQuery: () => navigatorKey.currentContext ?? context,
              ),
            ],
          );
        },
        theme: AppTheme.of(context).lightTheme,
        darkTheme: AppTheme.of(context).darkTheme,
        themeMode: controller.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
        translations: AppLanguages(),
        locale: controller.locale.value,
        fallbackLocale: const Locale('en'),
        // Transiciones suaves estilo iOS por defecto
        defaultTransition: Transition.cupertino,
        transitionDuration: const Duration(milliseconds: 300),
        initialRoute: AppRoutes.splash,
        getPages: AppPages.pages,
      )),
    );
  }
}
