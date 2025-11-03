import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:chat_messenger/components/message_badge.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/models/message.dart';
import 'package:chat_messenger/helpers/date_helper.dart';
import '../rich_text_message.dart';
import '../read_time_status.dart';

class TextMessage extends StatelessWidget {
  const TextMessage(this.message, {super.key});

  final Message message;

  @override
  Widget build(BuildContext context) {
    // Log message rendering for debugging
    debugPrint('TextMessage build() -> Message ID: ${message.msgId}, IsDeleted: ${message.isDeleted}, Text: "${message.textMsg}"');
    
    return Container(
      padding: const EdgeInsets.only(bottom: 6, right: 8), // Padding aún más fino
      constraints: const BoxConstraints(
        minWidth: 45,
        maxWidth: 280,
      ),
      child: message.isDeleted
          ? MessageDeleted(
              isSender: message.isSender,
              iconColor: message.isSender ? Colors.white : greyColor,
              style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: message.isSender ? Colors.white.withOpacity(0.9) : Colors.grey[600],
              ),
            )
          : message.textMsg.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    '[Mensaje vacío]',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: message.isSender ? Colors.white.withOpacity(0.7) : Colors.grey[500],
                    ),
                  ),
                )
              : _buildTextWithTime(),
    );
  }

  Widget _buildTextWithTime() {
    // Determinar si es un mensaje corto o largo
    final bool isShortMessage = message.textMsg.length <= 25; // Umbral más bajo para mensajes cortos
    
    if (isShortMessage) {
      // Mensaje corto: hora y checkmark al lado derecho (diseño compacto)
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Texto principal
          Flexible(
            child: RichTexMessage(
              text: message.textMsg,
              defaultStyle: TextStyle(
                fontSize: 13, // Texto aún más pequeño para mensajes cortos
                height: 1.2, // Altura de línea muy compacta
                letterSpacing: 0.05, // Espaciado mínimo
                color: Colors.black87,
                fontWeight: FontWeight.w400,
                fontFamily: 'Inter',
              ),
            ),
          ),
          
          const SizedBox(width: 6), // Espaciado reducido
          
          // Hora y checkmark al lado derecho
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hora
              Text(
                message.isDeleted
                    ? message.updatedAt?.formatMsgTime ?? ''
                    : message.sentAt?.formatMsgTime ?? '',
                style: TextStyle(
                  fontSize: 11, // Hora más pequeña
                  color: const Color(0xFF4CAF50),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 3), // Espaciado reducido
              // Checkmark
              if (message.isSender)
                Icon(
                  message.isRead ? Icons.done_all : Icons.done,
                  size: 12, // Checkmark más pequeño
                  color: const Color(0xFF4CAF50),
                ),
            ],
          ),
        ],
      );
    } else {
      // Mensaje largo: hora y checkmark abajo a la derecha (diseño moderno)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Texto principal
          RichTexMessage(
            text: message.textMsg,
            defaultStyle: TextStyle(
              fontSize: 14,
              height: 1.25, // Altura de línea optimizada para textos largos
              letterSpacing: 0.08, // Espaciado moderado
              color: Colors.black87,
              fontWeight: FontWeight.w400,
              fontFamily: 'Inter',
            ),
          ),
          
          // Hora y checkmark abajo a la derecha
          Padding(
            padding: const EdgeInsets.only(top: 3), // Espaciado ligeramente mayor
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Hora
                Text(
                  message.isDeleted
                      ? message.updatedAt?.formatMsgTime ?? ''
                      : message.sentAt?.formatMsgTime ?? '',
                  style: TextStyle(
                    fontSize: 11, // Hora más pequeña
                    color: const Color(0xFF4CAF50),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 3), // Espaciado reducido
                // Checkmark
                if (message.isSender)
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 12, // Checkmark más pequeño
                    color: const Color(0xFF4CAF50),
                  ),
              ],
            ),
          ),
        ],
      );
    }
  }
}
