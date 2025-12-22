import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/components/app_logo.dart';
import 'package:chat_messenger/config/app_config.dart';
import 'package:chat_messenger/routes/app_routes.dart';
import 'package:chat_messenger/helpers/routes_helper.dart';
import 'package:chat_messenger/models/user.dart';

import 'dialog_helper.dart';

abstract class NotificationHelper {
  //
  // NotificationHelper
  //

  // Handle notification click. E.g: open a route..
  static Future<void> onNotificationClick({
    bool openRoute = false,
    Map<String, dynamic>? payload,
  }) async {
    if (payload == null) return;
    
    // Vars
    String type = payload['type'] ?? '';
    String title = payload['title'] ?? '';
    String message = payload['message'] ?? '';

    // Handle notification type
    switch (type) {
      case 'alert':
        // Show alert dialog info
        DialogHelper.showAlertDialog(
          icon: const AppLogo(width: 35, height: 35),
          title: title.isNotEmpty ? Text(title) : const Text(AppConfig.appName),
          content: Text(message),
          actionText: 'OK'.tr,
          action: () => Get.back(),
          showCancelButton: false,
        );
        break;
      case 'message':
        if (!openRoute) return;
        final senderId = (payload['senderId'] ?? '').toString();
        final chatId = (payload['chatId'] ?? '').toString(); // 👈 agrega chatId
        if (senderId.isEmpty) return;

        final user = User(
          userId: senderId,
          fullname: payload['senderName'] ?? payload['title'] ?? '',
          photoUrl: payload['senderPhoto'] ?? '',
        );

        // Navegar a los mensajes
        await RoutesHelper.toMessages(isGroup: false, user: user);
        break;
      case 'call':
        if (openRoute) {
          try {
            // Los datos de llamada vienen en el campo 'call' como JSON string
            String? callDataStr = payload['call']?.toString();
            Map<String, dynamic>? callData;
            
            if (callDataStr != null && callDataStr.isNotEmpty) {
              // Intentar parsear como JSON
              try {
                callData = jsonDecode(callDataStr) as Map<String, dynamic>;
              } catch (e) {
                // Si falla, usar los datos directamente del payload
                callData = null;
              }
            }
            
            // Extraer datos de llamada (del objeto call o del payload directamente)
            final String callerId = callData?['callerId']?.toString() ?? 
                                    payload['senderId']?.toString() ?? '';
            final String callId = callData?['callId']?.toString() ?? 
                                  payload['callId']?.toString() ?? '';
            final bool isVideo = callData?['isVideoCall'] == true || 
                                 payload['isVideo'] == true || 
                                 (payload['isVideo']?.toString() == 'true');
            final String callerName = callData?['callerName']?.toString() ?? 
                                      payload['senderName']?.toString() ?? 
                                      title;
            final String callerPhoto = callData?['callerPhoto']?.toString() ?? 
                                       payload['senderPhoto']?.toString() ?? '';
            
            if (callerId.isNotEmpty && callId.isNotEmpty) {
              final user = User(
                userId: callerId,
                fullname: callerName,
                photoUrl: callerPhoto,
              );
              await Get.toNamed(
                AppRoutes.call,
                arguments: {
                  'user': user,
                  'isIncoming': true,
                  'channelId': callId,
                  'isVideo': isVideo,
                },
              );
            }
          } catch (e) {
            debugPrint('Error procesando notificación de llamada: $e');
          }
        }
        break;
      default:
        // Otros tipos: group, etc.
        break;
    }
  }
}
