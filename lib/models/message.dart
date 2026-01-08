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
  // Translations: language code -> translated text
  Map<String, String>? translations;
  String? detectedLanguage;
  DateTime? translatedAt;
  // This reference help us update this message
  DocumentReference<Map<String, dynamic>>? docRef;
  // Temporary message fields
  bool isTemporary; // Si el mensaje es temporal (24 horas)
  DateTime? expiresAt; // Fecha de expiración del mensaje
  bool viewOnce; // Si el mensaje/audio solo se puede ver/escuchar una vez
  List<String>? viewedBy; // Lista de usuarios que ya vieron/escucharon el mensaje

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
    this.translations,
    this.detectedLanguage,
    this.translatedAt,
    this.isTemporary = false,
    this.expiresAt,
    this.viewOnce = false,
    this.viewedBy,
  });

  bool get isSender => senderId == AuthController.instance.currentUser.userId;
  
  // Verificar si el mensaje está expirado
  bool get isExpired {
    if (!isTemporary || expiresAt == null) return false;
    return expiresAt!.isBefore(DateTime.now());
  }
  
  // Verificar si el mensaje viewOnce ya fue visto por el usuario actual
  bool get isViewedByCurrentUser {
    if (!viewOnce || viewedBy == null) return false;
    final currentUserId = AuthController.instance.currentUser.userId;
    return viewedBy!.contains(currentUserId);
  }

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

  // Get translated text for user's language
  String getTranslatedText(String languageCode) {
    // Si hay traducción disponible, usarla
    if (translations != null && translations!.containsKey(languageCode)) {
      return translations![languageCode]!;
    }
    // Si no, devolver el texto original
    return textMsg;
  }

  // Check if message has translation for a language
  bool hasTranslation(String languageCode) {
    return translations != null && translations!.containsKey(languageCode);
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
      translations: translations,
      detectedLanguage: detectedLanguage,
      translatedAt: translatedAt,
    );
  }

  @override
  String toString() {
    return 'Message(msgId: $msgId, senderId: $senderId, type: $type, textMsg: $textMsg, fileUrl: $fileUrl, gifUrl: $gifUrl, videoThumbnail: $videoThumbnail, isRead: $isRead, sentAt: $sentAt, groupUpdate: $groupUpdate, reactions: $reactions)';
  }

  // Get message type
  static MessageType getMsgType(String? type) {
    if (type == null || type.isEmpty) {
      print('⚠️⚠️⚠️ getMsgType: type es null o vacío, devolviendo MessageType.text por defecto');
      debugPrint('⚠️ getMsgType: type es null o vacío, devolviendo MessageType.text por defecto');
      return MessageType.text;
    }
    
    try {
      final msgType = MessageType.values.firstWhere((el) => el.name == type);
      print('✅ getMsgType: type="$type" -> $msgType');
      return msgType;
    } catch (e) {
      print('❌❌❌ getMsgType: ERROR - type="$type" no encontrado en enum, devolviendo MessageType.text por defecto');
      print('❌ Error: $e');
      debugPrint('❌ getMsgType: ERROR - type="$type" no encontrado en enum, devolviendo MessageType.text por defecto');
      debugPrint('❌ Error: $e');
      return MessageType.text;
    }
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

    // Parse translations
    Map<String, String>? translations;
    if (data['translations'] != null) {
      final translationsData = data['translations'] as Map<String, dynamic>;
      translations = {};
      translationsData.forEach((lang, text) {
        translations![lang] = text.toString();
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

    // Parse viewedBy list
    List<String>? viewedBy;
    if (data['viewedBy'] != null && data['viewedBy'] is List) {
      viewedBy = List<String>.from(data['viewedBy']);
    }

    // Debug: Log fileUrl para mensajes de imagen
    // IMPORTANTE: Asegurar que fileUrl se lee correctamente desde Firebase
    String fileUrl = '';
    if (data['fileUrl'] != null) {
      fileUrl = data['fileUrl'].toString();
    }
    
    // LOG CRÍTICO: Verificar el tipo ANTES de procesar
    final rawType = data['type'];
    final parsedType = getMsgType(rawType);
    
    // VALIDACIÓN CRÍTICA: Si el tipo es image pero fileUrl está vacío, es un error
    if (parsedType == MessageType.image && fileUrl.isEmpty) {
      print('❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌ ERROR CRÍTICO: Mensaje de imagen sin fileUrl ❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌');
      print('   - msgId: $messageId');
      print('   - rawType desde Firestore: "$rawType"');
      print('   - parsedType: $parsedType');
      print('   - fileUrl: VACÍO');
      print('   - data completo: $data');
      debugPrint('❌ ERROR CRÍTICO: Mensaje de imagen sin fileUrl - msgId=$messageId, data=$data');
    }
    
    print('🔍🔍🔍 Message.fromMap: PROCESANDO MENSAJE 🔍🔍🔍');
    print('   - msgId: $messageId');
    print('   - rawType desde Firestore: "$rawType" (${rawType.runtimeType})');
    print('   - parsedType: $parsedType');
    print('   - fileUrl: ${fileUrl.isEmpty ? "VACÍO" : fileUrl.substring(0, fileUrl.length > 50 ? 50 : fileUrl.length)}...');
    print('   - fileUrl length: ${fileUrl.length}');
    debugPrint('🔍 Message.fromMap: msgId=$messageId, rawType="$rawType", parsedType=$parsedType');
    
    if (parsedType == MessageType.image) {
      debugPrint('📸 [MESSAGE_FROM_MAP] Mensaje de imagen detectado');
      debugPrint('📸 [MESSAGE_FROM_MAP] - msgId: $messageId');
      debugPrint('📸 [MESSAGE_FROM_MAP] - fileUrl raw: ${data['fileUrl']}');
      debugPrint('📸 [MESSAGE_FROM_MAP] - fileUrl type: ${data['fileUrl'].runtimeType}');
      debugPrint('📸 [MESSAGE_FROM_MAP] - fileUrl: ${fileUrl.isEmpty ? "VACÍO" : (fileUrl.length > 80 ? fileUrl.substring(0, 80) + "..." : fileUrl)}');
      debugPrint('📸 [MESSAGE_FROM_MAP] - fileUrl length: ${fileUrl.length}');
      debugPrint('📸 [MESSAGE_FROM_MAP] - fileUrl es local: ${fileUrl.startsWith("/")}');
      debugPrint('📸 [MESSAGE_FROM_MAP] - fileUrl es remoto: ${fileUrl.startsWith("http")}');
      
      // Si fileUrl está vacío pero es un mensaje de imagen, es un error crítico
      if (fileUrl.isEmpty) {
        debugPrint('❌❌❌ [MESSAGE_FROM_MAP] ERROR CRÍTICO: Mensaje de imagen sin fileUrl ❌❌❌');
        debugPrint('❌ [MESSAGE_FROM_MAP] - data completo: $data');
      }
    }
    
    final String loadedSenderId = data['senderId'] ?? '';
    final Message loadedMessage = Message(
      docRef: docRef,
      msgId: messageId,
      senderId: loadedSenderId,
      type: getMsgType(data['type']),
      textMsg: finalTextMessage,
      fileUrl: fileUrl,
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
      translations: translations,
      detectedLanguage: data['detectedLanguage'],
      translatedAt: data['translatedAt']?.toDate() as DateTime?,
      isTemporary: data['isTemporary'] ?? false,
      expiresAt: data['expiresAt']?.toDate() as DateTime?,
      viewOnce: data['viewOnce'] ?? false,
      viewedBy: viewedBy,
    );
    
    // Debug: Verificar senderId al cargar desde Firestore
    if (getMsgType(data['type']) == MessageType.image) {
      try {
        final currentUserId = AuthController.instance.currentUser.userId;
        debugPrint('📥 [STICKER] Mensaje cargado desde Firestore:');
        debugPrint('   - msgId: $messageId');
        debugPrint('   - senderId desde Firestore: $loadedSenderId');
        debugPrint('   - currentUser.userId: $currentUserId');
        debugPrint('   - isSender calculado: ${loadedMessage.isSender}');
        debugPrint('   - type: ${getMsgType(data['type'])}');
      } catch (e) {
        debugPrint('⚠️ Error al verificar senderId: $e');
      }
    }
    
    return loadedMessage;
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

    // Convert translations to map for Firestore
    Map<String, dynamic>? translationsMap;
    if (translations != null) {
      translationsMap = {};
      translations!.forEach((lang, text) {
        translationsMap![lang] = text;
      });
    }

    // IMPORTANTE: Asegurar que fileUrl siempre se guarda como String, nunca como null
    final String safeFileUrl = fileUrl.isNotEmpty ? fileUrl : '';
    
    // Debug para mensajes de imagen
    if (type == MessageType.image) {
      debugPrint('💾 [MESSAGE_TO_MAP] Guardando mensaje de imagen en Firestore');
      debugPrint('💾 [MESSAGE_TO_MAP] - msgId: $msgId');
      debugPrint('💾 [MESSAGE_TO_MAP] - fileUrl original: ${fileUrl.isEmpty ? "VACÍO" : (fileUrl.length > 80 ? fileUrl.substring(0, 80) + "..." : fileUrl)}');
      debugPrint('💾 [MESSAGE_TO_MAP] - safeFileUrl: ${safeFileUrl.isEmpty ? "VACÍO" : (safeFileUrl.length > 80 ? safeFileUrl.substring(0, 80) + "..." : safeFileUrl)}');
      debugPrint('💾 [MESSAGE_TO_MAP] - fileUrl length: ${fileUrl.length}');
      debugPrint('💾 [MESSAGE_TO_MAP] - safeFileUrl length: ${safeFileUrl.length}');
      
      if (safeFileUrl.isEmpty) {
        debugPrint('❌❌❌ [MESSAGE_TO_MAP] ERROR: Intentando guardar mensaje de imagen sin fileUrl ❌❌❌');
      }
    }
    
    return {
      'msgId': msgId,
      'senderId': senderId,
      'type': type.name,
      'textMsg': isGroup ? textMsg : EncryptHelper.encrypt(textMsg, msgId),
      'fileUrl': safeFileUrl, // Usar safeFileUrl en lugar de fileUrl directamente
      'gifUrl': gifUrl,
      'location': location?.toMap(),
      'videoThumbnail': videoThumbnail,
      'isRead': isRead,
      'isForwarded': isForwarded,
      'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : FieldValue.serverTimestamp(),
      'replyMessage': replyMessage?.toMap(isGroup: isGroup),
      'groupUpdate': groupUpdate?.toMap(),
      'reactions': reactionsMap,
      'translations': translationsMap,
      'detectedLanguage': detectedLanguage,
      'translatedAt': translatedAt,
      'isTemporary': isTemporary,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'viewOnce': viewOnce,
      'viewedBy': viewedBy,
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
