import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/models/message.dart';

class ReplyMessage extends StatelessWidget {
  const ReplyMessage({
    super.key,
    required this.message,
    required this.senderName,
    this.bgColor,
    this.lineColor,
    this.senderColor,
    this.cancelReply,
    this.onTapReply, // Nueva función para navegar al mensaje
  });

  final Message message;
  final String senderName;
  final Color? bgColor, lineColor, senderColor;
  final Function()? cancelReply;
  final Function()? onTapReply; // Nueva función para navegar al mensaje

  @override
  Widget build(BuildContext context) {
    
    // For: image, gif video preview box
    bool isMediaMsg() {
      return message.type == MessageType.image ||
          message.type == MessageType.gif ||
          message.type == MessageType.video;
    }

    // Obtener color según tipo de usuario
    Color getUserColor() {
      if (message.isSender) {
        return Colors.blue[600]!;
      }
      // Para contactos, usar colores distintivos
      return Colors.green[600]!;
    }

    // Obtener texto descriptivo del mensaje
    String getMessageDescription() {
      switch (message.type) {
        case MessageType.image:
          return 'Foto';
        case MessageType.video:
          return 'Video';
        case MessageType.gif:
          return 'GIF';
        case MessageType.doc:
          return 'Documento';
        case MessageType.location:
          return 'Ubicación';
        case MessageType.audio:
          return 'Mensaje de voz';
        default:
          return message.textMsg.isNotEmpty ? message.textMsg : 'Mensaje';
      }
    }

    return Stack(
      children: [
        // Reply container - más pequeño y compacto
        GestureDetector(
          onTap: onTapReply, // Navegar al mensaje al tocar
          child: Container(
            width: double.maxFinite,
            margin: const EdgeInsets.symmetric(
              horizontal: 8, // Margen más pequeño
              vertical: 4, // Margen más pequeño
            ),
            decoration: BoxDecoration(
              color: bgColor ?? Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(8), // Bordes más pequeños
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4, // Sombra más sutil
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Línea vertical conectora - verde como en la imagen
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: lineColor ?? Colors.green[600], // Verde como en la imagen
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                ),
                // Miniatura de imagen (si es mensaje multimedia)
                if (isMediaMsg()) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 50,
                    height: 50,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildImagePreview(),
                    ),
                  ),
                ],
                // Contenido de texto - más compacto
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(isMediaMsg() ? 6.0 : 8.0), // Padding más pequeño
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sender name con color distintivo
                        Text(
                          message.isSender ? 'Tú' : senderName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: senderColor ?? Colors.green[600], // Verde como en la imagen
                            fontSize: 12, // Texto más pequeño
                          ),
                        ),
                        const SizedBox(height: 1), // Espaciado más pequeño
                        // Descripción del mensaje
                        Text(
                          getMessageDescription(),
                          style: TextStyle(
                            color: Colors.black87, // Texto negro como en la imagen
                            fontSize: 11, // Texto más pequeño
                          ),
                          maxLines: 1, // Solo una línea
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
        // Cancel reply button
        if (cancelReply != null)
          Positioned(
            top: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: cancelReply,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePreview() {
    // Si es una imagen local (path empieza con /)
    if (message.fileUrl.startsWith('/')) {
      final file = File(message.fileUrl);
      return FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data == true) {
            return Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                  ),
                );
              },
            );
          } else {
            return Container(
              color: Colors.grey[300],
              child: const Icon(
                Icons.image,
                color: Colors.grey,
              ),
            );
          }
        },
      );
    } else {
      // Imagen remota
      return CachedNetworkImage(
        imageUrl: message.fileUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: const Icon(
            Icons.image,
            color: Colors.grey,
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[300],
          child: const Icon(
            Icons.broken_image,
            color: Colors.grey,
          ),
        ),
      );
    }
  }
}

class ReplySeparator extends StatelessWidget {
  const ReplySeparator({
    super.key,
    this.color,
  });

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 80,
      decoration: BoxDecoration(
        color: color ?? primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomLeft: Radius.circular(8),
        ),
      ),
    );
  }
}
