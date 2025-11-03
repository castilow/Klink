import 'package:flutter/material.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/models/group.dart';
import 'package:chat_messenger/models/message.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:chat_messenger/plugins/swipeto/swipe_to.dart';
import 'package:chat_messenger/screens/messages/components/bubbles/location_message.dart';
import 'package:chat_messenger/screens/messages/components/reply_message.dart';
import 'package:chat_messenger/screens/messages/components/reaction_panel.dart';
import 'package:chat_messenger/screens/messages/components/message_reactions.dart';
import 'package:chat_messenger/screens/messages/controllers/message_controller.dart';
import 'package:chat_messenger/theme/app_theme.dart';
import 'package:get/get.dart';

import 'bubbles/audio_message.dart';
import 'bubbles/document_message.dart';
import 'bubbles/gif_message.dart';
import 'bubbles/image_message.dart';
import 'bubbles/text_message.dart';
import 'bubbles/video_message.dart';
import 'forwarded_badge.dart';
import 'read_time_status.dart';

class EnhancedBubbleMessage extends StatefulWidget {
  const EnhancedBubbleMessage({
    super.key,
    required this.message,
    required this.onTapProfile,
    required this.onReplyMessage,
    required this.user,
    required this.group,
    required this.onReactionTap,
  });

  final Message message;
  final User? user;
  final Group? group;
  final Function()? onTapProfile;
  final Function()? onReplyMessage;
  final Function(String emoji) onReactionTap;

  @override
  State<EnhancedBubbleMessage> createState() => _EnhancedBubbleMessageState();
}

class _EnhancedBubbleMessageState extends State<EnhancedBubbleMessage>
    with TickerProviderStateMixin {
  late AnimationController _bubbleAnimationController;
  late AnimationController _reactionAnimationController;
  late Animation<double> _bubbleSlideAnimation;
  late Animation<double> _bubbleOpacityAnimation;
  late Animation<Offset> _reactionSlideAnimation;
  
  bool _showReactionPanel = false;
  OverlayEntry? _reactionOverlay;

  @override
  void initState() {
    super.initState();
    
    _bubbleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _reactionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _bubbleSlideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bubbleAnimationController,
      curve: Curves.easeOut,
    ));
    
    _bubbleOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bubbleAnimationController,
      curve: Curves.easeOut,
    ));
    
    _reactionSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _reactionAnimationController,
      curve: Curves.elasticOut,
    ));
    
    // Start animation
    _bubbleAnimationController.forward();
  }

  @override
  void dispose() {
    _bubbleAnimationController.dispose();
    _reactionAnimationController.dispose();
    _hideReactionPanel();
    super.dispose();
  }

  void _showReactionPanelOverlay() {
    if (_reactionOverlay != null) return;
    
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    
    _reactionOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: widget.message.isSender ? null : position.dx,
        right: widget.message.isSender ? MediaQuery.of(context).size.width - position.dx - size.width : null,
        top: position.dy - 60,
        child: SlideTransition(
          position: _reactionSlideAnimation,
          child: ReactionPanel(
            message: widget.message,
            onReactionTap: (emoji) {
              widget.onReactionTap(emoji);
              _hideReactionPanel();
            },
            onReactionLongPress: () {
              // Show more emoji options
              _hideReactionPanel();
            },
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_reactionOverlay!);
    _reactionAnimationController.forward();
    setState(() => _showReactionPanel = true);
  }
  
  void _hideReactionPanel() {
    if (_reactionOverlay != null) {
      _reactionAnimationController.reverse().then((_) {
        _reactionOverlay?.remove();
        _reactionOverlay = null;
      });
      setState(() => _showReactionPanel = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = AppTheme.of(context).isDarkMode;
    final bool isSender = widget.message.isSender;
    
    // Colores más naturales - Verde claro para todos los mensajes
    final Color backgroundColor = isSender
        ? const Color(0xFFDCF8C6) // Verde claro para emisor (como WhatsApp)
        : isDarkMode
            ? const Color(0xFF2A2A2A)
            : const Color(0xFFDCF8C6); // Verde claro para receptor también
    
    final Color textColor = isSender
        ? Colors.white
        : isDarkMode
            ? Colors.white
            : Colors.black87;

    return Container(
      margin: EdgeInsets.only(
        top: 6,
        left: isSender ? 60 : 0,
        right: isSender ? 0 : 60,
      ),
      child: Column(
        crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Mensaje principal
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(!isSender ? 20 : 20),
                topRight: Radius.circular(isSender ? 20 : 20),
                bottomLeft: const Radius.circular(20),
                bottomRight: const Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nombre del remitente en grupos
                if (widget.group != null && !isSender && !widget.message.isDeleted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      widget.group!.getMemberProfile(widget.message.senderId).fullname,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ColorGenerator.getColorForSender(widget.message.senderId),
                      ),
                    ),
                  ),
                
                // Mensaje de respuesta
                if (widget.message.replyMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSender 
                          ? Colors.white.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSender 
                            ? Colors.white.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Respondiendo a ${widget.message.replyMessage!.isSender ? 'ti' : widget.group?.getMemberProfile(widget.message.replyMessage!.senderId).fullname ?? 'usuario'}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.message.replyMessage!.textMsg,
                          style: TextStyle(
                            fontSize: 13,
                            color: textColor.withOpacity(0.8),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                
                // Contenido del mensaje
                _showMessageContent(''),
              ],
            ),
          ),
          
          // Estado del mensaje
          Padding(
            padding: EdgeInsets.only(
              top: 4,
              right: isSender ? 8 : 0,
              left: isSender ? 0 : 8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSender) ...[
                  Text(
                    widget.message.sentAt?.formatTime ?? '',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    widget.message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: widget.message.isRead ? primaryColor : Colors.grey[500],
                  ),
                ] else ...[
                  Text(
                    widget.message.sentAt?.formatTime ?? '',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Reacciones
          if (widget.message.reactions != null && widget.message.reactions!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: MessageReactions(
                message: widget.message,
                onReactionTap: widget.onReactionTap,
                isSender: isSender,
              ),
            ),
        ],
      ),
    );
  }

  Widget _showMessageContent(String profileUrl) {
    switch (widget.message.type) {
      case MessageType.text:
        return TextMessage(widget.message);
      case MessageType.image:
        return ImageMessage(widget.message);
      case MessageType.gif:
        return GifMessage(widget.message);
      case MessageType.audio:
        return AudioMessage(widget.message, profileUrl: profileUrl);
      case MessageType.video:
        return VideoMessage(widget.message);
      case MessageType.doc:
        return DocumentMessage(message: widget.message);
      case MessageType.location:
        return LocationMessage(widget.message);
      default:
        return const SizedBox.shrink();
    }
  }
}

// Color generator for sender names
class ColorGenerator {
  static final List<Color> _colors = [
    const Color(0xFF1F8B4C),
    const Color(0xFF206694),
    const Color(0xFF71368A),
    const Color(0xFFAD1457),
    const Color(0xFFC53030),
    const Color(0xFFD97706),
    const Color(0xFF9D4EDD),
    const Color(0xFF2B6CB0),
  ];

  static Color getColorForSender(String senderId) {
    final hash = senderId.hashCode;
    return _colors[hash.abs() % _colors.length];
  }
} 