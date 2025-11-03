import 'package:flutter/material.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/screens/messages/controllers/message_controller.dart';
import 'package:get/get.dart';

class MultiSelectAppBar extends StatelessWidget implements PreferredSizeWidget {
  final MessageController controller;

  const MultiSelectAppBar({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isMultiSelectMode.value) {
        return const SizedBox.shrink();
      }

      final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
      return AppBar(
        backgroundColor: isDarkMode ? darkThemeBgColor : Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: TextButton(
            onPressed: () => _showClearChatConfirmation(context),
            child: const Text(
              'Vaciar chat',
              style: TextStyle(
                color: Color(0xFF00A884),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        leadingWidth: 120, // Aumentar espacio para asegurar que "Vaciar chat" se muestre completo
        title: Text(
          '${controller.selectedCount} seleccionado${controller.selectedCount != 1 ? 's' : ''}',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => controller.exitMultiSelectMode(),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: Color(0xFF00A884),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    });
  }

  void _showClearChatConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Vaciar chat'),
          content: const Text(
            '¿Estás seguro de que quieres eliminar todos los mensajes de este chat? Esta acción no se puede deshacer.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearAllMessages();
              },
              child: const Text(
                'Vaciar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _clearAllMessages() {
    // TODO: Implementar lógica para vaciar todo el chat
    print('Vaciar todo el chat');
    controller.exitMultiSelectMode();
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}