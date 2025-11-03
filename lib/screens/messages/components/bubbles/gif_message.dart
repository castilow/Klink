import 'package:chat_messenger/components/cached_card_image.dart';
import 'package:chat_messenger/models/message.dart';
import 'package:chat_messenger/screens/messages/components/read_time_status.dart';
import 'package:flutter/material.dart';
import 'package:chat_messenger/media/view_media_screen.dart';
import 'package:get/get.dart';

class GifMessage extends StatelessWidget {
  const GifMessage(this.message, {super.key, this.isGroup = false});

  // Params
  final Message message;
  final bool isGroup;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => ViewMediaScreen(fileUrl: message.gifUrl)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
          minWidth: MediaQuery.of(context).size.width * 0.45,
          maxHeight: MediaQuery.of(context).size.height * 0.4,
          minHeight: 120,
        ),
        child: AspectRatio(
          aspectRatio: 4 / 3, // Formato rectangular para GIFs
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
                // GIF
                CachedCardImage(message.gifUrl),
                
                // Tiempo y verificación dentro del GIF
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
        ),
      ),
    );
  }
}
