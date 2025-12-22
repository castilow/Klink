import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

/// Controlador para manejar el chatId actual de las conversaciones con Klink AI
class KlinkAIChatController extends GetxController {
  static KlinkAIChatController get instance => Get.find<KlinkAIChatController>();

  // ChatId actual de la conversación activa
  final RxString currentChatId = ''.obs;

  // Inicializar con un nuevo chatId
  void initializeNewChat() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    currentChatId.value = 'klink_ai_$timestamp';
    debugPrint('🆕 Nueva conversación creada: ${currentChatId.value}');
  }

  // Establecer un chatId específico (para cargar conversaciones del historial)
  void setChatId(String chatId) {
    currentChatId.value = chatId;
    debugPrint('📂 ChatId establecido: $chatId');
  }

  // Obtener el chatId actual o crear uno nuevo si no existe
  String getChatId() {
    if (currentChatId.value.isEmpty) {
      initializeNewChat();
    }
    return currentChatId.value;
  }

  // Verificar si hay un chatId activo
  bool hasActiveChat() {
    return currentChatId.value.isNotEmpty;
  }
}

