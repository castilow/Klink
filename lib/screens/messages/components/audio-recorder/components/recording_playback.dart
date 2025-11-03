import 'package:flutter/material.dart';
import 'package:chat_messenger/components/circle_button.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/media/helpers/media_helper.dart';
import 'package:chat_messenger/screens/messages/components/utils/custom_track_shape.dart';
import 'package:chat_messenger/screens/messages/controllers/audio_player_controller.dart';
import 'package:chat_messenger/widgets/audio_player_widget.dart';
import 'package:get/get.dart';

class RecordingPlayback extends StatelessWidget {
  const RecordingPlayback({super.key, required this.fileUrl});

  final String fileUrl;

  @override
  Widget build(BuildContext context) {
    // Init Audio Player Controller with unique tag
    final AudioPlayerController controller = Get.put(
      AudioPlayerController(fileUrl: fileUrl),
      tag: 'recording_playback',
    );

    return Obx(() {
      final bool isPlaying = controller.isPlaying.value;
      final Duration duration = controller.duration.value;
      final Duration position = controller.position.value;
      final bool hasError = controller.hasError.value;
      final String errorMessage = controller.errorMessage.value;
      final bool isLoading = controller.isLoading.value;

      // Si hay error, mostrar mensaje de error con opción de reintentar
      if (hasError) {
        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Error de Audio',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage.isNotEmpty ? errorMessage : 'No se pudo reproducir el audio',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => controller.retryAudio(),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reintentar'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }

      // Si está cargando, mostrar indicador de carga
      if (isLoading) {
        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade600),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Cargando audio...',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }

      return AudioPlayerWidget(
        isPlaying: isPlaying,
        position: position,
        duration: duration,
        onPlayPause: () => controller.playAudio(),
        onSeek: (seekPosition) {
          controller.seekAudio(seekPosition);
        },
        isSender: false,
        timestamp: null,
        isRead: false,
        showTimestamp: false,
        transcription: controller.getTranscription(),
      );
    });
  }
}
