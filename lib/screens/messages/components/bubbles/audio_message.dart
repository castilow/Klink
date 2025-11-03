import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:chat_messenger/models/message.dart';
import 'package:chat_messenger/widgets/audio_player_widget.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/screens/messages/controllers/message_controller.dart';

class AudioMessage extends StatefulWidget {
  const AudioMessage({
    super.key,
    required this.message,
    required this.isSender,
  });

  final Message message;
  final bool isSender;

  @override
  State<AudioMessage> createState() => _AudioMessageState();
}

class _AudioMessageState extends State<AudioMessage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Duration _estimatedDuration = Duration.zero; // Duración estimada desde el inicio

  @override
  void initState() {
    super.initState();
    _estimateDuration(); // Estimar duración desde el inicio
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((duration) {
      if (duration.inMilliseconds > 0) {
        setState(() {
          _duration = duration;
          // Actualizar la duración estimada con la real
          _estimatedDuration = duration;
        });
        print('Audio duration loaded: ${duration.inSeconds}s'); // Debug
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _position = position;
      });
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
        _isLoading = false; // Simplified loading state
      });
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
    
    // Cargar la duración del audio inmediatamente
    _loadAudioDuration();
  }

  void _estimateDuration() {
    // Estimar duración basada en el nombre del archivo o URL
    final fileName = widget.message.fileUrl.split('/').last;
    
    // Buscar patrones de duración en el nombre del archivo
    final durationPattern = RegExp(r'(\d+)s|(\d+)sec|(\d+)second|(\d+)ms|(\d+)min');
    final match = durationPattern.firstMatch(fileName);
    
    if (match != null) {
      int seconds = 0;
      if (match.group(1) != null) {
        seconds = int.tryParse(match.group(1)!) ?? 0;
      } else if (match.group(2) != null) {
        seconds = int.tryParse(match.group(2)!) ?? 0;
      } else if (match.group(3) != null) {
        seconds = int.tryParse(match.group(3)!) ?? 0;
      } else if (match.group(4) != null) {
        seconds = (int.tryParse(match.group(4)!) ?? 0) ~/ 1000; // Convertir ms a segundos
      } else if (match.group(5) != null) {
        seconds = (int.tryParse(match.group(5)!) ?? 0) * 60; // Convertir minutos a segundos
      }
      _estimatedDuration = Duration(seconds: seconds);
    } else {
      // Estimar basado en el tamaño del archivo o usar duración por defecto
      final fileSize = _estimateFileSize();
      if (fileSize > 0) {
        // Estimación: ~64KB por segundo de audio (calidad media)
        final estimatedSeconds = (fileSize / 64000).round();
        _estimatedDuration = Duration(seconds: estimatedSeconds.clamp(1, 300)); // Entre 1s y 5min
      } else {
        // Duración por defecto más realista
        _estimatedDuration = Duration(seconds: 8); // Duración por defecto más corta
      }
    }
    
    setState(() {});
  }
  
  int _estimateFileSize() {
    // Intentar extraer información de tamaño del archivo de la URL
    final url = widget.message.fileUrl;
    if (url.contains('size=')) {
      final sizeMatch = RegExp(r'size=(\d+)').firstMatch(url);
      if (sizeMatch != null) {
        return int.tryParse(sizeMatch.group(1)!) ?? 0;
      }
    }
    return 0; // No se pudo determinar el tamaño
  }
  
  Future<void> _loadAudioDuration() async {
    try {
      // Cargar la duración del audio sin reproducirlo
      if (widget.message.fileUrl.startsWith('http')) {
        await _audioPlayer.setSource(UrlSource(widget.message.fileUrl));
      } else {
        await _audioPlayer.setSource(DeviceFileSource(widget.message.fileUrl));
      }
      
      // La duración se obtendrá automáticamente a través del listener onDurationChanged
    } catch (e) {
      // Si falla la carga, usar la duración estimada
      print('Error loading audio duration: $e');
    }
  }

  Future<void> _playAudio() async {
    try {
      // Get the global MessageController
      final messageController = MessageController.globalInstance;
      
      // Check if this message is currently playing
      final isCurrentlyPlaying = messageController.currentPlayingMessageId == widget.message.msgId;
      
      if (isCurrentlyPlaying && messageController.isPlaying) {
        // Pause current audio
        await messageController.pauseAudio();
      } else {
        // Play this audio (will stop any other playing audio)
        await messageController.playAudio(widget.message);
      }
    } catch (e) {
      print('Audio playback error in widget: $e');
      // Notificaciones generales deshabilitadas
    }
  }



  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _formatTimestamp(DateTime? sentAt) {
    if (sentAt == null) return "00:00";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(sentAt.hour);
    final minutes = twoDigits(sentAt.minute);
    return '$hours:$minutes';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Usar duración real si está disponible, sino usar la estimada
    final effectiveDuration = _duration.inMilliseconds > 0 ? _duration : _estimatedDuration;
    
    // Asegurar que siempre tengamos una duración válida
    final finalDuration = effectiveDuration.inMilliseconds > 0 
        ? effectiveDuration 
        : Duration(seconds: 5); // Fallback mínimo
    
    // Get the MessageController for global state
    final messageController = MessageController.globalInstance;
    final isCurrentlyPlaying = messageController.currentPlayingMessageId == widget.message.msgId;
    final globalIsPlaying = messageController.isPlaying && isCurrentlyPlaying;
    
    return AudioPlayerWidget(
      isPlaying: globalIsPlaying,
      position: messageController.currentPosition,
      duration: finalDuration,
      onPlayPause: _isLoading ? () {} : _playAudio,
      onSeek: (position) {
        // TODO: Implementar seek functionality
      },
      isSender: widget.isSender,
      timestamp: _formatTimestamp(widget.message.sentAt), // Obtener timestamp real del mensaje
      isRead: widget.message.isRead, // Obtener estado real de lectura
      showTimestamp: true,
      transcription: "Mensaje de voz", // Mostrar "Mensaje de voz" como en la imagen
      message: widget.message, // Pass the message to the widget
    );
  }
} 