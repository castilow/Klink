import 'package:chat_messenger/helpers/encrypt_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:flutter/foundation.dart';

import 'group_update.dart';
import 'location.dart';

// Message types
enum MessageType { text, image, gif, video, doc, location, groupUpdate, audio }

class Message {
  String msgId;
  String senderId;
  MessageType type;
  String textMsg;
  String fileUrl;
  String gifUrl;
  Location? location;
  String videoThumbnail;
  bool isRead;
  bool isDeleted;
  bool isForwarded;
  DateTime? sentAt;
  DateTime? updatedAt;
  Message? replyMessage;
  // For Groups
  GroupUpdate? groupUpdate;
  // Reactions: emoji -> List of user IDs who reacted
  Map<String, List<String>>? reactions;
  // This reference help us update this message
  DocumentReference<Map<String, dynamic>>? docRef;

  Message({
    required this.msgId,
    this.docRef,
    this.senderId = '',
    this.type = MessageType.text,
    this.textMsg = '',
    this.fileUrl = '',
    this.gifUrl = '',
    this.location,
    this.videoThumbnail = '',
    this.isRead = false,
    this.isDeleted = false,
    this.isForwarded = false,
    this.sentAt,
    this.updatedAt,
    this.replyMessage,
    this.groupUpdate,
    this.reactions,
  });

  bool get isSender => senderId == AuthController.instance.currentUser.userId;

  // Get total reaction count
  int get totalReactions {
    if (reactions == null) return 0;
    return reactions!.values.fold(0, (sum, users) => sum + users.length);
  }

  // Check if current user has reacted with specific emoji
  bool hasUserReacted(String emoji) {
    final currentUserId = AuthController.instance.currentUser.userId;
    return reactions?[emoji]?.contains(currentUserId) ?? false;
  }

  // Add or remove reaction
  Message toggleReaction(String emoji, String userId) {
    Map<String, List<String>> updatedReactions = Map.from(reactions ?? {});
    
    if (updatedReactions.containsKey(emoji)) {
      if (updatedReactions[emoji]!.contains(userId)) {
        // Remove reaction
        updatedReactions[emoji]!.remove(userId);
        if (updatedReactions[emoji]!.isEmpty) {
          updatedReactions.remove(emoji);
        }
      } else {
        // Add reaction
        updatedReactions[emoji]!.add(userId);
      }
    } else {
      // Add new reaction
      updatedReactions[emoji] = [userId];
    }
    
    return Message(
      msgId: msgId,
      docRef: docRef,
      senderId: senderId,
      type: type,
      textMsg: textMsg,
      fileUrl: fileUrl,
      gifUrl: gifUrl,
      location: location,
      videoThumbnail: videoThumbnail,
      isRead: isRead,
      isDeleted: isDeleted,
      isForwarded: isForwarded,
      sentAt: sentAt,
      updatedAt: updatedAt,
      replyMessage: replyMessage,
      groupUpdate: groupUpdate,
      reactions: updatedReactions.isEmpty ? null : updatedReactions,
    );
  }

  @override
  String toString() {
    return 'Message(msgId: $msgId, senderId: $senderId, type: $type, textMsg: $textMsg, fileUrl: $fileUrl, gifUrl: $gifUrl, videoThumbnail: $videoThumbnail, isRead: $isRead, sentAt: $sentAt, groupUpdate: $groupUpdate, reactions: $reactions)';
  }

  // Get message type
  static MessageType getMsgType(String type) {
    return MessageType.values.firstWhere((el) => el.name == type);
  }

  factory Message.fromMap({
    required bool isGroup,
    required Map<String, dynamic> data,
    DocumentReference<Map<String, dynamic>>? docRef,
  }) {
    final String messageId = data['msgId'] ?? '';
    final String textMessage = data['textMsg'] ?? '';

    // Parse reactions
    Map<String, List<String>>? reactions;
    if (data['reactions'] != null) {
      final reactionsData = data['reactions'] as Map<String, dynamic>;
      reactions = {};
      reactionsData.forEach((emoji, userIds) {
        if (userIds is List) {
          reactions![emoji] = List<String>.from(userIds);
        }
      });
    }

    // Handle text message decryption with better error handling
    String finalTextMessage = textMessage;
    if (!isGroup && textMessage.isNotEmpty) {
      try {
        finalTextMessage = EncryptHelper.decrypt(textMessage, messageId);
        // Additional validation
        if (finalTextMessage == '[Mensaje no pudo ser desencriptado]') {
          debugPrint('Message.fromMap() -> Failed to decrypt message $messageId, marking as problematic');
        }
      } catch (e) {
        debugPrint('Message.fromMap() -> Error processing message $messageId: $e');
        finalTextMessage = '[Error al procesar mensaje]';
      }
    }

    return Message(
      docRef: docRef,
      msgId: messageId,
      senderId: data['senderId'] ?? '',
      type: getMsgType(data['type']),
      textMsg: finalTextMessage,
      fileUrl: data['fileUrl'] ?? '',
      gifUrl: data['gifUrl'] ?? '',
      location: Location.fromMap(data['location'] ?? {}),
      videoThumbnail: data['videoThumbnail'] ?? '',
      isRead: data['isRead'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
      isForwarded: data['isForwarded'] ?? false,
      sentAt: data['sentAt']?.toDate() as DateTime?,
      updatedAt: data['updatedAt']?.toDate() as DateTime?,
      replyMessage: data['replyMessage'] != null
          ? Message.fromMap(data: data['replyMessage'], isGroup: isGroup)
          : null,
      groupUpdate: GroupUpdate.froMap(data['groupUpdate'] ?? {}),
      reactions: reactions,
    );
  }

  Map<String, dynamic> toMap({required bool isGroup}) {
    // Convert reactions to map for Firestore
    Map<String, dynamic>? reactionsMap;
    if (reactions != null) {
      reactionsMap = {};
      reactions!.forEach((emoji, userIds) {
        reactionsMap![emoji] = userIds;
      });
    }

    return {
      'msgId': msgId,
      'senderId': senderId,
      'type': type.name,
      'textMsg': isGroup ? textMsg : EncryptHelper.encrypt(textMsg, msgId),
      'fileUrl': fileUrl,
      'gifUrl': gifUrl,
      'location': location?.toMap(),
      'videoThumbnail': videoThumbnail,
      'isRead': isRead,
      'isForwarded': isForwarded,
      'sentAt': FieldValue.serverTimestamp(),
      'replyMessage': replyMessage?.toMap(isGroup: isGroup),
      'groupUpdate': groupUpdate?.toMap(),
      'reactions': reactionsMap,
    };
  }

  Map<String, dynamic> toDeletedMap() {
    final deletedMap = {
      'isDeleted': true,
      'msgId': msgId,
      'type': 'text',
      'textMsg': 'deleted',
      'senderId': senderId,
      'replyMessage': null,
      'sentAt': sentAt,
      'updatedAt': FieldValue.serverTimestamp(),
      'reactions': reactions != null ? Map<String, dynamic>.from(reactions!.map((k, v) => MapEntry(k, v))) : null,
    };
    debugPrint('🔍 toDeletedMap() -> Created map: $deletedMap');
    return deletedMap;
  }
}
