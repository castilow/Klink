import 'package:chat_messenger/helpers/encrypt_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';

import 'message.dart';
import 'user.dart';

class Chat {
  String msgId;
  String lastMsg;
  MessageType msgType;
  String senderId;
  DateTime? sentAt;
  DateTime? updatedAt;
  int unread;
  bool isMuted;
  bool isDeleted;
  int deletedMessagesCount; // Contador de mensajes eliminados
  String? groupId; // Add groupId field
  // Local fields
  User? receiver;
  DocumentSnapshot<Map<String, dynamic>>? doc;

  Chat({
    this.doc,
    this.senderId = '',
    this.receiver,
    this.msgType = MessageType.text,
    this.lastMsg = '',
    this.msgId = '',
    this.sentAt,
    this.updatedAt,
    this.unread = 0,
    this.isMuted = false,
    this.isDeleted = false,
    this.deletedMessagesCount = 0,
    this.groupId,
  });

  bool get isSender => senderId == AuthController.instance.currentUser.userId;

  @override
  String toString() {
    return 'Chat(senderId: $senderId, msgType: $msgType, lastMsg: $lastMsg, sentAt: $sentAt, unread: $unread)';
  }

  // Get data from database
  factory Chat.fromMap(
    Map<String, dynamic> data, {
    DocumentSnapshot<Map<String, dynamic>>? doc,
    User? receiver,
  }) {
    final String messageId = data['msgId'] ?? '';
    final String textMessage = data['lastMsg'] ?? '';

    return Chat(
      doc: doc,
      msgId: messageId,
      receiver: receiver,
      senderId: data['senderId'] ?? '',
      msgType: Message.getMsgType(data['msgType']),
      lastMsg: EncryptHelper.decrypt(textMessage, messageId),
      sentAt: data['sentAt']?.toDate() as DateTime?,
      updatedAt: data['updatedAt']?.toDate() as DateTime?,
      unread: data['unread'] ?? 0,
      isMuted: data['isMuted'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
      deletedMessagesCount: data['deletedMessagesCount'] ?? 0,
      groupId: data['groupId'], // Add groupId from data
    );
  }

  // Update unread counter
  void viewChat() {
    if (doc != null && doc!.exists) {
      doc!.reference.update({'unread': 0});
    }
  }

  // Delete the chat node
  void deleteChat() {
    if (doc != null && doc!.exists) {
      doc!.reference.delete();
    }
  }

  Map<String, dynamic> toMap([bool increment = true]) {
    return {
      'isDeleted': false,
      'senderId': senderId,
      'msgType': msgType.name,
      'lastMsg': EncryptHelper.encrypt(lastMsg, msgId),
      'msgId': msgId,
      'unread': increment ? FieldValue.increment(1) : unread,
      'sentAt': FieldValue.serverTimestamp(),
      if (groupId != null) 'groupId': groupId, // Add groupId if present
    };
  }

  Map<String, dynamic> toDeletedMap() {
    return {
      'isDeleted': true,
      'msgType': 'text',
      'lastMsg': 'deleted',
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ---------- Serialización de caché local (sin Firestore ni cifrado) ----------
  factory Chat.fromCache(Map<String, dynamic> data) {
    return Chat(
      msgId: data['msgId'] ?? '',
      lastMsg: data['lastMsg'] ?? '',
      msgType: Message.getMsgType(data['msgType']),
      senderId: data['senderId'] ?? '',
      sentAt: data['sentAt'] != null
          ? DateTime.tryParse(data['sentAt'] as String)
          : null,
      updatedAt: data['updatedAt'] != null
          ? DateTime.tryParse(data['updatedAt'] as String)
          : null,
      unread: data['unread'] ?? 0,
      isMuted: data['isMuted'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
      deletedMessagesCount: data['deletedMessagesCount'] ?? 0,
      groupId: data['groupId'],
      receiver: data['receiver'] != null
          ? User.fromMap(Map<String, dynamic>.from(data['receiver']))
          : null,
    );
  }

  Map<String, dynamic> toCacheMap() {
    return {
      'msgId': msgId,
      'lastMsg': lastMsg,
      'msgType': msgType.name,
      'senderId': senderId,
      'sentAt': sentAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'unread': unread,
      'isMuted': isMuted,
      'isDeleted': isDeleted,
      'deletedMessagesCount': deletedMessagesCount,
      'groupId': groupId,
      if (receiver != null)
        'receiver': {
          'userId': receiver!.userId,
          'fullname': receiver!.fullname,
          'username': receiver!.username,
          'photoUrl': receiver!.photoUrl,
          'email': receiver!.email,
          'bio': receiver!.bio,
          'isOnline': receiver!.isOnline,
          'lastActive': receiver!.lastActive?.millisecondsSinceEpoch,
          'deviceToken': receiver!.deviceToken,
          'status': receiver!.status,
          'loginProvider': receiver!.loginProvider.name,
          'isTyping': receiver!.isTyping,
          'typingTo': receiver!.typingTo,
          'isRecording': receiver!.isRecording,
          'recordingTo': receiver!.recordingTo,
          'mutedGroups': receiver!.mutedGroups,
        },
    };
  }
}
