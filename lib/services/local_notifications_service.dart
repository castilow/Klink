import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../helpers/routes_helper.dart';
import '../models/user.dart';

/// Servicio para notificaciones locales cuando la app está en foreground
class LocalNotificationsService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Inicializa el plugin de notificaciones locales
  static Future<void> init() async {
    if (_initialized) return;

    const AndroidInitializationSettings initAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initIOS = DarwinInitializationSettings(
      requestAlertPermission: false, // Lo gestiona FCM/permission_handler
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        _onSelectNotification(payload);
      },
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: initAndroid,
      iOS: initIOS,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _onSelectNotification(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: _onBackgroundTap,
    );

    _initialized = true;
  }

  /// Muestra una notificación local simple
  static Future<void> showSimple({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    await init();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'messages_channel',
      'Mensajes',
      channelDescription: 'Notificaciones de mensajes en primer plano',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final String? encoded = payload == null ? null : jsonEncode(payload);
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: encoded,
    );
  }

  /// Manejo de taps en notificaciones
  static Future<void> _onSelectNotification(String? payload) async {
    if (payload == null || payload.isEmpty) return;
    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      final String type = (data['type'] ?? '').toString();

      if (type == 'message') {
        // Datos esperados: senderId, senderName, senderPhoto
        final String senderId = (data['senderId'] ?? '').toString();
        if (senderId.isEmpty) return;
        // Crear objeto mínimo de User para navegación inmediata
        final user = User(
          userId: senderId,
          fullname: (data['senderName'] ?? '').toString(),
          photoUrl: (data['senderPhoto'] ?? '').toString(),
        );
        await RoutesHelper.toMessages(isGroup: false, user: user);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('LocalNotificationsService._onSelectNotification error: $e');
      }
    }
  }
}

@pragma('vm:entry-point')
void _onBackgroundTap(NotificationResponse response) {
  LocalNotificationsService._onSelectNotification(response.payload);
}


