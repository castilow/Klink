import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/models/message.dart';
import 'package:chat_messenger/screens/messages/controllers/message_controller.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:chat_messenger/models/group.dart';
import 'package:chat_messenger/screens/messages/components/bubbles/text_message.dart';
import 'package:chat_messenger/screens/messages/components/bubbles/image_message.dart';
import 'package:chat_messenger/screens/messages/components/bubbles/gif_message.dart';
import 'package:chat_messenger/screens/messages/components/bubbles/video_message.dart';
import 'package:chat_messenger/screens/messages/components/bubbles/audio_message.dart';
import 'package:chat_messenger/screens/messages/components/bubbles/document_message.dart';
import 'package:chat_messenger/screens/messages/components/bubbles/location_message.dart';
import 'package:chat_messenger/screens/messages/components/read_time_status.dart';
import 'package:chat_messenger/screens/messages/components/reply_message.dart';
import 'package:chat_messenger/screens/messages/components/forwarded_badge.dart';

/// --------- API ----------
Future<void> showMessageActionsOverlay({
  required BuildContext context,
  required Message message,
  required MessageController controller,
  required bool isSender,
  required Rect anchorRect, // rect DEL BUBBLE (contenedor incluido)
  User? user,
  Group? group,
}) async {
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'MessageActionsOverlay',
    barrierColor: Colors.transparent,
    pageBuilder: (context, a1, a2) {
      return Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            _BlurAroundRect(
              rect: anchorRect,
              onTapOutside: () => Navigator.of(context).pop(),
            ),
            // Preview: MISMO contenedor oficial (ancho/posición exactos)
            _AnchoredPreview(
              anchorRect: anchorRect,
              isSender: isSender,
              child: _OfficialMessageBubble(
                message: message,
                isSender: isSender,
                isGroup: group != null,
                user: user,
                group: group,
                showTimeForTypes: const {
                  MessageType.doc,
                  MessageType.audio,
                  MessageType.location,
                },
              ),
            ),
            // Panel de acciones
            _AnchoredActions(
              anchorRect: anchorRect,
              isSender: isSender,
              child: _ActionsCard(
                message: message,
                controller: controller,
                isSender: isSender,
              ),
            ),
          ],
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 200),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// --------- WIDGETS PRIVADOS ----------

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({
    required this.message,
    required this.controller,
    required this.isSender,
  });

  final Message message;
  final MessageController controller;
  final bool isSender;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = (isDark ? Colors.grey[900]! : Colors.white).withOpacity(0.90);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionTile(
            icon: Icons.reply_outlined,
            label: 'Responder',
            onTap: () {
              Navigator.of(context).pop();
              controller.replyToMessage(message);
            },
          ),
          if (message.type == MessageType.text)
            _ActionTile(
              icon: Icons.edit_outlined,
              label: 'Editar',
              onTap: () {
                Navigator.of(context).pop();
                controller.editMessage(message);
              },
            ),
          _ActionTile(
            icon: Icons.copy_outlined,
            label: 'Copiar',
            onTap: () async {
              Navigator.of(context).pop();
              if (message.textMsg.isNotEmpty) {
                await Clipboard.setData(ClipboardData(text: message.textMsg));
              }
            },
          ),
          _ActionTile(
            icon: Icons.redo_outlined,
            label: 'Reenviar',
            onTap: () {
              Navigator.of(context).pop();
              controller.forwardMessage(message);
            },
          ),
          _ActionTile(
            icon: Icons.delete_outline,
            label: 'Eliminar',
            isDestructive: true,
            onTap: () {
              Navigator.of(context).pop();
              // Usar el nuevo diálogo de eliminación
              _showDeleteMessageDialog(context, controller, message);
            },
          ),
          _ActionTile(
            icon: Icons.check_circle_outline,
            label: 'Seleccionar',
            onTap: () {
              Navigator.of(context).pop();
              controller.enterMultiSelectMode(message);
            },
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final Color textColor = isDestructive
        ? Colors.red
        : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500, color: textColor),
              ),
            ),
            const SizedBox(width: 16),
            Icon(icon, size: 22, color: isDestructive ? Colors.red : Colors.grey[700]),
          ],
        ),
      ),
    );
  }
}

class _AnchoredActions extends StatelessWidget {
  const _AnchoredActions({
    required this.anchorRect,
    required this.child,
    required this.isSender,
  });
  final Rect anchorRect;
  final Widget child;
  final bool isSender;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bool placeBelow = (media.size.height - anchorRect.bottom) >= (anchorRect.top);
    final double messageWidth = anchorRect.width;
    final double panelWidth = (messageWidth * 0.5).clamp(220.0, messageWidth);
    final double left = isSender ? (anchorRect.right - panelWidth) : anchorRect.left;

    return Positioned(
      left: left,
      width: panelWidth,
      top: placeBelow ? anchorRect.bottom + 1 : null,
      bottom: placeBelow ? null : (media.size.height - anchorRect.top) + 1,
      child: child,
    );
  }
}

class _AnchoredPreview extends StatelessWidget {
  const _AnchoredPreview({
    required this.anchorRect,
    required this.child,
    required this.isSender,
  });
  final Rect anchorRect;
  final Widget child;
  final bool isSender;

  @override
  Widget build(BuildContext context) {
    // Enclava exactamente al ancho del bubble oficial
    return Positioned(
      left: anchorRect.left,
      top: anchorRect.top,
      width: anchorRect.width,
      child: SizedBox(
        width: anchorRect.width,
        child: child,
      ),
    );
  }
}

/// ========== Contenedor OFICIAL del mensaje (igual para lista y preview) ==========
class _OfficialMessageBubble extends StatelessWidget {
  const _OfficialMessageBubble({
    required this.message,
    required this.isSender,
    required this.isGroup,
    required this.user,
    required this.group,
    required this.showTimeForTypes,
  });

  final Message message;
  final bool isSender;
  final bool isGroup;
  final User? user;
  final Group? group;
  final Set<MessageType> showTimeForTypes;

  @override
  Widget build(BuildContext context) {
    // Máximo ancho como en un chat típico (ajústalo si tu lista usa otro valor)
    final double maxW = MediaQuery.of(context).size.width * 0.78;

    // Contenido base por tipo
    Widget baseContent;
    switch (message.type) {
      case MessageType.text:
        baseContent = TextMessage(message);
        break;
      case MessageType.image:
        baseContent = ImageMessage(message, isGroup: isGroup);
        break;
      case MessageType.gif:
        baseContent = GifMessage(message, isGroup: isGroup);
        break;
      case MessageType.video:
        baseContent = VideoMessage(message, isGroup: isGroup);
        break;
      case MessageType.audio:
        baseContent = AudioMessage(message: message, isSender: message.isSender);
        break;
      case MessageType.doc:
        baseContent = DocumentMessage(message: message);
        break;
      case MessageType.location:
        baseContent = LocationMessage(message);
        break;
      default:
        baseContent = const SizedBox.shrink();
    }

    // Badges y reply (mismo orden que en tu lista)
    final List<Widget> header = [
      if (message.isForwarded && !message.isDeleted) ...[
        const ForwardedBadge(isSender: true),
        const SizedBox(height: 4),
      ],
      if (message.replyMessage != null) ...[
        ReplyMessage(
          message: message.replyMessage!,
          senderName: isGroup
              ? group!.getMemberProfile(message.replyMessage!.senderId).fullname
              : user!.fullname,
          bgColor: isSender ? null : null,
          lineColor: isSender ? Colors.white : Colors.green[600],
          onTapReply: () {},
        ),
        const SizedBox(height: 6),
      ],
    ];

    // ¿Tu lista envuelve textos con un Container verde/blanco? Aquí lo replicamos:
    final bool isMedia = {
      MessageType.image,
      MessageType.video,
      MessageType.gif,
      MessageType.audio,
    }.contains(message.type);

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bubble = isSender
        ? const Color(0xFFDCF8C6)
        : (isDark ? const Color(0xFF2A2A2A) : Colors.white);

    Widget bubbleContent;

    if (isMedia) {
      // Media: normalmente sin el contenedor de color, tal como en tu código
      bubbleContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [...header, baseContent],
      );
    } else {
      // Texto/otros: MISMO contenedor oficial (padding/boxShadow/borderRadius)
      bubbleContent = Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        decoration: BoxDecoration(
          color: bubble.withOpacity(0.98),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(!isSender ? 18 : 20),
            topRight: Radius.circular(isSender ? 18 : 20),
            bottomLeft: const Radius.circular(20),
            bottomRight: const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ...header,
            baseContent,
            if (showTimeForTypes.contains(message.type))
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: ReadTimeStatus(message: message, isGroup: isGroup),
                ),
              ),
          ],
        ),
      );
    }

    // Alineación izquierda/derecha EXACTA
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxW),
      child: Align(
        alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
        child: bubbleContent,
      ),
    );
  }
}

class _BlurAroundRect extends StatelessWidget {
  const _BlurAroundRect({required this.rect, required this.onTapOutside});

  final Rect rect;
  final VoidCallback onTapOutside;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Positioned.fill(
      child: GestureDetector(
        onTap: onTapOutside,
        child: Stack(
          children: [
            Positioned(left: 0, right: 0, top: 0, bottom: size.height - rect.top, child: _blurLayer()),
            Positioned(left: 0, right: 0, top: rect.bottom, bottom: 0, child: _blurLayer()),
            Positioned(left: 0, right: size.width - rect.left, top: rect.top, bottom: size.height - rect.bottom, child: _blurLayer()),
            Positioned(left: rect.right, right: 0, top: rect.top, bottom: size.height - rect.bottom, child: _blurLayer()),
          ],
        ),
      ),
    );
  }

  Widget _blurLayer() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
      child: Container(color: Colors.black.withOpacity(0.05)),
    );
  }
}

void _showDeleteMessageDialog(
  BuildContext context,
  MessageController controller,
  Message message,
) {
  // Verificar si el mensaje es muy antiguo (más de 1 hora)
  final bool isMessageOld = message.sentAt != null 
      ? DateTime.now().difference(message.sentAt!).inHours > 1
      : false;
  
  // Verificar permisos de eliminación
  final bool isOwnMessage = message.isSender;
  final bool isAlreadyDeleted = message.isDeleted && message.textMsg == 'deleted';
  
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 200),
        child: AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF1F2937) 
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 12,
          contentPadding: const EdgeInsets.all(24),
          title: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Eliminar mensaje',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAlreadyDeleted) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.orange,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Este mensaje ya fue eliminado.\n¿Quieres eliminarlo completamente?',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.orange[800],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (isOwnMessage && !isMessageOld) ...[
                Text(
                  '¿Cómo quieres eliminar este mensaje?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[300] 
                        : Colors.grey[700],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.visibility_off_outlined,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Eliminar para ti',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Solo tú verás el mensaje como eliminado',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.delete_forever_outlined,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Eliminar para todos',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Todos verán el mensaje como eliminado',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.visibility_off_outlined,
                        color: Colors.blue,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '¿Quieres eliminar este mensaje para ti?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Solo tú verás el mensaje como eliminado',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            Container(
              width: double.infinity,
              child: Column(
                children: [
                  if (isAlreadyDeleted) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          controller.selectedMessage.value = message;
                          controller.deleteMessageCompletely();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Eliminar completamente',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ] else if (isOwnMessage && !isMessageOld) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          controller.selectedMessage.value = message;
                          controller.deleteMsgForMe();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Eliminar para ti',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          controller.selectedMessage.value = message;
                          _showDeleteForEveryoneConfirmation(context, controller);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Eliminar para todos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          controller.selectedMessage.value = message;
                          controller.deleteMsgForMe();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Eliminar para ti',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey[400] 
                            : Colors.grey[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
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
    },
  );
}

void _showDeleteForEveryoneConfirmation(
  BuildContext context,
  MessageController controller,
) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 200),
        child: AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF1F2937) 
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 12,
          contentPadding: const EdgeInsets.all(24),
          title: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Eliminar para todos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.delete_forever_outlined,
                      color: Colors.red,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '¿Estás seguro de eliminar este mensaje para todos?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Todos los participantes verán "Este mensaje fue eliminado"',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey[400] 
                            : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Container(
              width: double.infinity,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        controller.softDeleteForEveryone();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete_forever_outlined,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Eliminar para todos',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey[400] 
                            : Colors.grey[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
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
    },
  );
}