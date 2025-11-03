import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:chat_messenger/services/audio_transcription_service.dart';

class AudioPlayerController extends GetxController {
  AudioPlayerController({required this.fileUrl});

  final String fileUrl;
  
  // Audio Players
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _justAudioPlayer = AudioPlayer();
  
  // Observable variables
  final RxBool isPlaying = false.obs;
  final Rx<Duration> position = Duration.zero.obs;
  final Rx<Duration> duration = Duration.zero.obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  
  // Transcripción
  final RxString transcription = ''.obs;
  final RxBool isTranscribing = false.obs;
  final RxBool transcriptionAvailable = false.obs;
  
  // Audio source
  AudioSource? _audioSource;
  
  @override
  void onInit() {
    super.onInit();
    _initializeAudio();
  }
  
  @override
  void onClose() {
    _audioPlayer.dispose();
    _justAudioPlayer.dispose();
    super.onClose();
  }
  
  Future<void> _initializeAudio() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';
      
      // Intentar con just_audio primero (más estable)
      await _initializeJustAudio();
      
      // Inicializar transcripción
      await _initializeTranscription();
      
    } catch (e) {
      print('❌ Error inicializando audio: $e');
      hasError.value = true;
      errorMessage.value = 'Error inicializando audio: $e';
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> _initializeJustAudio() async {
    try {
      // Configurar el audio source
      if (fileUrl.startsWith('http')) {
        _audioSource = AudioSource.uri(Uri.parse(fileUrl));
      } else {
        _audioSource = AudioSource.file(fileUrl);
      }
      
      // Configurar el player
      await _justAudioPlayer.setAudioSource(_audioSource!);
      
      // Escuchar cambios de posición
      _justAudioPlayer.positionStream.listen((pos) {
        position.value = pos;
      });
      
      // Escuchar cambios de duración
      _justAudioPlayer.durationStream.listen((dur) {
        if (dur != null) {
          duration.value = dur;
        }
      });
      
      // Escuchar cambios de estado
      _justAudioPlayer.playerStateStream.listen((state) {
        isPlaying.value = state.playing;
        
        if (state.processingState == ProcessingState.completed) {
          isPlaying.value = false;
          position.value = Duration.zero;
        }
      });
      
      print('✅ Audio inicializado correctamente con just_audio');
      
    } catch (e) {
      print('❌ Error con just_audio: $e');
      // Intentar con audioplayers como fallback
      await _initializeAudioPlayers();
    }
  }
  
  Future<void> _initializeAudioPlayers() async {
    try {
      // Configurar audioplayers como fallback
      await _audioPlayer.setSourceUrl(fileUrl);
      
      // Escuchar cambios de posición
      _audioPlayer.onPositionChanged.listen((pos) {
        position.value = pos;
      });
      
      // Escuchar cambios de duración
      _audioPlayer.onDurationChanged.listen((dur) {
        duration.value = dur;
      });
      
      // Escuchar cambios de estado
      _audioPlayer.onPlayerStateChanged.listen((state) {
        isPlaying.value = state == PlayerState.playing;
      });
      
      print('✅ Audio inicializado correctamente con audioplayers');
      
    } catch (e) {
      print('❌ Error con audioplayers: $e');
      hasError.value = true;
      errorMessage.value = 'No se pudo reproducir el audio: $e';
    }
  }
  
  Future<void> playAudio() async {
    try {
      hasError.value = false;
      errorMessage.value = '';
      
      if (isPlaying.value) {
        await pauseAudio();
      } else {
        // Intentar con just_audio primero
        try {
          await _justAudioPlayer.play();
        } catch (e) {
          print('❌ Error reproduciendo con just_audio: $e');
          // Fallback a audioplayers
          await _audioPlayer.resume();
        }
      }
      
    } catch (e) {
      print('❌ Error en playAudio: $e');
      hasError.value = true;
      errorMessage.value = 'Error reproduciendo audio: $e';
    }
  }
  
  Future<void> pauseAudio() async {
    try {
      // Intentar con just_audio primero
      try {
        await _justAudioPlayer.pause();
      } catch (e) {
        print('❌ Error pausando con just_audio: $e');
        // Fallback a audioplayers
        await _audioPlayer.pause();
      }
    } catch (e) {
      print('❌ Error en pauseAudio: $e');
    }
  }
  
  Future<void> seekAudio(Duration position) async {
    try {
      // Intentar con just_audio primero
      try {
        await _justAudioPlayer.seek(position);
      } catch (e) {
        print('❌ Error seek con just_audio: $e');
        // Fallback a audioplayers
        await _audioPlayer.seek(position);
      }
    } catch (e) {
      print('❌ Error en seekAudio: $e');
    }
  }
  
  Future<void> stopAudio() async {
    try {
      // Intentar con just_audio primero
      try {
        await _justAudioPlayer.stop();
      } catch (e) {
        print('❌ Error stop con just_audio: $e');
        // Fallback a audioplayers
        await _audioPlayer.stop();
      }
      
      position.value = Duration.zero;
      isPlaying.value = false;
      
    } catch (e) {
      print('❌ Error en stopAudio: $e');
    }
  }
  
  Future<void> retryAudio() async {
    await stopAudio();
    await _initializeAudio();
  }
  
  /// Inicializa la transcripción del audio
  Future<void> _initializeTranscription() async {
    try {
      final AudioTranscriptionService transcriptionService = AudioTranscriptionService();
      
      // Verificar si el servicio está disponible
      final bool isAvailable = await transcriptionService.isTranscriptionAvailable();
      transcriptionAvailable.value = isAvailable;
      
      if (isAvailable) {
        // Obtener transcripción simulada para pruebas
        final String simulatedTranscription = transcriptionService.getSimulatedTranscription(fileUrl);
        transcription.value = simulatedTranscription;
        
        // En una implementación real, aquí llamarías a la transcripción real
        // final String? realTranscription = await transcriptionService.transcribeAudioFile(fileUrl);
        // if (realTranscription != null) {
        //   transcription.value = realTranscription;
        // }
      }
      
    } catch (e) {
      print('❌ Error inicializando transcripción: $e');
      transcriptionAvailable.value = false;
    }
  }
  
  /// Transcribe el audio manualmente
  Future<void> transcribeAudio() async {
    if (!transcriptionAvailable.value) return;
    
    try {
      isTranscribing.value = true;
      
      final AudioTranscriptionService transcriptionService = AudioTranscriptionService();
      
      // Para pruebas, usar transcripción simulada
      final String simulatedTranscription = transcriptionService.getSimulatedTranscription(fileUrl);
      transcription.value = simulatedTranscription;
      
      // En una implementación real:
      // final String? realTranscription = await transcriptionService.transcribeAudioFile(fileUrl);
      // if (realTranscription != null) {
      //   transcription.value = realTranscription;
      // }
      
    } catch (e) {
      print('❌ Error transcribiendo audio: $e');
      transcription.value = 'Error transcribiendo el audio. Intenta más tarde.';
    } finally {
      isTranscribing.value = false;
    }
  }
  
  /// Obtiene la transcripción actual
  String getTranscription() {
    return transcription.value;
  }
  
  /// Verifica si la transcripción está disponible
  bool isTranscriptionAvailable() {
    return transcriptionAvailable.value;
  }
} 