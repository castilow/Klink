import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/models/group.dart';
import 'package:chat_messenger/models/message.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:flutter/material.dart';
import 'package:chat_messenger/plugins/swipeto/swipe_to.dart';
import 'package:chat_messenger/screens/messages/components/bubbles/location_message.dart';
import 'package:chat_messenger/screens/messages/components/reply_message.dart';
import 'package:chat_messenger/screens/messages/components/selection_circle.dart';
import 'package:chat_messenger/screens/messages/controllers/message_controller.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'bubbles/document_message.dart';
import 'bubbles/gif_message.dart';
import 'bubbles/image_message.dart';
import 'bubbles/text_message.dart';
import 'bubbles/video_message.dart';
import 'bubbles/audio_message.dart';
import 'forwarded_badge.dart';
import 'read_time_status.dart';
import 'message_actions_overlay.dart';
import 'package:chat_messenger/controllers/preferences_controller.dart';

class BubbleMessage extends StatelessWidget {
  const BubbleMessage({
    super.key,
    required this.message,
    required this.onTapProfile,
    required this.onReplyMessage,
    required this.user,
    required this.group,
    required this.controller,
  });

  // final bool isGroup;
  final Message message;
  final User? user;
  final Group? group;
  final MessageController controller;
  // final String senderName;
  // final String? profileUrl;
  final Function()? onTapProfile;
  final Function()? onReplyMessage;

  @override
  Widget build(BuildContext context) {
    // Log para TODOS los mensajes
    debugPrint('💬💬💬💬💬💬💬💬💬💬 BubbleMessage.build EJECUTADO 💬💬💬💬💬💬💬💬💬💬');
    debugPrint('   - msgId: ${message.msgId}');
    debugPrint('   - type: ${message.type}');
    
    // DEBUG: Log para verificar que el mensaje tiene el tipo correcto - SIEMPRE
    if (message.type == MessageType.image) {
      print('🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️ BubbleMessage.build: MENSAJE DE IMAGEN 🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️');
      print('   - msgId: ${message.msgId}');
      print('   - type: ${message.type}');
      print('   - fileUrl: ${message.fileUrl.isEmpty ? "VACÍO" : message.fileUrl.substring(0, message.fileUrl.length > 50 ? 50 : message.fileUrl.length)}...');
      print('   - fileUrl length: ${message.fileUrl.length}');
      print('   - fileUrl startsWith http: ${message.fileUrl.startsWith("http")}');
      print('   - ⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️ BUBBLEMESSAGE.BUILD EJECUTADO PARA IMAGEN ⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️');
      debugPrint('🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️ BubbleMessage.build: MENSAJE DE IMAGEN 🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️');
      debugPrint('   - msgId: ${message.msgId}');
      debugPrint('   - type: ${message.type}');
      debugPrint('   - fileUrl: ${message.fileUrl.isEmpty ? "VACÍO" : message.fileUrl.substring(0, message.fileUrl.length > 50 ? 50 : message.fileUrl.length)}...');
      debugPrint('   - fileUrl length: ${message.fileUrl.length}');
      debugPrint('   - fileUrl startsWith http: ${message.fileUrl.startsWith("http")}');
      debugPrint('   - ⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️ BUBBLEMESSAGE.BUILD EJECUTADO PARA IMAGEN ⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️');
    }
    
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool isGroup = group != null;
    final bool isSender = message.isSender;
    final String profileUrl = isGroup
        ? group!.getMemberProfile(message.senderId).photoUrl
        : user!.photoUrl;

    // Get sender user
    final User senderUser =
        isGroup ? group!.getMemberProfile(message.senderId) : user!;

    // Background color based on sender and theme
    // Usar colores personalizados si existen, sino usar los por defecto
    final PreferencesController prefController = Get.find();
    final Color backgroundColor = isSender
        ? prefController.getSentBubbleColor()
        : prefController.getReceivedBubbleColor(isDarkMode);
    // Calcular color de texto automático basado en el color de fondo
    final Color textColor = PreferencesController.getContrastTextColor(backgroundColor);

    return Obx(() {
      final bool isMultiSelectMode = controller.isMultiSelectMode.value;
      final bool isSelected = controller.isMessageSelected(message);
      
      return AnimatedContainer(
        duration: const Duration(milliseconds: 150), // Más rápido como Telegram
        curve: Curves.easeOutCubic, // Curva más suave
        padding: EdgeInsets.symmetric(
          vertical: isMultiSelectMode ? 1.0 : 8.0, // Espaciado muy reducido en modo selección
        ),
        child: GestureDetector(
          onLongPress: () async {
            // Mostrar overlay moderno anclado al mensaje
            final RenderBox box = context.findRenderObject() as RenderBox;
            final Offset topLeft = box.localToGlobal(Offset.zero);
            final Size size = box.size;
            final Rect anchorRect = Rect.fromLTWH(topLeft.dx, topLeft.dy, size.width, size.height);
            await showMessageActionsOverlay(
              context: context,
              message: message,
              controller: controller,
              isSender: isSender,
              anchorRect: anchorRect,
              user: user,
              group: group,
            );
          },
          onTap: () {
            if (isMultiSelectMode) {
              controller.toggleMessageSelection(message);
            }
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selection circle - SIEMPRE a la izquierda en modo selección
              if (isMultiSelectMode)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 120), // Más rápido como Telegram
                  curve: Curves.easeOutBack, // Curva más dinámica
                  width: 32,
                  padding: const EdgeInsets.only(right: 2, top: 16), // Solo 2px de separación
                  child: GestureDetector(
                    onTap: () => controller.toggleMessageSelection(message),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF00A884) : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.white, // Borde blanco siempre
                          width: 1,
                        ),
                      ),
                      child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                    ),
                  ),
                ),
              
              // Avatar for incoming group messages
              if (isGroup && !isSender)
                Padding(
                  padding: const EdgeInsets.only(right: 8, top: 4), 
                  child: GestureDetector(
                    onTap: onTapProfile,
                    child: CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(senderUser.photoUrl),
                      radius: 16,
                    ),
                  ),
                ),

              // Main message container
              Expanded(
                child: SwipeTo(
                  iconColor: primaryColor,
                  iconOnLeftSwipe: Icons.reply, // Icono de respuesta para deslizar hacia la izquierda
                  onLeftSwipe: isMultiSelectMode ? null : onReplyMessage, // Deslizar hacia la izquierda para responder
                  animationDuration: const Duration(milliseconds: 200), // Animación más suave
                  child: Container(
                      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                      child: _isMediaMessage()
                          ? Container(
                                margin: EdgeInsets.only(
                                top: 8,
                                left: isSender ? (isMultiSelectMode ? 8 : 50) : 0, // Removed left margin because avatar is there
                                right: isSender ? 0 : 50,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (message.isForwarded && !message.isDeleted)
                                    _buildForwardedMediaInfo(),
                                  if (isGroup && !isSender && !message.isDeleted)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        senderUser.fullname,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFE91E63), // Pink/Premium color for name
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  _showMessageContent(profileUrl, backgroundColor),
                                ],
                              ),
                            )
                          : Obx(() {
                              final double radius = prefController.customBubbleRadius.value;
                              return Container(
                              margin: EdgeInsets.only(
                                top: 4, 
                                left: isSender ? (isMultiSelectMode ? 8 : 50) : 0, // Removed left margin
                                right: isSender ? 0 : 50,
                              ),
                              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6), // Slightly more compact
                              decoration: BoxDecoration(
                                gradient: (isSender && !prefController.hasCustomBubbleColors)
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF00F7FF), // Cyan Premium
                                          Color(0xFF00C6FF), // Blue Cyan
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: (isSender && !prefController.hasCustomBubbleColors)
                                    ? null
                                    : backgroundColor,
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(isSender ? radius : 16),
                                    topRight: Radius.circular(isSender ? 16 : radius),
                                    bottomLeft: Radius.circular(radius),
                                    bottomRight: Radius.circular(radius),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (message.isForwarded && !message.isDeleted)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 4),
                                          child: ForwardedBadge(isSender: isSender),
                                        ),
                                        if (isGroup && !isSender && !message.isDeleted)
                                          GestureDetector(
                                            onTap: onTapProfile,
                                            child: Padding(
                                              padding: const EdgeInsets.only(bottom: 2),
                                              child: Text(
                                                senderUser.fullname,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFFF9100), // Orange premium for text messages
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ),
                                      if (message.replyMessage != null)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: ReplyMessage(
                                            message: message.replyMessage!,
                                            senderName: isGroup
                                                ? group!.getMemberProfile(message.replyMessage!.senderId).fullname
                                                : user!.fullname,
                                            bgColor: message.isSender
                                                ? isDarkMode
                                                    ? Colors.black.withOpacity(0.2)
                                                    : Colors.white.withOpacity(0.3)
                                                : null,
                                            lineColor: message.isSender ? Colors.white : Colors.green[600],
                                            onTapReply: () => controller.navigateToReplyMessage(message.replyMessage!),
                                          ),
                                        ),
                                      _showMessageContent(profileUrl, backgroundColor),
                                    ],
                                  ),
                                  if (message.type != MessageType.text &&
                                      message.type != MessageType.image &&
                                      message.type != MessageType.video &&
                                      message.type != MessageType.gif)
                                    Positioned(
                                      bottom: -2,
                                      right: -2,
                                      child: ReadTimeStatus(
                                        message: message,
                                        isGroup: isGroup,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                    ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // Handle message type
  Widget _showMessageContent(String profileUrl, Color backgroundColor) {
    final bool isGroup = group != null;
    
    // DEBUG: Log para verificar el tipo de mensaje
    debugPrint('🔍 BubbleMessage._showMessageContent: msgId=${message.msgId}, type=${message.type}');
    
    // Check type
    switch (message.type) {
      case MessageType.text:
        // Show text msg
        return TextMessage(message, backgroundColor: backgroundColor);

      case MessageType.image:
        // Show image msg
        // Debug: Verificar que el mensaje es de tipo imagen - SIEMPRE
        print('🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️ BubbleMessage._showMessageContent: CREANDO ImageMessage 🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️');
        print('   - msgId: ${message.msgId}');
        print('   - fileUrl: ${message.fileUrl.isEmpty ? "VACÍO" : message.fileUrl.substring(0, message.fileUrl.length > 50 ? 50 : message.fileUrl.length)}...');
        print('   - fileUrl length: ${message.fileUrl.length}');
        print('   - fileUrl startsWith http: ${message.fileUrl.startsWith("http")}');
        print('   - fileUrl startsWith /: ${message.fileUrl.startsWith("/")}');
        debugPrint('🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️ BubbleMessage._showMessageContent: CREANDO ImageMessage 🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️🖼️');
        debugPrint('   - msgId: ${message.msgId}');
        debugPrint('   - fileUrl: ${message.fileUrl.isEmpty ? "VACÍO" : message.fileUrl.substring(0, message.fileUrl.length > 50 ? 50 : message.fileUrl.length)}...');
        debugPrint('   - fileUrl length: ${message.fileUrl.length}');
        debugPrint('   - fileUrl startsWith http: ${message.fileUrl.startsWith("http")}');
        debugPrint('   - fileUrl startsWith /: ${message.fileUrl.startsWith("/")}');
        
        // Obtener el mensaje actualizado del controlador para asegurar que tenemos el fileUrl más reciente
        final MessageController msgController = Get.find();
        Message currentMessage = message;
        try {
          final foundMessage = msgController.messages.firstWhere(
            (m) => m.msgId == message.msgId,
          );
          currentMessage = foundMessage;
          print('   - ✅ Mensaje actualizado encontrado en controlador');
          print('   - fileUrl actualizado: ${currentMessage.fileUrl.isEmpty ? "VACÍO" : currentMessage.fileUrl.substring(0, currentMessage.fileUrl.length > 50 ? 50 : currentMessage.fileUrl.length)}...');
          debugPrint('   - ✅ Mensaje actualizado encontrado en controlador');
          debugPrint('   - fileUrl actualizado: ${currentMessage.fileUrl.isEmpty ? "VACÍO" : currentMessage.fileUrl.substring(0, currentMessage.fileUrl.length > 50 ? 50 : currentMessage.fileUrl.length)}...');
        } catch (e) {
          print('   - ⚠️ Mensaje no encontrado en controlador, usando mensaje original');
          debugPrint('   - ⚠️ Mensaje no encontrado en controlador, usando mensaje original');
        }
        
        // Usar key basado en fileUrl para forzar reconstrucción cuando cambie
        final imageKey = currentMessage.fileUrl.isEmpty 
            ? '${currentMessage.msgId}_empty'
            : '${currentMessage.msgId}_${currentMessage.fileUrl.length > 100 ? currentMessage.fileUrl.substring(0, 100) : currentMessage.fileUrl}';
        print('   - Creando ImageMessage con key: $imageKey');
        print('   - fileUrl final: ${currentMessage.fileUrl.isEmpty ? "VACÍO" : currentMessage.fileUrl.substring(0, currentMessage.fileUrl.length > 100 ? 100 : currentMessage.fileUrl.length)}...');
        debugPrint('   - Creando ImageMessage con key: $imageKey');
        final imageWidget = ImageMessage(
          currentMessage, 
          isGroup: isGroup,
          key: ValueKey(imageKey),
        );
        print('   - ✅✅✅ ImageMessage creado exitosamente ✅✅✅');
        debugPrint('   - ✅✅✅ ImageMessage creado exitosamente ✅✅✅');
        return imageWidget;

      case MessageType.gif:
        // Show GIF msg
        return GifMessage(message, isGroup: isGroup);

      case MessageType.video:
        // Show video msg
        return VideoMessage(message, isGroup: isGroup);

      case MessageType.audio:
        // Show audio msg
        return AudioMessage(
          message: message,
          isSender: message.isSender,
        );

      case MessageType.doc:
        // Show document msg
        return DocumentMessage(
          message: message,
        );

      case MessageType.location:
        return LocationMessage(message);

      default:
        return const SizedBox.shrink();
    }
  }

  // Check if message is media type (image, video, gif, audio) to show without container
  bool _isMediaMessage() {
    return message.type == MessageType.image ||
           message.type == MessageType.video ||
           message.type == MessageType.gif ||
           message.type == MessageType.audio;
  }

  // Build forwarded info for media messages (images, videos, gifs, audio)
  Widget _buildForwardedMediaInfo() {
    // Use a simple approach without context dependency
    final bool isDarkMode = false; // Will be determined by the theme system
    
    // Get media type text in Spanish
    String mediaType;
    switch (message.type) {
      case MessageType.image:
        mediaType = 'Foto';
        break;
      case MessageType.video:
        mediaType = 'Video';
        break;
      case MessageType.gif:
        mediaType = 'GIF';
        break;
      case MessageType.audio:
        mediaType = 'Audio';
        break;
      default:
        mediaType = 'Media';
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Forwarded indicator with arrow
          Row(
            children: [
              Icon(
                Icons.redo,
                size: 14,
                color: isDarkMode ? Colors.white.withOpacity(0.6) : Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                'Reenviado',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white.withOpacity(0.6) : Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          // Media type label (like WhatsApp)
          Text(
            mediaType,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white.withOpacity(0.87) : Colors.black.withOpacity(0.87),
            ),
          ),
        ],
      ),
    );
  }
}
