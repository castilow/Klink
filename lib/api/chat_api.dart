import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:chat_messenger/api/user_api.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/models/chat.dart';
import 'package:chat_messenger/models/message.dart';
import 'package:chat_messenger/models/user.dart';

abstract class ChatApi {
  //
  // ChatApi - CRUD Operations
  //

  // Firestore instance
  static final _firestore = FirebaseFirestore.instance;
  
  // Getter público para acceder a Firestore desde otros lugares
  static FirebaseFirestore get firestore => _firestore;

  // Save chat for both users
  static Future<void> saveChat({
    required String userId1,
    required String userId2,
    required Message message,
    String? groupId,
  }) async {
    try {
      // Get chat instance
      final Chat chat = Chat(
        senderId: userId1,
        msgType: message.type,
        lastMsg: message.textMsg.isEmpty ? 'Nuevo chat' : message.textMsg,
        msgId: message.msgId,
        groupId: groupId, // Add groupId if provided
      );

      await Future.wait([
        // Save chat in current user collection
        _firestore
            .collection('Users/$userId1/Chats')
            .doc(userId2)
            .set(chat.toMap(false), SetOptions(merge: true)),

        // Save inverse chat copy for another user
        _firestore
            .collection('Users/$userId2/Chats')
            .doc(userId1)
            .set(chat.toMap(true), SetOptions(merge: true)),
      ]);

      // Debug
      debugPrint('saveChat() -> success');
    } catch (e) {
      debugPrint('saveChat() -> error: $e');
    }
  }

  // Save group chat for a user
  static Future<void> saveGroupChat({
    required String userId,
    required String groupId,
    required Message message,
  }) async {
    try {
      debugPrint('📝 [CHAT_API] saveGroupChat iniciado para userId: $userId, groupId: $groupId');
      
      // Get chat instance for group
      final Chat chat = Chat(
        senderId: message.senderId,
        msgType: message.type,
        lastMsg: message.textMsg,
        msgId: message.msgId,
        groupId: groupId, // This identifies it as a group chat
      );

      final chatMap = chat.toMap(false);
      debugPrint('📝 [CHAT_API] Datos del chat a guardar: groupId=$groupId, msgId=${chat.msgId}, lastMsg="${chat.lastMsg}"');
      debugPrint('📝 [CHAT_API] Ruta: Users/$userId/Chats/$groupId');

      // Save group chat in user's collection using groupId as document ID
      await _firestore
          .collection('Users/$userId/Chats')
          .doc(groupId)
          .set(chatMap, SetOptions(merge: true));

      // Verify it was saved
      final savedDoc = await _firestore
          .collection('Users/$userId/Chats')
          .doc(groupId)
          .get();
      
      if (savedDoc.exists) {
        debugPrint('✅ [CHAT_API] saveGroupChat -> ÉXITO para user: $userId, group: $groupId');
        debugPrint('✅ [CHAT_API] Documento verificado en Firestore');
      } else {
        debugPrint('⚠️ [CHAT_API] saveGroupChat -> Documento no encontrado después de guardar para user: $userId, group: $groupId');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [CHAT_API] saveGroupChat -> ERROR para user: $userId, group: $groupId');
      debugPrint('❌ [CHAT_API] Error: $e');
      debugPrint('❌ [CHAT_API] Stack trace: $stackTrace');
      rethrow; // Re-throw para que el error se propague
    }
  }

  static Stream<List<Chat>> getChats() {
    // Get current user model
    final User currentUer = AuthController.instance.currentUser;

    // Build query
    return _firestore
        .collection('Users/${currentUer.userId}/Chats')
        .orderBy('sentAt', descending: true)
        .snapshots()
        .asyncMap((event) async {
      // Hold the list
      List<Chat> chats = [];
      Set<String> processedGroups = {}; // Track processed groups to avoid duplicates

      for (var doc in event.docs) {
        // Get map data
        final data = doc.data();
        
        // Check if this is a group chat
        final String? groupId = data['groupId'];
        
        if (groupId != null) {
          // This is a group chat - only process if not already processed
          if (!processedGroups.contains(groupId)) {
            try {
              final groupDoc = await _firestore.collection('Groups').doc(groupId).get();
              if (groupDoc.exists) {
                final groupData = groupDoc.data()!;
                final String groupName = groupData['name'] ?? 'Grupo';
                debugPrint('📋 [CHAT_API] Obteniendo grupo $groupId: nombre="$groupName"');
                // Create a User object from group data for display
                final User groupUser = User(
                  userId: groupId,
                  fullname: groupName,
                  photoUrl: groupData['photoUrl'] ?? '',
                  username: groupName,
                );
                chats.add(Chat.fromMap(data, doc: doc, receiver: groupUser));
                processedGroups.add(groupId); // Mark as processed
              } else {
                debugPrint('⚠️ [CHAT_API] Grupo $groupId no existe en Firestore');
              }
            } catch (e) {
              debugPrint('❌ [CHAT_API] Error obteniendo datos del grupo $groupId: $e');
            }
          }
        } else {
          // This is a regular user chat - only load if it's not a group
          // Check if the document ID is not a group ID (groups use groupId as document ID)
          final User? user = await UserApi.getUser(doc.id);
          if (user != null) {
            // Verificar si el chat tiene mensajes
            final messagesRef = _firestore
                .collection('Users/${currentUer.userId}/Chats/${doc.id}/Messages');
            final messagesSnapshot = await messagesRef.limit(1).get();
            
            // Solo agregar el chat si tiene mensajes
            if (messagesSnapshot.docs.isNotEmpty) {
              chats.add(Chat.fromMap(data, doc: doc, receiver: user));
            } else {
              // Eliminar el chat si no tiene mensajes
              await doc.reference.delete();
              debugPrint('✅ Chat eliminado (sin mensajes): ${doc.id}');
            }
          }
        }
      }
      return chats;
    });
  }

  // Update Chat Node
  static Future<void> updateChatNode({
    required String userId1,
    required String userId2,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore
          .collection('Users')
          .doc(userId1)
          .collection('Chats')
          .doc(userId2)
          .set(data, SetOptions(merge: true));
      debugPrint('updateChatNode() -> success');
    } catch (e) {
      debugPrint('updateChatNode() -> error: $e');
    }
  }

  // Update Chat typing status
  static Future<void> updateChatTypingStatus(
    bool isTyping,
    String receiverId,
  ) async {
    try {
      final User currentUer = AuthController.instance.currentUser;

      await updateChatNode(
        userId1: receiverId,
        userId2: currentUer.userId,
        data: {'isTyping': isTyping, 'isRecording': false},
      );
      debugPrint('updateChatTypingStatus() -> success');
    } catch (e) {
      debugPrint('updateChatTypingStatus() -> error: $e');
    }
  }

  // Update Chat recording status
  static Future<void> updateChatRecordingStatus(
    bool isRecording,
    String receiverId,
  ) async {
    try {
      final User currentUer = AuthController.instance.currentUser;

      await updateChatNode(
        userId1: receiverId,
        userId2: currentUer.userId,
        data: {'isRecording': isRecording, 'isTyping': false},
      );
      debugPrint('updateChatRecordingStatus() -> success');
    } catch (e) {
      debugPrint('updateChatRecordingStatus() -> error: $e');
    }
  }

  // Update the Chat Node
  static Future<void> leaveChat(
    String receiverId,
  ) async {
    try {
      final User currentUer = AuthController.instance.currentUser;

      await Future.wait([
        UserApi.closeTypingOrRecordingStatus(),
        updateChatNode(
          userId1: receiverId,
          userId2: currentUer.userId,
          data: {'isTyping': false, 'isRecording': false, 'unread': 0},
        ),
      ]);
      debugPrint('updateTypingAndRecordingStatus() -> success');
    } catch (e) {
      debugPrint('updateTypingAndRecordingStatus() -> error: $e');
    }
  }

  // Soft delete chat.
  static Future<void> softDeleteChat({
    required String userId1,
    required String userId2,
    required String msgId,
  }) async {
    final User currentUer = AuthController.instance.currentUser;

    // Get Chat instance
    final Chat chat = Chat(
      senderId: currentUer.userId,
      msgType: MessageType.text,
      lastMsg: 'deleted',
      msgId: msgId,
    );
    _firestore
        .collection('Users/$userId1/Chats')
        .doc(userId2)
        .set(chat.toDeletedMap(), SetOptions(merge: true));
  }

  // Reset the last message in chat node.
  static Future<void> resetChat({
    required String userId1,
    required String userId2,
  }) async {
    _firestore
        .collection('Users/$userId1/Chats')
        .doc(userId2)
        .set({'msgType': 'text', 'lastMsg': null, 'sentAt': null});
  }

  static Future<void> clearChat({
    required List<Message> messages,
    required String receiverId,
    bool showMessage = true,
  }) async {
    try {
      final User currentUer = AuthController.instance.currentUser;

      // Reset the last message in my chat node.
      resetChat(userId1: currentUer.userId, userId2: receiverId);

      // Loop the message futures
      final List<Future<void>> messageFutures =
          messages.map((msg) => msg.docRef!.delete()).toList();

      if (messageFutures.isNotEmpty) {
        Future.wait(messageFutures);
      }
      // Debug
      debugPrint("clearChat() -> success");
    } catch (e) {
      // Debug
      debugPrint("clearChat() -> error: $e");
    }
  }

  static Future<void> muteChat({
    required bool isMuted,
    required String receiverId,
  }) async {
    try {
      final User currentUer = AuthController.instance.currentUser;

      await _firestore
          .collection('Users/$receiverId/Chats')
          .doc(currentUer.userId)
          .set({'isMuted': isMuted}, SetOptions(merge: true));
      // Debug
      debugPrint("muteChat() -> $isMuted");
    } catch (e) {
      // Debug
      debugPrint("muteChat() -> error: $e");
    }
  }

  static Future<bool> checkMuteStatus(String receiverId) async {
    try {
      final User currentUer = AuthController.instance.currentUser;

      final chatDoc = await _firestore
          .collection('Users/$receiverId/Chats')
          .doc(currentUer.userId)
          .get();
      return chatDoc.data()?['isMuted'] ?? false;
    } catch (e) {
      // Debug
      debugPrint("getMuteStatus() -> error: $e");
      return false;
    }
  }

  static Future<void> deleteChat({required String userId}) async {
    try {
      final User currentUer = AuthController.instance.currentUser;

      final reference = _firestore.collection('Users/${currentUer.userId}/Chats');

      // Delete messages
      final results = await reference.doc(userId).collection('Messages').get();
      final futures = results.docs.map((e) => e.reference.delete()).toList();
      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }
      // Delete the chat node
      await reference.doc(userId).delete();

      debugPrint('saveChat() -> success');
    } catch (e) {
      debugPrint('saveChat() -> error: $e');
    }
  }

  static Future<void> deleteGroupChat({required String groupId}) async {
    try {
      final User currentUer = AuthController.instance.currentUser;

      final reference = _firestore.collection('Users/${currentUer.userId}/Chats');

      // Delete the group chat node
      await reference.doc(groupId).delete();

      debugPrint('deleteGroupChat() -> success');
    } catch (e) {
      debugPrint('deleteGroupChat() -> error: $e');
    }
  }
}
