import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chat_messenger/api/story_api.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/models/story/story.dart';
import 'package:chat_messenger/models/story/submodels/seen_by.dart';
import 'package:chat_messenger/models/story/submodels/story_text.dart' as txt;
import 'package:chat_messenger/models/story/submodels/story_image.dart' as img;
import 'package:chat_messenger/models/story/submodels/story_video.dart' as vdo;
import 'package:chat_messenger/models/story/submodels/story_music.dart';
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

  dynamic get storyItem => items[index.value];
  DateTime get createdAt => items[index.value].createdAt;
  List<SeenBy> get seenByList => items[index.value].seenBy;
  
  // Audio player para música de fondo
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StoryMusic? _currentPlayingMusic;
  
  // Obtener música del item actual
  StoryMusic? get currentMusic {
    final item = storyItem;
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
  void onInit() {
    _loadStoryItems();
    // Reproducir música del primer item si tiene
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playMusicForCurrentItem();
    });
    super.onInit();
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

  // Load all story items
  void _loadStoryItems() {
    // <-- Get story texts -->
    for (final txt.StoryText storyText in story.texts) {
      storyItems.add(
        StoryItem.text(
          title: storyText.text,
          backgroundColor: storyText.bgColor,
          textStyle: const TextStyle(fontSize: 24, color: Colors.white),
        ),
      );
      items.add(storyText);
    }

    // <-- Get story images -->
    for (final storyImage in story.images) {
      storyItems.add(
        StoryItem.pageImage(
            url: storyImage.imageUrl, controller: storyController),
      );
      items.add(storyImage);
    }

    // <-- Get story videos -->
    for (final storyVideo in story.videos) {
      storyItems.add(
        StoryItem.pageVideo(storyVideo.videoUrl, controller: storyController),
      );
      items.add(storyVideo);
    }
  }

  void markSeen() {
    if (story.isOwner) return;

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
    StoryApi.deleteStoryItem(story: story, storyItem: storyItem);
  }

  // Reproducir música para el item actual
  Future<void> _playMusicForCurrentItem() async {
    final music = currentMusic;
    
    // Si no hay música, detener y salir
    if (music == null) {
      debugPrint('🎵 [STORY_VIEW] No hay música en este item, deteniendo...');
      await _stopMusic();
      return;
    }
    
    // Si es la misma música que ya está reproduciendo, verificar que esté reproduciéndose
    if (_currentPlayingMusic?.trackId == music.trackId && 
        _currentPlayingMusic?.startTime == music.startTime) {
      final state = _audioPlayer.playerState;
      if (state.processingState == ProcessingState.ready && state.playing) {
        debugPrint('🎵 [STORY_VIEW] Ya está reproduciendo esta música, continuando...');
        return;
      } else {
        debugPrint('🎵 [STORY_VIEW] Misma música pero no está reproduciéndose, reiniciando...');
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
    await _loadAndPlayMusic(music);
  }

  // Cargar y reproducir música
  Future<void> _loadAndPlayMusic(StoryMusic music) async {
    try {
      debugPrint('🎵 [STORY_VIEW] Cargando música: ${music.trackName}');
      debugPrint('🎵 [STORY_VIEW] Preview URL: ${music.previewUrl}');
      debugPrint('🎵 [STORY_VIEW] YouTube Video ID: ${music.youtubeVideoId}');
      
      String? audioUrl;
      
      // Si tiene YouTube Video ID, usar ese
      if (music.youtubeVideoId != null && music.youtubeVideoId!.isNotEmpty) {
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
      // Si tiene preview URL de Spotify, usar esa
      else if (music.previewUrl.isNotEmpty && 
               !music.previewUrl.contains('youtube.com') && 
               !music.previewUrl.contains('youtu.be')) {
        debugPrint('🎵 [STORY_VIEW] Usando preview URL de Spotify');
        audioUrl = music.previewUrl;
      }
      // Si no hay URL, intentar buscar en YouTube usando el nombre de la canción
      else {
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
      
      // Cargar audio usando AudioSource para mejor control
      try {
        final audioSource = AudioSource.uri(Uri.parse(audioUrl));
        await _audioPlayer.setAudioSource(audioSource);
        debugPrint('✅ [STORY_VIEW] Audio source cargado');
      } catch (e) {
        debugPrint('❌ [STORY_VIEW] Error cargando audio source: $e');
        // Fallback a setUrl
        try {
          await _audioPlayer.setUrl(audioUrl);
          debugPrint('✅ [STORY_VIEW] Audio cargado con setUrl (fallback)');
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
      int attempts = 0;
      bool isReady = false;
      while (attempts < 20) {
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
        } else {
          await Future.delayed(const Duration(milliseconds: 200));
        }
        attempts++;
      }
      
      if (!isReady) {
        debugPrint('⚠️ [STORY_VIEW] Audio no está listo después de ${attempts} intentos, intentando reproducir de todas formas...');
      }
      
      // Ir al tiempo de inicio
      try {
        await _audioPlayer.seek(startTime);
        debugPrint('✅ [STORY_VIEW] Seek a ${startTime.inSeconds}s completado');
      } catch (e) {
        debugPrint('⚠️ [STORY_VIEW] Error en seek inicial: $e');
      }
      
      // Esperar un poco para asegurar que el seek se complete
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Verificar estado antes de reproducir
      final currentState = _audioPlayer.playerState;
      if (currentState.processingState == ProcessingState.ready || 
          currentState.processingState == ProcessingState.buffering) {
        // Reproducir automáticamente (como Instagram)
        try {
          await _audioPlayer.play();
          debugPrint('✅ [STORY_VIEW] Música iniciada desde ${startTime.inSeconds}s por ${segmentDuration.inSeconds}s (loop activo)');
          
          // Verificar que realmente esté reproduciéndose después de un momento
          await Future.delayed(const Duration(milliseconds: 500));
          final verifyState = _audioPlayer.playerState;
          if (!verifyState.playing) {
            debugPrint('⚠️ [STORY_VIEW] El audio no está reproduciéndose, intentando de nuevo...');
            await _audioPlayer.play();
          }
        } catch (e) {
          debugPrint('❌ [STORY_VIEW] Error reproduciendo audio: $e');
        }
      } else {
        debugPrint('⚠️ [STORY_VIEW] Audio no está en estado ready/buffering (${currentState.processingState}), no se puede reproducir');
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
