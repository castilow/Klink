import 'package:get/get.dart';
import 'package:chat_messenger/api/chatgpt_api.dart';
import 'package:chat_messenger/api/message_api.dart';
import 'package:chat_messenger/models/message.dart';
import 'package:chat_messenger/models/ai_assistant_user.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/helpers/app_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AssistantController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isTyping = false.obs;
  final RxString lastResponse = ''.obs;
  final RxList<Map<String, String>> conversationHistory = <Map<String, String>>[].obs;
  
  // ID del usuario asistente (Klink AI)
  static const String assistantUserId = 'klink_ai_assistant';
  
  final _firestore = FirebaseFirestore.instance;
  
  // Protección contra múltiples llamadas simultáneas
  bool _isProcessing = false;

  /// Pregunta al asistente con imagen y guarda en Firestore
  Future<String?> askAssistantWithImage(String question, String imageBase64) async {
    // Protección contra múltiples llamadas simultáneas
    if (_isProcessing) {
      debugPrint('⚠️ AssistantController.askAssistantWithImage: Ya hay una petición en proceso, ignorando...');
      return null;
    }
    
    _isProcessing = true;
    try {
      debugPrint('🟢 AssistantController.askAssistantWithImage: Iniciando con pregunta y imagen');
      isLoading.value = true;
      isTyping.value = true;
      
      final currentUser = AuthController.instance.currentUser;
      debugPrint('🟢 AssistantController.askAssistantWithImage: Usuario actual: ${currentUser.userId}');
      
      // Marcar al asistente como "escribiendo"
      await _setAssistantTypingStatus(true, currentUser.userId);
      debugPrint('🟢 AssistantController.askAssistantWithImage: Estado de escritura actualizado');
      
      // Agregar pregunta al historial local
      conversationHistory.add({
        'role': 'user',
        'content': question,
      });
      debugPrint('🟢 AssistantController.askAssistantWithImage: Historial actualizado, total: ${conversationHistory.length}');
      
      // Obtener respuesta de ChatGPT con imagen
      debugPrint('🟢 AssistantController.askAssistantWithImage: Llamando a ChatGPTApi.sendMessage con imagen...');
      final response = await ChatGPTApi.sendMessage(
        message: question.isNotEmpty ? question : '¿Qué ves en esta imagen?',
        conversationHistory: conversationHistory.take(10).toList(),
        imageBase64: imageBase64,
      );
      debugPrint('🟢 AssistantController.askAssistantWithImage: Respuesta recibida de ChatGPTApi');
      
      // Desmarcar al asistente como "escribiendo"
      await _setAssistantTypingStatus(false, currentUser.userId);
      isTyping.value = false;
      
      if (response != null && response.isNotEmpty) {
        // Agregar respuesta al historial local
        conversationHistory.add({
          'role': 'assistant',
          'content': response,
        });
        
        lastResponse.value = response;
        
        // Guardar respuesta del asistente en Firestore
        final assistantMessage = Message(
          msgId: AppHelper.generateID,
          senderId: assistantUserId,
          type: MessageType.text,
          textMsg: response,
        );
        
        await MessageApi.sendAssistantMessage(
          message: assistantMessage,
          receiver: currentUser,
        );
        debugPrint('🟢 AssistantController.askAssistantWithImage: Mensaje del asistente guardado exitosamente');
        
        return response;
      } else {
        debugPrint('⚠️ AssistantController.askAssistantWithImage: Respuesta vacía o nula');
        final errorMessage = Message(
          msgId: AppHelper.generateID,
          senderId: assistantUserId,
          type: MessageType.text,
          textMsg: response ?? 'Lo siento, no pude procesar tu solicitud.',
        );
        
        await MessageApi.sendAssistantMessage(
          message: errorMessage,
          receiver: currentUser,
        );
        
        return response;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ AssistantController.askAssistantWithImage: Error capturado: $e');
      debugPrint('❌ AssistantController.askAssistantWithImage: StackTrace: $stackTrace');
      await _setAssistantTypingStatus(false, AuthController.instance.currentUser.userId);
      isTyping.value = false;
      
      final errorMsg = 'Ocurrió un error al analizar la imagen. Por favor, inténtalo más tarde.';
      
      final currentUser = AuthController.instance.currentUser;
      final errorMessage = Message(
        msgId: AppHelper.generateID,
        senderId: assistantUserId,
        type: MessageType.text,
        textMsg: errorMsg,
      );
      
      await MessageApi.sendAssistantMessage(
        message: errorMessage,
        receiver: currentUser,
      );
      
      return errorMsg;
    } finally {
      _isProcessing = false;
      isLoading.value = false;
      isTyping.value = false;
      debugPrint('🟢 AssistantController.askAssistantWithImage: Finalizado');
    }
  }

  /// Pregunta al asistente y guarda en Firestore
  Future<String?> askAssistant(String question) async {
    // Protección contra múltiples llamadas simultáneas
    if (_isProcessing) {
      debugPrint('⚠️ AssistantController.askAssistant: Ya hay una petición en proceso, ignorando...');
      return null;
    }
    
    _isProcessing = true;
    try {
      debugPrint('🟢 AssistantController.askAssistant: Iniciando con pregunta: $question');
      isLoading.value = true;
      isTyping.value = true;
      
      final currentUser = AuthController.instance.currentUser;
      debugPrint('🟢 AssistantController.askAssistant: Usuario actual: ${currentUser.userId}');
      
      // Marcar al asistente como "escribiendo"
      await _setAssistantTypingStatus(true, currentUser.userId);
      debugPrint('🟢 AssistantController.askAssistant: Estado de escritura actualizado');
      
      // Agregar pregunta al historial local
      // NOTA: El mensaje del usuario ya se guardó en message_controller.dart antes de llamar a este método
      conversationHistory.add({
        'role': 'user',
        'content': question,
      });
      debugPrint('🟢 AssistantController.askAssistant: Historial actualizado, total: ${conversationHistory.length}');
      
      // Obtener respuesta de ChatGPT a través de Firebase Functions
      debugPrint('🟢 AssistantController.askAssistant: Llamando a ChatGPTApi.sendMessage...');
      debugPrint('🟢 AssistantController.askAssistant: Historial a enviar: ${conversationHistory.take(10).toList()}');
      final response = await ChatGPTApi.sendMessage(
        message: question,
        conversationHistory: conversationHistory.take(10).toList(), // Últimos 10 mensajes
      );
      debugPrint('🟢 AssistantController.askAssistant: Respuesta recibida de ChatGPTApi');
      debugPrint('🟢 AssistantController.askAssistant: response != null: ${response != null}');
      debugPrint('🟢 AssistantController.askAssistant: response.isNotEmpty: ${response?.isNotEmpty ?? false}');
      if (response != null) {
        final previewLength = response.length > 100 ? 100 : response.length;
        debugPrint('🟢 AssistantController.askAssistant: Respuesta preview: ${response.substring(0, previewLength)}...');
      }
      
      // Desmarcar al asistente como "escribiendo"
      debugPrint('🟢 AssistantController.askAssistant: Desmarcando estado de escritura...');
      await _setAssistantTypingStatus(false, currentUser.userId);
      isTyping.value = false;
      debugPrint('🟢 AssistantController.askAssistant: Estado de escritura desmarcado');
      
      if (response != null && response.isNotEmpty) {
        debugPrint('🟢 AssistantController.askAssistant: Respuesta válida, guardando...');
        // Agregar respuesta al historial local
        conversationHistory.add({
          'role': 'assistant',
          'content': response,
        });
        
        lastResponse.value = response;
        
        // Guardar respuesta del asistente en Firestore usando MessageApi
        final assistantMessage = Message(
          msgId: AppHelper.generateID,
          senderId: assistantUserId,
          type: MessageType.text,
          textMsg: response,
        );
        
        debugPrint('🟢 AssistantController.askAssistant: Guardando mensaje del asistente en Firestore...');
        await MessageApi.sendAssistantMessage(
          message: assistantMessage,
          receiver: currentUser,
        );
        debugPrint('🟢 AssistantController.askAssistant: Mensaje del asistente guardado exitosamente');
        
        return response;
      } else {
        debugPrint('⚠️ AssistantController.askAssistant: Respuesta vacía o nula');
        // Guardar la respuesta de error que ya viene de ChatGPTApi
        final errorMessage = Message(
          msgId: AppHelper.generateID,
          senderId: assistantUserId,
          type: MessageType.text,
          textMsg: response ?? 'Lo siento, no pude procesar tu solicitud.',
        );
        
        await MessageApi.sendAssistantMessage(
          message: errorMessage,
          receiver: currentUser,
        );
        
        return response;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ AssistantController.askAssistant: Error capturado: $e');
      debugPrint('❌ AssistantController.askAssistant: StackTrace: $stackTrace');
      await _setAssistantTypingStatus(false, AuthController.instance.currentUser.userId);
      isTyping.value = false;
      
      final errorMsg = 'Ocurrió un error al comunicarme con el asistente. Por favor, inténtalo más tarde.';
      
      final currentUser = AuthController.instance.currentUser;
      final errorMessage = Message(
        msgId: AppHelper.generateID,
        senderId: assistantUserId,
        type: MessageType.text,
        textMsg: errorMsg,
      );
      
      await MessageApi.sendAssistantMessage(
        message: errorMessage,
        receiver: currentUser,
      );
      
      return errorMsg;
    } finally {
      _isProcessing = false;
      isLoading.value = false;
      isTyping.value = false;
      debugPrint('🟢 AssistantController.askAssistant: Finalizado');
    }
  }

  /// Establece el estado de "escribiendo" del asistente
  Future<void> _setAssistantTypingStatus(bool isTyping, String typingTo) async {
    try {
      await _firestore.collection('Users').doc(assistantUserId).update({
        'isTyping': isTyping,
        'typingTo': isTyping ? typingTo : '',
      });
      debugPrint('🟢 _setAssistantTypingStatus: Estado actualizado correctamente');
    } catch (e) {
      debugPrint('⚠️ _setAssistantTypingStatus: Error actualizando estado de escritura: $e');
      // No lanzar el error, solo registrar
    }
  }

  
  void clearConversation() {
    conversationHistory.clear();
    lastResponse.value = '';
  }

  /// Carga el historial de conversación desde Firestore
  Future<void> loadConversationHistory() async {
    try {
      final currentUser = AuthController.instance.currentUser;
      
      final querySnapshot = await _firestore
          .collection('Messages')
          .where('senderId', whereIn: [currentUser.userId, assistantUserId])
          .where('receiverId', whereIn: [currentUser.userId, assistantUserId])
          .orderBy('sentAt', descending: false)
          .limit(20)
          .get();
      
      conversationHistory.clear();
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final isSender = data['senderId'] == currentUser.userId;
        
        conversationHistory.add({
          'role': isSender ? 'user' : 'assistant',
          'content': data['textMsg'] ?? '',
        });
      }
    } catch (e) {
      print('Error cargando historial: $e');
    }
  }
}

