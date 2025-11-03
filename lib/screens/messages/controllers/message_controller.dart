import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:chat_messenger/api/chat_api.dart';
import 'package:chat_messenger/api/message_api.dart';
import 'package:chat_messenger/api/user_api.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/helpers/app_helper.dart';
import 'package:chat_messenger/helpers/encrypt_helper.dart';
import 'package:flutter/material.dart';
import 'package:chat_messenger/helpers/dialog_helper.dart';
import 'package:chat_messenger/helpers/routes_helper.dart';

import 'package:chat_messenger/models/group.dart';
import 'package:chat_messenger/models/location.dart';
import 'package:chat_messenger/models/message.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:chat_messenger/tabs/groups/controllers/group_controller.dart';
import 'package:get/get.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class MessageController extends GetxController {
  final bool isGroup;
  final User? user;

  MessageController({
    required this.isGroup,
    this.user,
  });
  
  // Singleton instance for global audio control
  static MessageController? _globalInstance;
  
  static MessageController get globalInstance {
    _globalInstance ??= MessageController(isGroup: false);
    return _globalInstance!;
  }

  // Variables
  final GroupController _groupController = Get.find();
  final chatFocusNode = FocusNode();
  final textController = TextEditingController();
  final scrollController = ScrollController();

  // Message vars
  final RxBool isLoading = RxBool(true);
  final RxList<Message> messages = RxList();
  StreamSubscription<List<Message>>? _stream;

  // Obx & other vars
  final RxBool showEmoji = RxBool(false);
  final RxBool isTextMsg = RxBool(false);
  final RxBool isUploading = RxBool(false);
  final RxBool showScrollButton = RxBool(false);
  final RxList<File> documents = RxList([]);
  final RxList<File> uploadingFiles = RxList([]);
  final RxBool isChatMuted = RxBool(false);
  final Rxn<Message> selectedMessage = Rxn();
  final Rxn<Message> replyMessage = Rxn();
  final Rxn<Message> editingMessage = Rxn();
  
  // Multi-selection vars
  final RxBool isMultiSelectMode = RxBool(false);
  final RxList<Message> selectedMessages = RxList<Message>([]);
  
  // Pending deletions with undo (messages)
  final RxList<Message> _pendingMessageDeletions = RxList<Message>([]);
  // Keep original indexes to restore messages in the same position on undo
  final Map<String, int> _pendingDeletionIndexes = <String, int>{};
  Timer? _messageDeletionTimer;
  Timer? _messageCountdownTimer;
  final RxInt _messageCountdown = RxInt(5);
  
  // Audio recording vars
  final RxBool isRecording = RxBool(false);
  final RxString recordingDuration = RxString('00:00');
  final RxBool isRecordingPaused = RxBool(false);
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _recordingPath;
  Timer? _recordingTimer;
  final Rx<Duration> recordingDurationValue = Rx<Duration>(Duration.zero);
  final RxBool showRecordingOverlay = RxBool(false);
  final RxBool isMicPressed = RxBool(false);
  final RxBool showVoiceRecordingBar = RxBool(false);
  final RxBool isRecordingLocked = RxBool(false);
  
  // Normal vars
  bool isReceiverOnline = false;
  
  // Audio player variables
  final AudioPlayer audioPlayer = AudioPlayer();
  bool isPlaying = false;
  String? currentPlayingMessageId;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  double playbackSpeed = 1.0;
  
  // Global audio player bar
  Rx<Message?> currentPlayingMessage = Rx<Message?>(null);
  RxBool showAudioPlayerBar = false.obs;

  bool get isReplying => replyMessage.value != null;
  bool get isEditing => editingMessage.value != null;
  Group? get selectedGroup => _groupController.selectedGroup.value;
  void clearSelectedMsg() => selectedMessage.value = null;
  
  // Multi-selection methods
  bool get hasSelectedMessages => selectedMessages.isNotEmpty;
  int get selectedCount => selectedMessages.length;
  
  bool isMessageSelected(Message message) {
    return selectedMessages.any((msg) => msg.msgId == message.msgId);
  }
  
  void enterMultiSelectMode(Message message) {
    isMultiSelectMode.value = true;
    selectedMessages.clear();
    selectedMessages.add(message);
  }
  
  void exitMultiSelectMode() {
    isMultiSelectMode.value = false;
    selectedMessages.clear();
  }
  
  void toggleMessageSelection(Message message) {
    if (isMessageSelected(message)) {
      selectedMessages.removeWhere((msg) => msg.msgId == message.msgId);
      if (selectedMessages.isEmpty) {
        exitMultiSelectMode();
      }
    } else {
      selectedMessages.add(message);
    }
  }
  
  void selectAllMessages() {
    selectedMessages.clear();
    selectedMessages.addAll(messages.where((msg) => !msg.isDeleted));
  }
  
  // Audio recording methods
  Future<void> startRecording() async {
    try {
      // Check permissions
      if (!await _audioRecorder.hasPermission()) {
        DialogHelper.showSnackbarMessage(
          SnackMsgType.error,
          'Se necesita permiso de micrófono para grabar audio',
        );
        return;
      }

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      _recordingPath = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Start recording
      await _audioRecorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _recordingPath!,
      );

      isRecording.value = true;
      _startRecordingTimer();
    } catch (e) {
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'Error al iniciar grabación: $e',
      );
    }
  }





  // Audio player methods
  Future<void> playAudio(Message message) async {
    try {
      // Stop current audio if playing
      if (isPlaying) {
        await audioPlayer.stop();
      }
      
      // Set new message as current
      currentPlayingMessage.value = message;
      currentPlayingMessageId = message.msgId;
      showAudioPlayerBar.value = true;
      
      // Get audio file path
      final audioPath = message.fileUrl;
      if (audioPath.isEmpty) {
        DialogHelper.showSnackbarMessage(
          SnackMsgType.error,
          'No se encontró el archivo de audio',
        );
        return;
      }
      
      // Check if it's a URL or local file and play accordingly
      if (audioPath.startsWith('http')) {
        // Remote URL - validate URL format
        try {
          Uri.parse(audioPath);
          await audioPlayer.play(UrlSource(audioPath));
        } catch (e) {
          DialogHelper.showSnackbarMessage(
            SnackMsgType.error,
            'URL de audio inválida',
          );
          return;
        }
      } else {
        // Local file - check if file exists
        final file = File(audioPath);
        if (!await file.exists()) {
          DialogHelper.showSnackbarMessage(
            SnackMsgType.error,
            'El archivo de audio no existe',
          );
          return;
        }
        await audioPlayer.play(DeviceFileSource(audioPath));
      }
      isPlaying = true;
      
      // Listen to position changes
      audioPlayer.onPositionChanged.listen((position) {
        currentPosition = position;
      });
      
      // Listen to duration changes
      audioPlayer.onDurationChanged.listen((duration) {
        totalDuration = duration;
      });
      
      // Listen to player state changes
      audioPlayer.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.completed) {
          isPlaying = false;
          currentPlayingMessageId = null;
          showAudioPlayerBar.value = false;
          currentPlayingMessage.value = null;
        } else if (state == PlayerState.stopped) {
          isPlaying = false;
        }
      });
      
    } catch (e) {
      debugPrint('Audio playback error: $e');
      
      // Provide more specific error messages
      String errorMessage = 'No se pudo reproducir el audio.';
      if (e.toString().contains('Failed to set source')) {
        errorMessage = 'El archivo de audio no es válido o no existe.';
      } else if (e.toString().contains('Network')) {
        errorMessage = 'Error de red al cargar el audio.';
      } else if (e.toString().contains('Permission')) {
        errorMessage = 'Sin permisos para acceder al archivo de audio.';
      }
      
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        errorMessage,
      );
      
      // Reset state on error
      isPlaying = false;
      currentPlayingMessageId = null;
      showAudioPlayerBar.value = false;
      currentPlayingMessage.value = null;
    }
  }
  
  Future<void> pauseAudio() async {
    try {
      await audioPlayer.pause();
      isPlaying = false;
    } catch (e) {
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'Error al pausar audio: $e',
      );
    }
  }
  
  Future<void> resumeAudio() async {
    try {
      await audioPlayer.resume();
      isPlaying = true;
    } catch (e) {
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'Error al reanudar audio: $e',
      );
    }
  }
  
  Future<void> stopAudio() async {
    try {
      await audioPlayer.stop();
      isPlaying = false;
      currentPlayingMessageId = null;
      showAudioPlayerBar.value = false;
      currentPlayingMessage.value = null;
    } catch (e) {
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'Error al detener audio: $e',
      );
    }
  }
  
  Future<void> changePlaybackSpeed() async {
    try {
      // Cycle through speeds: 1.0 -> 1.5 -> 2.0 -> 1.0
      if (playbackSpeed == 1.0) {
        playbackSpeed = 1.5;
      } else if (playbackSpeed == 1.5) {
        playbackSpeed = 2.0;
      } else {
        playbackSpeed = 1.0;
      }
      
      await audioPlayer.setPlaybackRate(playbackSpeed);
    } catch (e) {
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'Error al cambiar velocidad: $e',
      );
    }
  }
  

  
  void disposeGlobalInstance() {
    // Clean up global instance if this is the global instance
    if (this == _globalInstance) {
      _globalInstance = null;
    }
  }
  
  void _startRecordingTimer() {
    int milliseconds = 0;
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      milliseconds += 100;
      recordingDurationValue.value = Duration(milliseconds: milliseconds);
      final minutes = milliseconds ~/ 60000;
      final remainingSeconds = (milliseconds % 60000) ~/ 1000;
      final remainingMilliseconds = (milliseconds % 1000) ~/ 10;
      recordingDuration.value = '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')},${remainingMilliseconds.toString().padLeft(2, '0')}';
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    recordingDuration.value = '00:00';
    recordingDurationValue.value = Duration.zero;
    showRecordingOverlay.value = false;
    showVoiceRecordingBar.value = false;
    isMicPressed.value = false;
    isRecordingLocked.value = false;
  }
  
  // New recording methods for bottom bar
  Future<void> startVoiceRecording() async {
    try {
      // Check permissions
      if (!await _audioRecorder.hasPermission()) {
        DialogHelper.showSnackbarMessage(
          SnackMsgType.error,
          'Se necesita permiso de micrófono para grabar audio',
        );
        return;
      }

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      _recordingPath = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Start recording
      await _audioRecorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _recordingPath!,
      );

      isRecording.value = true;
      showVoiceRecordingBar.value = true;
      isMicPressed.value = true;
      _startRecordingTimer();
    } catch (e) {
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'Error al iniciar grabación: $e',
      );
    }
  }
  
  void onMicPressed() {
    isMicPressed.value = true;
    if (!isRecording.value) {
      startVoiceRecording();
    }
  }
  
  void onMicReleased() {
    isMicPressed.value = false;
    if (isRecording.value) {
      stopRecordingAndSend();
    }
  }
  
  void onMicCancelled() {
    isMicPressed.value = false;
    if (isRecording.value) {
      cancelRecording();
    }
  }
  
  void onLockRecording() {
    isRecordingLocked.value = true;
    debugPrint('Grabación bloqueada - modo manos libres activado');
  }
  
  void onPauseRecording() {
    isRecording.value = false;
    isRecordingLocked.value = false;
    showVoiceRecordingBar.value = false;
    if (_recordingTimer != null) {
      _recordingTimer!.cancel();
      _recordingTimer = null;
    }
    debugPrint('Grabación pausada');
  }
  
  Future<void> stopRecordingAndSend() async {
    try {
      if (!isRecording.value || _recordingPath == null) return;

      // Stop recording
      await _audioRecorder.stop();
      _stopRecordingTimer();
      isRecording.value = false;
      showRecordingOverlay.value = false;
      showVoiceRecordingBar.value = false;

      // Check if recording is too short
      final file = File(_recordingPath!);
      if (await file.exists()) {
        final fileSize = await file.length();
        if (fileSize < 1000) { // Less than 1KB
          await file.delete();
          return;
        }

        // Send audio message
        await sendMessage(MessageType.audio, file: file);
      }
    } catch (e) {
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'Error al enviar audio: $e',
      );
    }
  }
  
  Future<void> cancelRecording() async {
    try {
      if (!isRecording.value) return;

      // Stop recording
      await _audioRecorder.stop();
      _stopRecordingTimer();
      isRecording.value = false;
      showRecordingOverlay.value = false;
      showVoiceRecordingBar.value = false;

      // Delete recording file
      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Recording cancelled silently
    } catch (e) {
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'Error al cancelar grabación: $e',
      );
    }
  }

  Future<void> deleteSelectedMessages() async {
    if (selectedMessages.isEmpty) return;
    await _deleteMessagesWithUndo(List<Message>.from(selectedMessages));
    exitMultiSelectMode();
  }

  Future<void> _deleteMessagesWithUndo(List<Message> toDelete) async {
    // Ocultar inmediatamente de la UI
    for (final msg in toDelete) {
      final idx = messages.indexWhere((m) => m.msgId == msg.msgId);
      if (idx != -1) {
        _pendingDeletionIndexes[msg.msgId] = idx; // save index for undo
        messages.removeAt(idx);
      }
    }
    _pendingMessageDeletions.clear();
    _pendingMessageDeletions.addAll(toDelete);
    _messageCountdown.value = 5;

    // Mostrar snackbar con contador y opción de deshacer
    _showMessagesUndoSnackbar();

    // Timer de confirmación
    _messageDeletionTimer?.cancel();
    _messageDeletionTimer = Timer(const Duration(seconds: 5), () async {
      await _confirmMessagesDeletion();
    });

    // Timer de countdown
    _messageCountdownTimer?.cancel();
    _messageCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_messageCountdown.value > 1) {
        _messageCountdown.value--;
      } else {
        _messageCountdownTimer?.cancel();
      }
    });
  }

  void _showMessagesUndoSnackbar() {
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
                    '${_messageCountdown.value}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Mensaje(s) eliminado(s).',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          )),
      // Barra oscura tipo "barrita" con 90% opacidad
      backgroundColor: const Color(0xFF2F3A34).withValues(alpha: 0.90),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.fromLTRB(16, 88, 16, 16),
      borderRadius: 15,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      barBlur: 20, // efecto espejo (blur)
      duration: const Duration(seconds: 5),
      mainButton: TextButton(
        onPressed: () {
          _undoMessagesDeletion();
          Get.closeCurrentSnackbar();
        },
        child: const Text(
          'Deshacer',
          style: TextStyle(
            color: Color(0xFF42A5F5), // azul claro
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _undoMessagesDeletion() {
    _messageDeletionTimer?.cancel();
    _messageCountdownTimer?.cancel();
    // Reinsertar mensajes en su índice original para mantener posición
    for (final msg in _pendingMessageDeletions) {
      final idx = _pendingDeletionIndexes[msg.msgId];
      if (idx != null && idx >= 0 && idx <= messages.length) {
        messages.insert(idx, msg);
      } else {
        messages.insert(0, msg);
      }
    }
    _pendingMessageDeletions.clear();
    _pendingDeletionIndexes.clear();
  }

  Future<void> _confirmMessagesDeletion() async {
    _messageCountdownTimer?.cancel();
    final List<Message> toDelete = List<Message>.from(_pendingMessageDeletions);
    _pendingMessageDeletions.clear();
    
    // Verificar que user no sea null antes de proceder
    if (user == null) {
      debugPrint('Error: user is null in _confirmMessagesDeletion');
      return;
    }
    
    for (final message in toDelete) {
      await MessageApi.deleteMessageForever(
        isGroup: isGroup,
        msgId: message.msgId,
        group: selectedGroup,
        receiverId: user!.userId,
        replaceMsg: getReplaceMessage(message),
      );
    }
  }

  // Public method to reload messages
  void reloadMessages() {
    isLoading.value = true;
    messages.clear();
    _getMessages();
  }

  @override
  void onInit() {
    // Get selected group instance
    _groupController.getSelectedGroup();

    // Get messages
    _getMessages();
    // Check
    if (!isGroup) {
      _scrollControllerListener();
      _checkMuteStatus();
      ever(isTextMsg, (value) {
        UserApi.updateUserTypingStatus(value, user!.userId);
      });
    }
    super.onInit();
  }

  @override
  void onClose() {
    // Clear the previous one
    _groupController.clearSelectedGroup();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    chatFocusNode.dispose();
    textController.dispose();
    scrollController.dispose();
    _stream?.cancel();
    super.onClose();
  }

  // Get Message Updates
  void _getMessages() {
    if (isGroup) {
      _stream =
          MessageApi.getGroupMessages(selectedGroup!.groupId).listen((event) {
        debugPrint('Group Messages Received: ${event.length}');
        // Log individual messages for debugging
        for (var message in event) {
          debugPrint('Group Message - ID: ${message.msgId}, Type: ${message.type}, Text: ${message.textMsg.isEmpty ? "Empty" : "Has content"}');
        }
        messages.value = event;
        isLoading.value = false;
        scrollToBottom();
      }, onError: (e) {
        debugPrint('Error fetching group messages: $e');
        // Set loading to false even on error to show error state
        isLoading.value = false;
        // Clear messages on error
        messages.clear();
      });
    } else {
      final currentUser = AuthController.instance.currentUser;
      debugPrint('Current User ID: ${currentUser.userId}');
      debugPrint('Chat User ID: ${user!.userId}');
      
      _stream = MessageApi.getMessages(user!.userId).listen((event) {
        debugPrint('Messages Received: ${event.length}');
        // Log individual messages for debugging
        for (var message in event) {
          debugPrint('Private Message - ID: ${message.msgId}, Type: ${message.type}, Text: ${message.textMsg.isEmpty ? "Empty" : "Has content"}, IsDeleted: ${message.isDeleted}');
        }
        messages.value = event;
        isLoading.value = false;
        scrollToBottom();
      }, onError: (e) {
        debugPrint('Error fetching messages: $e');
        // Set loading to false even on error to show error state  
        isLoading.value = false;
        // Clear messages on error
        messages.clear();
      });
    }
  }

  // <-- Send Message Method -->
  Future<void> sendMessage(
    MessageType type, {
    File? file,
    String? text,
    String? gifUrl,
    Location? location,
  }) async {
    // Vars
    String? textMsg, fileUrl;
    final String messageId = AppHelper.generateID;

    // Check msg type
    switch (type) {
      case MessageType.text:
        // Get text msg
        textMsg = text;
        break;

      case MessageType.image:
      case MessageType.doc:
      case MessageType.video:
      case MessageType.audio:
        // Para archivos, crear el mensaje inmediatamente con el archivo local
        final Message tempMessage = Message(
          msgId: messageId,
          type: type,
          textMsg: textMsg ?? '',
          fileUrl: file!.path, // Usar path local temporalmente para preview
          gifUrl: gifUrl ?? '',
          location: location,
          videoThumbnail: '', // No thumbnail
          senderId: AuthController.instance.currentUser.userId,
          isRead: false,
          replyMessage: replyMessage.value,
        );

        // Agregar mensaje temporal a la lista inmediatamente
        messages.insert(0, tempMessage);
        scrollToBottom();

        // Subir archivo en background
        fileUrl = await _uploadFile(file);
        
        // Actualizar mensaje con URL final
        final int index = messages.indexWhere((m) => m.msgId == messageId);
        if (index != -1) {
          final updatedMessage = Message(
            msgId: messageId,
            type: type,
            textMsg: textMsg ?? '',
            fileUrl: fileUrl ?? '', // URL del servidor
            gifUrl: gifUrl ?? '',
            location: location,
            videoThumbnail: '', // No thumbnail
            senderId: AuthController.instance.currentUser.userId,
            isRead: isReceiverOnline,
            replyMessage: replyMessage.value,
          );
          messages[index] = updatedMessage;
        }
        break;
      default:
        // Do nothing..
        break;
    }

    // <--- Build final message --->
    final Message message = Message(
      msgId: messageId,
      type: type,
      textMsg: textMsg ?? '',
      fileUrl: fileUrl ?? '',
      gifUrl: gifUrl ?? '',
      location: location,
      videoThumbnail: '', // No thumbnail
      senderId: AuthController.instance.currentUser.userId,
      isRead: isReceiverOnline,
      replyMessage: replyMessage.value,
    );

    // Para mensajes sin archivo, agregar a la lista ahora
    if (type == MessageType.text || type == MessageType.location || type == MessageType.gif || type == MessageType.audio) {
      messages.insert(0, message);
      scrollToBottom();
    }

    // Send to API
    if (isGroup) {
      final Group group = selectedGroup!;
      // Check broadcast
      if (group.isBroadcast) {
        MessageApi.sendBroadcastMessage(group: group, message: message);
      } else {
        MessageApi.sendGroupMessage(group: group, message: message);
      }
    } else {
      MessageApi.sendMessage(message: message, receiver: user!);
    }

    // Reset values and update UI
    isTextMsg.value = false;
    textController.clear();
    selectedMessage.value = null;
    replyMessage.value = null;
  }

  Future<void> forwardMessage(Message message) async {
    final List? contacts = await RoutesHelper.toSelectContacts(
        title: 'forward_to'.tr, showGroups: true, isBroadcast: false);
    if (contacts == null) return;
    // Decrypt private message on forward
    if (!isGroup) {
      message.textMsg = EncryptHelper.decrypt(message.textMsg, message.msgId);
    }
    MessageApi.forwardMessage(message: message, contacts: contacts);
  }

  // <-- Handle Reactions -->
  Future<void> toggleReaction(String emoji, Message message) async {
    final String currentUserId = AuthController.instance.currentUser.userId;
    
    // Verificar que user no sea null antes de proceder
    if (user == null) {
      debugPrint('Error: user is null in toggleReaction');
      return;
    }
    
    try {
      // Update the message locally first for immediate feedback
      final updatedMessage = message.toggleReaction(emoji, currentUserId);
      final messageIndex = messages.indexWhere((m) => m.msgId == message.msgId);
      
      if (messageIndex != -1) {
        messages[messageIndex] = updatedMessage;
      }
      
      // Update the message in Firestore
      await MessageApi.updateMessageReaction(
        isGroup: isGroup,
        message: updatedMessage,
        emoji: emoji,
        userId: currentUserId,
        receiverId: user!.userId,
        groupId: selectedGroup?.groupId,
      );
      
    } catch (e) {
      debugPrint('toggleReaction() -> error: $e');
      // Revert local change on error
      final messageIndex = messages.indexWhere((m) => m.msgId == message.msgId);
      if (messageIndex != -1) {
        messages[messageIndex] = message;
      }
    }
  }

  // Get reactions for a specific message
  Map<String, List<String>>? getMessageReactions(String messageId) {
    final message = messages.firstWhereOrNull((m) => m.msgId == messageId);
    return message?.reactions;
  }

  // Check if current user reacted to a message with specific emoji
  bool hasUserReacted(String messageId, String emoji) {
    final message = messages.firstWhereOrNull((m) => m.msgId == messageId);
    return message?.hasUserReacted(emoji) ?? false;
  }

  // Get total reaction count for a message
  int getTotalReactions(String messageId) {
    final message = messages.firstWhereOrNull((m) => m.msgId == messageId);
    return message?.totalReactions ?? 0;
  }

  // <-- Hanlde file upload with loading status --->
  Future<String?> _uploadFile(File file) async {
    // Vars
    String? fileUrl;

    // Add single file to upload list
    uploadingFiles.add(file);

    // Update loading status
    isUploading.value = true;

    // Upload file
    fileUrl = await AppHelper.uploadFile(
      file: file,
      userId: AuthController.instance.currentUser.userId,
    );

    // Remove file from uploading list
    uploadingFiles.remove(file);

    // Update loading status
    isUploading.value = uploadingFiles.isNotEmpty;

    return fileUrl;
  }

  // Check if a file is currently being uploaded
  bool isFileUploading(String filePath) {
    return uploadingFiles.any((file) => file.path == filePath);
  }

  // Cancel file upload
  void cancelUpload(String filePath) {
    // Remove from uploading list
    uploadingFiles.removeWhere((file) => file.path == filePath);
    
    // Remove message from list
    messages.removeWhere((message) => message.fileUrl == filePath);
    
    // Update loading status
    isUploading.value = uploadingFiles.isNotEmpty;
  }
  // END.

  // <-- Reply features -->

  void replyToMessage(Message message) {
    replyMessage.value = message;
    chatFocusNode.requestFocus();
  }

  void cancelReply() {
    replyMessage.value = null;
    selectedMessage.value = null;
    chatFocusNode.unfocus();
  }

  void editMessage(Message message) {
    if (message.type != MessageType.text) return; // solo texto
    editingMessage.value = message;
    textController.text = message.textMsg;
    textController.selection = TextSelection.fromPosition(
      TextPosition(offset: textController.text.length),
    );
    chatFocusNode.requestFocus();
  }

  void cancelEdit() {
    editingMessage.value = null;
    textController.clear();
    chatFocusNode.unfocus();
  }

  Future<void> saveEditedMessage() async {
    final Message? original = editingMessage.value;
    if (original == null) return;
    final String newText = textController.text.trim();
    if (newText.isEmpty) {
      // No cambios o vacío: simplemente salir del modo edición
      cancelEdit();
      return;
    }

    // Verificar que user no sea null antes de proceder
    if (user == null) {
      debugPrint('Error: user is null in saveEditedMessage');
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'No se pudo editar el mensaje',
      );
      cancelEdit();
      return;
    }

    try {
      await MessageApi.updateMessageText(
        isGroup: isGroup,
        message: original,
        newText: newText,
        receiverId: user!.userId,
        groupId: selectedGroup?.groupId,
      );

      // Actualizar en memoria para feedback inmediato
      final int index = messages.indexWhere((m) => m.msgId == original.msgId);
      if (index != -1) {
        final Message updated = Message(
          msgId: original.msgId,
          docRef: original.docRef,
          senderId: original.senderId,
          type: original.type,
          textMsg: newText,
          fileUrl: original.fileUrl,
          gifUrl: original.gifUrl,
          location: original.location,
          videoThumbnail: original.videoThumbnail,
          isRead: original.isRead,
          isDeleted: original.isDeleted,
          isForwarded: original.isForwarded,
          sentAt: original.sentAt,
          updatedAt: DateTime.now(),
          replyMessage: original.replyMessage,
          groupUpdate: original.groupUpdate,
          reactions: original.reactions,
        );
        messages[index] = updated;
      }

      DialogHelper.showSnackbarMessage(
        SnackMsgType.success,
        'Mensaje editado',
      );
    } catch (e) {
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'No se pudo editar el mensaje',
      );
    } finally {
      cancelEdit();
    }
  }

  void navigateToReplyMessage(Message replyMsg) {
    // Buscar el mensaje exacto en la lista
    final index = messages.indexWhere((msg) => msg.msgId == replyMsg.msgId);
    if (index != -1) {
      // Resaltar inmediatamente el mensaje
      selectedMessage.value = replyMsg;
      
      // Hacer scroll después de un pequeño delay para que se vea el resaltado
      Future.delayed(const Duration(milliseconds: 150), () {
        if (scrollController.hasClients) {
          // Para lista en reverse, necesitamos calcular diferente
          // Los mensajes más nuevos están al final (índice 0 en reverse)
          final reverseIndex = messages.length - 1 - index;
          final itemHeight = 100.0; // Altura aproximada de un mensaje
          final targetPosition = reverseIndex * itemHeight;
          
          // Asegurar que la posición esté dentro de los límites
          final maxScroll = scrollController.position.maxScrollExtent;
          final clampedPosition = targetPosition.clamp(0.0, maxScroll);
          
          scrollController.animateTo(
            clampedPosition,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          );
        }
      });
      
      // Quitar el resaltado después de un tiempo
      Future.delayed(const Duration(milliseconds: 1000), () {
        selectedMessage.value = null;
      });
    }
  }

  // END.

  // Handle emoji picker and keyboard
  void handleEmojiPicker() {
    if (showEmoji.value) {
      showEmoji.value = false;
      chatFocusNode.requestFocus();
    } else {
      showEmoji.value = true;
      chatFocusNode.unfocus();
    }
  }

  // Auto scroll the messages list to bottom
  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 150), // Más rápido como Telegram
        curve: Curves.easeOutCubic, // Curva más suave
      );
    }
  }

  // Listen scrollController updates
  void _scrollControllerListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels == 0.0) {
        // Update value
        showScrollButton.value = false;
      } else {
        showScrollButton.value = true;
      }
    });
  }

  Message? getReplaceMessage(Message deletedMsg) {
    Message? lastMsg;
    // Get last message
    if (messages.length > 1) {
      messages.remove(deletedMsg);
      lastMsg = messages.reversed.last;
    }
    return lastMsg;
  }

  Future<void> softDeleteForEveryone() async {
    final Message message = selectedMessage.value!;

    // Verificar que user no sea null antes de proceder
    if (user == null) {
      debugPrint('❌ Error: user is null in softDeleteForEveryone');
      return;
    }

    debugPrint('🔍 softDeleteForEveryone() -> Iniciando desde controller');
    debugPrint('🔍 Mensaje seleccionado: ${message.msgId}');
    debugPrint('🔍 Usuario receptor: ${user!.userId}');
    debugPrint('🔍 Es grupo: $isGroup');

    try {
      await MessageApi.softDeleteForEveryone(
        isGroup: isGroup,
        message: message,
        receiverId: user!.userId,
        group: selectedGroup,
      );
      debugPrint('✅ softDeleteForEveryone() -> Completado exitosamente desde controller');
      selectedMessage.value = null;
    } catch (e) {
      debugPrint('❌ Error in softDeleteForEveryone: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'No se pudo eliminar el mensaje',
      );
    }
  }

  Future<void> deleteMsgForMe() async {
    if (selectedMessage.value == null) return;
    
    final Message message = selectedMessage.value!;
    
    if (message.isSender) {
      // Para mensajes propios: usar el sistema de undo (mostrar "eliminado" temporalmente)
      await _deleteMessagesWithUndo([message]);
    } else {
      // Para mensajes de otros: eliminar permanentemente sin undo (como WhatsApp)
      if (user == null) {
        debugPrint('Error: user is null in deleteMsgForMe');
        return;
      }
      
      try {
        // Remover inmediatamente de la UI
        messages.removeWhere((m) => m.msgId == message.msgId);
        
        // Eliminar permanentemente en el servidor
        await MessageApi.deleteMsgForMe(
          message: message,
          receiverId: user!.userId,
          replaceMsg: getReplaceMessage(message),
        );
      } catch (e) {
        debugPrint('Error in deleteMsgForMe: $e');
        // Revertir en caso de error - agregar al final si no sabemos la posición exacta
        messages.add(message);
        DialogHelper.showSnackbarMessage(
          SnackMsgType.error,
          'No se pudo eliminar el mensaje',
        );
      }
    }
    
    selectedMessage.value = null;
  }

  Future<void> deleteMessageForever() async {
    if (selectedMessage.value == null) return;
    await _deleteMessagesWithUndo([selectedMessage.value!]);
    selectedMessage.value = null;
  }

  Future<void> deleteMessageCompletely() async {
    if (selectedMessage.value == null) return;
    
    // Verificar que user no sea null antes de proceder
    if (user == null) {
      debugPrint('Error: user is null in deleteMessageCompletely');
      return;
    }
    
    final Message message = selectedMessage.value!;
    
    try {
      await MessageApi.deleteMessageCompletely(
        isGroup: isGroup,
        msgId: message.msgId,
        group: selectedGroup,
        receiverId: user!.userId,
        replaceMsg: getReplaceMessage(message),
      );
      
      // Remover el mensaje de la lista local
      messages.removeWhere((m) => m.msgId == message.msgId);
      selectedMessage.value = null;
    } catch (e) {
      debugPrint('Error in deleteMessageCompletely: $e');
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'No se pudo eliminar completamente el mensaje',
      );
    }
  }

  Future<void> clearChat() async {
    // Close confirm dialog
    DialogHelper.closeDialog();
    // Send the request
    ChatApi.clearChat(messages: messages, receiverId: user!.userId);
    messages.clear();
  }

  Future<void> muteChat() async {
    isChatMuted.toggle();
    ChatApi.muteChat(isMuted: isChatMuted.value, receiverId: user!.userId);
  }

  Future<void> _checkMuteStatus() async {
    final bool result = await ChatApi.checkMuteStatus(user!.userId);
    isChatMuted.value = result;
  }
}

class ColorGenerator {
  static final Map<String, Color> _senderColors = {};

  static Color getColorForSender(String senderId) {
    if (!_senderColors.containsKey(senderId)) {
      _senderColors[senderId] = _generateRandomColor();
    }
    return _senderColors[senderId]!;
  }

  static Color _generateRandomColor() {
    Random random = Random();
    final red = random.nextInt(256);
    final green = random.nextInt(256);
    final blue = random.nextInt(256);
    return Color.fromARGB(255, red, green, blue);
  }
}
