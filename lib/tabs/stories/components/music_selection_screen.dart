import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import 'package:chat_messenger/api/music_api.dart';
import 'package:chat_messenger/models/story/submodels/story_music.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class MusicSelectionScreen extends StatefulWidget {
  final MusicTrack track;
  final Function(StoryMusic)? onMusicSelected;

  const MusicSelectionScreen({
    super.key,
    required this.track,
    this.onMusicSelected,
  });

  @override
  State<MusicSelectionScreen> createState() => _MusicSelectionScreenState();
}

class _MusicSelectionScreenState extends State<MusicSelectionScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final RxBool _isPlaying = false.obs;
  final RxBool _isLoading = false.obs;
  final RxDouble _currentPosition = 0.0.obs;
  final RxDouble _duration = 0.0.obs;
  final RxDouble _startTime = 0.0.obs;
  final RxDouble _selectedDuration = 30.0.obs; // Máximo 30 segundos
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  bool _hasAutoPlayed = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      debugPrint('🎵 [MUSIC_SELECTION] Inicializando player para: ${widget.track.name}');
      debugPrint('🎵 [MUSIC_SELECTION] Preview URL: ${widget.track.previewUrl ?? "null"}');
      debugPrint('🎵 [MUSIC_SELECTION] Track ID: ${widget.track.id}');
      
      // Verificar si es YouTube (solo si la preview URL contiene youtube)
      bool isYouTube = widget.track.previewUrl != null && 
                       (widget.track.previewUrl!.contains('youtube.com') || 
                        widget.track.previewUrl!.contains('youtu.be'));
      
      _isLoading.value = true;
      
      // Para YouTube, usar el video ID para obtener audio
      if (isYouTube) {
        String? videoId = _extractYouTubeVideoId(widget.track.previewUrl ?? '') ?? widget.track.id;
        
        if (videoId != null && videoId.isNotEmpty) {
          debugPrint('🎵 [MUSIC_SELECTION] Video de YouTube detectado: $videoId');
          await _loadYouTubeAudio(videoId);
          return;
        }
      }
      
      // Para Spotify con preview URL
      if (widget.track.previewUrl != null && widget.track.previewUrl!.isNotEmpty) {
        String audioUrl = widget.track.previewUrl!;
        
        // Verificar que la URL sea válida
        try {
          final uri = Uri.parse(audioUrl);
          if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
            throw Exception('URL inválida: $audioUrl');
          }
          debugPrint('✅ [MUSIC_SELECTION] URL válida: ${uri.scheme}://${uri.host}');
        } catch (e) {
          debugPrint('❌ [MUSIC_SELECTION] URL inválida: $e');
          _isLoading.value = false;
          return;
        }
        
        try {
          debugPrint('📥 [MUSIC_SELECTION] Configurando audio source desde: $audioUrl');
          await _audioPlayer.setUrl(audioUrl);
          debugPrint('✅ [MUSIC_SELECTION] Audio cargado exitosamente');
        } catch (e) {
          debugPrint('❌ [MUSIC_SELECTION] Error cargando audio: $e');
          _isLoading.value = false;
          
          // Mostrar error después del build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Get.snackbar(
                'Error',
                'No se pudo cargar el preview: $e',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 3),
              );
            }
          });
          return;
        }
      } else {
        // No hay preview disponible en Spotify - intentar buscar en YouTube
        debugPrint('⚠️ [MUSIC_SELECTION] No hay preview de Spotify, intentando buscar en YouTube...');
        
        // Buscar en YouTube usando el nombre de la canción
        try {
          final yt = YoutubeExplode();
          final searchQuery = '${widget.track.name} ${widget.track.artist}';
          debugPrint('🔍 [MUSIC_SELECTION] Buscando en YouTube: $searchQuery');
          
          final searchResults = await yt.search.search(searchQuery);
          if (searchResults.isNotEmpty) {
            final firstResult = searchResults.first;
            final videoId = firstResult.id.value;
            debugPrint('✅ [MUSIC_SELECTION] Video encontrado en YouTube: $videoId');
            yt.close();
            // Cargar y reproducir automáticamente
            await _loadYouTubeAudio(videoId);
            return;
          }
          yt.close();
          debugPrint('⚠️ [MUSIC_SELECTION] No se encontraron resultados en YouTube');
        } catch (e) {
          debugPrint('❌ [MUSIC_SELECTION] Error buscando en YouTube: $e');
        }
        
        // Si no se encontró en YouTube, establecer duración por defecto
        _duration.value = widget.track.duration != null 
            ? (widget.track.duration! / 1000.0) 
            : 180.0;
        _isLoading.value = false;
        
        // Mostrar mensaje al usuario
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Get.snackbar(
                'Sin preview',
                'No hay preview disponible para esta canción. Puedes seleccionar el segmento que deseas usar.',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 3),
              );
            }
          });
        }
        return;
      }

      // Escuchar posición
      _positionSubscription = _audioPlayer.positionStream.listen((position) {
        _currentPosition.value = position.inSeconds.toDouble();
        
        // Si llegamos al final del segmento seleccionado (inicio + duración), pausar
        final segmentEnd = _startTime.value + _selectedDuration.value;
        if (position.inSeconds >= segmentEnd && segmentEnd > 0) {
          _audioPlayer.pause();
          _isPlaying.value = false;
          debugPrint('⏸️ [MUSIC_SELECTION] Llegó al final del segmento seleccionado (${segmentEnd}s)');
        }
        // Si llegamos al final de la canción completa, también pausar
        else if (position.inSeconds >= _duration.value && _duration.value > 0) {
          _isPlaying.value = false;
        }
      });

      // Escuchar duración
      _durationSubscription = _audioPlayer.durationStream.listen((duration) {
        if (duration != null) {
          _duration.value = duration.inSeconds.toDouble();
          if (_duration.value < 30.0) {
            _selectedDuration.value = _duration.value;
          }
        }
      });

      // Escuchar cambios de estado del player
      _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
        debugPrint('🎵 [MUSIC_SELECTION] Estado del player: ${state.processingState}, playing: ${state.playing}');
        
        // Reproducir automáticamente cuando esté listo (solo una vez)
        if ((state.processingState == ProcessingState.ready || 
             state.processingState == ProcessingState.buffering) && 
            !_isPlaying.value && 
            !_hasAutoPlayed) {
          _hasAutoPlayed = true;
          debugPrint('▶️ [MUSIC_SELECTION] Player listo, iniciando reproducción automática desde stream...');
          Future.delayed(const Duration(milliseconds: 300), () async {
            if (!mounted) return;
            try {
              // Ir al inicio antes de reproducir
              await _audioPlayer.seek(Duration.zero);
              await _audioPlayer.play();
              _isPlaying.value = true;
              _currentPosition.value = 0.0;
              debugPrint('✅ [MUSIC_SELECTION] Preview iniciado automáticamente desde el inicio');
            } catch (e) {
              debugPrint('❌ [MUSIC_SELECTION] Error al reproducir desde stream: $e');
              _hasAutoPlayed = false; // Permitir reintentar
              // Reintentar después de un delay
              Future.delayed(const Duration(milliseconds: 500), () {
                if (!_hasAutoPlayed && !_isPlaying.value && mounted) {
                  _startAutoPlay();
                }
              });
            }
          });
        }
        
        if (state.processingState == ProcessingState.completed) {
          _isPlaying.value = false;
          debugPrint('⏹️ [MUSIC_SELECTION] Canción terminada');
        }
      });

      // Intentar obtener duración inmediatamente
      try {
        final duration = await _audioPlayer.duration;
        if (duration != null) {
          _duration.value = duration.inSeconds.toDouble();
          if (_duration.value < 30.0) {
            _selectedDuration.value = _duration.value;
          }
          debugPrint('📏 [MUSIC_SELECTION] Duración obtenida: ${_duration.value}s');
        }
      } catch (e) {
        debugPrint('⚠️ [MUSIC_SELECTION] No se pudo obtener duración inmediatamente: $e');
      }

      _isLoading.value = false;
      debugPrint('✅ [MUSIC_SELECTION] Player inicializado');
      
      // Reproducir automáticamente desde el inicio cuando se abre la pantalla
      // Intentar múltiples veces para asegurar que funcione
      _attemptAutoPlay();
      
      // También intentar después de más tiempo como respaldo
      Future.delayed(const Duration(milliseconds: 1000), () async {
        if (!_hasAutoPlayed && !_isPlaying.value && mounted) {
          debugPrint('🔄 [MUSIC_SELECTION] Reintentando autoplay después de 1s...');
          await _startAutoPlay();
        }
      });
      
      // Último intento después de 2 segundos
      Future.delayed(const Duration(milliseconds: 2000), () async {
        if (!_hasAutoPlayed && !_isPlaying.value && mounted) {
          debugPrint('🔄 [MUSIC_SELECTION] Último intento de autoplay después de 2s...');
          await _startAutoPlay();
        }
      });
    } catch (e) {
      debugPrint('❌ [MUSIC_SELECTION] Error inicializando player: $e');
      _isLoading.value = false;
    }
  }

  // Método para iniciar reproducción automática desde el inicio
  Future<void> _startAutoPlay() async {
    if (_hasAutoPlayed || _isPlaying.value || !mounted) {
      if (_hasAutoPlayed) {
        debugPrint('⏭️ [MUSIC_SELECTION] Autoplay ya ejecutado, saltando...');
      }
      return;
    }
    
    try {
      final state = _audioPlayer.playerState;
      debugPrint('🎵 [MUSIC_SELECTION] Iniciando auto-play. Estado: ${state.processingState}, playing: ${state.playing}');
      
      if (state.processingState == ProcessingState.ready) {
        // Ir al inicio (0 segundos)
        await _audioPlayer.seek(Duration.zero);
        // Esperar un poco para que el seek se complete
        await Future.delayed(const Duration(milliseconds: 100));
        // Reproducir
        await _audioPlayer.play();
        _isPlaying.value = true;
        _hasAutoPlayed = true;
        _currentPosition.value = 0.0;
        debugPrint('✅ [MUSIC_SELECTION] Reproducción automática iniciada desde el inicio');
      } else if (state.processingState == ProcessingState.buffering || 
                 state.processingState == ProcessingState.loading) {
        // Esperar un poco más y reintentar
        debugPrint('⏳ [MUSIC_SELECTION] Player cargando, esperando...');
        Future.delayed(const Duration(milliseconds: 500), () async {
          if (!_hasAutoPlayed && !_isPlaying.value && mounted) {
            await _startAutoPlay();
          }
        });
      } else {
        // Si está en otro estado, intentar de todas formas
        debugPrint('🔄 [MUSIC_SELECTION] Estado inesperado, intentando reproducir de todas formas...');
        try {
          await _audioPlayer.seek(Duration.zero);
          await Future.delayed(const Duration(milliseconds: 100));
          await _audioPlayer.play();
          _isPlaying.value = true;
          _hasAutoPlayed = true;
          debugPrint('✅ [MUSIC_SELECTION] Reproducción forzada exitosa');
        } catch (e2) {
          debugPrint('❌ [MUSIC_SELECTION] Error forzando reproducción: $e2');
          // Reintentar después de un delay
          Future.delayed(const Duration(milliseconds: 500), () async {
            if (!_hasAutoPlayed && !_isPlaying.value && mounted) {
              await _startAutoPlay();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('❌ [MUSIC_SELECTION] Error en auto-play: $e');
      // Reintentar una vez más después de un delay
      Future.delayed(const Duration(milliseconds: 1000), () async {
        if (!_hasAutoPlayed && !_isPlaying.value && mounted) {
          try {
            await _audioPlayer.seek(Duration.zero);
            await Future.delayed(const Duration(milliseconds: 100));
            await _audioPlayer.play();
            _isPlaying.value = true;
            _hasAutoPlayed = true;
            debugPrint('✅ [MUSIC_SELECTION] Auto-play exitoso en segundo intento');
          } catch (e2) {
            debugPrint('❌ [MUSIC_SELECTION] Error en segundo intento de auto-play: $e2');
          }
        }
      });
    }
  }

  // Método para intentar reproducir automáticamente con múltiples intentos
  Future<void> _attemptAutoPlay({int attempt = 0}) async {
    if (_hasAutoPlayed || _isPlaying.value || attempt >= 5) {
      if (attempt >= 5) {
        debugPrint('⚠️ [MUSIC_SELECTION] Máximo de intentos alcanzado para auto-play');
      }
      return;
    }
    
    if (attempt > 0) {
      await Future.delayed(Duration(milliseconds: 300 + (attempt * 300)));
    }
    
    if (!mounted || _hasAutoPlayed || _isPlaying.value) {
      return;
    }
    
    try {
      final state = _audioPlayer.playerState;
      debugPrint('🎵 [MUSIC_SELECTION] Intento ${attempt + 1}: Estado = ${state.processingState}, playing = ${state.playing}');
      
      if (state.processingState == ProcessingState.ready) {
        debugPrint('▶️ [MUSIC_SELECTION] Reproduciendo automáticamente (intento ${attempt + 1})...');
        await _audioPlayer.play();
        _isPlaying.value = true;
        _hasAutoPlayed = true;
        debugPrint('✅ [MUSIC_SELECTION] Preview reproduciéndose automáticamente');
      } else if (state.processingState == ProcessingState.buffering || 
                   state.processingState == ProcessingState.loading) {
          debugPrint('⏳ [MUSIC_SELECTION] Player cargando, reintentando...');
          if (attempt < 5) {
            _attemptAutoPlay(attempt: attempt + 1);
          }
        } else if (attempt < 5) {
          // Reintentar si aún no está listo
          debugPrint('⏳ [MUSIC_SELECTION] Esperando que el player esté listo...');
          _attemptAutoPlay(attempt: attempt + 1);
        } else {
          // Último intento: forzar reproducción
          debugPrint('🔄 [MUSIC_SELECTION] Último intento: forzando reproducción...');
          try {
            await _audioPlayer.play();
            _isPlaying.value = true;
            _hasAutoPlayed = true;
            debugPrint('✅ [MUSIC_SELECTION] Reproducción forzada exitosa');
          } catch (e) {
            debugPrint('❌ [MUSIC_SELECTION] No se pudo forzar reproducción: $e');
          }
        }
    } catch (e) {
      debugPrint('❌ [MUSIC_SELECTION] Error en intento ${attempt + 1}: $e');
      if (attempt < 5) {
        _attemptAutoPlay(attempt: attempt + 1);
      }
    }
  }

  String? _extractYouTubeVideoId(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.contains('youtube.com')) {
        return uri.queryParameters['v'];
      } else if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
      }
    } catch (e) {
      debugPrint('❌ [MUSIC_SELECTION] Error extrayendo video ID: $e');
    }
    return null;
  }

  // Método para cargar audio de YouTube usando youtube_explode_dart
  Future<void> _loadYouTubeAudio(String videoId) async {
    try {
      debugPrint('🎵 [MUSIC_SELECTION] Cargando audio de YouTube: $videoId');
      _isLoading.value = true;

      final yt = YoutubeExplode();
      
      // Obtener información del video
      final video = await yt.videos.get(videoId);
      final duration = video.duration;
      _duration.value = duration?.inSeconds.toDouble() ?? (widget.track.duration != null 
          ? (widget.track.duration! / 1000.0) 
          : 180.0);
      debugPrint('📏 [MUSIC_SELECTION] Duración del video: ${_duration.value}s');

      // Obtener el stream de audio
      final manifest = await yt.videos.streamsClient.getManifest(videoId);
      
      // Intentar obtener el mejor stream de audio disponible
      AudioOnlyStreamInfo? audioStream = manifest.audioOnly.withHighestBitrate();
      
      if (audioStream == null) {
        throw Exception('No se encontró stream de audio para este video');
      }

      debugPrint('✅ [MUSIC_SELECTION] Stream de audio encontrado: ${audioStream.url}');
      
      // Intentar cargar el audio usando AudioSource.uri() para mejor compatibilidad
      bool loaded = false;
      AudioSource? audioSource;
      
      try {
        // Usar AudioSource.uri() en lugar de setUrl() para mejor compatibilidad en iOS
        audioSource = AudioSource.uri(Uri.parse(audioStream.url.toString()));
        await _audioPlayer.setAudioSource(audioSource);
        debugPrint('✅ [MUSIC_SELECTION] Audio de YouTube cargado exitosamente');
        loaded = true;
      } catch (e) {
        debugPrint('⚠️ [MUSIC_SELECTION] Error cargando stream principal: $e');
        debugPrint('🔄 [MUSIC_SELECTION] Intentando con streams alternativos...');
        
        // Intentar con otros streams de audio si está disponible
        final allAudioStreams = manifest.audioOnly.toList();
        if (allAudioStreams.length > 1) {
          // Ordenar por bitrate y probar desde el más bajo (más compatible)
          allAudioStreams.sort((a, b) => a.bitrate.compareTo(b.bitrate));
          
          for (var stream in allAudioStreams) {
            if (stream == audioStream) continue; // Ya probamos este
            try {
              debugPrint('🔄 [MUSIC_SELECTION] Intentando con stream alternativo (bitrate: ${stream.bitrate})...');
              audioSource = AudioSource.uri(Uri.parse(stream.url.toString()));
              await _audioPlayer.setAudioSource(audioSource);
              debugPrint('✅ [MUSIC_SELECTION] Audio de YouTube cargado con stream alternativo');
              loaded = true;
              break;
            } catch (e2) {
              debugPrint('❌ [MUSIC_SELECTION] Error con stream alternativo: $e2');
              continue;
            }
          }
        }
        
        if (!loaded) {
          throw Exception('No se pudo cargar ningún stream de audio: $e');
        }
      }

      // Configurar listeners
      _positionSubscription = _audioPlayer.positionStream.listen((position) {
        _currentPosition.value = position.inSeconds.toDouble();
        
        // Si llegamos al final del segmento seleccionado, pausar
        final segmentEnd = _startTime.value + _selectedDuration.value;
        if (position.inSeconds >= segmentEnd && segmentEnd > 0) {
          _audioPlayer.pause();
          _isPlaying.value = false;
          debugPrint('⏸️ [MUSIC_SELECTION] Llegó al final del segmento seleccionado (${segmentEnd}s)');
        }
        // Si llegamos al final de la canción completa, también pausar
        else if (position.inSeconds >= _duration.value && _duration.value > 0) {
          _isPlaying.value = false;
        }
      });

      _durationSubscription = _audioPlayer.durationStream.listen((duration) {
        if (duration != null) {
          _duration.value = duration.inSeconds.toDouble();
          if (_duration.value < 30.0) {
            _selectedDuration.value = _duration.value;
          }
        }
      });

      _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
        debugPrint('🎵 [MUSIC_SELECTION] Estado del player: ${state.processingState}, playing: ${state.playing}');
        
        // Si hay un error, intentar recuperarse
        if (state.processingState == ProcessingState.idle && 
            state.playing == false && 
            _isLoading.value == false &&
            !_hasAutoPlayed) {
          // Si está en idle después de intentar cargar, puede haber un error
          debugPrint('⚠️ [MUSIC_SELECTION] Player en idle, puede haber un problema');
        }
        
        // Reproducir automáticamente cuando esté listo (solo una vez) - para YouTube
        if ((state.processingState == ProcessingState.ready || 
             state.processingState == ProcessingState.buffering) && 
            !_isPlaying.value && 
            !_hasAutoPlayed) {
          _hasAutoPlayed = true;
          debugPrint('▶️ [MUSIC_SELECTION] Player de YouTube listo, iniciando reproducción automática...');
          Future.delayed(const Duration(milliseconds: 300), () async {
            if (!mounted) return;
            try {
              // Ir al inicio antes de reproducir
              await _audioPlayer.seek(Duration.zero);
              await Future.delayed(const Duration(milliseconds: 200));
              await _audioPlayer.play();
              _isPlaying.value = true;
              _currentPosition.value = 0.0;
              debugPrint('✅ [MUSIC_SELECTION] Audio de YouTube iniciado automáticamente desde el inicio');
            } catch (e) {
              debugPrint('❌ [MUSIC_SELECTION] Error al reproducir YouTube desde stream: $e');
              _hasAutoPlayed = false; // Permitir reintentar
              // Reintentar después de un delay
              Future.delayed(const Duration(milliseconds: 500), () {
                if (!_hasAutoPlayed && !_isPlaying.value && mounted) {
                  _startAutoPlay();
                }
              });
            }
          });
        }
        
        if (state.processingState == ProcessingState.completed) {
          _isPlaying.value = false;
          debugPrint('⏹️ [MUSIC_SELECTION] Canción terminada');
        }
      });

      _isLoading.value = false;
      debugPrint('✅ [MUSIC_SELECTION] Audio de YouTube cargado');
      
      // Esperar a que el player cambie de estado (de idle a loading/buffering/ready)
      // El listener del playerStateStream debería manejar la reproducción automática
      // Pero también intentamos manualmente como respaldo
      int retryCount = 0;
      while (retryCount < 15 && !_hasAutoPlayed && !_isPlaying.value) {
        await Future.delayed(const Duration(milliseconds: 400));
        final currentState = _audioPlayer.playerState;
        
        debugPrint('🔄 [MUSIC_SELECTION] Intento ${retryCount + 1}: Estado = ${currentState.processingState}, playing = ${currentState.playing}');
        
        // Si está en loading o buffering, esperar un poco más
        if (currentState.processingState == ProcessingState.loading ||
            currentState.processingState == ProcessingState.buffering) {
          debugPrint('⏳ [MUSIC_SELECTION] Player cargando, esperando...');
          retryCount++;
          continue;
        }
        
        // Si está ready, intentar reproducir
        if (currentState.processingState == ProcessingState.ready) {
          try {
            await _audioPlayer.seek(Duration.zero);
            await Future.delayed(const Duration(milliseconds: 300));
            await _audioPlayer.play();
            _isPlaying.value = true;
            _hasAutoPlayed = true;
            _currentPosition.value = 0.0;
            debugPrint('✅ [MUSIC_SELECTION] Audio de YouTube iniciado automáticamente (intento ${retryCount + 1})');
            break;
          } catch (e) {
            debugPrint('❌ [MUSIC_SELECTION] Error al iniciar YouTube (intento ${retryCount + 1}): $e');
            retryCount++;
          }
        } else if (currentState.processingState == ProcessingState.idle) {
          // Si sigue en idle después de varios intentos, puede que haya un problema
          retryCount++;
          if (retryCount >= 5) {
            debugPrint('⚠️ [MUSIC_SELECTION] Player sigue en idle, intentando forzar carga...');
            // Intentar forzar la carga llamando a setAudioSource de nuevo
            try {
              if (audioSource != null) {
                await _audioPlayer.setAudioSource(audioSource);
                await Future.delayed(const Duration(milliseconds: 500));
              }
            } catch (e) {
              debugPrint('❌ [MUSIC_SELECTION] Error forzando carga: $e');
            }
          }
        } else {
          retryCount++;
        }
      }
      
      // Si aún no se pudo reproducir, intentar con los métodos de respaldo
      if (!_hasAutoPlayed && !_isPlaying.value && mounted) {
        debugPrint('🔄 [MUSIC_SELECTION] Intentando autoplay con método de respaldo...');
        _attemptAutoPlay();
        
        // También intentar después de más tiempo como respaldo
        Future.delayed(const Duration(milliseconds: 1000), () async {
          if (!_hasAutoPlayed && !_isPlaying.value && mounted) {
            debugPrint('🔄 [MUSIC_SELECTION] Reintentando autoplay de YouTube después de 1s...');
            await _startAutoPlay();
          }
        });
        
        // Último intento después de 2 segundos
        Future.delayed(const Duration(milliseconds: 2000), () async {
          if (!_hasAutoPlayed && !_isPlaying.value && mounted) {
            debugPrint('🔄 [MUSIC_SELECTION] Último intento de autoplay de YouTube después de 2s...');
            await _startAutoPlay();
          }
        });
      }

      // Cerrar YoutubeExplode
      yt.close();

    } catch (e) {
      debugPrint('❌ [MUSIC_SELECTION] Error cargando audio de YouTube: $e');
      _isLoading.value = false;
      
      // Si falla, establecer duración por defecto
      _duration.value = widget.track.duration != null 
          ? (widget.track.duration! / 1000.0) 
          : 180.0;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Get.snackbar(
            'Error',
            'No se pudo cargar el audio de YouTube. Puedes seleccionar el segmento igualmente.',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
          );
        }
      });
    }
  }

  Future<void> _playPause() async {
    try {
      // Si es YouTube, mostrar mensaje
      bool isYouTube = widget.track.previewUrl?.contains('youtube.com') == true || 
                       widget.track.previewUrl?.contains('youtu.be') == true;
      
      if (isYouTube) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Get.snackbar(
                'YouTube',
                'La reproducción completa de YouTube requiere configuración adicional. Puedes seleccionar el segmento que deseas usar.',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 3),
              );
            }
          });
        }
        return;
      }
      
      debugPrint('🎵 [MUSIC_SELECTION] Play/Pause presionado. Estado actual: ${_isPlaying.value}');
      
      if (_isPlaying.value) {
        debugPrint('⏸️ [MUSIC_SELECTION] Pausando...');
        await _audioPlayer.pause();
        _isPlaying.value = false;
      } else {
        debugPrint('▶️ [MUSIC_SELECTION] Reproduciendo...');
        
        // Verificar el estado del player antes de reproducir
        final state = _audioPlayer.playerState;
        debugPrint('🎵 [MUSIC_SELECTION] Estado del player antes de play: ${state.processingState}');
        
        // Si el player no está listo, esperar un poco
        if (state.processingState != ProcessingState.ready && 
            state.processingState != ProcessingState.buffering) {
          debugPrint('⏳ [MUSIC_SELECTION] Player no está listo, esperando...');
          await Future.delayed(const Duration(milliseconds: 300));
        }
        
        // Si estamos al final de la canción, volver al inicio
        if (_currentPosition.value >= _duration.value && _duration.value > 0) {
          debugPrint('🔄 [MUSIC_SELECTION] Volviendo al inicio de la canción');
          await _audioPlayer.seek(Duration.zero);
          _currentPosition.value = 0.0;
        }
        
        try {
          await _audioPlayer.play();
          _isPlaying.value = true;
          _hasAutoPlayed = true; // Marcar como reproducido
          debugPrint('✅ [MUSIC_SELECTION] Reproducción iniciada exitosamente');
        } catch (e) {
          debugPrint('❌ [MUSIC_SELECTION] Error al iniciar reproducción: $e');
          // Intentar cargar el audio de nuevo si falla
          try {
            await _audioPlayer.setUrl(widget.track.previewUrl!);
            await _audioPlayer.play();
            _isPlaying.value = true;
            debugPrint('✅ [MUSIC_SELECTION] Reproducción iniciada después de recargar');
          } catch (e2) {
            debugPrint('❌ [MUSIC_SELECTION] Error al recargar y reproducir: $e2');
            if (mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Get.snackbar(
                    'Error',
                    'No se pudo reproducir el audio: $e2',
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 3),
                  );
                }
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [MUSIC_SELECTION] Error en play/pause: $e');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Get.snackbar(
              'Error',
              'Error al reproducir/pausar: $e',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 3),
            );
          }
        });
      }
    }
  }

  Future<void> _seekTo(double seconds) async {
    try {
      final seekPosition = Duration(seconds: seconds.toInt());
      await _audioPlayer.seek(seekPosition);
      _currentPosition.value = seconds;
    } catch (e) {
      debugPrint('❌ [MUSIC_SELECTION] Error en seek: $e');
    }
  }

  // Método para cuando se cambia el tiempo de inicio - reproduce desde ese punto
  Future<void> _onStartTimeChanged(double value) async {
    _startTime.value = value;
    
    // Verificar si hay audio disponible (preview de Spotify o YouTube)
    bool isYouTube = widget.track.previewUrl != null && 
                     (widget.track.previewUrl!.contains('youtube.com') || 
                      widget.track.previewUrl!.contains('youtu.be'));
    bool hasPreview = widget.track.previewUrl != null && 
                      widget.track.previewUrl!.isNotEmpty &&
                      !isYouTube;
    
    // Si tiene preview (Spotify o YouTube cargado), reproducir desde ese punto
    if (hasPreview || isYouTube || _duration.value > 0) {
      try {
        // Verificar que el player tenga audio cargado
        final state = _audioPlayer.playerState;
        debugPrint('🎵 [MUSIC_SELECTION] Cambiando inicio a ${value}s. Estado: ${state.processingState}');
        
        if (state.processingState == ProcessingState.ready || 
            state.processingState == ProcessingState.buffering ||
            state.processingState == ProcessingState.loading) {
          // Buscar a la nueva posición
          await _seekTo(value);
          
          // Si no está reproduciendo, iniciar reproducción
          if (!_isPlaying.value) {
            await _audioPlayer.play();
            _isPlaying.value = true;
            debugPrint('▶️ [MUSIC_SELECTION] Reproduciendo desde ${value}s');
          }
        } else {
          debugPrint('⚠️ [MUSIC_SELECTION] Player no está listo (${state.processingState}), esperando...');
          // Esperar un poco y reintentar
          Future.delayed(const Duration(milliseconds: 300), () async {
            if (mounted) {
              final newState = _audioPlayer.playerState;
              if (newState.processingState == ProcessingState.ready || 
                  newState.processingState == ProcessingState.buffering) {
                await _seekTo(value);
                if (!_isPlaying.value) {
                  await _audioPlayer.play();
                  _isPlaying.value = true;
                  debugPrint('▶️ [MUSIC_SELECTION] Reproduciendo desde ${value}s (reintento)');
                }
              }
            }
          });
        }
      } catch (e) {
        debugPrint('❌ [MUSIC_SELECTION] Error al reproducir desde nuevo inicio: $e');
      }
    }
  }

  Future<void> _selectMusic() async {
    debugPrint('🎵 [MUSIC_SELECTION] Botón "Usar esta música" presionado');
    
    // Determinar si es YouTube (solo si la preview URL contiene youtube)
    bool isYouTube = widget.track.previewUrl != null && 
                     (widget.track.previewUrl!.contains('youtube.com') || 
                      widget.track.previewUrl!.contains('youtu.be'));
    
    // Extraer video ID de YouTube si es necesario
    String? youtubeVideoId;
    if (isYouTube) {
      youtubeVideoId = _extractYouTubeVideoId(widget.track.previewUrl ?? '');
      debugPrint('🎵 [MUSIC_SELECTION] Video ID de YouTube: $youtubeVideoId');
    }
    
    // Si no hay preview URL y no es YouTube, buscar en YouTube para guardar el video ID
    if ((widget.track.previewUrl == null || widget.track.previewUrl!.isEmpty) && !isYouTube) {
      debugPrint('🔍 [MUSIC_SELECTION] No hay preview, buscando en YouTube para guardar video ID...');
      try {
        final yt = YoutubeExplode();
        final searchQuery = '${widget.track.name} ${widget.track.artist}';
        final searchResults = await yt.search.search(searchQuery);
        if (searchResults.isNotEmpty) {
          final firstResult = searchResults.first;
          youtubeVideoId = firstResult.id.value;
          debugPrint('✅ [MUSIC_SELECTION] Video ID encontrado en YouTube: $youtubeVideoId');
        }
        yt.close();
      } catch (e) {
        debugPrint('❌ [MUSIC_SELECTION] Error buscando en YouTube: $e');
      }
    }
    
    // Si tiene preview URL (Spotify), reproducir antes de seleccionar
    if (widget.track.previewUrl != null && 
        widget.track.previewUrl!.isNotEmpty && 
        !isYouTube) {
      debugPrint('▶️ [MUSIC_SELECTION] Reproduciendo canción antes de seleccionar...');
      
      // Asegurarse de que el player esté listo
      try {
        final state = _audioPlayer.playerState;
        if (state.processingState == ProcessingState.ready) {
          // Si no está reproduciendo, iniciar reproducción
          if (!_isPlaying.value) {
            await _audioPlayer.play();
            _isPlaying.value = true;
            debugPrint('✅ [MUSIC_SELECTION] Canción reproduciéndose');
          }
          
          // Buscar al tiempo de inicio seleccionado
          if (_startTime.value > 0) {
            await _audioPlayer.seek(Duration(seconds: _startTime.value.toInt()));
            debugPrint('⏩ [MUSIC_SELECTION] Buscando a ${_startTime.value}s');
          }
        } else {
          // Si no está listo, intentar cargar y reproducir
          debugPrint('⏳ [MUSIC_SELECTION] Player no está listo, cargando...');
          await _audioPlayer.setUrl(widget.track.previewUrl!);
          await Future.delayed(const Duration(milliseconds: 500));
          await _audioPlayer.play();
          if (_startTime.value > 0) {
            await _audioPlayer.seek(Duration(seconds: _startTime.value.toInt()));
          }
          _isPlaying.value = true;
          debugPrint('✅ [MUSIC_SELECTION] Canción cargada y reproduciéndose');
        }
      } catch (e) {
        debugPrint('❌ [MUSIC_SELECTION] Error al reproducir: $e');
        // Continuar con la selección aunque falle la reproducción
      }
    }
    
    // Asegurar que la duración no exceda 30 segundos
    final finalDuration = _selectedDuration.value.clamp(5.0, 30.0);
    
    final storyMusic = StoryMusic(
      trackId: widget.track.id,
      trackName: widget.track.name,
      artistName: widget.track.artist,
      albumName: widget.track.album,
      previewUrl: widget.track.previewUrl ?? '',
      thumbnailUrl: widget.track.thumbnailUrl,
      youtubeVideoId: youtubeVideoId, // Guardar el video ID de YouTube
      startTime: _startTime.value > 0 ? _startTime.value : null,
      duration: finalDuration, // Asegurar máximo 30 segundos
      isCurrentlyPlaying: false,
      createdAt: DateTime.now(),
    );

    debugPrint('✅ [MUSIC_SELECTION] Música seleccionada:');
    debugPrint('   - Track: ${storyMusic.trackName}');
    debugPrint('   - Artista: ${storyMusic.artistName}');
    debugPrint('   - Preview URL: ${storyMusic.previewUrl}');
    debugPrint('   - YouTube Video ID: ${storyMusic.youtubeVideoId ?? "N/A"}');
    debugPrint('   - Inicio: ${storyMusic.startTime ?? 0}s');
    debugPrint('   - Duración: ${storyMusic.duration}s');

    // Llamar al callback si existe (esto guarda la selección)
    widget.onMusicSelected?.call(storyMusic);
    
    // Retornar el resultado y cerrar la pantalla después de un breve delay
    // para que el usuario vea la confirmación visual
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        Get.back(result: storyMusic);
      }
    });
    
    // NO detener la reproducción - dejar que siga sonando
    // NO cerrar las pantallas inmediatamente - dejar que el usuario escuche
    
    debugPrint('🎵 [MUSIC_SELECTION] Música seleccionada y reproduciéndose. El usuario puede cerrar cuando quiera.');
  }

  String _formatTime(double seconds) {
    final mins = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Verificar si es YouTube (solo si la preview URL contiene youtube)
    final bool isYouTube = widget.track.previewUrl != null && 
                           (widget.track.previewUrl!.contains('youtube.com') || 
                            widget.track.previewUrl!.contains('youtu.be'));
    final hasPreview = widget.track.previewUrl != null && 
                       widget.track.previewUrl!.isNotEmpty &&
                       !widget.track.previewUrl!.contains('youtube.com') &&
                       !widget.track.previewUrl!.contains('youtu.be');
    final canPlay = hasPreview || isYouTube; // Puede reproducir si tiene preview o es YouTube

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Música'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          // Información de la canción
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: widget.track.thumbnailUrl != null
                      ? CachedNetworkImage(
                          imageUrl: widget.track.thumbnailUrl!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: const Icon(Icons.music_note, size: 50),
                          ),
                        )
                      : Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.music_note, size: 50),
                        ),
                ),
                const SizedBox(width: 16),
                // Información
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.track.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.track.artist,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.track.album.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.track.album,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Indicador de reproducción (banner superior)
          Obx(() {
            if (_isPlaying.value && !_isLoading.value) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  border: Border(
                    bottom: BorderSide(color: Colors.green.withOpacity(0.3), width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.graphic_eq, color: Colors.green[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '🔊 Reproduciendo...',
                      style: TextStyle(
                        color: Colors.green[900],
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Controles de preview - Estilo Instagram
          Expanded(
            child: Obx(() {
              if (_isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              bool isYouTube = widget.track.previewUrl?.contains('youtube.com') == true || 
                               widget.track.previewUrl?.contains('youtu.be') == true;

              // Si es YouTube, mostrar controles aunque no tenga preview
              if (isYouTube) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Mensaje informativo
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Canción de YouTube',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Esta canción se agregará a tu historia. Puedes seleccionar el segmento que deseas usar.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Controles de selección de segmento
                      Obx(() => Column(
                        children: [
                          // Información del segmento seleccionado
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        Text('Inicio', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                        Text(
                                          _formatTime(_startTime.value),
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    Container(width: 1, height: 40, color: Colors.grey[300]),
                                    Column(
                                      children: [
                                        Text('Duración', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                        Text(
                                          _formatTime(_selectedDuration.value),
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          // Selector de inicio
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Seleccionar inicio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  Obx(() => Text(
                                    _formatTime(_startTime.value),
                                    style: TextStyle(fontSize: 14, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600),
                                  )),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Obx(() => Slider(
                                value: _startTime.value.clamp(0.0, (_duration.value - _selectedDuration.value).clamp(0.0, _duration.value)),
                                min: 0.0,
                                max: (_duration.value - _selectedDuration.value).clamp(0.0, _duration.value),
                                onChanged: (_duration.value - _selectedDuration.value) > 0 ? (value) {
                                  _onStartTimeChanged(value);
                                } : null,
                              )),
                            ],
                          ),
                          const SizedBox(height: 30),
                          // Selector de duración
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Duración del clip', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  Obx(() => Text(
                                    '${_formatTime(_selectedDuration.value)} / 30s',
                                    style: TextStyle(fontSize: 14, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600),
                                  )),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Obx(() => Slider(
                                value: _selectedDuration.value.clamp(5.0, 30.0),
                                min: 5.0,
                                max: (_duration.value - _startTime.value).clamp(5.0, 30.0),
                                onChanged: (value) {
                                  _selectedDuration.value = value;
                                  final maxStart = (_duration.value - value).clamp(0.0, _duration.value);
                                  if (_startTime.value > maxStart) {
                                    _startTime.value = maxStart;
                                  }
                                },
                              )),
                            ],
                          ),
                        ],
                      )),
                    ],
                  ),
                );
              }
              
              // Si no tiene preview y no es YouTube, mostrar controles de selección igualmente
              if (!hasPreview && !isYouTube) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Mensaje informativo
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange[700], size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Preview no disponible',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[900],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Esta canción no tiene preview, pero puedes seleccionar el segmento de 30 segundos que deseas usar.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      // Barra de progreso visual (sin reproducción)
                      Obx(() => Column(
                        children: [
                          Container(
                            height: 60,
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            child: Stack(
                              children: [
                                // Barra de fondo (toda la canción)
                                Positioned.fill(
                                  child: Container(
                                    height: 4,
                                    margin: const EdgeInsets.symmetric(vertical: 28),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                // Segmento seleccionado (resaltado)
                                if (_duration.value > 0)
                                  Positioned(
                                    left: ((_startTime.value / _duration.value) * (MediaQuery.of(context).size.width - 80)).clamp(0.0, double.infinity),
                                    width: ((_selectedDuration.value / _duration.value) * (MediaQuery.of(context).size.width - 80)).clamp(0.0, double.infinity),
                                    top: 28,
                                    child: Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Tiempos
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatTime(_startTime.value)),
                                Text(_formatTime(_duration.value)),
                              ],
                            ),
                          ),
                        ],
                      )),
                      
                      const SizedBox(height: 30),
                      
                      // Información del segmento seleccionado
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text('Inicio', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                Obx(() => Text(
                                  _formatTime(_startTime.value),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                )),
                              ],
                            ),
                            Container(width: 1, height: 40, color: Colors.grey[300]),
                            Column(
                              children: [
                                Text('Duración', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                Obx(() => Text(
                                  _formatTime(_selectedDuration.value),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                )),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Selector de inicio
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Seleccionar inicio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Obx(() => Text(
                                _formatTime(_startTime.value),
                                style: TextStyle(fontSize: 14, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600),
                              )),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Obx(() => Slider(
                            value: _startTime.value.clamp(0.0, (_duration.value - _selectedDuration.value).clamp(0.0, _duration.value)),
                            min: 0.0,
                            max: (_duration.value - _selectedDuration.value).clamp(0.0, _duration.value),
                            onChanged: (_duration.value - _selectedDuration.value) > 0 ? (value) {
                              _onStartTimeChanged(value);
                            } : null,
                          )),
                        ],
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Selector de duración
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Duración del clip (máx. 30s)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Obx(() => Text(
                                '${_formatTime(_selectedDuration.value)} / 30s',
                                style: TextStyle(fontSize: 14, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600),
                              )),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Obx(() => Slider(
                            value: _selectedDuration.value.clamp(5.0, 30.0),
                            min: 5.0,
                            max: (_duration.value - _startTime.value).clamp(5.0, 30.0),
                            onChanged: (value) {
                              _selectedDuration.value = value;
                              final maxStart = (_duration.value - value).clamp(0.0, _duration.value);
                              if (_startTime.value > maxStart) {
                                _startTime.value = maxStart;
                              }
                            },
                          )),
                        ],
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Barra de progreso principal (estilo Instagram)
                    Obx(() => Column(
                      children: [
                        // Indicador visual del segmento seleccionado
                        Container(
                          height: 60,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          child: Stack(
                            children: [
                              // Barra de fondo (toda la canción)
                              Positioned.fill(
                                child: Container(
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(vertical: 28),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              // Segmento seleccionado (resaltado)
                              if (_duration.value > 0)
                                Positioned(
                                  left: ((_startTime.value / _duration.value) * (MediaQuery.of(context).size.width - 80)).clamp(0.0, double.infinity),
                                  width: ((_selectedDuration.value / _duration.value) * (MediaQuery.of(context).size.width - 80)).clamp(0.0, double.infinity),
                                  top: 28,
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              // Indicador de posición actual
                              if (_duration.value > 0)
                                Positioned(
                                  left: ((_currentPosition.value / _duration.value) * (MediaQuery.of(context).size.width - 80)).clamp(0.0, MediaQuery.of(context).size.width - 80),
                                  top: 0,
                                  child: Container(
                                    width: 4,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: _isPlaying.value ? Theme.of(context).primaryColor : Colors.grey[600],
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        // Tiempos
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatTime(_currentPosition.value),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              _formatTime(_duration.value),
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                          ],
                        ),
                        
                        // Información del segmento seleccionado
                        Container(
                          margin: const EdgeInsets.only(top: 15),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text('Inicio', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                  Text(
                                    _formatTime(_startTime.value),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Container(width: 1, height: 30, color: Colors.grey[300]),
                              Column(
                                children: [
                                  Text('Duración', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                  Text(
                                    _formatTime(_selectedDuration.value),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    )),

                    const SizedBox(height: 30),

                    // Botón play/pause grande (centrado) con indicador de estado
                    Obx(() => Column(
                      children: [
                        // Botón de play/pause
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: _isPlaying.value ? [
                              BoxShadow(
                                color: Theme.of(context).primaryColor.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ] : null,
                          ),
                          child: IconButton(
                            iconSize: 80,
                            icon: Icon(
                              _isPlaying.value ? Icons.pause_circle_filled : Icons.play_circle_filled,
                              color: _isPlaying.value 
                                  ? Colors.green[700] 
                                  : Theme.of(context).primaryColor,
                            ),
                            onPressed: _playPause,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Indicador de estado
                        Text(
                          _isPlaying.value ? '🔊 Reproduciendo' : '⏸ Pausado',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _isPlaying.value 
                                ? Colors.green[700] 
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    )),

                    const SizedBox(height: 40),

                    // Selector de inicio (deslizable)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Seleccionar inicio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Obx(() => Text(
                              _formatTime(_startTime.value),
                              style: TextStyle(fontSize: 14, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600),
                            )),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Obx(() {
                          final maxStart = (_duration.value - _selectedDuration.value).clamp(0.0, _duration.value);
                          return Slider(
                            value: _startTime.value.clamp(0.0, maxStart),
                            min: 0.0,
                            max: maxStart > 0 ? maxStart : 0.0,
                            onChanged: maxStart > 0 ? (value) {
                              _onStartTimeChanged(value);
                            } : null,
                          );
                        }),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Selector de duración
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Duración del clip', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Obx(() => Text(
                              '${_formatTime(_selectedDuration.value)} / 30s',
                              style: TextStyle(fontSize: 14, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600),
                            )),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Obx(() => Slider(
                          value: _selectedDuration.value.clamp(5.0, 30.0),
                          min: 5.0,
                          max: (_duration.value - _startTime.value).clamp(5.0, 30.0),
                          onChanged: (value) {
                            _selectedDuration.value = value;
                            final maxStart = (_duration.value - value).clamp(0.0, _duration.value);
                            if (_startTime.value > maxStart) {
                              _startTime.value = maxStart;
                            }
                          },
                        )),
                      ],
                    ),

                    if (isYouTube) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Para YouTube, selecciona el segmento que deseas usar. El video completo estará disponible en tu historia.',
                                style: TextStyle(fontSize: 12, color: Colors.orange[900]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ),

          // Botón de seleccionar
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await _selectMusic();
                  // _selectMusic ya maneja el cierre de la pantalla con Get.back(result: ...)
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Usar esta música',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

