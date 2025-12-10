import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:flutter/material.dart';

/// Servicio para limpiar automáticamente mensajes temporales expirados
class MessageCleanupService {
  static final MessageCleanupService _instance = MessageCleanupService._internal();
  factory MessageCleanupService() => _instance;
  MessageCleanupService._internal();

  Timer? _cleanupTimer;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Iniciar servicio de limpieza automática
  void start() {
    // Ejecutar limpieza cada hora
    _cleanupTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _cleanupExpiredMessages();
    });
    
    // Ejecutar limpieza inmediatamente al iniciar
    _cleanupExpiredMessages();
    
    debugPrint('✅ MessageCleanupService iniciado');
  }

  /// Detener servicio de limpieza
  void stop() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    debugPrint('⏹️ MessageCleanupService detenido');
  }

  /// Limpiar mensajes expirados
  Future<void> _cleanupExpiredMessages() async {
    try {
      final currentUser = AuthController.instance.currentUser;
      final now = DateTime.now();
      
      debugPrint('🧹 Iniciando limpieza de mensajes expirados...');
      
      // Obtener todos los chats del usuario
      final chatsSnapshot = await _firestore
          .collection('Users/${currentUser.userId}/Chats')
          .get();
      
      int deletedCount = 0;
      
      for (var chatDoc in chatsSnapshot.docs) {
        final chatId = chatDoc.id;
        final messagesRef = _firestore
            .collection('Users/${currentUser.userId}/Chats/$chatId/Messages');
        
        // Obtener mensajes temporales expirados
        final expiredMessages = await messagesRef
            .where('isTemporary', isEqualTo: true)
            .where('expiresAt', isLessThan: Timestamp.fromDate(now))
            .get();
        
        // Eliminar mensajes expirados
        for (var messageDoc in expiredMessages.docs) {
          await messageDoc.reference.delete();
          deletedCount++;
        }
        
        // Verificar si el chat queda sin mensajes
        final remainingMessages = await messagesRef.limit(1).get();
        if (remainingMessages.docs.isEmpty) {
          // Eliminar el chat si no tiene mensajes
          await chatDoc.reference.delete();
          debugPrint('✅ Chat eliminado (sin mensajes): $chatId');
        }
      }
      
      if (deletedCount > 0) {
        debugPrint('✅ Limpieza completada: $deletedCount mensajes expirados eliminados');
      } else {
        debugPrint('✅ Limpieza completada: No hay mensajes expirados');
      }
    } catch (e) {
      debugPrint('❌ Error en limpieza de mensajes: $e');
    }
  }

  /// Limpiar mensajes expirados de un chat específico
  Future<void> cleanupChatMessages(String chatUserId) async {
    try {
      final currentUser = AuthController.instance.currentUser;
      final now = DateTime.now();
      
      final messagesRef = _firestore
          .collection('Users/${currentUser.userId}/Chats/$chatUserId/Messages');
      
      // Obtener mensajes temporales expirados
      final expiredMessages = await messagesRef
          .where('isTemporary', isEqualTo: true)
          .where('expiresAt', isLessThan: Timestamp.fromDate(now))
          .get();
      
      // Eliminar mensajes expirados
      for (var messageDoc in expiredMessages.docs) {
        await messageDoc.reference.delete();
      }
      
      // También eliminar del otro usuario
      final otherUserMessagesRef = _firestore
          .collection('Users/$chatUserId/Chats/${currentUser.userId}/Messages');
      
      final otherExpiredMessages = await otherUserMessagesRef
          .where('isTemporary', isEqualTo: true)
          .where('expiresAt', isLessThan: Timestamp.fromDate(now))
          .get();
      
      for (var messageDoc in otherExpiredMessages.docs) {
        await messageDoc.reference.delete();
      }
      
      debugPrint('✅ Mensajes expirados eliminados del chat: $chatUserId');
    } catch (e) {
      debugPrint('❌ Error limpiando mensajes del chat: $e');
    }
  }
}





















