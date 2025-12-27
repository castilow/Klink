import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:audio_session/audio_session.dart';
import 'package:chat_messenger/api/music_api.dart';
import 'package:chat_messenger/models/story/submodels/story_music.dart';
// import 'package:youtube_explode_dart/youtube_explode_dart.dart'; // Temporalmente deshabilitado

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
  final ap.AudioPlayer _fallbackPlayer = ap.AudioPlayer();
  bool _usingFallback = false;
  final RxBool _isPlaying = false.obs;
  final RxBool _isLoading = false.obs;
  final RxDouble _currentPosition = 0.0.obs;
  final RxDouble _duration = 0.0.obs;
  final RxDouble _startTime = 0.0.obs;
  final RxDouble _selectedDuration = 30.0.obs; // Máximo 30 segundos
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _fallbackPositionSubscription;
  StreamSubscription<Duration>? _fallbackDurationSubscription;
  StreamSubscription<ap.PlayerState>? _fallbackStateSubscription;
  bool _hasAutoPlayed = false;
  
  // Controladores para inputs de tiempo exacto
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final FocusNode _startTimeFocus = FocusNode();
  final FocusNode _durationFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    
    // Inicializar controladores
    _startTimeController.text = _formatTime(_startTime.value);
    _durationController.text = _formatTime(_selectedDuration.value);
    
    // Actualizar controladores cuando cambien los valores
    ever(_startTime, (_) => _updateControllers());
    ever(_selectedDuration, (_) => _updateControllers());
  }

  Future<void> _initializePlayer() async {
    try {
      debugPrint('🎵 [MUSIC_SELECTION] Inicializando player para: ${widget.track.name}');
      debugPrint('🎵 [MUSIC_SELECTION] Preview URL: ${widget.track.previewUrl ?? "null"}');
      debugPrint('🎵 [MUSIC_SELECTION] Track ID: ${widget.track.id}');
      
      _isLoading.value = true;
      
      // Solo usar Audius (música completa)
      if (widget.track.previewUrl != null && widget.track.previewUrl!.isNotEmpty) {
        String audioUrl = widget.track.previewUrl!;
        
        // Configurar volumen y modo de audio antes de cargar
        await _audioPlayer.setVolume(1.0);
        await _audioPlayer.setSpeed(1.0);
        
        // Verificar que la URL sea válida
        try {
          final uri = Uri.parse(audioUrl);
          if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
            throw Exception('URL inválida: $audioUrl');
          }
          debugPrint('✅ [MUSIC_SELECTION] URL válida de Audius: ${uri.scheme}://${uri.host}');
        } catch (e) {
          debugPrint('❌ [MUSIC_SELECTION] URL inválida: $e');
          _isLoading.value = false;
          return;
        }
        
        try {
          debugPrint('📥 [MUSIC_SELECTION] Configurando audio source desde Audius: $audioUrl');
          await _audioPlayer.setUrl(audioUrl);
          debugPrint('✅ [MUSIC_SELECTION] Audio de Audius cargado exitosamente');
          
          // Esperar un momento y luego reproducir automáticamente
          await Future.delayed(const Duration(milliseconds: 500));
          try {
            await _audioPlayer.seek(Duration.zero);
            await Future.delayed(const Duration(milliseconds: 200));
            await _audioPlayer.play();
            _isPlaying.value = true;
            _hasAutoPlayed = true;
            _currentPosition.value = 0.0;
            debugPrint('✅ [MUSIC_SELECTION] Música completa de Audius iniciada automáticamente');
          } catch (e) {
            debugPrint('⚠️ [MUSIC_SELECTION] Error al iniciar automáticamente: $e');
          }
        } catch (e) {
          debugPrint('❌ [MUSIC_SELECTION] Error cargando audio de Audius: $e');
          _isLoading.value = false;
          
          // Mostrar error después del build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Get.snackbar(
                'Error',
                'No se pudo cargar la música: $e',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 3),
              );
            }
          });
          return;
        }
      } else {
        // Si no hay URL de Audius, mostrar mensaje
        debugPrint('⚠️ [MUSIC_SELECTION] No hay URL de música disponible');
        
        // Establecer duración por defecto
        _duration.value = widget.track.duration != null 
            ? (widget.track.duration! / 1000.0) 
            : 180.0;
        _isLoading.value = false;
        
        // Mostrar mensaje al usuario
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Get.snackbar(
                'Sin música',
                'No hay música disponible para esta canción. Puedes seleccionar el segmento que deseas usar.',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 3),
              );
            }
          });
        }
        return;
      }

      // Listeners moved to _setupJustAudioListeners to avoid duplication



      // Intentar obtener duración inmediatamente
      try {
        final duration = await _audioPlayer.duration;
        if (duration != null) {
          _duration.value = duration.inSeconds.toDouble();
          if (_duration.value < 30.0) {
            _selectedDuration.value = _duration.value.clamp(5.0, 30.0);
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
    if (_hasAutoPlayed || _isPlaying.value || !mounted || _usingFallback) {
      if (_hasAutoPlayed) {
        debugPrint('⏭️ [MUSIC_SELECTION] Autoplay ya ejecutado, saltando...');
      }
      if (_usingFallback) {
        debugPrint('⏭️ [MUSIC_SELECTION] Usando fallback, autoplay ya manejado...');
      }
      return;
    }
    
    try {
      final state = _audioPlayer.playerState;
      debugPrint('🎵 [MUSIC_SELECTION] Iniciando auto-play. Estado: ${state.processingState}, playing: ${state.playing}');
      
      // Intentar reproducir independientemente del estado
      // Solo esperar si está en loading o buffering
      if (state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering) {
        debugPrint('⏳ [MUSIC_SELECTION] Player cargando, esperando...');
        await Future.delayed(const Duration(milliseconds: 500));
        if (!_hasAutoPlayed && !_isPlaying.value && mounted && !_usingFallback) {
            await _startAutoPlay();
          }
        return;
      }
      
      // Para cualquier otro estado (ready, idle, etc.), intentar reproducir
      debugPrint('🔄 [MUSIC_SELECTION] Intentando reproducir...');
      try {
        await _audioPlayer.setVolume(1.0);
          await _audioPlayer.seek(Duration.zero);
        await Future.delayed(const Duration(milliseconds: 200));
          await _audioPlayer.play();
          _isPlaying.value = true;
          _hasAutoPlayed = true;
        _currentPosition.value = 0.0;
        debugPrint('✅ [MUSIC_SELECTION] Reproducción automática iniciada');
        } catch (e2) {
          debugPrint('❌ [MUSIC_SELECTION] Error forzando reproducción: $e2');
        // Si just_audio falla después de varios intentos, cambiar a audioplayers
        if (!_usingFallback) {
          debugPrint('🔄 [MUSIC_SELECTION] just_audio falló, intentando cambiar a audioplayers...');
          // Esto se manejará en el método de carga
        }
          // Reintentar después de un delay
          Future.delayed(const Duration(milliseconds: 500), () async {
          if (!_hasAutoPlayed && !_isPlaying.value && mounted && !_usingFallback) {
              await _startAutoPlay();
            }
          });
      }
    } catch (e) {
      debugPrint('❌ [MUSIC_SELECTION] Error en auto-play: $e');
      // Reintentar una vez más después de un delay
      Future.delayed(const Duration(milliseconds: 1000), () async {
        if (!_hasAutoPlayed && !_isPlaying.value && mounted && !_usingFallback) {
          try {
            await _audioPlayer.setVolume(1.0);
            await _audioPlayer.seek(Duration.zero);
            await Future.delayed(const Duration(milliseconds: 200));
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
    if (_hasAutoPlayed || _isPlaying.value || attempt >= 5 || _usingFallback) {
      if (attempt >= 5) {
        debugPrint('⚠️ [MUSIC_SELECTION] Máximo de intentos alcanzado para auto-play');
      }
      if (_usingFallback) {
        debugPrint('⏭️ [MUSIC_SELECTION] Usando fallback, autoplay ya manejado...');
      }
      return;
    }
    
    if (attempt > 0) {
      await Future.delayed(Duration(milliseconds: 300 + (attempt * 300)));
    }
    
    if (!mounted || _hasAutoPlayed || _isPlaying.value || _usingFallback) {
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
    // Temporalmente deshabilitado - YouTube no está disponible
    debugPrint('⚠️ [MUSIC_SELECTION] Soporte de YouTube temporalmente deshabilitado');
    _isLoading.value = false;
    _duration.value = widget.track.duration != null 
        ? (widget.track.duration! / 1000.0) 
        : 180.0;
    // Código de YouTube comentado - no disponible
    /*
      yt = YoutubeExplode();
      
      // Obtener información del video
      final video = await yt!.videos.get(videoId);
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
      
      // Configurar el player antes de cargar el audio
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setSpeed(1.0);
      
      // Intentar cargar el audio usando AudioSource.uri() para mejor compatibilidad
      bool loaded = false;
      AudioSource? audioSource;
      
      try {
        // Usar setAudioSource primero ya que es más compatible en iOS
        final audioUrl = audioStream.url.toString();
        debugPrint('📥 [MUSIC_SELECTION] Cargando audio con setAudioSource: ${audioUrl.substring(0, 100)}...');
        audioSource = AudioSource.uri(Uri.parse(audioUrl));
        await _audioPlayer.setAudioSource(audioSource);
        debugPrint('✅ [MUSIC_SELECTION] Audio de YouTube cargado exitosamente con setAudioSource');
        
        // Esperar un momento para que el player procese el audio source
        await Future.delayed(const Duration(milliseconds: 500));
        
        // En iOS, el player necesita que se llame play() para iniciar la carga
        // Intentar reproducir inmediatamente para forzar la carga
        try {
          debugPrint('▶️ [MUSIC_SELECTION] Forzando inicio de carga con play()...');
          await _audioPlayer.play();
          await Future.delayed(const Duration(milliseconds: 1000));
          final checkState = _audioPlayer.playerState;
          debugPrint('🎵 [MUSIC_SELECTION] Estado después de play(): ${checkState.processingState}, playing: ${checkState.playing}');
          
          if (checkState.playing) {
            debugPrint('✅ [MUSIC_SELECTION] Audio iniciado correctamente');
          } else if (checkState.processingState == ProcessingState.loading || 
                     checkState.processingState == ProcessingState.buffering) {
            debugPrint('⏳ [MUSIC_SELECTION] Audio cargando, continuando...');
          } else {
            // Si aún está en idle, pausar y reintentar
            await _audioPlayer.pause();
            await Future.delayed(const Duration(milliseconds: 500));
            await _audioPlayer.play();
            debugPrint('🔄 [MUSIC_SELECTION] Reintentando play()...');
          }
        } catch (e) {
          debugPrint('⚠️ [MUSIC_SELECTION] Error al forzar carga inicial: $e (continuando...)');
        }
        
        loaded = true;
      } catch (e) {
        debugPrint('⚠️ [MUSIC_SELECTION] Error con setAudioSource: $e, intentando con setUrl...');
        try {
          // Fallback a setUrl()
          final audioUrl = audioStream.url.toString();
          await _audioPlayer.setUrl(audioUrl);
          debugPrint('✅ [MUSIC_SELECTION] Audio de YouTube cargado exitosamente con setUrl');
          
          // Intentar reproducir para forzar la carga
          try {
            await _audioPlayer.play();
            await Future.delayed(const Duration(milliseconds: 1000));
            await _audioPlayer.pause();
          } catch (e2) {
            debugPrint('⚠️ [MUSIC_SELECTION] Error al forzar carga con setUrl: $e2');
          }
          
          loaded = true;
        } catch (e2) {
          debugPrint('⚠️ [MUSIC_SELECTION] Error con setAudioSource: $e2, intentando con streams alternativos...');
        
        // Intentar con otros streams de audio si está disponible
        final allAudioStreams = manifest.audioOnly.toList();
        if (allAudioStreams.length > 1) {
          // Ordenar por bitrate y probar desde el más bajo (más compatible)
          allAudioStreams.sort((a, b) => a.bitrate.compareTo(b.bitrate));
          
          for (var stream in allAudioStreams) {
            if (stream == audioStream) continue; // Ya probamos este
            try {
              debugPrint('🔄 [MUSIC_SELECTION] Intentando con stream alternativo (bitrate: ${stream.bitrate})...');
                final altUrl = stream.url.toString();
                await _audioPlayer.setUrl(altUrl);
              debugPrint('✅ [MUSIC_SELECTION] Audio de YouTube cargado con stream alternativo');
              loaded = true;
              break;
              } catch (e3) {
                debugPrint('❌ [MUSIC_SELECTION] Error con stream alternativo: $e3');
              continue;
            }
          }
        }
        
        if (!loaded) {
            // Si just_audio falla completamente, intentar con audioplayers
            debugPrint('🔄 [MUSIC_SELECTION] just_audio falló, intentando con audioplayers...');
            try {
              final audioUrl = audioStream.url.toString();
              await _fallbackPlayer.setSource(ap.UrlSource(audioUrl));
              _usingFallback = true;
              loaded = true;
              debugPrint('✅ [MUSIC_SELECTION] Audio cargado con audioplayers (fallback)');
            } catch (e4) {
              debugPrint('❌ [MUSIC_SELECTION] Error con audioplayers también: $e4');
              throw Exception('No se pudo cargar ningún stream de audio: $e, $e2, $e4');
            }
          }
        }
      }

      // Si just_audio no está funcionando (se queda en idle), usar audioplayers
      if (loaded && !_usingFallback) {
        // Esperar un momento y verificar si just_audio está funcionando
        await Future.delayed(const Duration(milliseconds: 2000));
        final checkState = _audioPlayer.playerState;
        if (checkState.processingState == ProcessingState.idle && !checkState.playing) {
          debugPrint('⚠️ [MUSIC_SELECTION] just_audio se quedó en idle, cambiando a audioplayers...');
          try {
            final audioUrl = audioStream.url.toString();
            await _fallbackPlayer.setSource(ap.UrlSource(audioUrl));
            _usingFallback = true;
            debugPrint('✅ [MUSIC_SELECTION] Cambiado a audioplayers exitosamente');
          } catch (e) {
            debugPrint('❌ [MUSIC_SELECTION] Error cambiando a audioplayers: $e');
          }
        }
      }

      // Configurar listeners según el player que estemos usando
      if (_usingFallback) {
        _setupFallbackListeners();
      } else {
        _setupJustAudioListeners();
      }

      _isLoading.value = false;
      debugPrint('✅ [MUSIC_SELECTION] Audio de YouTube cargado');
      
      // Si estamos usando el fallback, no hacer nada más (ya se reproduce automáticamente)
      if (_usingFallback) {
        return;
      }
      
      // Esperar un momento adicional para que el player procese completamente
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Verificar el estado inicial
      final initialState = _audioPlayer.playerState;
      debugPrint('🎵 [MUSIC_SELECTION] Estado inicial después de cargar: ${initialState.processingState}, playing: ${initialState.playing}');
      
      // Si ya está reproduciéndose, no hacer nada más
      if (initialState.playing) {
        _isPlaying.value = true;
        _hasAutoPlayed = true;
        _currentPosition.value = 0.0;
        debugPrint('✅ [MUSIC_SELECTION] Audio ya está reproduciéndose');
        return;
      }
      
      // En iOS, el player puede quedarse en idle hasta que se llama play()
      // Intentar reproducir inmediatamente múltiples veces para forzar la carga
      for (int attempt = 0; attempt < 10; attempt++) {
        try {
          debugPrint('▶️ [MUSIC_SELECTION] Intento ${attempt + 1}/10: Intentando reproducir...');
          
          // Asegurar que el volumen esté al máximo
          await _audioPlayer.setVolume(1.0);
          await _audioPlayer.setSpeed(1.0);
          
          // Intentar reproducir
          await _audioPlayer.play();
          
          // Esperar más tiempo para que el player inicie (especialmente en iOS)
          await Future.delayed(const Duration(milliseconds: 1200));
          
          final verifyState = _audioPlayer.playerState;
          debugPrint('🎵 [MUSIC_SELECTION] Estado después de intento ${attempt + 1}: ${verifyState.processingState}, playing: ${verifyState.playing}');
          
          // Si está reproduciéndose, éxito!
          if (verifyState.playing) {
            _isPlaying.value = true;
            _hasAutoPlayed = true;
            _currentPosition.value = 0.0;
            debugPrint('✅ [MUSIC_SELECTION] Audio de YouTube iniciado automáticamente y reproduciéndose');
            break;
          }
          
          // Si está en loading, buffering o ready, esperar más tiempo
          if (verifyState.processingState == ProcessingState.loading ||
              verifyState.processingState == ProcessingState.buffering ||
              verifyState.processingState == ProcessingState.ready) {
            // Esperar más tiempo antes del siguiente intento
            await Future.delayed(const Duration(milliseconds: 800));
            continue;
          }
          
          // Si sigue en idle, esperar un poco más antes del siguiente intento
          if (verifyState.processingState == ProcessingState.idle) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        } catch (e) {
          debugPrint('❌ [MUSIC_SELECTION] Error en intento ${attempt + 1}: $e');
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      // Cerrar YoutubeExplode
      // yt?.close();
    */
    // El código de YouTube está comentado, pero mantenemos el catch por si acaso
    try {
      // No hacer nada - YouTube no está disponible
    } catch (e) {
      debugPrint('❌ [MUSIC_SELECTION] Error cargando audio: $e');
      _isLoading.value = false;
      
      // Cerrar YoutubeExplode si está abierto
      // yt?.close();
      
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

  void _setupJustAudioListeners() {
    // Cancelar listeners anteriores
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();

    // Configurar listeners para just_audio
      _positionSubscription = _audioPlayer.positionStream.listen((position) {
        // Use milliseconds for smooth progress bar update
        _currentPosition.value = position.inMilliseconds.toDouble() / 1000.0;
        
        // Si llegamos al final del segmento seleccionado, pausar
        final segmentEnd = _startTime.value + _selectedDuration.value;
        // Check with small threshold to avoid rounding errors
        if (position.inMilliseconds >= (segmentEnd * 1000) && segmentEnd > 0) {
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
            _selectedDuration.value = _duration.value.clamp(5.0, 30.0);
          }
        }
      });

      _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
        debugPrint('🎵 [MUSIC_SELECTION] Estado del player: ${state.processingState}, playing: ${state.playing}');
        
        // Actualizar el estado de reproducción basado en el estado real del player
        if (state.playing != _isPlaying.value) {
          _isPlaying.value = state.playing;
          debugPrint('🔄 [MUSIC_SELECTION] Estado de reproducción actualizado: ${state.playing}');
        }
        
        // Reproducir automáticamente cuando esté listo (solo una vez)
        if ((state.processingState == ProcessingState.ready || 
             state.processingState == ProcessingState.buffering ||
             state.processingState == ProcessingState.loading) && 
            !_isPlaying.value && 
            !_hasAutoPlayed) {
          _hasAutoPlayed = true;
          debugPrint('▶️ [MUSIC_SELECTION] Player listo/cargando, iniciando reproducción automática...');
          Future.delayed(const Duration(milliseconds: 200), () async {
            if (!mounted) return;
            try {
              // Ir al inicio antes de reproducir
              await _audioPlayer.seek(Duration.zero);
              await Future.delayed(const Duration(milliseconds: 200));
              
              await _audioPlayer.play();
              _isPlaying.value = true;
               _currentPosition.value = 0.0;
            } catch (e) {
              debugPrint('❌ [MUSIC_SELECTION] Error al reproducir automáticamente: $e');
              _hasAutoPlayed = false;
            }
          });
        }
        
        // Si está en idle después de un tiempo, intentar forzar reproducción
        if (state.processingState == ProcessingState.idle && 
            !_isPlaying.value && 
            !_hasAutoPlayed &&
            _isLoading.value == false) {
          // Esperar un poco y luego intentar reproducir
          Future.delayed(const Duration(milliseconds: 1500), () async {
            if (!mounted || _hasAutoPlayed || _isPlaying.value) return;
            final currentState = _audioPlayer.playerState;
            if (currentState.processingState == ProcessingState.idle && !currentState.playing) {
              try {
                await _audioPlayer.setVolume(1.0);
                await _audioPlayer.play();
                _isPlaying.value = true;
                _hasAutoPlayed = true;
              } catch (e) {
                 // ignore
              }
            }
          });
        }
        
        if (state.processingState == ProcessingState.completed) {
          _isPlaying.value = false;
          debugPrint('⏹️ [MUSIC_SELECTION] Canción terminada');
        }
      });
  }

  void _setupFallbackListeners() {
    // Configurar listeners para audioplayers
    _fallbackPositionSubscription?.cancel();
    _fallbackDurationSubscription?.cancel();
    _fallbackStateSubscription?.cancel();

    _fallbackPositionSubscription = _fallbackPlayer.onPositionChanged.listen((position) {
      // Use milliseconds for smooth progress bar update
      _currentPosition.value = position.inMilliseconds.toDouble() / 1000.0;
      
      // Si llegamos al final del segmento seleccionado, pausar
      final segmentEnd = _startTime.value + _selectedDuration.value;
      if (position.inMilliseconds >= (segmentEnd * 1000) && segmentEnd > 0) {
        _fallbackPlayer.pause();
        _isPlaying.value = false;
        debugPrint('⏸️ [MUSIC_SELECTION] Llegó al final del segmento seleccionado (${segmentEnd}s)');
      }
      // Si llegamos al final de la canción completa, también pausar
      else if (position.inSeconds >= _duration.value && _duration.value > 0) {
        _isPlaying.value = false;
      }
    });

    _fallbackDurationSubscription = _fallbackPlayer.onDurationChanged.listen((duration) {
      _duration.value = duration.inSeconds.toDouble();
      if (_duration.value < 30.0) {
        _selectedDuration.value = _duration.value;
      }
    });

    _fallbackStateSubscription = _fallbackPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying.value = state == ap.PlayerState.playing;
      
      if (state == ap.PlayerState.completed) {
        _isPlaying.value = false;
        debugPrint('⏹️ [MUSIC_SELECTION] Canción terminada (fallback)');
      }
    });

    // Reproducir automáticamente con audioplayers
    if (!_hasAutoPlayed) {
      _hasAutoPlayed = true;
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (!mounted) return;
        try {
          await _fallbackPlayer.resume();
          _isPlaying.value = true;
          _currentPosition.value = 0.0;
          debugPrint('✅ [MUSIC_SELECTION] Audio iniciado con audioplayers (fallback)');
        } catch (e) {
          debugPrint('❌ [MUSIC_SELECTION] Error iniciando con audioplayers: $e');
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
        if (_usingFallback) {
          await _fallbackPlayer.pause();
        } else {
        await _audioPlayer.pause();
        }
        _isPlaying.value = false;
      } else {
        debugPrint('▶️ [MUSIC_SELECTION] Reproduciendo...');
        
        if (_usingFallback) {
          // Usar audioplayers
          // Si estamos al final de la canción, volver al inicio
          if (_currentPosition.value >= _duration.value && _duration.value > 0) {
            debugPrint('🔄 [MUSIC_SELECTION] Volviendo al inicio de la canción (fallback)');
            await _fallbackPlayer.seek(Duration.zero);
            _currentPosition.value = 0.0;
          }
          await _fallbackPlayer.resume();
          _isPlaying.value = true;
        } else {
          // Usar just_audio
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
      if (_usingFallback) {
        await _fallbackPlayer.seek(seekPosition);
      } else {
      await _audioPlayer.seek(seekPosition);
      }
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
    // Código comentado - YouTube no disponible
    /*
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
    */
    
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

  // Parsear tiempo desde formato MM:SS o SS
  double _parseTime(String timeStr) {
    try {
      if (timeStr.isEmpty) return 0.0;
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        final mins = int.tryParse(parts[0]) ?? 0;
        final secs = int.tryParse(parts[1]) ?? 0;
        return (mins * 60 + secs).toDouble();
      } else {
        return double.tryParse(timeStr) ?? 0.0;
      }
    } catch (e) {
      return 0.0;
    }
  }

  // Actualizar controladores cuando cambien los valores
  void _updateControllers() {
    if (!_startTimeFocus.hasFocus) {
      _startTimeController.text = _formatTime(_startTime.value);
    }
    if (!_durationFocus.hasFocus) {
      _durationController.text = _formatTime(_selectedDuration.value);
    }
  }

  // Widget helper para botones de ajuste fino
  Widget _buildAdjustButton(BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(15),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 20, color: Colors.white),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget helper para botones pequeños de ajuste
  Widget _buildSmallAdjustButton(BuildContext context, String label, VoidCallback onPressed) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _fallbackPositionSubscription?.cancel();
    _fallbackDurationSubscription?.cancel();
    _fallbackStateSubscription?.cancel();
    _audioPlayer.dispose();
    _fallbackPlayer.dispose();
    _startTimeController.dispose();
    _durationController.dispose();
    _startTimeFocus.dispose();
    _durationFocus.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    // Theme Constants
    const Color premiumBlack = Color(0xFF0F172A);
    const Color cyanColor = Color(0xFF00E5FF);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background - Thumbnail Blurred
          Positioned.fill(
            child: widget.track.thumbnailUrl != null
                ? CachedNetworkImage(
                    imageUrl: widget.track.thumbnailUrl!,
                    fit: BoxFit.cover,
                  )
                : Container(color: premiumBlack),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: premiumBlack.withOpacity(0.8),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Custom AppBar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                        onPressed: () => Get.back(),
                      ),
                      const Expanded(
                        child: Text(
                          'Seleccionar Música',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Balance for back button
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Cover Art
                        Hero(
                          tag: 'music_cover_${widget.track.id}',
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: widget.track.thumbnailUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: widget.track.thumbnailUrl!,
                                      width: 240,
                                      height: 240,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 240,
                                      height: 240,
                                      color: Colors.white.withOpacity(0.1),
                                      child: const Icon(Icons.music_note, color: Colors.white, size: 80),
                                    ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Track Info
                        Text(
                          widget.track.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.track.artist,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                        
                        const SizedBox(height: 50),
                        
                        // Trimmer & Controls
                        Obx(() {
                             final effectiveDuration = _duration.value > 0 ? _duration.value : 180.0;
                             
                             return Column(
                               children: [
                                 // Trimmer UI
                                 GestureDetector(
                                  onTapDown: (details) {
                                    if (effectiveDuration > 0) {
                                      final width = MediaQuery.of(context).size.width - 40;
                                      final dx = details.localPosition.dx.clamp(0.0, width);
                                      final newStartTime = (dx / width) * effectiveDuration;
                                      final maxStart = (effectiveDuration - _selectedDuration.value).clamp(0.0, effectiveDuration);
                                      _onStartTimeChanged(newStartTime.clamp(0.0, maxStart));
                                    }
                                  },
                                  child: Container(
                                    height: 60,
                                    margin: const EdgeInsets.symmetric(vertical: 10),
                                    child: Stack(
                                      alignment: Alignment.centerLeft,
                                      children: [
                                        // Background Track
                                        Container(
                                          height: 6,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                        ),
                                        
                                        // Selected Segment
                                        if (effectiveDuration > 0)
                                          Positioned(
                                            left: ((_startTime.value / effectiveDuration) * (MediaQuery.of(context).size.width - 40)).clamp(0.0, double.infinity),
                                            width: ((_selectedDuration.value / effectiveDuration) * (MediaQuery.of(context).size.width - 40)).clamp(0.0, double.infinity),
                                            child: Container(
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: cyanColor,
                                                borderRadius: BorderRadius.circular(3),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: cyanColor.withOpacity(0.6),
                                                    blurRadius: 10,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          
                                        // Progress Indicator
                                         if (effectiveDuration > 0)
                                          Positioned(
                                            left: ((_currentPosition.value / effectiveDuration) * (MediaQuery.of(context).size.width - 40)).clamp(0.0, MediaQuery.of(context).size.width - 40),
                                            child: Container(
                                              height: 30,
                                              width: 3,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(1.5),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.3),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                     ],
                                   ),
                                  ),
                                 ),
                                 
                                 // Time Labels
                                 Padding(
                                   padding: const EdgeInsets.symmetric(horizontal: 0),
                                   child: Row(
                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                     children: [
                                       Text(
                                         _formatTime(_currentPosition.value), 
                                         style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)
                                       ),
                                       Text(
                                         _formatTime(effectiveDuration), 
                                         style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)
                                       ),
                                     ],
                                   ),
                                 ),
                                 
                                 const SizedBox(height: 40),
                                 
                                 // Controls
                                 Row(
                                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                   children: [
                                      _buildAdjustButton(context, icon: Icons.replay_10, label: '-10s', onPressed: () {
                                         final newTime = (_startTime.value - 10.0).clamp(0.0, effectiveDuration);
                                         _onStartTimeChanged(newTime);
                                      }),
                                      
                                      GestureDetector(
                                        onTap: () {
                                          if (_isPlaying.value) {
                                            _audioPlayer.pause();
                                          } else {
                                            _audioPlayer.play();
                                          }
                                        },
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(100),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                            child: Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                                              ),
                                              child: Icon(
                                                _isPlaying.value ? Icons.pause : Icons.play_arrow,
                                                color: Colors.white,
                                                size: 40,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                                      _buildAdjustButton(context, icon: Icons.forward_10, label: '+10s', onPressed: () {
                                         final newTime = (_startTime.value + 10.0).clamp(0.0, effectiveDuration);
                                         _onStartTimeChanged(newTime);
                                      }),
                                   ],
                                 ),
                               ],
                             );
                        }),
                      ],
                    ),
                  ),
                ),
                
                // Footer
                 Padding(
                   padding: const EdgeInsets.all(20),
                   child: SizedBox(
                   width: double.infinity,
                   height: 56,
                   child: ElevatedButton(
                     onPressed: () => _selectMusic(),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.transparent,
                       shadowColor: Colors.transparent,
                       padding: EdgeInsets.zero,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                     ),
                     child: Ink(
                       decoration: BoxDecoration(
                         gradient: const LinearGradient(colors: [cyanColor, Color(0xFF2979FF)]),
                         borderRadius: BorderRadius.circular(16),
                         boxShadow: [
                            BoxShadow(color: cyanColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                         ],
                       ),
                       child: Container(
                         alignment: Alignment.center,
                         child: const Text(
                           'Usar esta música',
                           style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                         ),
                       ),
                     ),
                   ),
                 ),
                 ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _oldBuild(BuildContext context) {
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
              bool isYouTube = widget.track.previewUrl?.contains('youtube.com') == true || 
                               widget.track.previewUrl?.contains('youtu.be') == true;
              bool hasPreview = widget.track.previewUrl != null && 
                               widget.track.previewUrl!.isNotEmpty &&
                               !isYouTube;

              // Debug: verificar qué se está detectando
              debugPrint('🎵 [UI] hasPreview: $hasPreview, isYouTube: $isYouTube, isLoading: ${_isLoading.value}');
              debugPrint('🎵 [UI] previewUrl: ${widget.track.previewUrl}');
              debugPrint('🎵 [UI] duration: ${_duration.value}, startTime: ${_startTime.value}, selectedDuration: ${_selectedDuration.value}');

              // PRIORIDAD 1: Si tiene preview (Audius, SoundCloud, etc.), mostrar controles SIEMPRE
              // Esto incluye cuando está cargando para que el usuario vea la interfaz inmediatamente
              if (hasPreview) {
                // Mostrar controles mejorados con reproductor interactivo
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Indicador de carga sutil si está cargando
                      Obx(() => _isLoading.value
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Cargando música...',
                                  style: TextStyle(
                                    color: Colors.blue[900],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                      ),
                      // Barra de progreso principal (estilo Instagram) - INTERACTIVA
                      Obx(() {
                        // Usar duración por defecto si aún no está disponible
                        final effectiveDuration = _duration.value > 0 ? _duration.value : 180.0;
                        return Column(
                          children: [
                            // Indicador visual del segmento seleccionado - CLICKEABLE MEJORADO
                            GestureDetector(
                              onTapDown: (details) {
                                if (effectiveDuration > 0) {
                                  final RenderBox? box = context.findRenderObject() as RenderBox?;
                                  if (box != null) {
                                    final localPosition = box.globalToLocal(details.globalPosition);
                                    final width = MediaQuery.of(context).size.width - 80;
                                    final tapX = localPosition.dx.clamp(0.0, width);
                                    final newStartTime = (tapX / width) * effectiveDuration;
                                    final maxStart = (effectiveDuration - _selectedDuration.value).clamp(0.0, effectiveDuration);
                                    final double clampedStart = newStartTime.clamp(0.0, maxStart).toDouble();
                                    _onStartTimeChanged(clampedStart);
                                  }
                                }
                              },
                              child: Container(
                                height: 80,
                                margin: const EdgeInsets.symmetric(vertical: 10),
                                child: Stack(
                                  children: [
                                    // Barra de fondo (toda la canción) - MÁS GRUESA
                                    Positioned.fill(
                                      child: Container(
                                        height: 6,
                                        margin: const EdgeInsets.symmetric(vertical: 37),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                    // Segmento seleccionado (resaltado) - MÁS VISIBLE
                                    if (effectiveDuration > 0)
                                      Positioned(
                                        left: ((_startTime.value / effectiveDuration) * (MediaQuery.of(context).size.width - 80)).clamp(0.0, double.infinity),
                                        width: ((_selectedDuration.value / effectiveDuration) * (MediaQuery.of(context).size.width - 80)).clamp(0.0, double.infinity),
                                        top: 37,
                                        child: Container(
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor,
                                            borderRadius: BorderRadius.circular(3),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Theme.of(context).primaryColor.withOpacity(0.3),
                                                blurRadius: 4,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    // Indicador de posición actual - MÁS VISIBLE
                                    if (effectiveDuration > 0)
                                      Positioned(
                                        left: ((_currentPosition.value / effectiveDuration) * (MediaQuery.of(context).size.width - 80)).clamp(0.0, MediaQuery.of(context).size.width - 80),
                                        top: 0,
                                        child: Container(
                                          width: 3,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            color: _isPlaying.value ? Colors.green[600] : Colors.grey[500],
                                            borderRadius: BorderRadius.circular(1.5),
                                            boxShadow: _isPlaying.value ? [
                                              BoxShadow(
                                                color: Colors.green.withOpacity(0.5),
                                                blurRadius: 4,
                                                spreadRadius: 1,
                                              ),
                                            ] : null,
                                          ),
                                        ),
                                      ),
                                    // Marcador de inicio del segmento - MÁS GRANDE Y VISIBLE
                                    if (effectiveDuration > 0)
                                      Positioned(
                                        left: ((_startTime.value / effectiveDuration) * (MediaQuery.of(context).size.width - 80)).clamp(0.0, MediaQuery.of(context).size.width - 80) - 8,
                                        top: 28,
                                        child: Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 3),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Theme.of(context).primaryColor.withOpacity(0.5),
                                                blurRadius: 6,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.arrow_back_ios,
                                            size: 8,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    // Marcador de fin del segmento - MÁS GRANDE Y VISIBLE
                                    if (effectiveDuration > 0)
                                      Positioned(
                                        left: (((_startTime.value + _selectedDuration.value) / effectiveDuration) * (MediaQuery.of(context).size.width - 80)).clamp(0.0, MediaQuery.of(context).size.width - 80) - 8,
                                        top: 28,
                                        child: Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 3),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Theme.of(context).primaryColor.withOpacity(0.5),
                                                blurRadius: 6,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.arrow_forward_ios,
                                            size: 8,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            // Tiempos y ayuda
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatTime(_currentPosition.value),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      _formatTime(effectiveDuration),
                                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '👆 Toca la barra para seleccionar el inicio',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                            // Información del segmento seleccionado - MEJORADA
                            Container(
                              margin: const EdgeInsets.only(top: 15),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).primaryColor.withOpacity(0.15),
                                    Theme.of(context).primaryColor.withOpacity(0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.play_arrow, size: 16, color: Theme.of(context).primaryColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Inicio',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Obx(() => Text(
                                          _formatTime(_startTime.value),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                        )),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.grey[300],
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.timer, size: 16, color: Theme.of(context).primaryColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Duración',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Obx(() => Text(
                                          _formatTime(_selectedDuration.value),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                        )),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.grey[300],
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.stop, size: 16, color: Theme.of(context).primaryColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Fin',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Obx(() => Text(
                                          _formatTime((_startTime.value + _selectedDuration.value).clamp(0.0, effectiveDuration)),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                        )),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),

                      const SizedBox(height: 30),

                      // Controles de reproducción mejorados con ajuste fino
                      Obx(() => Column(
                        children: [
                          // Botones de navegación rápida (1s, 5s, 10s) - Diseño compacto
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Retroceder 10s
                              _buildAdjustButton(
                                context,
                                icon: Icons.skip_previous,
                                label: '10s',
                                onPressed: () {
                                  final effectiveDuration = _duration.value > 0 ? _duration.value : 180.0;
                                  final newTime = (_startTime.value - 10.0).clamp(0.0, effectiveDuration);
                                  _onStartTimeChanged(newTime);
                                },
                              ),
                              const SizedBox(width: 4),
                              // Retroceder 5s
                              _buildAdjustButton(
                                context,
                                icon: Icons.replay_5,
                                label: '5s',
                                onPressed: () {
                                  final effectiveDuration = _duration.value > 0 ? _duration.value : 180.0;
                                  final newTime = (_startTime.value - 5.0).clamp(0.0, effectiveDuration);
                                  _onStartTimeChanged(newTime);
                                },
                              ),
                              const SizedBox(width: 4),
                              // Retroceder 1s
                              _buildAdjustButton(
                                context,
                                icon: Icons.replay,
                                label: '1s',
                                onPressed: () {
                                  final effectiveDuration = _duration.value > 0 ? _duration.value : 180.0;
                                  final newTime = (_startTime.value - 1.0).clamp(0.0, effectiveDuration);
                                  _onStartTimeChanged(newTime);
                                },
                              ),
                              const SizedBox(width: 12),
                              // Botón de play/pause grande
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
                                  iconSize: 70,
                                  icon: Icon(
                                    _isPlaying.value ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                    color: _isPlaying.value 
                                        ? Colors.green[700] 
                                        : Theme.of(context).primaryColor,
                                  ),
                                  onPressed: _playPause,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Avanzar 1s
                              _buildAdjustButton(
                                context,
                                icon: Icons.forward,
                                label: '1s',
                                onPressed: () {
                                  final effectiveDuration = _duration.value > 0 ? _duration.value : 180.0;
                                  final maxStart = (effectiveDuration - _selectedDuration.value).clamp(0.0, effectiveDuration);
                                  final newTime = (_startTime.value + 1.0).clamp(0.0, maxStart);
                                  _onStartTimeChanged(newTime);
                                },
                              ),
                              const SizedBox(width: 4),
                              // Avanzar 5s
                              _buildAdjustButton(
                                context,
                                icon: Icons.forward_5,
                                label: '5s',
                                onPressed: () {
                                  final effectiveDuration = _duration.value > 0 ? _duration.value : 180.0;
                                  final maxStart = (effectiveDuration - _selectedDuration.value).clamp(0.0, effectiveDuration);
                                  final newTime = (_startTime.value + 5.0).clamp(0.0, maxStart);
                                  _onStartTimeChanged(newTime);
                                },
                              ),
                              const SizedBox(width: 4),
                              // Avanzar 10s
                              _buildAdjustButton(
                                context,
                                icon: Icons.skip_next,
                                label: '10s',
                                onPressed: () {
                                  final effectiveDuration = _duration.value > 0 ? _duration.value : 180.0;
                                  final maxStart = (effectiveDuration - _selectedDuration.value).clamp(0.0, effectiveDuration);
                                  final newTime = (_startTime.value + 10.0).clamp(0.0, maxStart);
                                  _onStartTimeChanged(newTime);
                                },
                              ),
                            ],
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

                      // Selector de inicio MEJORADO con input exacto
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '⏱️ Tiempo de inicio',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                // Input de tiempo exacto
                                Container(
                                  width: 100,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Theme.of(context).primaryColor),
                                  ),
                                  child: TextField(
                                    controller: _startTimeController,
                                    focusNode: _startTimeFocus,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    keyboardType: TextInputType.text,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
                                    ],
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                      hintText: '00:00',
                                    ),
                                    onChanged: (value) {
                                      if (value.isNotEmpty) {
                                        final parsed = _parseTime(value);
                                        final effectiveDuration = _duration.value > 0 ? _duration.value : 180.0;
                                        final maxStart = (effectiveDuration - _selectedDuration.value).clamp(0.0, effectiveDuration);
                                        final clamped = parsed.clamp(0.0, maxStart);
                                        _onStartTimeChanged(clamped);
                                      }
                                    },
                                    onSubmitted: (value) {
                                      _startTimeFocus.unfocus();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Obx(() {
                              final effectiveDuration = _duration.value > 0 ? _duration.value : 180.0;
                              final maxStart = (effectiveDuration - _selectedDuration.value).clamp(0.0, effectiveDuration);
                              return Slider(
                                value: _startTime.value.clamp(0.0, maxStart),
                                min: 0.0,
                                max: maxStart > 0 ? maxStart : 0.0,
                                divisions: maxStart > 0 ? (maxStart * 2).toInt() : null, // Más preciso
                                label: _formatTime(_startTime.value),
                                onChanged: maxStart > 0 ? (value) {
                                  _onStartTimeChanged(value);
                                } : null,
                              );
                            }),
                            const SizedBox(height: 8),
                            // Botones de ajuste fino para inicio
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildSmallAdjustButton(context, '-10s', () {
                                  final effectiveDuration = _duration.value > 0 ? _duration.value : 180.0;
                                  final newTime = (_startTime.value - 10.0).clamp(0.0, effectiveDuration);
                                  _onStartTimeChanged(newTime);
                                }),
                                _buildSmallAdjustButton(context, '-5s', () {
                                  final effectiveDuration = _duration.value > 0 ? _duration.value : 180.0;
                                  final newTime = (_startTime.value - 5.0).clamp(0.0, effectiveDuration);
                                  _onStartTimeChanged(newTime);
                                }),
                                _buildSmallAdjustButton(context, '-1s', () {
                                  final effectiveDuration = _duration.value > 0 ? _duration.value : 180.0;
                                  final newTime = (_startTime.value - 1.0).clamp(0.0, effectiveDuration);
                                  _onStartTimeChanged(newTime);
                                }),
                                _buildSmallAdjustButton(context, '+1s', () {
                                  final effectiveDuration = _duration.value > 0 ? _duration.value : 180.0;
                                  final maxStart = (effectiveDuration - _selectedDuration.value).clamp(0.0, effectiveDuration);
                                  final newTime = (_startTime.value + 1.0).clamp(0.0, maxStart);
                                  _onStartTimeChanged(newTime);
                                }),
                                _buildSmallAdjustButton(context, '+5s', () {
                                  final effectiveDuration = _duration.value > 0 ? _duration.value : 180.0;
                                  final maxStart = (effectiveDuration - _selectedDuration.value).clamp(0.0, effectiveDuration);
                                  final newTime = (_startTime.value + 5.0).clamp(0.0, maxStart);
                                  _onStartTimeChanged(newTime);
                                }),
                                _buildSmallAdjustButton(context, '+10s', () {
                                  final effectiveDuration = _duration.value > 0 ? _duration.value : 180.0;
                                  final maxStart = (effectiveDuration - _selectedDuration.value).clamp(0.0, effectiveDuration);
                                  final newTime = (_startTime.value + 10.0).clamp(0.0, maxStart);
                                  _onStartTimeChanged(newTime);
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Selector de duración MEJORADO con input exacto
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '⏳ Duración del clip',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                // Input de duración exacta
                                Container(
                                  width: 100,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Theme.of(context).primaryColor),
                                  ),
                                  child: TextField(
                                    controller: _durationController,
                                    focusNode: _durationFocus,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    keyboardType: TextInputType.text,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
                                    ],
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                      hintText: '00:30',
                                    ),
                                    onChanged: (value) {
                                      if (value.isNotEmpty) {
                                        final parsed = _parseTime(value);
                                        final effectiveDuration = _duration.value > 0 ? _duration.value : 180.0;
                                        final maxDuration = (effectiveDuration - _startTime.value).clamp(5.0, 30.0);
                                        final clamped = parsed.clamp(5.0, maxDuration);
                                        _selectedDuration.value = clamped;
                                        final maxStart = (effectiveDuration - clamped).clamp(0.0, effectiveDuration);
                                        if (_startTime.value > maxStart) {
                                          _startTime.value = maxStart;
                                        }
                                      }
                                    },
                                    onSubmitted: (value) {
                                      _durationFocus.unfocus();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Obx(() {
                              final effectiveDuration = _duration.value > 0 ? _duration.value : 180.0;
                              final maxDuration = (effectiveDuration - _startTime.value).clamp(5.0, 30.0);
                              final currentValue = _selectedDuration.value.clamp(5.0, maxDuration);
                              return Slider(
                                value: currentValue,
                                min: 5.0,
                                max: maxDuration,
                                divisions: ((maxDuration - 5.0) * 2).toInt(), // Más preciso
                                label: '${_formatTime(currentValue)} / 30s',
                                onChanged: (value) {
                                  _selectedDuration.value = value;
                                  final maxStart = (effectiveDuration - value).clamp(0.0, effectiveDuration);
                                  if (_startTime.value > maxStart) {
                                    _startTime.value = maxStart;
                                  }
                                },
                              );
                            }),
                            const SizedBox(height: 8),
                            // Botones de ajuste fino para duración
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildSmallAdjustButton(context, '-5s', () {
                                  final effectiveDuration = _duration.value > 0 ? _duration.value : 180.0;
                                  final maxDuration = (effectiveDuration - _startTime.value).clamp(5.0, 30.0);
                                  final newDuration = (_selectedDuration.value - 5.0).clamp(5.0, maxDuration);
                                  _selectedDuration.value = newDuration;
                                  final maxStart = (effectiveDuration - newDuration).clamp(0.0, effectiveDuration);
                                  if (_startTime.value > maxStart) {
                                    _startTime.value = maxStart;
                                  }
                                }),
                                _buildSmallAdjustButton(context, '-1s', () {
                                  final effectiveDuration = _duration.value > 0 ? _duration.value : 180.0;
                                  final maxDuration = (effectiveDuration - _startTime.value).clamp(5.0, 30.0);
                                  final newDuration = (_selectedDuration.value - 1.0).clamp(5.0, maxDuration);
                                  _selectedDuration.value = newDuration;
                                  final maxStart = (effectiveDuration - newDuration).clamp(0.0, effectiveDuration);
                                  if (_startTime.value > maxStart) {
                                    _startTime.value = maxStart;
                                  }
                                }),
                                _buildSmallAdjustButton(context, '+1s', () {
                                  final effectiveDuration = _duration.value > 0 ? _duration.value : 180.0;
                                  final maxDuration = (effectiveDuration - _startTime.value).clamp(5.0, 30.0);
                                  final newDuration = (_selectedDuration.value + 1.0).clamp(5.0, maxDuration);
                                  _selectedDuration.value = newDuration;
                                  final maxStart = (effectiveDuration - newDuration).clamp(0.0, effectiveDuration);
                                  if (_startTime.value > maxStart) {
                                    _startTime.value = maxStart;
                                  }
                                }),
                                _buildSmallAdjustButton(context, '+5s', () {
                                  final effectiveDuration = _duration.value > 0 ? _duration.value : 180.0;
                                  final maxDuration = (effectiveDuration - _startTime.value).clamp(5.0, 30.0);
                                  final newDuration = (_selectedDuration.value + 5.0).clamp(5.0, maxDuration);
                                  _selectedDuration.value = newDuration;
                                  final maxStart = (effectiveDuration - newDuration).clamp(0.0, effectiveDuration);
                                  if (_startTime.value > maxStart) {
                                    _startTime.value = maxStart;
                                  }
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

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
                              Obx(() {
                                final maxDuration = (_duration.value - _startTime.value).clamp(5.0, 30.0);
                                final currentValue = _selectedDuration.value.clamp(5.0, maxDuration);
                                return Slider(
                                  value: currentValue,
                                  min: 5.0,
                                  max: maxDuration,
                                  onChanged: (value) {
                                    _selectedDuration.value = value;
                                    final maxStart = (_duration.value - value).clamp(0.0, _duration.value);
                                    if (_startTime.value > maxStart) {
                                      _startTime.value = maxStart;
                                    }
                                  },
                                );
                              }),
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
                      
                      // Barra de progreso visual (sin reproducción) - MEJORADA
                      Obx(() => Column(
                        children: [
                          GestureDetector(
                            onTapDown: (details) {
                              if (_duration.value > 0) {
                                final RenderBox? box = context.findRenderObject() as RenderBox?;
                                if (box != null) {
                                  final localPosition = box.globalToLocal(details.globalPosition);
                                  final width = MediaQuery.of(context).size.width - 80;
                                  final tapX = localPosition.dx.clamp(0.0, width);
                                  final newStartTime = (tapX / width) * _duration.value;
                                  final maxStart = (_duration.value - _selectedDuration.value).clamp(0.0, _duration.value);
                                  final clampedStart = newStartTime.clamp(0.0, maxStart);
                                  _onStartTimeChanged(clampedStart);
                                }
                              }
                            },
                            child: Container(
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
                                  // Marcador de inicio del segmento
                                  if (_duration.value > 0)
                                    Positioned(
                                      left: ((_startTime.value / _duration.value) * (MediaQuery.of(context).size.width - 80)).clamp(0.0, MediaQuery.of(context).size.width - 80),
                                      top: 20,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                      ),
                                    ),
                                  // Marcador de fin del segmento
                                  if (_duration.value > 0)
                                    Positioned(
                                      left: (((_startTime.value + _selectedDuration.value) / _duration.value) * (MediaQuery.of(context).size.width - 80)).clamp(0.0, MediaQuery.of(context).size.width - 80),
                                      top: 20,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          ),
                          // Tiempos y ayuda
                          Column(
                            children: [
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
                              const SizedBox(height: 4),
                              Text(
                                '👆 Toca la barra para seleccionar el inicio',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
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
                          Obx(() {
                            final maxDuration = (_duration.value - _startTime.value).clamp(5.0, 30.0);
                            final currentValue = _selectedDuration.value.clamp(5.0, maxDuration);
                            return Slider(
                              value: currentValue,
                              min: 5.0,
                              max: maxDuration,
                              onChanged: (value) {
                                _selectedDuration.value = value;
                                final maxStart = (_duration.value - value).clamp(0.0, _duration.value);
                                if (_startTime.value > maxStart) {
                                  _startTime.value = maxStart;
                                }
                              },
                            );
                          }),
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
                    // Barra de progreso principal (estilo Instagram) - INTERACTIVA
                    Obx(() => Column(
                      children: [
                        // Indicador visual del segmento seleccionado - CLICKEABLE
                        GestureDetector(
                          onTapDown: (details) {
                            if (_duration.value > 0) {
                              final RenderBox? box = context.findRenderObject() as RenderBox?;
                              if (box != null) {
                                final localPosition = box.globalToLocal(details.globalPosition);
                                final width = MediaQuery.of(context).size.width - 80;
                                final tapX = localPosition.dx.clamp(0.0, width);
                                final newStartTime = (tapX / width) * _duration.value;
                                final maxStart = (_duration.value - _selectedDuration.value).clamp(0.0, _duration.value);
                                final clampedStart = newStartTime.clamp(0.0, maxStart);
                                _onStartTimeChanged(clampedStart);
                              }
                            }
                          },
                          child: Container(
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
                                // Marcador de inicio del segmento
                                if (_duration.value > 0)
                                  Positioned(
                                    left: ((_startTime.value / _duration.value) * (MediaQuery.of(context).size.width - 80)).clamp(0.0, MediaQuery.of(context).size.width - 80),
                                    top: 20,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                                // Marcador de fin del segmento
                                if (_duration.value > 0)
                                  Positioned(
                                    left: (((_startTime.value + _selectedDuration.value) / _duration.value) * (MediaQuery.of(context).size.width - 80)).clamp(0.0, MediaQuery.of(context).size.width - 80),
                                    top: 20,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                            ],
                            ),
                          ),
                        ),
                        
                        // Tiempos y ayuda
                        Column(
                          children: [
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
                            const SizedBox(height: 4),
                            Text(
                              '👆 Toca la barra para seleccionar el inicio',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
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

                    // Controles de reproducción mejorados
                    Obx(() => Column(
                      children: [
                        // Botones de navegación rápida
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Retroceder 5 segundos
                            IconButton(
                              icon: const Icon(Icons.replay_5),
                              iconSize: 32,
                              color: Theme.of(context).primaryColor,
                              onPressed: () {
                                final newTime = (_startTime.value - 5.0).clamp(0.0, _duration.value);
                                _onStartTimeChanged(newTime);
                              },
                              tooltip: 'Retroceder 5s',
                            ),
                            const SizedBox(width: 20),
                            // Botón de play/pause grande
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
                            // Avanzar 5 segundos
                            const SizedBox(width: 20),
                            IconButton(
                              icon: const Icon(Icons.forward_5),
                              iconSize: 32,
                              color: Theme.of(context).primaryColor,
                              onPressed: () {
                                final maxStart = (_duration.value - _selectedDuration.value).clamp(0.0, _duration.value);
                                final newTime = (_startTime.value + 5.0).clamp(0.0, maxStart);
                                _onStartTimeChanged(newTime);
                              },
                              tooltip: 'Avanzar 5s',
                            ),
                          ],
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
                        Obx(() {
                          final maxDuration = (_duration.value - _startTime.value).clamp(5.0, 30.0);
                          final currentValue = _selectedDuration.value.clamp(5.0, maxDuration);
                          return Slider(
                            value: currentValue,
                            min: 5.0,
                            max: maxDuration,
                            onChanged: (value) {
                              _selectedDuration.value = value;
                              final maxStart = (_duration.value - value).clamp(0.0, _duration.value);
                              if (_startTime.value > maxStart) {
                                _startTime.value = maxStart;
                              }
                            },
                          );
                        }),
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


