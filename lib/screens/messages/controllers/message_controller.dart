import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:chat_messenger/api/chat_api.dart';
import 'package:chat_messenger/api/message_api.dart';
import 'package:chat_messenger/api/user_api.dart';
import 'package:chat_messenger/api/translation_api.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/controllers/preferences_controller.dart';
import 'package:chat_messenger/controllers/assistant_controller.dart';
import 'package:chat_messenger/helpers/app_helper.dart';
import 'package:chat_messenger/helpers/encrypt_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:just_audio/just_audio.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:audio_session/audio_session.dart';

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
  final RxSet<String> animatingMessageIds = RxSet<String>();
  
  // Pending deletions with undo (messages)
  final RxList<Message> _pendingMessageDeletions = RxList<Message>([]);
  // Keep original indexes to restore messages in the same position on undo
  final Map<String, int> _pendingDeletionIndexes = <String, int>{};
  Timer? _messageDeletionTimer;
  Timer? _messageCountdownTimer;
  final RxInt _messageCountdown = RxInt(5);
  Timer? _expiredMessagesTimer; // Timer para verificar mensajes expirados
  
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
  
  // Audio player variables (using just_audio)
  final AudioPlayer audioPlayer = AudioPlayer();
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  bool isPlaying = false;
  String? currentPlayingMessageId;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  double playbackSpeed = 1.0;
  
  // Global audio player bar
  Rx<Message?> currentPlayingMessage = Rx<Message?>(null);
  RxBool showAudioPlayerBar = false.obs;
  
  // Image message update trigger - usado para forzar reconstrucción cuando cambia fileUrl
  final RxInt imageMessageUpdateTrigger = RxInt(0);
  
  // AI responding state - usado para mostrar indicador de escritura de la IA
  final RxBool isAIResponding = RxBool(false);

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





  // Audio player methods (using just_audio)
  Future<void> playAudio(Message message) async {
    try {
      // Verificar si el audio es viewOnce y ya fue escuchado
      if (message.viewOnce && message.viewedBy != null) {
        final currentUserId = AuthController.instance.currentUser.userId;
        if (message.viewedBy!.contains(currentUserId)) {
          DialogHelper.showSnackbarMessage(
            SnackMsgType.error,
            'Este audio solo se puede escuchar una vez',
          );
          return;
        }
      }
      
      // Stop current audio if playing
      if (isPlaying) {
        await audioPlayer.stop();
        _positionSubscription?.cancel();
        _durationSubscription?.cancel();
        _playerStateSubscription?.cancel();
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
      
      // Cargar audio usando just_audio
      AudioSource audioSource;
      if (audioPath.startsWith('http')) {
        // Remote URL
        try {
          audioSource = AudioSource.uri(Uri.parse(audioPath));
        } catch (e) {
          DialogHelper.showSnackbarMessage(
            SnackMsgType.error,
            'URL de audio inválida',
          );
          return;
        }
      } else {
        // Local file
        final file = File(audioPath);
        if (!await file.exists()) {
          DialogHelper.showSnackbarMessage(
            SnackMsgType.error,
            'El archivo de audio no existe',
          );
          return;
        }
        audioSource = AudioSource.file(audioPath);
      }
      
      // Configurar sesión de audio para reproducción
      try {
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.defaultToSpeaker,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.music,
            flags: AndroidAudioFlags.none,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        ));
        debugPrint('✅ Audio session configurada correctamente');
      } catch (e) {
        debugPrint('⚠️ Error configurando audio session: $e');
        // Continuar aunque falle la configuración de sesión
      }
      
      // Configurar audio source
      await audioPlayer.setAudioSource(audioSource);
      
      // Configurar listeners
      _positionSubscription?.cancel();
      _durationSubscription?.cancel();
      _playerStateSubscription?.cancel();
      
      _positionSubscription = audioPlayer.positionStream.listen((position) {
        currentPosition = position;
      });
      
      _durationSubscription = audioPlayer.durationStream.listen((duration) {
        if (duration != null) {
          totalDuration = duration;
        }
      });
      
      _playerStateSubscription = audioPlayer.playerStateStream.listen((state) {
        isPlaying = state.playing;
        
        // Si el audio se completó
        if (state.processingState == ProcessingState.completed) {
          isPlaying = false;
          currentPlayingMessageId = null;
          showAudioPlayerBar.value = false;
          currentPlayingMessage.value = null;
        }
      });
      
      // Reproducir audio
      await audioPlayer.play();
      isPlaying = true;
      
      debugPrint('✅ Audio iniciado correctamente: ${message.msgId}');
      
      // Si es viewOnce, marcar como visto cuando se inicia la reproducción
      // (no esperar a que termine, porque si el usuario pausa, ya lo escuchó)
      if (message.viewOnce) {
        _markAudioAsViewed(message);
      }
      
    } catch (e) {
      debugPrint('❌ Audio playback error: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      
      // Resetear estado en caso de error
      isPlaying = false;
      currentPlayingMessageId = null;
      showAudioPlayerBar.value = false;
      currentPlayingMessage.value = null;
      
      // Provide more specific error messages
      String errorMessage = 'No se pudo reproducir el audio.';
      if (e.toString().contains('Failed to set source') || e.toString().contains('setAudioSource')) {
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
  
  // Eliminar mensaje expirado de Firestore
  Future<void> _deleteExpiredMessage(Message message) async {
    try {
      if (message.docRef != null) {
        await message.docRef!.delete();
        debugPrint('✅ Mensaje expirado eliminado de Firestore: ${message.msgId}');
      }
      
      // También eliminar del otro usuario si es mensaje privado
      if (!isGroup && user != null) {
        final currentUser = AuthController.instance.currentUser;
        try {
          // Obtener referencia a la colección del otro usuario
          final otherUserCollection = FirebaseFirestore.instance
              .collection('Users/${user!.userId}/Chats/${currentUser.userId}/Messages');
          await otherUserCollection.doc(message.msgId).delete();
          debugPrint('✅ Mensaje expirado eliminado del otro usuario: ${message.msgId}');
        } catch (e) {
          debugPrint('⚠️ Error eliminando mensaje del otro usuario: $e');
        }
      }
      
      // Verificar si el chat queda sin mensajes y eliminarlo
      if (!isGroup && user != null) {
        await _checkAndDeleteEmptyChat();
      }
    } catch (e) {
      debugPrint('❌ Error eliminando mensaje expirado: $e');
    }
  }
  
  // Verificar y eliminar mensajes expirados con animación
  void _checkAndRemoveExpiredMessages() {
    final now = DateTime.now();
    final List<Message> expiredMessages = [];
    
    // Buscar mensajes expirados en la lista actual
    for (var message in messages) {
      if (message.isTemporary && message.expiresAt != null) {
        if (message.expiresAt!.isBefore(now) || message.expiresAt!.difference(now).inSeconds <= 0) {
          expiredMessages.add(message);
        }
      }
    }
    
    // Si hay mensajes expirados, eliminarlos con animación
    if (expiredMessages.isNotEmpty) {
      debugPrint('⏰ Eliminando ${expiredMessages.length} mensaje(s) expirado(s) con animación');
      
      // Eliminar mensajes uno por uno con un pequeño delay para ver la animación
      for (int i = 0; i < expiredMessages.length; i++) {
        final expiredMessage = expiredMessages[i];
        
        // Agregar delay para que se vea la animación de eliminación
        Future.delayed(Duration(milliseconds: i * 200), () {
          // Eliminar de la lista local (GetX actualizará automáticamente con animación)
          if (messages.contains(expiredMessage)) {
            messages.remove(expiredMessage);
            debugPrint('🗑️ Mensaje eliminado de la lista con animación: ${expiredMessage.msgId}');
          }
          
          // Eliminar de Firestore en background
          _deleteExpiredMessage(expiredMessage).catchError((e) {
            debugPrint('❌ Error eliminando mensaje expirado de Firestore: $e');
          });
        });
      }
    }
  }
  
  // Verificar y eliminar chat si no tiene mensajes
  Future<void> _checkAndDeleteEmptyChat() async {
    try {
      if (user == null) return;
      
      final currentUser = AuthController.instance.currentUser;
      final chatRef = FirebaseFirestore.instance
          .collection('Users/${currentUser.userId}/Chats')
          .doc(user!.userId);
      
      // Verificar si hay mensajes
      final messagesRef = FirebaseFirestore.instance
          .collection('Users/${currentUser.userId}/Chats/${user!.userId}/Messages');
      
      final messagesSnapshot = await messagesRef.limit(1).get();
      
      if (messagesSnapshot.docs.isEmpty) {
        // No hay mensajes, eliminar el chat
        await chatRef.delete();
        debugPrint('✅ Chat eliminado (sin mensajes): ${user!.userId}');
      }
    } catch (e) {
      debugPrint('⚠️ Error verificando chat vacío: $e');
    }
  }
  
  // Marcar audio como visto (viewOnce)
  Future<void> _markAudioAsViewed(Message message) async {
    try {
      final currentUserId = AuthController.instance.currentUser.userId;
      
      // Si ya fue visto por este usuario, no hacer nada
      if (message.viewedBy != null && message.viewedBy!.contains(currentUserId)) {
        return;
      }
      
      // Agregar usuario a la lista de vistos
      final updatedViewedBy = List<String>.from(message.viewedBy ?? []);
      if (!updatedViewedBy.contains(currentUserId)) {
        updatedViewedBy.add(currentUserId);
      }
      
      // Actualizar en Firestore
      if (message.docRef != null) {
        await message.docRef!.update({
          'viewedBy': updatedViewedBy,
        });
      }
      
      // Actualizar en la lista local
      final index = messages.indexWhere((m) => m.msgId == message.msgId);
      if (index != -1) {
        final updatedMessage = Message(
          msgId: message.msgId,
          docRef: message.docRef,
          senderId: message.senderId,
          type: message.type,
          textMsg: message.textMsg,
          fileUrl: message.fileUrl,
          gifUrl: message.gifUrl,
          location: message.location,
          videoThumbnail: message.videoThumbnail,
          isRead: message.isRead,
          isDeleted: message.isDeleted,
          isForwarded: message.isForwarded,
          sentAt: message.sentAt,
          updatedAt: message.updatedAt,
          replyMessage: message.replyMessage,
          groupUpdate: message.groupUpdate,
          reactions: message.reactions,
          translations: message.translations,
          detectedLanguage: message.detectedLanguage,
          translatedAt: message.translatedAt,
          isTemporary: message.isTemporary,
          expiresAt: message.expiresAt,
          viewOnce: message.viewOnce,
          viewedBy: updatedViewedBy,
        );
        messages[index] = updatedMessage;
      }
      
      debugPrint('✅ Audio marcado como visto: ${message.msgId}');
    } catch (e) {
      debugPrint('❌ Error marcando audio como visto: $e');
    }
  }
  
  Future<void> pauseAudio() async {
    try {
      await audioPlayer.pause();
      isPlaying = false;
    } catch (e) {
      debugPrint('Error al pausar audio: $e');
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'Error al pausar audio: $e',
      );
    }
  }
  
  Future<void> resumeAudio() async {
    try {
      await audioPlayer.play();
      isPlaying = true;
    } catch (e) {
      debugPrint('Error al reanudar audio: $e');
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
      _positionSubscription?.cancel();
      _durationSubscription?.cancel();
      _playerStateSubscription?.cancel();
    } catch (e) {
      debugPrint('Error al detener audio: $e');
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
      
      await audioPlayer.setSpeed(playbackSpeed);
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
    debugPrint('🎤 onMicReleased llamado');
    isMicPressed.value = false;
    if (isRecording.value) {
      // Enviar si está grabando (incluso si está bloqueado, el usuario soltó el botón)
      debugPrint('✅ Enviando audio desde onMicReleased...');
      stopRecordingAndSend();
    }
  }
  
  // Método para enviar audio cuando se toca el botón de micrófono
  void onMicTapped() {
    debugPrint('🎤 onMicTapped llamado');
    debugPrint('   - isRecording: ${isRecording.value}');
    debugPrint('   - isRecordingLocked: ${isRecordingLocked.value}');
    debugPrint('   - _recordingPath: $_recordingPath');
    
    if (isRecording.value) {
      // Si está grabando, enviar (incluso si está bloqueado, el usuario quiere enviar)
      debugPrint('✅ Enviando audio desde onMicTapped...');
      stopRecordingAndSend();
    } else {
      debugPrint('⚠️ No se está grabando, no se puede enviar');
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
      debugPrint('🛑 stopRecordingAndSend llamado');
      debugPrint('   - isRecording: ${isRecording.value}');
      debugPrint('   - _recordingPath: $_recordingPath');
      
      // Verificar si hay una grabación activa
      if (!isRecording.value) {
        debugPrint('⚠️ No hay grabación activa (isRecording = false)');
        // Intentar detener de todas formas por si acaso
        try {
          await _audioRecorder.stop();
        } catch (e) {
          debugPrint('⚠️ Error al detener grabador (puede que no esté grabando): $e');
        }
        return;
      }
      
      if (_recordingPath == null) {
        debugPrint('⚠️ No hay ruta de grabación guardada');
        // Intentar detener y obtener la ruta
        try {
          final recordingPath = await _audioRecorder.stop();
          if (recordingPath != null) {
            _recordingPath = recordingPath;
            debugPrint('✅ Ruta de grabación obtenida: $recordingPath');
          } else {
            debugPrint('❌ No se pudo obtener la ruta de grabación');
            return;
          }
        } catch (e) {
          debugPrint('❌ Error al obtener ruta de grabación: $e');
          return;
        }
      }

      debugPrint('🛑 Deteniendo grabación y enviando audio...');
      
      // Stop recording
      final recordingPath = await _audioRecorder.stop();
      debugPrint('✅ Grabación detenida, ruta: $recordingPath');
      
      _stopRecordingTimer();
      isRecording.value = false;
      showRecordingOverlay.value = false;
      showVoiceRecordingBar.value = false;
      isMicPressed.value = false;

      // Usar la ruta devuelta por stop() o la guardada
      final audioPath = recordingPath ?? _recordingPath;
      if (audioPath == null) {
        debugPrint('❌ No se pudo obtener la ruta del audio grabado');
        DialogHelper.showSnackbarMessage(
          SnackMsgType.error,
          'Error: No se pudo guardar el audio',
        );
        return;
      }

      // Check if recording file exists and is valid
      final file = File(audioPath);
      if (!await file.exists()) {
        debugPrint('❌ El archivo de audio no existe: $audioPath');
        DialogHelper.showSnackbarMessage(
          SnackMsgType.error,
          'Error: El archivo de audio no se guardó correctamente',
        );
        return;
      }

      final fileSize = await file.length();
      debugPrint('📊 Tamaño del archivo de audio: $fileSize bytes');
      
      if (fileSize < 1000) { // Less than 1KB
        debugPrint('⚠️ Audio demasiado corto, eliminando...');
        await file.delete();
        DialogHelper.showSnackbarMessage(
          SnackMsgType.info,
          'El audio es demasiado corto',
        );
        return;
      }

      debugPrint('✅ Enviando mensaje de audio...');
      // Send audio message
      await sendMessage(MessageType.audio, file: file);
      debugPrint('✅ Mensaje de audio enviado exitosamente');
      
      // Limpiar la ruta de grabación después de enviar
      _recordingPath = null;
      
    } catch (e, stackTrace) {
      debugPrint('❌ Error al enviar audio: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      
      // Asegurar que el estado se resetee incluso si hay error
      isRecording.value = false;
      showRecordingOverlay.value = false;
      showVoiceRecordingBar.value = false;
      isMicPressed.value = false;
      _recordingPath = null;
      
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'Error al enviar audio: ${e.toString()}',
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

    // 1. Add messages to animating set to trigger UI animation
    final messagesToDelete = List<Message>.from(selectedMessages);
    debugPrint('🗑️ Starting deletion animation for ${messagesToDelete.length} messages');
    for (final msg in messagesToDelete) {
      animatingMessageIds.add(msg.msgId);
    }
    debugPrint('✨ Added to animatingMessageIds: $animatingMessageIds');
    
    // Exit selection mode immediately so UI looks clean during animation
    exitMultiSelectMode();

    // 2. Wait for animation to finish (allow extra time for capture + animation)
    await Future.delayed(const Duration(milliseconds: 1000));
    debugPrint('⏱️ Animation delay finished, proceeding to delete');

    // 3. Proceed with actual deletion logic
    await _deleteMessagesWithUndo(messagesToDelete);
    
    // 4. Clear animating set
    animatingMessageIds.clear();
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
    
    // Iniciar timer para verificar mensajes expirados cada 5 segundos
    _expiredMessagesTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkAndRemoveExpiredMessages();
    });
    
    super.onInit();
  }

  @override
  void onClose() {
    // Clear the previous one
    _groupController.clearSelectedGroup();
    _recordingTimer?.cancel();
    _expiredMessagesTimer?.cancel(); // Cancelar timer de mensajes expirados
    _audioRecorder.dispose();
    chatFocusNode.dispose();
    textController.dispose();
    scrollController.dispose();
    _stream?.cancel();
    
    // Limpiar listeners de audio
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    audioPlayer.dispose();
    
    super.onClose();
  }

  // Get Message Updates
  void _getMessages() {
    if (isGroup) {
      _stream =
          MessageApi.getGroupMessages(selectedGroup!.groupId).listen((event) async {
        debugPrint('Group Messages Received: ${event.length}');
        
        // Preservar fileUrl de mensajes locales que tienen URL remota
        final Map<String, String> localFileUrls = {};
        for (var localMsg in messages) {
          if (localMsg.fileUrl.isNotEmpty && 
              localMsg.fileUrl.startsWith('http') && 
              (localMsg.type == MessageType.image || localMsg.type == MessageType.video || localMsg.type == MessageType.doc)) {
            localFileUrls[localMsg.msgId] = localMsg.fileUrl;
            debugPrint('💾 Preservando fileUrl local para grupo ${localMsg.msgId}: ${localMsg.fileUrl.substring(0, localMsg.fileUrl.length > 50 ? 50 : localMsg.fileUrl.length)}...');
          }
        }
        
        // Filtrar mensajes expirados y preservar fileUrl
        final now = DateTime.now();
        final validMessages = event.map((message) {
          // Si este mensaje tiene un fileUrl local preservado, usarlo
          if (localFileUrls.containsKey(message.msgId) && 
              (message.type == MessageType.image || message.type == MessageType.video || message.type == MessageType.doc)) {
            final preservedFileUrl = localFileUrls[message.msgId]!;
            if (message.fileUrl != preservedFileUrl) {
              debugPrint('🔄 Actualizando fileUrl desde local para grupo ${message.msgId}');
              // Crear nuevo mensaje con el fileUrl preservado
              return Message(
                msgId: message.msgId,
                docRef: message.docRef,
                senderId: message.senderId,
                type: message.type,
                textMsg: message.textMsg,
                fileUrl: preservedFileUrl,
                gifUrl: message.gifUrl,
                location: message.location,
                videoThumbnail: message.videoThumbnail,
                isRead: message.isRead,
                isDeleted: message.isDeleted,
                isForwarded: message.isForwarded,
                sentAt: message.sentAt,
                updatedAt: message.updatedAt,
                replyMessage: message.replyMessage,
                groupUpdate: message.groupUpdate,
                reactions: message.reactions,
                translations: message.translations,
                detectedLanguage: message.detectedLanguage,
                translatedAt: message.translatedAt,
                isTemporary: message.isTemporary,
                expiresAt: message.expiresAt,
                viewOnce: message.viewOnce,
                viewedBy: message.viewedBy,
              );
            }
          }
          return message;
        }).where((message) {
          if (message.isTemporary && message.expiresAt != null) {
            return message.expiresAt!.isAfter(now);
          }
          return true;
        }).toList();
        
        // Log individual messages for debugging
        int imageCount = 0;
        int textCount = 0;
        for (var message in validMessages) {
          if (message.type == MessageType.image) {
            imageCount++;
            print('🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️ MENSAJE DE IMAGEN EN validMessages (GRUPO) 🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️');
            print('   - msgId: ${message.msgId}');
            print('   - type: ${message.type}');
            print('   - fileUrl: ${message.fileUrl.isEmpty ? "VACÍO" : message.fileUrl.substring(0, message.fileUrl.length > 50 ? 50 : message.fileUrl.length)}...');
            print('   - fileUrl length: ${message.fileUrl.length}');
            print('   - fileUrl startsWith http: ${message.fileUrl.startsWith("http")}');
          } else if (message.type == MessageType.text) {
            textCount++;
          }
          debugPrint('Group Message - ID: ${message.msgId}, Type: ${message.type}, Text: ${message.textMsg.isEmpty ? "Empty" : "Has content"}');
          if (message.type == MessageType.image) {
            debugPrint('📥 [STICKER] Mensaje de imagen cargado desde Firestore:');
            debugPrint('   - msgId: ${message.msgId}');
            debugPrint('   - type: ${message.type}');
            debugPrint('   - fileUrl: ${message.fileUrl.isEmpty ? "VACÍO" : (message.fileUrl.length > 80 ? message.fileUrl.substring(0, 80) + "..." : message.fileUrl)}');
            debugPrint('   - fileUrl length: ${message.fileUrl.length}');
            debugPrint('   - fileUrl startsWith http: ${message.fileUrl.startsWith("http")}');
          }
        }
        print('🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨 ANTES DE messages.value = validMessages (GRUPO) 🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨');
        print('   - validMessages.length: ${validMessages.length}');
        print('   - imageCount en validMessages: $imageCount');
        print('   - textCount en validMessages: $textCount');
        messages.value = validMessages;
        
        // FORZAR: Actualizar explícitamente la lista para que GetX detecte el cambio
        messages.refresh();
        
        print('🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨 DESPUÉS DE messages.value = validMessages (GRUPO) 🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨');
        print('   - messages.length: ${messages.length}');
        final imageCountInMessages = messages.where((m) => m.type == MessageType.image).length;
        print('   - imageCount en messages: $imageCountInMessages');
        if (imageCountInMessages > 0) {
          final firstImage = messages.firstWhere((m) => m.type == MessageType.image);
          print('   - Primer mensaje de imagen: msgId=${firstImage.msgId}, fileUrl=${firstImage.fileUrl.isEmpty ? "VACÍO" : firstImage.fileUrl.substring(0, 50)}...');
        }
        
        // FORZAR: Esperar un frame para que GetX procese el cambio
        await Future.delayed(const Duration(milliseconds: 100));
        
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
      
      _stream = MessageApi.getMessages(user!.userId).listen((event) async {
        debugPrint('Messages Received: ${event.length}');
        
        // IMPORTANTE: Para mensajes de imagen, SIEMPRE usar el fileUrl de Firebase si está presente
        // Solo preservar fileUrl local si el mensaje de Firebase NO tiene fileUrl o está vacío
        final Map<String, String> localFileUrls = {};
        for (var localMsg in messages) {
          if (localMsg.fileUrl.isNotEmpty && 
              localMsg.fileUrl.startsWith('http') && 
              (localMsg.type == MessageType.image || localMsg.type == MessageType.video || localMsg.type == MessageType.doc)) {
            localFileUrls[localMsg.msgId] = localMsg.fileUrl;
            debugPrint('💾 Preservando fileUrl local para ${localMsg.msgId}: ${localMsg.fileUrl.substring(0, localMsg.fileUrl.length > 50 ? 50 : localMsg.fileUrl.length)}...');
          }
        }
        
        // Filtrar mensajes expirados
        final now = DateTime.now();
        final List<Message> validMessages = [];
        final List<Message> expiredMessages = [];
        
        for (var message in event) {
          // LOG: Verificar si es mensaje de imagen antes de procesar
          if (message.type == MessageType.image) {
            print('🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️ PROCESANDO MENSAJE DE IMAGEN EN event 🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️');
            print('   - msgId: ${message.msgId}');
            print('   - type: ${message.type}');
            print('   - fileUrl: ${message.fileUrl.isEmpty ? "VACÍO" : message.fileUrl.substring(0, message.fileUrl.length > 50 ? 50 : message.fileUrl.length)}...');
            print('   - fileUrl length: ${message.fileUrl.length}');
            print('   - fileUrl startsWith http: ${message.fileUrl.startsWith("http")}');
            print('   - isTemporary: ${message.isTemporary}');
            print('   - expiresAt: ${message.expiresAt}');
          }
          
          // IMPORTANTE: Para mensajes de imagen, priorizar el fileUrl de Firebase
          // Solo usar el fileUrl local si el de Firebase está vacío
          if (message.type == MessageType.image || message.type == MessageType.video || message.type == MessageType.doc) {
            // Si el mensaje de Firebase tiene un fileUrl válido, usarlo directamente
            if (message.fileUrl.isNotEmpty && message.fileUrl.startsWith('http')) {
              debugPrint('✅ Usando fileUrl de Firebase para ${message.msgId}: ${message.fileUrl.substring(0, message.fileUrl.length > 50 ? 50 : message.fileUrl.length)}...');
              // El mensaje ya tiene el fileUrl correcto, no hacer nada
            } 
            // Si el mensaje de Firebase NO tiene fileUrl pero tenemos uno local preservado, usarlo
            else if (localFileUrls.containsKey(message.msgId)) {
              final preservedFileUrl = localFileUrls[message.msgId]!;
              debugPrint('🔄 Actualizando fileUrl desde local para ${message.msgId} (Firebase no tenía fileUrl)');
              debugPrint('   - fileUrl anterior: ${message.fileUrl.isEmpty ? "VACÍO" : message.fileUrl.substring(0, message.fileUrl.length > 50 ? 50 : message.fileUrl.length)}...');
              debugPrint('   - fileUrl nuevo: ${preservedFileUrl.substring(0, preservedFileUrl.length > 50 ? 50 : preservedFileUrl.length)}...');
              // Crear nuevo mensaje con el fileUrl preservado
              message = Message(
                msgId: message.msgId,
                docRef: message.docRef,
                senderId: message.senderId,
                type: message.type,
                textMsg: message.textMsg,
                fileUrl: preservedFileUrl,
                gifUrl: message.gifUrl,
                location: message.location,
                videoThumbnail: message.videoThumbnail,
                isRead: message.isRead,
                isDeleted: message.isDeleted,
                isForwarded: message.isForwarded,
                sentAt: message.sentAt,
                updatedAt: message.updatedAt,
                replyMessage: message.replyMessage,
                groupUpdate: message.groupUpdate,
                reactions: message.reactions,
                translations: message.translations,
                detectedLanguage: message.detectedLanguage,
                translatedAt: message.translatedAt,
                isTemporary: message.isTemporary,
                expiresAt: message.expiresAt,
                viewOnce: message.viewOnce,
                viewedBy: message.viewedBy,
              );
            } else {
              // No hay fileUrl ni local ni en Firebase - esto es un error
              debugPrint('❌❌❌ ERROR: Mensaje de imagen ${message.msgId} sin fileUrl en Firebase ni local ❌❌❌');
            }
          }
          
          if (message.isTemporary && message.expiresAt != null) {
            final isExpired = message.expiresAt!.isBefore(now) || message.expiresAt!.difference(now).inSeconds <= 0;
            if (isExpired) {
              debugPrint('⏰ Mensaje expirado detectado: ${message.msgId}');
              debugPrint('   - expiresAt: ${message.expiresAt}');
              debugPrint('   - now: $now');
              expiredMessages.add(message);
              // Eliminar mensaje expirado de Firestore (no esperar)
              _deleteExpiredMessage(message).catchError((e) {
                debugPrint('❌ Error eliminando mensaje expirado: $e');
              });
            } else {
              final timeLeft = message.expiresAt!.difference(now);
              debugPrint('⏰ Mensaje temporal activo: ${message.msgId}');
              debugPrint('   - expiresAt: ${message.expiresAt}');
              debugPrint('   - Tiempo restante: ${timeLeft.inHours}h ${timeLeft.inMinutes.remainder(60)}m');
              validMessages.add(message);
            }
          } else {
            // LOG: Verificar si es mensaje de imagen antes de agregar
            if (message.type == MessageType.image) {
              print('🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️ AGREGANDO MENSAJE DE IMAGEN A validMessages 🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️');
              print('   - msgId: ${message.msgId}');
              print('   - fileUrl: ${message.fileUrl.isEmpty ? "VACÍO" : message.fileUrl.substring(0, message.fileUrl.length > 50 ? 50 : message.fileUrl.length)}...');
            }
            validMessages.add(message);
          }
        }
        
        if (expiredMessages.isNotEmpty) {
          debugPrint('🗑️ Eliminando ${expiredMessages.length} mensaje(s) expirado(s) de la lista local');
        }
        
        // LOG: Verificar cuántos mensajes de imagen hay en validMessages
        final imageCountInValid = validMessages.where((m) => m.type == MessageType.image).length;
        print('🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️ TOTAL MENSAJES DE IMAGEN EN validMessages: $imageCountInValid 🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️');
        
        // Log individual messages for debugging (incluye info de sender para depurar traducción)
        print('🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨 _getMessages: validMessages.length=${validMessages.length} 🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨');
        int imageCount = 0;
        int textCount = 0;
        for (var message in validMessages) {
          if (message.type == MessageType.image) {
            imageCount++;
            print('🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️ MENSAJE DE IMAGEN EN validMessages 🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️');
            print('   - msgId: ${message.msgId}');
            print('   - type: ${message.type}');
            print('   - type.name: ${message.type.name}');
            print('   - fileUrl: ${message.fileUrl.isEmpty ? "VACÍO" : message.fileUrl.substring(0, message.fileUrl.length > 50 ? 50 : message.fileUrl.length)}...');
            print('   - fileUrl length: ${message.fileUrl.length}');
            print('   - fileUrl startsWith http: ${message.fileUrl.startsWith("http")}');
            debugPrint('📥 [STICKER] Mensaje de imagen cargado desde Firestore:');
            debugPrint('   - msgId: ${message.msgId}');
            debugPrint('   - type: ${message.type}');
            debugPrint('   - fileUrl: ${message.fileUrl.isEmpty ? "VACÍO" : (message.fileUrl.length > 80 ? message.fileUrl.substring(0, 80) + "..." : message.fileUrl)}');
            debugPrint('   - fileUrl length: ${message.fileUrl.length}');
            debugPrint('   - fileUrl startsWith http: ${message.fileUrl.startsWith("http")}');
          } else if (message.type == MessageType.text) {
            textCount++;
          }
          debugPrint(
            'Private Message - ID: ${message.msgId}, '
            'Type: ${message.type}, '
            'SenderId: ${message.senderId}, '
            'IsSender: ${message.isSender}, '
            'Text: ${message.textMsg.isEmpty ? "Empty" : "Has content"}, '
            'IsDeleted: ${message.isDeleted}',
          );
        }
        print('🚨 Total mensajes de imagen encontrados: $imageCount');
        
        // Actualizar lista local primero
        print('🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨 ANTES DE messages.value = validMessages 🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨');
        print('   - validMessages.length: ${validMessages.length}');
        print('   - imageCount en validMessages: $imageCount');
        print('   - textCount en validMessages: $textCount');
        
        messages.value = validMessages;
        
        // FORZAR: Actualizar explícitamente la lista para que GetX detecte el cambio
        messages.refresh();
        
        print('🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨 DESPUÉS DE messages.value = validMessages 🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨');
        print('   - messages.length: ${messages.length}');
        final imageCountInMessages = messages.where((m) => m.type == MessageType.image).length;
        print('   - imageCount en messages: $imageCountInMessages');
        if (imageCountInMessages > 0) {
          final firstImage = messages.firstWhere((m) => m.type == MessageType.image);
          print('   - Primer mensaje de imagen: msgId=${firstImage.msgId}, fileUrl=${firstImage.fileUrl.isEmpty ? "VACÍO" : firstImage.fileUrl.substring(0, 50)}...');
        }
        
        // FORZAR: Actualizar el controlador para que GetX detecte el cambio
        update();
        
        // FORZAR: Usar SchedulerBinding para forzar actualización después del frame
        if (Get.context != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            print('🔄🔄🔄 FORZANDO ACTUALIZACIÓN DESPUÉS DEL FRAME 🔄🔄🔄');
            update();
            messages.refresh();
          });
        }
        
        // FORZAR: Esperar un frame para que GetX procese el cambio
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Traducir mensajes que no tienen traducción usando la lista actual
        await _translateMessagesIfNeeded(messages);
        
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
    // LOG CRÍTICO AL INICIO: Verificar que sendMessage se está llamando
    print('🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨 sendMessage LLAMADO 🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨');
    print('   - type: $type');
    print('   - type.name: ${type.name}');
    print('   - file != null: ${file != null}');
    print('   - file path: ${file?.path ?? "NULL"}');
    print('   - text != null: ${text != null}');
    print('   - text: ${text ?? "NULL"}');
    debugPrint('🚨 sendMessage LLAMADO - type=$type, file=${file?.path ?? "NULL"}');
    
    // Vars
    String? textMsg, fileUrl, videoThumbnailUrl, localVideoThumbnailPath;
    File? videoThumbnailFile;
    final String messageId = AppHelper.generateID;

    // Generate video thumbnail ahead of time for smoother previews
    if (type == MessageType.video && file != null) {
      videoThumbnailFile = await _createVideoThumbnail(file);
      localVideoThumbnailPath = videoThumbnailFile?.path;
    }

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
        // LOG CRÍTICO: Verificar que el tipo es correcto
        print('🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨 sendMessage: ENVIANDO IMAGEN 🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨');
        print('   - type: $type');
        print('   - type == MessageType.image: ${type == MessageType.image}');
        print('   - file != null: ${file != null}');
        print('   - file path: ${file?.path ?? "NULL"}');
        debugPrint('🚨 sendMessage: ENVIANDO IMAGEN - type=$type, file=${file?.path ?? "NULL"}');
        
        // Para archivos, crear el mensaje inmediatamente con el archivo local
        final bool isVideo = type == MessageType.video;
        // Obtener preferencias del usuario actual
        final currentUser = AuthController.instance.currentUser;
        final isTemporary = currentUser.temporaryMessagesEnabled;
        final isViewOnce = type == MessageType.audio && currentUser.audioViewOnceEnabled;
        
        // Calcular fecha de expiración si es temporal (PRUEBA: 1 minuto en lugar de 24 horas)
        DateTime? expiresAt;
        if (isTemporary) {
          expiresAt = DateTime.now().add(const Duration(minutes: 1)); // ⚠️ PRUEBA: Cambiado a 1 minuto
          debugPrint('⏰ Mensaje temporal creado (PRUEBA 1 minuto): expiresAt = ${expiresAt.toString()}');
        }
        
        final Message tempMessage = Message(
          msgId: messageId,
          type: type,
          textMsg: textMsg ?? '',
          fileUrl: file!.path, // Usar path local temporalmente para preview
          gifUrl: gifUrl ?? '',
          location: location,
          videoThumbnail:
              isVideo ? (localVideoThumbnailPath ?? '') : '', // thumbnail local
          senderId: currentUser.userId,
          isRead: false,
          replyMessage: replyMessage.value,
          isTemporary: isTemporary,
          expiresAt: expiresAt,
          viewOnce: isViewOnce,
          viewedBy: isViewOnce ? [] : null,
        );
        
        // LOG CRÍTICO: Verificar que el mensaje temporal tiene el tipo correcto
        print('🚨 tempMessage creado: msgId=${tempMessage.msgId}, type=${tempMessage.type}, type.name=${tempMessage.type.name}');
        debugPrint('🚨 tempMessage creado: msgId=${tempMessage.msgId}, type=${tempMessage.type}');

        // Agregar mensaje temporal a la lista inmediatamente
        messages.insert(0, tempMessage);
        scrollToBottom();

        // Subir archivo en background
        print('📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤 INICIANDO SUBIDA DE ARCHIVO 📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤');
        debugPrint('📤📤📤 [IMAGE_UPLOAD] Iniciando subida de archivo para mensaje: $messageId 📤📤📤');
        print('📤 [IMAGE_UPLOAD] Mensaje ID: $messageId');
        print('📤 [IMAGE_UPLOAD] Tipo de mensaje: $type');
        print('📤 [IMAGE_UPLOAD] Archivo local: ${file.path}');
        final fileSize = await file.length();
        print('📤 [IMAGE_UPLOAD] Tamaño del archivo: $fileSize bytes');
        debugPrint('📤 [IMAGE_UPLOAD] Archivo local: ${file.path}');
        debugPrint('📤 [IMAGE_UPLOAD] Tamaño del archivo: $fileSize bytes');
        
        print('🔄 [IMAGE_UPLOAD] Llamando a _uploadFile...');
        fileUrl = await _uploadFile(file);
        
        print('📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤 SUBIDA COMPLETADA 📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤');
        debugPrint('📤📤📤 [IMAGE_UPLOAD] Archivo subido, fileUrl obtenido 📤📤📤');
        print('📤 [IMAGE_UPLOAD] fileUrl: ${fileUrl != null ? (fileUrl!.length > 100 ? fileUrl!.substring(0, 100) + "..." : fileUrl!) : "NULL"}');
        print('📤 [IMAGE_UPLOAD] fileUrl length: ${fileUrl?.length ?? 0}');
        print('📤 [IMAGE_UPLOAD] fileUrl startsWith http: ${fileUrl?.startsWith("http") ?? false}');
        print('📤 [IMAGE_UPLOAD] fileUrl startsWith https: ${fileUrl?.startsWith("https") ?? false}');
        debugPrint('📤 [IMAGE_UPLOAD] fileUrl: ${fileUrl != null ? (fileUrl!.length > 100 ? fileUrl!.substring(0, 100) + "..." : fileUrl!) : "NULL"}');
        debugPrint('📤 [IMAGE_UPLOAD] fileUrl length: ${fileUrl?.length ?? 0}');
        debugPrint('📤 [IMAGE_UPLOAD] fileUrl startsWith http: ${fileUrl?.startsWith("http") ?? false}');
        debugPrint('📤 [IMAGE_UPLOAD] fileUrl startsWith https: ${fileUrl?.startsWith("https") ?? false}');
        
        if (isVideo && videoThumbnailFile != null) {
          videoThumbnailUrl = await _uploadThumbnail(videoThumbnailFile);
          if (videoThumbnailUrl != null) {
            await _deleteLocalFile(videoThumbnailFile);
          }
        }
        
        // IMPORTANTE: Si fileUrl es null o vacío, no continuar
        if (fileUrl == null || fileUrl!.isEmpty) {
          debugPrint('❌ [IMAGE_UPLOAD] fileUrl es null o vacío después de subir, no se puede continuar');
          // Remover mensaje temporal de la lista
          messages.removeWhere((m) => m.msgId == messageId);
          DialogHelper.showSnackbarMessage(
            SnackMsgType.error,
            'Error al subir la imagen. Por favor, inténtalo de nuevo.',
          );
          return;
        }
        
        // Actualizar mensaje con URL final
        debugPrint('📤 [IMAGE_UPLOAD] Buscando mensaje en lista para actualizar: $messageId');
        final int index = messages.indexWhere((m) => m.msgId == messageId);
        debugPrint('📤 [IMAGE_UPLOAD] Índice encontrado: $index (total mensajes: ${messages.length})');
        if (index != -1) {
          // Obtener preferencias del usuario actual
          final currentUser = AuthController.instance.currentUser;
          final isTemporary = currentUser.temporaryMessagesEnabled;
          final isViewOnce = type == MessageType.audio && currentUser.audioViewOnceEnabled;
          
        // Calcular fecha de expiración si es temporal (PRUEBA: 1 minuto en lugar de 24 horas)
        DateTime? expiresAt;
        if (isTemporary) {
          expiresAt = DateTime.now().add(const Duration(minutes: 1)); // ⚠️ PRUEBA: Cambiado a 1 minuto
        }
          
          final updatedMessage = Message(
            msgId: messageId,
            type: type,
            textMsg: textMsg ?? '',
            fileUrl: fileUrl ?? '', // URL del servidor
            gifUrl: gifUrl ?? '',
            location: location,
            videoThumbnail: isVideo
                ? (videoThumbnailUrl ?? localVideoThumbnailPath ?? '')
                : '',
            senderId: currentUser.userId,
            isRead: isReceiverOnline,
            replyMessage: replyMessage.value,
            isTemporary: isTemporary,
            expiresAt: expiresAt,
            viewOnce: isViewOnce,
            viewedBy: isViewOnce ? [] : null,
          );
          
          // LOG CRÍTICO: Verificar que el mensaje actualizado tiene el tipo correcto
          print('🚨 updatedMessage creado: msgId=${updatedMessage.msgId}, type=${updatedMessage.type}, type.name=${updatedMessage.type.name}');
          print('   - fileUrl: ${updatedMessage.fileUrl.length > 50 ? updatedMessage.fileUrl.substring(0, 50) + "..." : updatedMessage.fileUrl}');
          debugPrint('🚨 updatedMessage creado: msgId=${updatedMessage.msgId}, type=${updatedMessage.type}');
          debugPrint('📤 [IMAGE_UPLOAD] Actualizando mensaje en lista local con fileUrl: ${fileUrl != null ? (fileUrl!.length > 50 ? fileUrl!.substring(0, 50) + "..." : fileUrl!) : "NULL"}');
          
          // Actualizar el mensaje en la lista
          messages[index] = updatedMessage;
          
          // FORZAR: Reemplazar toda la lista para que GetX detecte el cambio
          // Esto es necesario porque GetX puede no detectar cambios en elementos individuales
          final currentMessages = List<Message>.from(messages);
          messages.value = currentMessages;
          
          // También forzar actualización con refresh
          messages.refresh();
          
          debugPrint('🔄 [IMAGE_UPLOAD] Lista de mensajes actualizada, total: ${messages.length}');
          debugPrint('🔄 [IMAGE_UPLOAD] Mensaje actualizado: msgId=$messageId, fileUrl=${fileUrl != null ? (fileUrl!.length > 50 ? fileUrl!.substring(0, 50) + "..." : fileUrl!) : "NULL"}');
          debugPrint('🔄 [IMAGE_UPLOAD] Forzando actualización de UI con messages.value = y messages.refresh()');
          
          // Guardar mensaje en Firebase con la URL final
          if (fileUrl != null && fileUrl.isNotEmpty) {
            debugPrint('📤 [IMAGE_UPLOAD] Guardando mensaje en Firebase...');
            debugPrint('📤 [IMAGE_UPLOAD] - msgId: $messageId');
            debugPrint('📤 [IMAGE_UPLOAD] - fileUrl: ${fileUrl.length > 80 ? fileUrl.substring(0, 80) + "..." : fileUrl}');
            debugPrint('📤 [IMAGE_UPLOAD] - fileUrl length: ${fileUrl.length}');
            debugPrint('📤 [IMAGE_UPLOAD] - fileUrl startsWith http: ${fileUrl.startsWith("http")}');
            debugPrint('📤 [IMAGE_UPLOAD] - isGroup: $isGroup');
            debugPrint('📤 [IMAGE_UPLOAD] - updatedMessage.fileUrl: ${updatedMessage.fileUrl.length > 80 ? updatedMessage.fileUrl.substring(0, 80) + "..." : updatedMessage.fileUrl}');
            debugPrint('📤 [IMAGE_UPLOAD] - updatedMessage.fileUrl length: ${updatedMessage.fileUrl.length}');
            
            try {
              // IMPORTANTE: Guardar el mensaje completo directamente en Firebase
              // No intentar actualizar primero porque el mensaje no existe todavía
              if (isGroup) {
                debugPrint('📤 [IMAGE_UPLOAD] Guardando mensaje completo en grupo: ${selectedGroup?.groupId}');
                await MessageApi.sendGroupMessage(
                  group: selectedGroup!,
                  message: updatedMessage,
                );
              } else {
                debugPrint('📤 [IMAGE_UPLOAD] Guardando mensaje completo en chat 1-1 con: ${user?.userId}');
                await MessageApi.sendMessage(
                  message: updatedMessage,
                  receiver: user!,
                );
              }
              debugPrint('✅ [IMAGE_UPLOAD] Mensaje guardado en Firebase exitosamente');
              
              // Actualizar nuevamente después de Firebase para asegurar sincronización
              final updatedIndex = messages.indexWhere((m) => m.msgId == messageId);
              if (updatedIndex != -1) {
                // Asegurar que el fileUrl se actualiza correctamente
                messages[updatedIndex] = updatedMessage;
                // Forzar actualización de la lista
                final currentMessages = List<Message>.from(messages);
                messages.value = currentMessages;
                messages.refresh();
                debugPrint('🔄 [IMAGE_UPLOAD] Mensaje actualizado en lista local después de Firebase');
                debugPrint('🔄 [IMAGE_UPLOAD] - fileUrl en lista: ${messages[updatedIndex].fileUrl.length > 80 ? messages[updatedIndex].fileUrl.substring(0, 80) + "..." : messages[updatedIndex].fileUrl}');
              }
            } catch (e, stackTrace) {
              debugPrint('❌ [IMAGE_UPLOAD] Error guardando mensaje en Firebase: $e');
              debugPrint('❌ [IMAGE_UPLOAD] Stack trace: $stackTrace');
              // Mostrar error al usuario
              DialogHelper.showSnackbarMessage(
                SnackMsgType.error,
                'Error al guardar la imagen en Firebase: ${e.toString()}',
              );
            }
          } else {
            debugPrint('⚠️ [IMAGE_UPLOAD] fileUrl está vacío o es null, no se guarda en Firebase');
            // Remover mensaje temporal si no se pudo obtener fileUrl
            messages.removeWhere((m) => m.msgId == messageId);
            DialogHelper.showSnackbarMessage(
              SnackMsgType.error,
              'Error: No se pudo obtener la URL de la imagen subida',
            );
          }
          
          // Incrementar trigger para forzar reconstrucción de mensajes de imagen
          if (type == MessageType.image) {
            imageMessageUpdateTrigger.value++;
            debugPrint('🔄 [IMAGE_UPLOAD] Trigger incrementado: ${imageMessageUpdateTrigger.value}');
          }
        }
        break;
      default:
        // Do nothing..
        break;
    }

    // <--- Build final message --->
    // Obtener preferencias del usuario actual
    final currentUser = AuthController.instance.currentUser;
    final isTemporary = currentUser.temporaryMessagesEnabled;
    final isViewOnce = type == MessageType.audio && currentUser.audioViewOnceEnabled;
    
    debugPrint('📝 Enviando mensaje: isTemporary = $isTemporary, isViewOnce = $isViewOnce');
    
    // Calcular fecha de expiración si es temporal (PRUEBA: 1 minuto en lugar de 24 horas)
    DateTime? expiresAt;
    if (isTemporary) {
      expiresAt = DateTime.now().add(const Duration(minutes: 1)); // ⚠️ PRUEBA: Cambiado a 1 minuto
      debugPrint('⏰ Mensaje temporal creado (PRUEBA 1 minuto): expiresAt = ${expiresAt.toString()}');
    }
    
    final Message message = Message(
      msgId: messageId,
      type: type,
      textMsg: textMsg ?? '',
      fileUrl: fileUrl ?? '',
      gifUrl: gifUrl ?? '',
      location: location,
      videoThumbnail: type == MessageType.video
          ? (videoThumbnailUrl ?? localVideoThumbnailPath ?? '')
          : '',
      senderId: currentUser.userId,
      isRead: isReceiverOnline,
      replyMessage: replyMessage.value,
      isTemporary: isTemporary,
      expiresAt: expiresAt,
      viewOnce: isViewOnce,
      viewedBy: isViewOnce ? [] : null,
    );

    // Para mensajes sin archivo, agregar a la lista ahora
    if (type == MessageType.text || type == MessageType.location || type == MessageType.gif || type == MessageType.audio) {
      messages.insert(0, message);
      scrollToBottom();
    }

    // Send to API
    // IMPORTANTE: Para mensajes de imagen/video/doc, NO enviar aquí porque ya se envió después de subir el archivo
    // Solo enviar mensajes de texto, location, gif y audio aquí
    if (type == MessageType.text || type == MessageType.location || type == MessageType.gif || type == MessageType.audio) {
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
    } else {
      // Para mensajes de imagen/video/doc, el mensaje ya se guardó en Firebase con updateMessageFileUrl
      debugPrint('📤 [IMAGE_UPLOAD] Mensaje de archivo ya guardado en Firebase con updateMessageFileUrl, no se envía de nuevo');
    }
    
    // Continuar con el procesamiento del asistente si aplica
    if (!isGroup) {
      
      // Si es un mensaje al asistente IA, obtener respuesta automática
      debugPrint('🔍 sendMessage: Verificando si es asistente...');
      debugPrint('🔍 sendMessage: type = $type');
      debugPrint('🔍 sendMessage: user?.userId = ${user?.userId}');
      debugPrint('🔍 sendMessage: file != null: ${file != null}');
      
      if (user != null && user!.userId == 'klink_ai_assistant') {
        if (type == MessageType.text) {
          debugPrint('✅ sendMessage: Es un mensaje de texto al asistente, llamando _handleAssistantResponse...');
          _handleAssistantResponse(textMsg ?? '');
        } else if (type == MessageType.image) {
          // Para imágenes, procesar automáticamente con la IA
          if (file != null) {
            debugPrint('✅ sendMessage: Es una imagen al asistente, procesando automáticamente...');
            // Usar el archivo local directamente para procesar con la IA
            _handleAssistantImageResponse(file, textMsg ?? '¿Qué ves en esta imagen?').catchError((error) {
              debugPrint('❌ Error procesando imagen con IA: $error');
            });
          } else {
            debugPrint('⚠️ sendMessage: Es una imagen al asistente pero file es null');
          }
        } else {
          debugPrint('❌ sendMessage: Tipo de mensaje no soportado para el asistente: $type');
        }
      } else {
        debugPrint('❌ sendMessage: No es un mensaje al asistente');
        debugPrint('   - user != null: ${user != null}');
        debugPrint('   - user?.userId == klink_ai_assistant: ${user?.userId == 'klink_ai_assistant'}');
      }
    }

    // Reset values and update UI
    isTextMsg.value = false;
    textController.clear();
    selectedMessage.value = null;
    replyMessage.value = null;
  }

  /// Maneja la respuesta automática del asistente IA
  Future<void> _handleAssistantResponse(String userMessage) async {
    try {
      debugPrint('🔵 _handleAssistantResponse: Iniciando con mensaje: $userMessage');
      
      // Marcar que la IA está respondiendo
      isAIResponding.value = true;
      
      // Verificar si el controlador está disponible, si no, inicializarlo
      AssistantController assistantController;
      try {
        assistantController = Get.find<AssistantController>();
        debugPrint('🔵 _handleAssistantResponse: AssistantController encontrado');
      } catch (e) {
        debugPrint('⚠️ AssistantController no encontrado, inicializando...');
        assistantController = Get.put(AssistantController());
        debugPrint('🔵 _handleAssistantResponse: AssistantController inicializado');
      }
      
      // Observar el estado isTyping del AssistantController para sincronizar
      final subscription = assistantController.isTyping.listen((isTyping) {
        isAIResponding.value = isTyping;
        debugPrint('🔵 _handleAssistantResponse: isAIResponding actualizado a $isTyping');
      });
      
      try {
        // Llamar al asistente (esto guardará automáticamente la respuesta en Firestore)
        debugPrint('🔵 _handleAssistantResponse: Llamando a askAssistant...');
        final response = await assistantController.askAssistant(userMessage);
        debugPrint('🔵 _handleAssistantResponse: Respuesta recibida: ${response?.substring(0, response.length > 50 ? 50 : response.length)}...');
      } finally {
        // Cancelar la suscripción cuando termine
        await subscription.cancel();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error obteniendo respuesta del asistente: $e');
      debugPrint('❌ StackTrace: $stackTrace');
    } finally {
      // Asegurar que se desactive el estado cuando termine (por si acaso)
      isAIResponding.value = false;
      debugPrint('🔵 _handleAssistantResponse: Finalizado, isAIResponding = false');
    }
  }

  /// Maneja la respuesta automática del asistente IA cuando se envía una imagen
  Future<void> _handleAssistantImageResponse(File imageFile, String question) async {
    try {
      debugPrint('🖼️ _handleAssistantImageResponse: Iniciando con imagen y pregunta: $question');
      
      // Marcar que la IA está respondiendo
      isAIResponding.value = true;
      
      // Verificar si el controlador está disponible, si no, inicializarlo
      AssistantController assistantController;
      try {
        assistantController = Get.find<AssistantController>();
        debugPrint('🖼️ _handleAssistantImageResponse: AssistantController encontrado');
      } catch (e) {
        debugPrint('⚠️ AssistantController no encontrado, inicializando...');
        assistantController = Get.put(AssistantController());
        debugPrint('🖼️ _handleAssistantImageResponse: AssistantController inicializado');
      }
      
      // Observar el estado isTyping del AssistantController para sincronizar
      final subscription = assistantController.isTyping.listen((isTyping) {
        isAIResponding.value = isTyping;
        debugPrint('🖼️ _handleAssistantImageResponse: isAIResponding actualizado a $isTyping');
      });
      
      try {
        // Convertir imagen a base64
        debugPrint('🖼️ _handleAssistantImageResponse: Leyendo archivo de imagen...');
        final imageBytes = await imageFile.readAsBytes();
        final imageBase64 = base64Encode(imageBytes);
        debugPrint('🖼️ _handleAssistantImageResponse: Imagen convertida a base64 (${imageBase64.length} caracteres)');
        
        // Llamar al asistente con imagen (esto guardará automáticamente la respuesta en Firestore)
        debugPrint('🖼️ _handleAssistantImageResponse: Llamando a askAssistantWithImage...');
        final response = await assistantController.askAssistantWithImage(question, imageBase64);
        debugPrint('🖼️ _handleAssistantImageResponse: Respuesta recibida: ${response?.substring(0, response.length > 50 ? 50 : response.length)}...');
      } finally {
        // Cancelar la suscripción cuando termine
        await subscription.cancel();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error obteniendo respuesta del asistente con imagen: $e');
      debugPrint('❌ StackTrace: $stackTrace');
    } finally {
      // Asegurar que se desactive el estado cuando termine (por si acaso)
      isAIResponding.value = false;
      debugPrint('🖼️ _handleAssistantImageResponse: Finalizado, isAIResponding = false');
    }
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

    try {
      // Verificar que el archivo existe
      if (!await file.exists()) {
        debugPrint('❌ El archivo no existe: ${file.path}');
        throw Exception('El archivo no existe');
      }

      // Add single file to upload list
      uploadingFiles.add(file);

      // Update loading status
      isUploading.value = true;

      print('📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤 _uploadFile LLAMADO 📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤📤');
      debugPrint('📤 [UPLOAD_FILE] Subiendo archivo: ${file.path}');
      print('📤 [UPLOAD_FILE] Subiendo archivo: ${file.path}');
      print('📊 [UPLOAD_FILE] Tamaño del archivo: ${await file.length()} bytes');
      print('📊 [UPLOAD_FILE] Usuario: ${AuthController.instance.currentUser.userId}');
      debugPrint('📊 [UPLOAD_FILE] Tamaño del archivo: ${await file.length()} bytes');
      debugPrint('📊 [UPLOAD_FILE] Usuario: ${AuthController.instance.currentUser.userId}');

      // Upload file
      print('🔄 [UPLOAD_FILE] Llamando a AppHelper.uploadFile...');
      fileUrl = await AppHelper.uploadFile(
        file: file,
        userId: AuthController.instance.currentUser.userId,
      );

      print('✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅ _uploadFile COMPLETADO ✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅');
      debugPrint('✅ [UPLOAD_FILE] Archivo subido exitosamente');
      print('✅ [UPLOAD_FILE] Archivo subido exitosamente');
      print('✅ [UPLOAD_FILE] URL obtenida: ${fileUrl != null ? (fileUrl!.length > 80 ? fileUrl!.substring(0, 80) + "..." : fileUrl!) : "NULL"}');
      debugPrint('✅ [UPLOAD_FILE] URL obtenida: ${fileUrl != null ? (fileUrl!.length > 80 ? fileUrl!.substring(0, 80) + "..." : fileUrl!) : "NULL"}');

      // Remove file from uploading list
      uploadingFiles.remove(file);

      // Update loading status
      isUploading.value = uploadingFiles.isNotEmpty;

      return fileUrl;
    } catch (e, stackTrace) {
      print('❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌ ERROR EN _uploadFile ❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌');
      print('❌ Error: $e');
      print('❌ Stack trace: $stackTrace');
      debugPrint('❌ Error subiendo archivo: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      
      // Remove file from uploading list on error
      uploadingFiles.remove(file);
      isUploading.value = uploadingFiles.isNotEmpty;
      
      // Mostrar error al usuario
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'Error al subir el archivo: ${e.toString()}',
      );
      
      rethrow;
    }
  }

  Future<String?> _uploadThumbnail(File file) async {
    try {
      return await AppHelper.uploadFile(
        file: file,
        userId: AuthController.instance.currentUser.userId,
      );
    } catch (e) {
      debugPrint('_uploadThumbnail() -> error: $e');
      return null;
    }
  }

  Future<File?> _createVideoThumbnail(File videoFile) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String? thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.PNG,
        quality: 75,
      );

      if (thumbnailPath == null) return null;
      return File(thumbnailPath);
    } catch (e) {
      debugPrint('_createVideoThumbnail() -> error: $e');
      return null;
    }
  }

  Future<void> _deleteLocalFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('_deleteLocalFile() -> error: $e');
    }
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

  // <-- Traducción automática de mensajes -->
  Future<void> _translateMessagesIfNeeded(List<Message> newMessages) async {
    try {
      // Obtener el idioma preferido del usuario actual
      final userLang = PreferencesController.instance.locale.value.languageCode;
      final currentUserId = AuthController.instance.currentUser.userId;
      
      debugPrint('[_translateMessagesIfNeeded] ========================================');
      debugPrint('[_translateMessagesIfNeeded] User language: $userLang');
      debugPrint('[_translateMessagesIfNeeded] Current user ID: $currentUserId');
      debugPrint('[_translateMessagesIfNeeded] Total messages: ${newMessages.length}');
      
      if (newMessages.isEmpty) {
        debugPrint('[_translateMessagesIfNeeded] No messages to process');
        return;
      }
      
      // Filtrar mensajes que necesitan traducción
      final messagesToTranslate = <Message>[];
      
      for (final message in newMessages) {
        final textPreview = message.textMsg.length > 30 
            ? '${message.textMsg.substring(0, 30)}...' 
            : message.textMsg;
        
        debugPrint('[_translateMessagesIfNeeded] Checking message ${message.msgId}:');
        debugPrint('  - Type: ${message.type}');
        debugPrint('  - SenderId: ${message.senderId}');
        debugPrint('  - CurrentUserId: $currentUserId');
        debugPrint('  - IsSender: ${message.isSender}');
        debugPrint('  - Text: "$textPreview"');
        debugPrint('  - Text length: ${message.textMsg.length}');
        debugPrint('  - HasTranslation($userLang): ${message.hasTranslation(userLang)}');
        debugPrint('  - Text isEmpty: ${message.textMsg.trim().isEmpty}');
        
        // Solo mensajes de texto
        if (message.type != MessageType.text) {
          debugPrint('  - ❌ Filtered: not text message');
          continue;
        }
        
        // Solo mensajes de otros usuarios
        if (message.isSender) {
          debugPrint('  - ❌ Filtered: is sender (senderId matches currentUserId)');
          continue;
        }
        
        // Solo si no tiene traducción para el idioma del usuario
        if (message.hasTranslation(userLang)) {
          debugPrint('  - ❌ Filtered: already has translation for $userLang');
          continue;
        }
        
        // Solo si el mensaje no está vacío
        if (message.textMsg.trim().isEmpty) {
          debugPrint('  - ❌ Filtered: empty message');
          continue;
        }
        
        debugPrint('  - ✅ Will translate');
        messagesToTranslate.add(message);
      }
      
      if (messagesToTranslate.isEmpty) {
        debugPrint('[_translateMessagesIfNeeded] No messages to translate after filtering');
        debugPrint('[_translateMessagesIfNeeded] ========================================');
        return;
      }
      
      debugPrint('[_translateMessagesIfNeeded] Translating ${messagesToTranslate.length} messages');
      debugPrint('[_translateMessagesIfNeeded] ========================================');
      
      // Traducir cada mensaje
      for (final message in messagesToTranslate) {
        try {
          debugPrint('[_translateMessagesIfNeeded] Translating message ${message.msgId}');
          debugPrint('  - Original text: "${message.textMsg}"');
          debugPrint('  - Target language: $userLang');
          
          final translation = await TranslationApi.translateAndCache(
            messageText: message.textMsg,
            targetLanguage: userLang,
          );
          
          if (translation != null && translation.containsKey(userLang)) {
            // Crear un nuevo objeto Message con la traducción
            final updatedMessage = Message(
              msgId: message.msgId,
              docRef: message.docRef,
              senderId: message.senderId,
              type: message.type,
              textMsg: message.textMsg,
              fileUrl: message.fileUrl,
              gifUrl: message.gifUrl,
              location: message.location,
              videoThumbnail: message.videoThumbnail,
              isRead: message.isRead,
              isDeleted: message.isDeleted,
              isForwarded: message.isForwarded,
              sentAt: message.sentAt,
              updatedAt: message.updatedAt,
              replyMessage: message.replyMessage,
              groupUpdate: message.groupUpdate,
              reactions: message.reactions,
              translations: translation,
              detectedLanguage: message.detectedLanguage,
              translatedAt: DateTime.now(),
            );
            
            debugPrint('[_translateMessagesIfNeeded] ✅ Translated: "${translation[userLang]}"');
            
            // Actualizar en la lista local
            final index = messages.indexWhere((m) => m.msgId == message.msgId);
            if (index != -1) {
              messages[index] = updatedMessage;
              messages.refresh(); // Forzar actualización de GetX
              debugPrint('[_translateMessagesIfNeeded] ✅ Updated message in list at index $index');
            } else {
              debugPrint('[_translateMessagesIfNeeded] ⚠️ Message not found in list: ${message.msgId}');
            }
            
            // Guardar en Firestore para que persista
            if (!isGroup && user != null) {
              await MessageApi.updateMessageTranslation(
                userId: AuthController.instance.currentUser.userId,
                receiverId: user!.userId,
                messageId: message.msgId,
                translations: translation,
              );
              debugPrint('[_translateMessagesIfNeeded] ✅ Saved translation to Firestore');
            }
          } else {
            debugPrint('[_translateMessagesIfNeeded] ❌ Translation returned null or empty for message ${message.msgId}');
          }
        } catch (e, stackTrace) {
          debugPrint('[_translateMessagesIfNeeded] ❌ Error translating message ${message.msgId}: $e');
          debugPrint('[_translateMessagesIfNeeded] Stack trace: $stackTrace');
        }
      }
      
      debugPrint('[_translateMessagesIfNeeded] ========================================');
    } catch (e, stackTrace) {
      debugPrint('[_translateMessagesIfNeeded] ❌ ERROR: $e');
      debugPrint('[_translateMessagesIfNeeded] Stack trace: $stackTrace');
    }
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
