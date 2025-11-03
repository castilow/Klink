import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:chat_messenger/components/svg_icon.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/helpers/app_helper.dart';
import 'package:chat_messenger/helpers/dialog_helper.dart';
import 'package:chat_messenger/models/message.dart';
import 'package:chat_messenger/screens/messages/controllers/message_controller.dart';
import 'package:get/get.dart';

class MsgAppBarTools extends StatelessWidget implements PreferredSizeWidget {
  const MsgAppBarTools({super.key});

  @override
  Widget build(BuildContext context) {
    final MessageController controller = Get.find();

    const Size iconSize = Size(23, 23);

    return Obx(() {
      final Message message = controller.selectedMessage.value!;
      final bool isTextMsg = message.type == MessageType.text;

      return AppBar(
        leading: IconButton(
          onPressed: () => controller.selectedMessage.value = null,
          icon: const Icon(Icons.arrow_back_ios_new_sharp, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        actions: [
          // <-- Reply message -->
          if (!message.isDeleted)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton(
                onPressed: () => controller.replyToMessage(message),
                icon: SvgIcon(
                  'assets/icons/reply.svg',
                  width: iconSize.width,
                  height: iconSize.height,
                  color: Colors.white,
                ),
              ),
            ),

          // <-- Delete message -->
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: () {
                _showDeleteMessageDialog(context, controller, message);
              },
              icon: const Icon(
                IconlyBold.delete,
                color: Colors.white,
                size: 25,
              ),
            ),
          ),

          // <-- Forward message -->
          if (!message.isDeleted)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton(
                onPressed: () => controller
                    .forwardMessage(message)
                    .then((_) => controller.clearSelectedMsg()),
                icon: SvgIcon(
                  'assets/icons/forward.svg',
                  width: iconSize.width,
                  height: iconSize.height,
                  color: Colors.white,
                ),
              ),
            ),

          // Copy message / Download the file
          if (!message.isDeleted)
            if (message.type != MessageType.location)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: IconButton(
                  onPressed: () {
                    // Check message type
                    if (isTextMsg) {
                      // <-- Copy text message -->
                      Clipboard.setData(ClipboardData(text: message.textMsg))
                          .then((_) => controller.clearSelectedMsg());
                      DialogHelper.showSnackbarMessage(
                          SnackMsgType.success, 'message_copied'.tr,
                          duration: 1);
                    } else {
                      //
                      // <-- Download the file -->
                      //
                      AppHelper.downloadFile(message.fileUrl);
                    }
                  },
                  icon: Icon(isTextMsg ? Icons.copy : Icons.download,
                      color: Colors.white, size: 25),
                ),
              ),
        ],
      );
    });
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
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
