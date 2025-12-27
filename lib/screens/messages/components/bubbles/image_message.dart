import 'dart:io';
import 'package:chat_messenger/components/cached_card_image.dart';
import 'package:chat_messenger/models/message.dart';
import 'package:chat_messenger/screens/messages/controllers/message_controller.dart';
import 'package:chat_messenger/screens/messages/components/read_time_status.dart';
import 'package:flutter/material.dart';
import 'package:chat_messenger/media/view_media_screen.dart';
import 'package:get/get.dart';

class ImageMessage extends StatelessWidget {
  const ImageMessage(this.message, {super.key, this.isGroup = false});

  // Params
  final Message message;
  final bool isGroup;

  @override
  Widget build(BuildContext context) {
    final MessageController controller = Get.find();
    
    return GestureDetector(
      onTap: () {
        // Solo permitir ver la imagen si no se está cargando
        if (!controller.isFileUploading(message.fileUrl)) {
          Get.to(() => ViewMediaScreen(fileUrl: message.fileUrl));
        }
      },
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
          minWidth: MediaQuery.of(context).size.width * 0.45,
          maxHeight: MediaQuery.of(context).size.height * 0.4,
          minHeight: 120,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Detectar si es sticker (generalmente cuadrados o pequeños)
            final bool isLikelySticker = constraints.maxWidth < 200 || 
                                        constraints.maxHeight < 200 ||
                                        message.fileUrl.contains('sticker') ||
                                        message.fileUrl.contains('giphy') ||
                                        message.fileUrl.contains('tenor') ||
                                        message.fileUrl.contains('openmoji');
            
            final double aspectRatio = isLikelySticker ? 1.0 : 4 / 3; // Cuadrado para stickers, 4:3 para fotos
            
            return AspectRatio(
              aspectRatio: aspectRatio,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10), // 10px esquinas suaves
                  // Borde eliminado para stickers
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10), // Mismo radio que el contenedor
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                    // Imagen (local o remota)
                    _buildImage(isLikelySticker),
                
                // Indicador de progreso circular compacto si se está subiendo
                Obx(() {
                  if (controller.isFileUploading(message.fileUrl)) {
                    return Container(
                      color: Colors.black.withOpacity(0.3),
                      child: Center(
                        child: GestureDetector(
                          onTap: () => controller.cancelUpload(message.fileUrl),
                          child: Container(
                            width: 40, // Más pequeño y compacto
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
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

                // Tiempo y verificación dentro de la imagen
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildImage([bool isSticker = false]) {
    // Para stickers, usar contain para mantener calidad y proporción
    final BoxFit fit = isSticker ? BoxFit.contain : BoxFit.cover;
    
    // Verificar si el fileUrl está vacío o no válido
    if (message.fileUrl.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Si el fileUrl es un path local (empieza con /), usar File
    if (message.fileUrl.startsWith('/')) {
      return Image.file(
        File(message.fileUrl),
        fit: fit,
        // Mejorar calidad de renderizado
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(
              Icons.broken_image,
              size: 50,
              color: Colors.grey,
            ),
          );
        },
      );
    } else if (message.fileUrl.startsWith('http://') || message.fileUrl.startsWith('https://')) {
      // Es una URL remota, usar CachedCardImage
      return CachedCardImage(message.fileUrl);
    } else {
      // URL no válida o vacía
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(
            Icons.broken_image,
            size: 50,
            color: Colors.grey,
          ),
        ),
      );
    }
  }
}

