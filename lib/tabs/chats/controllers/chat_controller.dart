import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/api/chat_api.dart';
import 'package:chat_messenger/models/chat.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/services/local_cache_service.dart';
import 'package:chat_messenger/services/avatar_cache_manager.dart';

class ChatController extends GetxController {
  // Get the current instance
  static ChatController instance = Get.find();

  // Vars
  final RxBool isLoading = RxBool(true);
  final RxList<Chat> chats = RxList();
  final RxBool isSearching = RxBool(false);
  final TextEditingController searchController = TextEditingController();
  StreamSubscription<List<Chat>>? _stream;
  
  // Para manejo de eliminación con opción de deshacer
  final RxList<String> _pendingDeletions = RxList<String>();
  final RxMap<String, int> _deletedChatsCount = RxMap<String, int>(); // Contador de mensajes eliminados por chat
  Timer? _deletionTimer;
  Timer? _countdownTimer;
  final RxInt _countdown = RxInt(5);

  bool get newMessage => chats.where((el) => el.unread > 0).isNotEmpty;

  @override
  void onInit() {
    // 1) Cargar instantáneamente desde caché local
    _loadCachedChats();
    // 2) Suscribirse al stream remoto y actualizar caché cuando lleguen datos
    _getChats();
    // 3) Precargar avatares en background
    _prefetchAvatars();
    super.onInit();
  }

  @override
  void onClose() {
    _stream?.cancel();
    _deletionTimer?.cancel();
    _countdownTimer?.cancel();
    searchController.dispose();
    super.onClose();
  }

  void _getChats() {
    _stream = ChatApi.getChats().listen((event) async {
      // Procesar chats para manejar reactivación automática
      final processedChats = _processIncomingChats(event);
      chats.value = processedChats;
      isLoading.value = false;
      // Guardar en caché para próximas aperturas instantáneas
      unawaited(LocalCacheService.instance.writeChats(processedChats));
    }, onError: (e) => debugPrint(e.toString()));
  }

  List<Chat> _processIncomingChats(List<Chat> incomingChats) {
    final List<Chat> processedChats = [];
    
    for (final chat in incomingChats) {
      final userId = chat.receiver?.userId ?? '';
      final groupId = chat.groupId ?? '';
      final chatId = groupId.isNotEmpty ? groupId : userId;
      
      // Si el chat tenía mensajes eliminados, mostrar el contador
      if (_deletedChatsCount.containsKey(chatId)) {
        final deletedCount = _deletedChatsCount[chatId]!;
        // Crear una copia del chat con el contador actualizado
        final updatedChat = Chat(
          doc: chat.doc,
          senderId: chat.senderId,
          receiver: chat.receiver,
          msgType: chat.msgType,
          lastMsg: chat.lastMsg,
          msgId: chat.msgId,
          sentAt: chat.sentAt,
          updatedAt: chat.updatedAt,
          unread: chat.unread,
          isMuted: chat.isMuted,
          isDeleted: chat.isDeleted,
          deletedMessagesCount: deletedCount,
          groupId: chat.groupId,
        );
        processedChats.add(updatedChat);
        
        // Limpiar el contador temporal ya que el chat está activo de nuevo
        // (se mantiene hasta que se envíe el primer mensaje)
      } else {
        processedChats.add(chat);
      }
    }
    
    return processedChats;
  }

  Future<void> _loadCachedChats() async {
    try {
      final cached = await LocalCacheService.instance.readChats();
      if (cached.isNotEmpty) {
        chats.value = cached;
        isLoading.value = false;
      }
    } catch (e) {
      debugPrint('loadCachedChats() -> $e');
    }
  }

  Future<void> _prefetchAvatars() async {
    try {
      final urls = chats
          .map((c) => c.receiver?.photoUrl ?? '')
          .where((u) => u.isNotEmpty)
          .toSet()
          .toList();
      if (urls.isEmpty) return;
      final manager = AvatarCacheManager.instance;
      await manager.prefetch(urls);
    } catch (e) {
      debugPrint('prefetchAvatars() -> $e');
    }
  }

  Chat getChat(String receiverId) {
    final Chat chat = ChatController.instance.chats
        .firstWhere((chat) => chat.receiver!.userId == receiverId);
    return chat;
  }

  bool isChatMuted(String receiverId) {
    final Chat chat = ChatController.instance.chats
        .firstWhere((chat) => chat.receiver!.userId == receiverId);
    return chat.isMuted;
  }

  // Search chats by user full name
  List<Chat> searchChat() {
    final String text = searchController.text.trim();

    isSearching.value = text.isNotEmpty;
    return chats
        .where((chat) {
          final userId = chat.receiver?.userId ?? '';
          final groupId = chat.groupId ?? '';
          final chatId = groupId.isNotEmpty ? groupId : userId;
          
          return chat.receiver!.fullname.toLowerCase().contains(text.toLowerCase()) &&
                 !_pendingDeletions.contains(chatId);
        })
        .toList();
  }

  // Filtrar chats que no están pendientes de eliminación
  List<Chat> get visibleChats {
    return chats
        .where((chat) {
          final userId = chat.receiver?.userId ?? '';
          final groupId = chat.groupId ?? '';
          final chatId = groupId.isNotEmpty ? groupId : userId;
          return !_pendingDeletions.contains(chatId);
        })
        .toList();
  }

  void clearSerachInput(BuildContext context) {
    searchController.clear();
    isSearching.value = false;
    FocusScope.of(context).unfocus();
  }

  void deleteChat(String userId) {
    // Agregar a la lista de eliminaciones pendientes (ocultar de la UI inmediatamente)
    _pendingDeletions.add(userId);
    
    // Cancelar timers anteriores si existen
    _deletionTimer?.cancel();
    _countdownTimer?.cancel();
    
    // Resetear contador a 5 segundos
    _countdown.value = 5;
    
    // Mostrar SnackBar con contador visual
    _showUndoSnackbar(userId);
    
    // Configurar timer de 5 segundos para eliminación permanente
    _deletionTimer = Timer(const Duration(seconds: 5), () {
      _confirmDeletion(userId);
    });
    
    // Configurar countdown timer que actualiza cada segundo
    _startCountdown();
  }

  void deleteGroupChat(String groupId) {
    // Agregar a la lista de eliminaciones pendientes (ocultar de la UI inmediatamente)
    _pendingDeletions.add(groupId);
    
    // Cancelar timers anteriores si existen
    _deletionTimer?.cancel();
    _countdownTimer?.cancel();
    
    // Resetear contador a 5 segundos
    _countdown.value = 5;
    
    // Mostrar SnackBar con contador visual
    _showUndoSnackbar(groupId);
    
    // Configurar timer de 5 segundos para eliminación permanente
    _deletionTimer = Timer(const Duration(seconds: 5), () {
      _confirmGroupDeletion(groupId);
    });
    
    // Configurar countdown timer que actualiza cada segundo
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown.value > 1) {
        _countdown.value--;
      } else {
        _countdownTimer?.cancel();
      }
    });
  }

  void _showUndoSnackbar(String chatId) async {
    // Determinar si es un grupo o chat individual
    final isGroup = chatId.length > 20; // Los groupIds suelen ser más largos
    final messageCount = isGroup 
        ? await _countGroupMessages(chatId)
        : await _countMessagesInChat(chatId);
    
    final String chatType = isGroup ? 'Grupo' : 'Chat';
    final String messageText = messageCount > 0 
        ? '$chatType con $messageCount ${messageCount == 1 ? 'mensaje' : 'mensajes'} eliminado.'
        : '$chatType eliminado.';
    
    Get.snackbar(
      '',
      '',
      titleText: const SizedBox.shrink(),
      messageText: Obx(() => Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${_countdown.value}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  messageText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          )),
      backgroundColor: const Color(0xFF2F3A34).withValues(alpha: 0.90),
      colorText: Colors.white,
      // Mostrar arriba de la barra de navegación inferior
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      borderRadius: 15,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      barBlur: 20,
      duration: const Duration(seconds: 5),
      mainButton: TextButton(
        onPressed: () {
          _undoDeletion(chatId);
          Get.closeCurrentSnackbar();
        },
        child: const Text(
          'Deshacer',
          style: TextStyle(
            color: Color(0xFF42A5F5),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _undoDeletion(String chatId) {
    // Cancelar timers de eliminación y countdown
    _deletionTimer?.cancel();
    _countdownTimer?.cancel();
    
    // Remover de la lista de eliminaciones pendientes (mostrar en la UI nuevamente)
    _pendingDeletions.remove(chatId);
  }

  void _confirmDeletion(String userId) async {
    // Cancelar countdown timer
    _countdownTimer?.cancel();
    
    // Contar mensajes antes de eliminar
    final messageCount = await _countMessagesInChat(userId);
    
    // Guardar el contador para cuando el chat se reactive
    if (messageCount > 0) {
      _deletedChatsCount[userId] = messageCount;
    }
    
    // Eliminar permanentemente del servidor
    ChatApi.deleteChat(userId: userId);
    
    // Remover de la lista de eliminaciones pendientes
    _pendingDeletions.remove(userId);
    
    debugPrint('Chat eliminado. Mensajes contados: $messageCount');
  }

  Future<int> _countMessagesInChat(String userId) async {
    try {
      // Obtener referencia a la colección de mensajes
      final User currentUser = AuthController.instance.currentUser;
      final messagesCollection = ChatApi.firestore
          .collection('Users/${currentUser.userId}/Chats/$userId/Messages');
      
      // Contar documentos
      final snapshot = await messagesCollection.get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error counting messages: $e');
      return 0;
    }
  }

  // Método público para limpiar el contador de mensajes eliminados
  // Se llama cuando se envía un nuevo mensaje a un chat reactivado
  void clearDeletedMessagesCount(String chatId) {
    _deletedChatsCount.remove(chatId);
    
    // Buscar el chat por userId o groupId
    final chatIndex = chats.indexWhere((c) => 
      (c.receiver?.userId == chatId) || (c.groupId == chatId)
    );
    
    if (chatIndex != -1) {
      final chat = chats[chatIndex];
      if (chat.deletedMessagesCount > 0) {
        // Crear una copia del chat sin el contador
        final updatedChat = Chat(
          doc: chat.doc,
          senderId: chat.senderId,
          receiver: chat.receiver,
          msgType: chat.msgType,
          lastMsg: chat.lastMsg,
          msgId: chat.msgId,
          sentAt: chat.sentAt,
          updatedAt: chat.updatedAt,
          unread: chat.unread,
          isMuted: chat.isMuted,
          isDeleted: chat.isDeleted,
          deletedMessagesCount: 0, // Limpiar contador
          groupId: chat.groupId,
        );
        chats[chatIndex] = updatedChat;
      }
    }
  }

  void _confirmGroupDeletion(String groupId) async {
    // Cancelar countdown timer
    _countdownTimer?.cancel();
    
    // Contar mensajes antes de eliminar
    final messageCount = await _countGroupMessages(groupId);
    
    // Guardar el contador para cuando el chat se reactive
    if (messageCount > 0) {
      _deletedChatsCount[groupId] = messageCount;
    }
    
    // Eliminar permanentemente del servidor
    ChatApi.deleteGroupChat(groupId: groupId);
    
    // Remover de la lista de eliminaciones pendientes
    _pendingDeletions.remove(groupId);
    
    debugPrint('Grupo eliminado. Mensajes contados: $messageCount');
  }

  Future<int> _countGroupMessages(String groupId) async {
    try {
      // Obtener referencia a la colección de mensajes del grupo
      final messagesCollection = ChatApi.firestore
          .collection('Groups/$groupId/Messages');
      
      // Contar documentos
      final snapshot = await messagesCollection.get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error counting group messages: $e');
      return 0;
    }
  }
}
