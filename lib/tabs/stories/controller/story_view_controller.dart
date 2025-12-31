import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chat_messenger/api/story_api.dart';
import 'package:chat_messenger/api/music_api.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/models/story/story.dart';
import 'package:chat_messenger/models/story/submodels/seen_by.dart';
import 'package:chat_messenger/models/story/submodels/story_text.dart' as txt;
import 'package:chat_messenger/models/story/submodels/story_image.dart' as img;
import 'package:chat_messenger/models/story/submodels/story_video.dart' as vdo;
import 'package:chat_messenger/models/story/submodels/story_music.dart';
import 'package:chat_messenger/helpers/dialog_helper.dart';
import 'package:get/get.dart';
import 'package:story_view/story_view.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class StoryViewController extends GetxController {
  final Story story;

  StoryViewController({required this.story});

  final StoryController storyController = StoryController();
  final List<StoryItem> storyItems = [];
  final List<dynamic> items = [];
  final RxInt index = RxInt(0);

  dynamic get storyItem {
    if (items.isEmpty || index.value >= items.length) {
      return null;
    }
    return items[index.value];
  }
  
  DateTime get createdAt {
    if (storyItem == null) return DateTime.now();
    return storyItem.createdAt;
  }
  
  List<SeenBy> get seenByList {
    if (storyItem == null) return [];
    return storyItem.seenBy;
  }
  
  // Audio player para música de fondo
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StoryMusic? _currentPlayingMusic;
  
  @override
  void onInit() {
    super.onInit();
    // Configurar volumen y velocidad por defecto
    _audioPlayer.setVolume(1.0);
    _audioPlayer.setSpeed(1.0);
    
    _loadStoryItems();
    
    // Si no hay items válidos, cerrar la pantalla
    if (storyItems.isEmpty) {
      debugPrint('⚠️ [STORY_VIEW] No hay items válidos en la historia, cerrando...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.back();
        DialogHelper.showSnackbarMessage(
          SnackMsgType.error,
          'Esta historia no tiene contenido disponible',
        );
      });
      return;
    }
    
    // Reproducir música del primer item si tiene
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playMusicForCurrentItem();
    });
  }
  
  // Obtener música del item actual
  StoryMusic? get currentMusic {
    final item = storyItem;
    if (item == null) return null;
    
    if (item is txt.StoryText) {
      return item.music;
    } else if (item is img.StoryImage) {
      return item.music;
    } else if (item is vdo.StoryVideo) {
      return item.music;
    }
    return null;
  }

  void getStoryItemIndex(int position) {
    if (index.value == position) {
      // Ya estamos en este item, no hacer nada
      return;
    }
    
    index.value = position;
    
    // Reproducir música del nuevo item si tiene (con pequeño delay para sincronización)
    Future.delayed(const Duration(milliseconds: 100), () {
      _playMusicForCurrentItem();
    });
  }


  @override
  void onClose() {
    // Detener música de forma síncrona (pero el método maneja async internamente)
    _stopMusic();
    
    // Cancelar todos los listeners
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    
    // Limpiar referencias
    _positionSubscription = null;
    _durationSubscription = null;
    _playerStateSubscription = null;
    _currentPlayingMusic = null;
    
    // Dispose de los recursos
    try {
      _audioPlayer.dispose();
    } catch (e) {
      debugPrint('⚠️ [STORY_VIEW] Error al hacer dispose del audio player: $e');
    }
    
    storyController.dispose();
    super.onClose();
  }

  // Load all story items (solo items válidos, no expirados)
  void _loadStoryItems() {
    debugPrint('📚 [STORY_VIEW] Cargando items de historia: ${story.id}');
    debugPrint('📚 [STORY_VIEW] Textos válidos: ${story.validTexts.length}');
    debugPrint('📚 [STORY_VIEW] Imágenes válidas: ${story.validImages.length}');
    debugPrint('📚 [STORY_VIEW] Videos válidos: ${story.validVideos.length}');
    
    // <-- Get valid story texts -->
    for (final txt.StoryText storyText in story.validTexts) {
      // Si tiene música, la historia dura 30 segundos
      final hasMusic = storyText.music != null;
      storyItems.add(
        StoryItem.text(
          title: storyText.text,
          backgroundColor: storyText.bgColor,
          textStyle: const TextStyle(fontSize: 24, color: Colors.white),
          duration: hasMusic ? const Duration(seconds: 30) : null,
        ),
      );
      items.add(storyText);
    }

    // <-- Get valid story images -->
    for (final storyImage in story.validImages) {
      // Si tiene música, la historia dura 30 segundos
      final hasMusic = storyImage.music != null;
      storyItems.add(
        StoryItem.pageImage(
            url: storyImage.imageUrl, 
            controller: storyController,
            imageFit: BoxFit.contain, // Usar contain para mantener proporción original
            duration: hasMusic ? const Duration(seconds: 30) : null,
        ),
      );
      items.add(storyImage);
    }

    // <-- Get valid story videos -->
    for (final storyVideo in story.validVideos) {
      // Si tiene música, la historia dura 30 segundos
      final hasMusic = storyVideo.music != null;
      storyItems.add(
        StoryItem.pageVideo(
            storyVideo.videoUrl, 
            controller: storyController,
            imageFit: BoxFit.cover,
            duration: hasMusic ? const Duration(seconds: 30) : null,
        ),
      );
      items.add(storyVideo);
    }
    
    debugPrint('📚 [STORY_VIEW] Total items cargados: ${storyItems.length}');
  }

  void markSeen() {
    if (story.isOwner) return;
    if (storyItem == null) return;

    // Check current user in the list
    final bool isSeen = seenByList
        .any((e) => e.userId == AuthController.instance.currentUser.userId);

    // Check result
    if (isSeen) {
      debugPrint('markSeen() -> already seen.');
      return;
    }

    StoryApi.markSeen(
      story: story,
      storyItem: storyItem,
      seenByList: seenByList,
    );
  }

  Map<String, dynamic> get reportStoryItemData {
    if (storyItem == null) {
      return {
        'userId': story.userId,
        'type': '',
      };
    }
    
    final Map<String, dynamic> data = storyItem.toMap();
    data.remove('seenBy');

    final String type = switch (storyItem) {
      txt.StoryText _ => 'text',
      img.StoryImage _ => 'image'.tr,
      vdo.StoryVideo _ => 'video'.tr,
      _ => '',
    };

    return {
      'userId': story.userId,
      'type': type,
      ...data,
    };
  }

  void deleteStoryItem() {
    if (storyItem == null) return;
    StoryApi.deleteStoryItem(story: story, storyItem: storyItem);
  }

  // Reproducir música para el item actual
  Future<void> _playMusicForCurrentItem() async {
    debugPrint('🎵 [STORY_VIEW] _playMusicForCurrentItem llamado, índice: ${index.value}');
    final music = currentMusic;
    
    // Si no hay música, detener y salir
    if (music == null) {
      debugPrint('🎵 [STORY_VIEW] No hay música en este item, deteniendo...');
      await _stopMusic();
      return;
    }
    
    debugPrint('🎵 [STORY_VIEW] Música encontrada: ${music.trackName} - ${music.artistName}');
    debugPrint('🎵 [STORY_VIEW] Preview URL: ${music.previewUrl}');
    
    // Si es la misma música que ya está reproduciendo, verificar que esté reproduciéndose
    if (_currentPlayingMusic?.trackId == music.trackId && 
        _currentPlayingMusic?.startTime == music.startTime) {
      final state = _audioPlayer.playerState;
      if (state.processingState == ProcessingState.ready && state.playing) {
        debugPrint('🎵 [STORY_VIEW] Ya está reproduciendo esta música, continuando...');
        return;
      } else {
        debugPrint('🎵 [STORY_VIEW] Misma música pero no está reproduciéndose, reiniciando...');
        debugPrint('🎵 [STORY_VIEW] Estado actual: ${state.processingState}, playing: ${state.playing}');
        // Reiniciar la reproducción
        await _stopMusic();
        await Future.delayed(const Duration(milliseconds: 150));
      }
    }
    
    // Detener música anterior solo si es diferente
    if (_currentPlayingMusic != null && 
        (_currentPlayingMusic!.trackId != music.trackId || 
         _currentPlayingMusic!.startTime != music.startTime)) {
      debugPrint('🎵 [STORY_VIEW] Cambiando de música...');
      await _stopMusic();
      // Esperar un poco para que se detenga completamente
      await Future.delayed(const Duration(milliseconds: 150));
    }
    
    _currentPlayingMusic = music;
    debugPrint('🎵 [STORY_VIEW] Llamando _loadAndPlayMusic...');
    await _loadAndPlayMusic(music);
  }

  // Cargar y reproducir música
  Future<void> _loadAndPlayMusic(StoryMusic music) async {
    try {
      debugPrint('🎵 [STORY_VIEW] Cargando música: ${music.trackName}');
      debugPrint('🎵 [STORY_VIEW] Preview URL: ${music.previewUrl}');
      debugPrint('🎵 [STORY_VIEW] YouTube Video ID: ${music.youtubeVideoId}');
      
      String? audioUrl;
      
      // PRIMERO: Verificar si previewUrl es de Audius (música completa)
      if (music.previewUrl.isNotEmpty && 
          (music.previewUrl.contains('audius.co') || music.previewUrl.contains('audius'))) {
        debugPrint('🎵 [STORY_VIEW] URL de Audius detectada (música completa)');
        audioUrl = music.previewUrl;
      }
      // Si tiene YouTube Video ID, usar ese
      else if (music.youtubeVideoId != null && music.youtubeVideoId!.isNotEmpty) {
        debugPrint('🎵 [STORY_VIEW] Usando YouTube Video ID: ${music.youtubeVideoId}');
        audioUrl = await _getYouTubeAudioUrl(music.youtubeVideoId!);
      }
      // Si no, verificar si previewUrl es de YouTube
      else if (music.previewUrl.isNotEmpty && 
               (music.previewUrl.contains('youtube.com') || music.previewUrl.contains('youtu.be'))) {
        debugPrint('🎵 [STORY_VIEW] Preview URL es de YouTube');
        String? videoId = _extractYouTubeVideoId(music.previewUrl);
        if (videoId != null && videoId.isNotEmpty) {
          audioUrl = await _getYouTubeAudioUrl(videoId);
        }
      }
      // Si tiene preview URL de Spotify o SoundCloud, usar esa
      else if (music.previewUrl.isNotEmpty && 
               !music.previewUrl.contains('youtube.com') && 
               !music.previewUrl.contains('youtu.be') &&
               !music.previewUrl.contains('audius.co') &&
               !music.previewUrl.contains('audius')) {
        debugPrint('🎵 [STORY_VIEW] Usando preview URL (Spotify/SoundCloud)');
        audioUrl = music.previewUrl;
      }
      // Si no hay URL pero tiene trackId, intentar obtener stream URL de Audius
      else if (music.trackId.isNotEmpty) {
        debugPrint('🔍 [STORY_VIEW] No hay previewUrl, intentando obtener stream URL de Audius con track ID: ${music.trackId}');
        try {
          audioUrl = await MusicApi.getAudiusStreamUrl(music.trackId);
          if (audioUrl != null && audioUrl.isNotEmpty) {
            debugPrint('✅ [STORY_VIEW] Stream URL obtenido de Audius: ${audioUrl.substring(0, audioUrl.length > 50 ? 50 : audioUrl.length)}...');
          } else {
            debugPrint('⚠️ [STORY_VIEW] No se pudo obtener stream URL de Audius');
          }
        } catch (e) {
          debugPrint('❌ [STORY_VIEW] Error obteniendo stream URL de Audius: $e');
        }
      }
      
      // Si aún no hay URL, intentar buscar en YouTube usando el nombre de la canción
      if (audioUrl == null || audioUrl.isEmpty) {
        debugPrint('⚠️ [STORY_VIEW] No hay URL disponible, buscando en YouTube...');
        try {
          final yt = YoutubeExplode();
          final searchQuery = '${music.trackName} ${music.artistName}';
          debugPrint('🔍 [STORY_VIEW] Buscando en YouTube: $searchQuery');
          
          final searchResults = await yt.search.search(searchQuery);
          if (searchResults.isNotEmpty) {
            final firstResult = searchResults.first;
            final videoId = firstResult.id.value;
            debugPrint('✅ [STORY_VIEW] Video encontrado en YouTube: $videoId');
            audioUrl = await _getYouTubeAudioUrl(videoId);
            yt.close();
          } else {
            yt.close();
            debugPrint('⚠️ [STORY_VIEW] No se encontró video en YouTube');
          }
        } catch (e) {
          debugPrint('❌ [STORY_VIEW] Error buscando en YouTube: $e');
        }
      }
      
      if (audioUrl == null || audioUrl.isEmpty) {
        debugPrint('⚠️ [STORY_VIEW] No se pudo obtener URL de audio para: ${music.trackName}');
        return;
      }
      
      debugPrint('✅ [STORY_VIEW] URL de audio obtenida: ${audioUrl.substring(0, audioUrl.length > 50 ? 50 : audioUrl.length)}...');
      
      // Calcular tiempo de inicio y duración del segmento (máximo 30 segundos)
      final startTime = Duration(seconds: (music.startTime ?? 0).toInt());
      final rawDuration = music.duration ?? 30.0;
      final segmentDuration = Duration(seconds: rawDuration.clamp(5.0, 30.0).toInt());
      
      // Cancelar listeners anteriores
      _positionSubscription?.cancel();
      _durationSubscription?.cancel();
      _playerStateSubscription?.cancel();
      
      // Detener cualquier reproducción anterior
      try {
        if (_audioPlayer.playing) {
          await _audioPlayer.stop();
        }
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        debugPrint('⚠️ [STORY_VIEW] Error deteniendo audio anterior: $e');
      }
      
      // Configurar volumen y modo de audio antes de cargar
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setSpeed(1.0);
      
      // Cargar audio usando AudioSource para mejor control
      try {
        final audioSource = AudioSource.uri(Uri.parse(audioUrl));
        await _audioPlayer.setAudioSource(audioSource);
        debugPrint('✅ [STORY_VIEW] Audio source cargado');
        // Forzar play inmediatamente para iniciar la carga
        try {
          await _audioPlayer.play();
          await Future.delayed(const Duration(milliseconds: 300));
          await _audioPlayer.pause();
        } catch (e) {
          debugPrint('⚠️ [STORY_VIEW] Error en play inicial (puede ser normal): $e');
        }
      } catch (e) {
        debugPrint('❌ [STORY_VIEW] Error cargando audio source: $e');
        // Fallback a setUrl
        try {
          await _audioPlayer.setUrl(audioUrl);
          debugPrint('✅ [STORY_VIEW] Audio cargado con setUrl (fallback)');
          // Forzar play inmediatamente para iniciar la carga
          try {
            await _audioPlayer.play();
            await Future.delayed(const Duration(milliseconds: 300));
            await _audioPlayer.pause();
          } catch (e2) {
            debugPrint('⚠️ [STORY_VIEW] Error en play inicial con setUrl (puede ser normal): $e2');
          }
        } catch (e2) {
          debugPrint('❌ [STORY_VIEW] Error con setUrl también: $e2');
          return;
        }
      }
      
      // Configurar listeners DESPUÉS de cargar el audio
      _positionSubscription = _audioPlayer.positionStream.listen((position) {
        // Si llegamos al final del segmento, reiniciar desde el inicio del segmento (loop)
        final segmentEnd = startTime + segmentDuration;
        if (position >= segmentEnd) {
          // Hacer loop suave: volver al inicio del segmento
          _audioPlayer.seek(startTime);
        }
        // También verificar si estamos antes del inicio del segmento (por seguridad)
        if (position < startTime && position.inSeconds > 0) {
          _audioPlayer.seek(startTime);
        }
      });
      
      _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
        debugPrint('🎵 [STORY_VIEW] Estado del player: ${state.processingState}, playing: ${state.playing}');
        
        if (state.processingState == ProcessingState.ready && state.playing) {
          debugPrint('✅ [STORY_VIEW] Música reproduciéndose correctamente');
        }
        
        // Si se completa (no debería pasar con el loop, pero por seguridad)
        if (state.processingState == ProcessingState.completed) {
          debugPrint('🔄 [STORY_VIEW] Audio completado, reiniciando loop...');
          _audioPlayer.seek(startTime);
          _audioPlayer.play();
        }
        
        // Si hay un error, intentar recuperar
        if (state.processingState == ProcessingState.idle && !state.playing) {
          // Solo loguear, no intentar reproducir automáticamente aquí
          // para evitar loops infinitos
        }
      });
      
      // Esperar a que el audio esté listo (ready o buffering)
      // Dar tiempo para que el audio se cargue después del play/pause inicial
      await Future.delayed(const Duration(milliseconds: 500));
      
      int attempts = 0;
      bool isReady = false;
      while (attempts < 30) {
        final state = _audioPlayer.playerState;
        if (state.processingState == ProcessingState.ready) {
          debugPrint('✅ [STORY_VIEW] Audio listo para reproducir (ready)');
          isReady = true;
          break;
        } else if (state.processingState == ProcessingState.buffering) {
          debugPrint('⏳ [STORY_VIEW] Audio buffering... (intento ${attempts + 1})');
          // Si está buffering, esperar un poco más
          await Future.delayed(const Duration(milliseconds: 300));
        } else if (state.processingState == ProcessingState.loading) {
          debugPrint('⏳ [STORY_VIEW] Audio cargando... (intento ${attempts + 1})');
          await Future.delayed(const Duration(milliseconds: 200));
        } else if (state.processingState == ProcessingState.idle) {
          debugPrint('⏳ [STORY_VIEW] Audio en estado idle... (intento ${attempts + 1}), intentando forzar carga...');
          // Si está en idle, intentar forzar la carga
          try {
            await _audioPlayer.setVolume(1.0);
            await _audioPlayer.play();
            await Future.delayed(const Duration(milliseconds: 400));
            await _audioPlayer.pause();
          } catch (e) {
            debugPrint('⚠️ [STORY_VIEW] Error forzando carga: $e');
          }
          await Future.delayed(const Duration(milliseconds: 200));
        } else {
          await Future.delayed(const Duration(milliseconds: 200));
        }
        attempts++;
      }
      
      if (!isReady) {
        debugPrint('⚠️ [STORY_VIEW] Audio no está listo después de ${attempts} intentos, intentando reproducir de todas formas...');
      }
      
      // Intentar reproducir con múltiples intentos (especialmente importante para Audius)
      bool playbackStarted = false;
      for (int attempt = 0; attempt < 15; attempt++) {
        try {
          final currentState = _audioPlayer.playerState;
          debugPrint('🎵 [STORY_VIEW] Intento ${attempt + 1}: Estado actual = ${currentState.processingState}, playing = ${currentState.playing}');
          
          // Asegurar volumen y velocidad siempre
          await _audioPlayer.setVolume(1.0);
          await _audioPlayer.setSpeed(1.0);
          
          // Si está en idle, intentar forzar la carga primero
          if (currentState.processingState == ProcessingState.idle) {
            debugPrint('🔄 [STORY_VIEW] Estado idle, forzando carga del audio...');
            // Intentar play para forzar la carga
            try {
              await _audioPlayer.play();
              await Future.delayed(const Duration(milliseconds: 600));
              // Verificar si ahora está cargando
              final newState = _audioPlayer.playerState;
              if (newState.processingState == ProcessingState.idle && !newState.playing) {
                await _audioPlayer.pause();
                await Future.delayed(const Duration(milliseconds: 200));
              }
            } catch (e) {
              debugPrint('⚠️ [STORY_VIEW] Error en play para forzar carga: $e');
            }
            await Future.delayed(const Duration(milliseconds: 300));
          }
          
          // Verificar estado actual después de intentar forzar carga
          final state = _audioPlayer.playerState;
          
          // Intentar reproducir en cualquier estado excepto completed
          if (state.processingState != ProcessingState.completed) {
            // Ir al tiempo de inicio (solo si el audio está listo o buffering)
            if (state.processingState == ProcessingState.ready || 
                state.processingState == ProcessingState.buffering) {
              try {
                await _audioPlayer.seek(startTime);
                debugPrint('✅ [STORY_VIEW] Seek a ${startTime.inSeconds}s completado');
                await Future.delayed(const Duration(milliseconds: 200));
              } catch (e) {
                debugPrint('⚠️ [STORY_VIEW] Error en seek: $e');
              }
            }
            
            // Intentar reproducir
            try {
              await _audioPlayer.play();
              debugPrint('✅ [STORY_VIEW] Intento ${attempt + 1}: Play() llamado');
              
              // Verificar que realmente esté reproduciéndose
              await Future.delayed(const Duration(milliseconds: 1000));
              final verifyState = _audioPlayer.playerState;
              debugPrint('🎵 [STORY_VIEW] Estado después de play: ${verifyState.processingState}, playing: ${verifyState.playing}');
              
              if (verifyState.playing) {
                debugPrint('✅ [STORY_VIEW] Música confirmada reproduciéndose (intento ${attempt + 1})');
                playbackStarted = true;
                break; // Éxito, salir del loop
              } else {
                debugPrint('⚠️ [STORY_VIEW] Intento ${attempt + 1}: Audio no está reproduciéndose aún (${verifyState.processingState})');
              }
            } catch (e) {
              debugPrint('❌ [STORY_VIEW] Error llamando play() en intento ${attempt + 1}: $e');
            }
          } else {
            debugPrint('⏳ [STORY_VIEW] Intento ${attempt + 1}: Estado completed, esperando...');
          }
        } catch (e) {
          debugPrint('❌ [STORY_VIEW] Error en intento ${attempt + 1}: $e');
        }
        
        // Esperar antes del siguiente intento
        if (!playbackStarted && attempt < 14) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      if (!playbackStarted) {
        debugPrint('❌ [STORY_VIEW] No se pudo iniciar la reproducción después de 10 intentos');
        final finalState = _audioPlayer.playerState;
        debugPrint('❌ [STORY_VIEW] Estado final: ${finalState.processingState}, playing: ${finalState.playing}');
      }
      
    } catch (e) {
      debugPrint('❌ [STORY_VIEW] Error cargando música: $e');
      debugPrint('❌ [STORY_VIEW] Stack trace: ${StackTrace.current}');
    }
  }

  // Detener música
  Future<void> _stopMusic() async {
    try {
      // Cancelar listeners primero
      _positionSubscription?.cancel();
      _durationSubscription?.cancel();
      _playerStateSubscription?.cancel();
      
      // Solo detener si realmente está reproduciéndose o cargando
      final state = _audioPlayer.playerState;
      if (state.playing || 
          (state.processingState != ProcessingState.idle && 
           state.processingState != ProcessingState.completed)) {
        try {
          await _audioPlayer.stop();
          debugPrint('⏹️ [STORY_VIEW] Música detenida');
        } catch (e) {
          debugPrint('⚠️ [STORY_VIEW] Error al detener (puede estar ya detenido): $e');
        }
      }
      
      // Limpiar referencia
      _currentPlayingMusic = null;
      
      // Pequeña pausa para asegurar que todo se limpie
      await Future.delayed(const Duration(milliseconds: 50));
    } catch (e) {
      debugPrint('❌ [STORY_VIEW] Error deteniendo música: $e');
      // Asegurar que la referencia se limpie incluso si hay error
      _currentPlayingMusic = null;
    }
  }

  // Extraer video ID de YouTube desde URL
  String? _extractYouTubeVideoId(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.contains('youtube.com')) {
        return uri.queryParameters['v'];
      } else if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
      }
    } catch (e) {
      debugPrint('❌ [STORY_VIEW] Error extrayendo video ID: $e');
    }
    return null;
  }

  // Obtener URL de audio de YouTube
  Future<String?> _getYouTubeAudioUrl(String videoId) async {
    try {
      debugPrint('🔍 [STORY_VIEW] Obteniendo URL de audio para video: $videoId');
      final yt = YoutubeExplode();
      
      // Obtener el stream de audio
      final manifest = await yt.videos.streamsClient.getManifest(videoId);
      
      // Intentar obtener el stream de audio con mayor bitrate
      AudioOnlyStreamInfo? audioStream;
      try {
        audioStream = manifest.audioOnly.withHighestBitrate();
        debugPrint('✅ [STORY_VIEW] Stream de audio encontrado: ${audioStream.bitrate} bps');
      } catch (e) {
        debugPrint('⚠️ [STORY_VIEW] No se pudo obtener stream de mayor bitrate, intentando con cualquier audio...');
        // Si falla, intentar con cualquier stream de audio disponible
        final audioStreams = manifest.audioOnly;
        if (audioStreams.isNotEmpty) {
          audioStream = audioStreams.first;
          debugPrint('✅ [STORY_VIEW] Usando stream de audio alternativo: ${audioStream.bitrate} bps');
        } else {
          debugPrint('❌ [STORY_VIEW] No hay streams de audio disponibles');
          yt.close();
          return null;
        }
      }
      
      final audioUrl = audioStream.url.toString();
      yt.close();
      
      debugPrint('✅ [STORY_VIEW] URL de audio obtenida exitosamente (${audioUrl.length} caracteres)');
      return audioUrl;
    } catch (e) {
      debugPrint('❌ [STORY_VIEW] Error obteniendo URL de YouTube: $e');
      debugPrint('❌ [STORY_VIEW] Stack trace: ${StackTrace.current}');
      return null;
    }
  }
}
