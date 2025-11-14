import 'dart:io';
import 'package:chat_messenger/components/cached_card_image.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/models/message.dart';
import 'package:chat_messenger/screens/messages/controllers/message_controller.dart';
import 'package:chat_messenger/screens/messages/components/read_time_status.dart';
import 'package:flutter/material.dart';
import 'package:chat_messenger/media/view_media_screen.dart';
import 'package:get/get.dart';

class VideoMessage extends StatelessWidget {
  const VideoMessage(this.message, {super.key, this.isGroup = false});

  // Params
  final Message message;
  final bool isGroup;

  @override
  Widget build(BuildContext context) {
    final MessageController controller = Get.find();
    
    return GestureDetector(
      onTap: () {
        // Solo permitir ver el video si no se está cargando
        if (!controller.isFileUploading(message.fileUrl)) {
          Get.to(() => ViewMediaScreen(fileUrl: message.fileUrl, isVideo: true));
        }
      },
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
          minWidth: MediaQuery.of(context).size.width * 0.45,
          maxHeight: MediaQuery.of(context).size.height * 0.4,
          minHeight: 120,
        ),
        child: AspectRatio(
          aspectRatio: 16 / 9, // Formato cinematográfico para videos
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10), // 10px esquinas suaves
              border: Border.all(
                color: const Color(0xFFCCCCCC), // #ccc color
                width: 1, // 1px borde fino
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9), // Ligeramente menor para el clip interno
              child: Stack(
                fit: StackFit.expand,
                children: [
                // Video preview (local file o thumbnail)
                _buildVideoPreview(),
                
                // Play icon (solo si no se está cargando)
                Obx(() {
                  if (!controller.isFileUploading(message.fileUrl)) {
                    return const Center(
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: primaryColor,
                        child: Icon(
                          Icons.play_arrow,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                
                // Indicador de progreso circular compacto si se está subiendo
                Obx(() {
                  if (controller.isFileUploading(message.fileUrl)) {
                    return Container(
                      color: const Color(0x4D000000),
                      child: Center(
                        child: GestureDetector(
                          onTap: () => controller.cancelUpload(message.fileUrl),
                          child: Container(
                            width: 40, // Más pequeño y compacto
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xB3000000),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Stack(
                              children: [
                                // Círculo de progreso más pequeño
                                Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                // X en el centro más pequeña
                                Center(
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),

                // Tiempo y verificación dentro del video
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0x99000000),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ReadTimeStatus(
                      message: message,
                      isGroup: isGroup,
                    ),
                  ),
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (message.videoThumbnail.isNotEmpty) {
      // Si el thumbnail es local, mostrarlo directamente
      if (_isLocalPath(message.videoThumbnail)) {
        return Image.file(
          File(message.videoThumbnail),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _videoPlaceholder(),
        );
      }

      // Thumbnail remoto en cache
      return CachedCardImage(message.videoThumbnail);
    }

    // Sin thumbnail disponible, usar placeholder
    return _videoPlaceholder();
  }

  Widget _videoPlaceholder() {
    return Container(
      color: Colors.grey[800],
      child: const Center(
        child: Icon(
          Icons.videocam,
          size: 50,
          color: Colors.white,
        ),
      ),
    );
  }

  bool _isLocalPath(String path) {
    return path.startsWith('/') || path.startsWith('file://');
  }
}
