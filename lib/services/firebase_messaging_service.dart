import 'dart:io';

import 'package:chat_messenger/helpers/notification_helper.dart';
import 'package:chat_messenger/api/user_api.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'local_notifications_service.dart';

abstract class FirebaseMessagingService {
  ///
  /// Handle incoming notifications while the app is in the Foreground
  ///
  static Future<void> initFirebaseMessagingUpdates() async {
    // Asegurar permisos antes (iOS)
    await _requestNotificationsPermission();

    // Importante: registrar background handler ya se hace en main.dart

    // Obtener y guardar FCM token
    final fcm = FirebaseMessaging.instance;
    final String? token = await fcm.getToken();
    if (token != null) {
      await UserApi.updateUserPushToken(
        AuthController.instance.currentUser.userId,
        token,
      );
    }

    // Escuchar rotación del token (iOS cambia frecuente, iCloud restore también)
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await UserApi.updateUserPushToken(
        AuthController.instance.currentUser.userId,
        newToken,
      );
    });

    // Mensajes en foreground (solo data-only)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final data = message.data;
      final type = data['type'] ?? 'alert';
      final isDataOnly = message.notification == null;

      if (type == 'message' && isDataOnly) {
        await LocalNotificationsService.showSimple(
          title: data['title'] ?? 'Nuevo mensaje',
          body: data['message'] ?? '',
          payload: data,
        );
      }
    });

    // Click con app en background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      await NotificationHelper.onNotificationClick(
        openRoute: true,
        payload: message.data,
      );
    });

    // Click con app "terminated"
    final RemoteMessage? initialMsg =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMsg != null) {
      // Defer para esperar que el router y providers monten
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await NotificationHelper.onNotificationClick(
          openRoute: true,
          payload: initialMsg.data,
        );
      });
    }
  }

  /// Request push notifications permission.
  static Future<void> _requestNotificationsPermission() async {
    // Request permission for iOS devices
    if (Platform.isIOS) {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final AuthorizationStatus status = settings.authorizationStatus;
      // Debug
      debugPrint('requestNotificationsPermission() for iOS -> $status');
    } else {
      // <-- Android permissions -->

      final PermissionStatus status = await Permission.notification.request();
      if (status.isPermanentlyDenied) {
        // Permission permanently denied, you can open the app settings to allow permissions
        await openAppSettings();
      }
      // Debug
      debugPrint('requestNotificationsPermission() for Android -> $status');
    }
  }

  /// Diagnóstico completo de FCM token y permisos
  static Future<void> diagnoseFCMToken() async {
    debugPrint('🔍 === DIAGNÓSTICO FCM TOKEN ===');
    
    final fm = FirebaseMessaging.instance;

    try {
      // iOS: permiso
      if (Platform.isIOS) {
        final settings = await fm.requestPermission(alert: true, badge: true, sound: true);
        debugPrint('📱 Notifs permiso iOS: ${settings.authorizationStatus}');
        
        // iOS: mostrar notifs en primer plano
        await fm.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
        debugPrint('📱 Foreground notifications habilitadas para iOS');
        
        // iOS (opcional): verifica también el token APNs
        final apns = await fm.getAPNSToken();
        debugPrint('🍎 APNS TOKEN: $apns');
      } else {
        final PermissionStatus status = await Permission.notification.request();
        debugPrint('🤖 Notifs permiso Android: $status');
      }

      // Token FCM
      final token = await fm.getToken();
      debugPrint('🔥 FCM TOKEN: $token');
      
      if (token == null || token.isEmpty) {
        debugPrint('❌ ERROR: No se pudo obtener FCM token');
        debugPrint('💡 Posibles causas:');
        debugPrint('   - Permisos denegados');
        debugPrint('   - google-services.json/GoogleService-Info.plist incorrecto');
        debugPrint('   - Configuración de Firebase incorrecta');
        debugPrint('   - Problemas de red');
      } else {
        debugPrint('✅ FCM token obtenido correctamente');
        debugPrint('📏 Longitud del token: ${token.length} caracteres');
      }

      // Si rota el token, regístralo
      fm.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 NEW FCM TOKEN: $newToken');
        debugPrint('📏 Nueva longitud: ${newToken.length} caracteres');
      });

      debugPrint('🔍 === FIN DIAGNÓSTICO ===');
      
    } catch (e) {
      debugPrint('❌ ERROR en diagnóstico FCM: $e');
    }
  }
}
