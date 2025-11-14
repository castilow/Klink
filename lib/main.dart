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
    debugPrint('Background message received: ${message.messageId}');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        // Sin transiciones por defecto y sin duración para el push inicial
        defaultTransition: Transition.noTransition,
        transitionDuration: Duration.zero,
        initialRoute: AppRoutes.splash,
        getPages: AppPages.pages,
      )),
    );
  }
}
