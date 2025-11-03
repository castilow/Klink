import 'package:flutter/material.dart';
import 'package:chat_messenger/screens/messages/controllers/message_controller.dart';
import 'package:chat_messenger/helpers/dialog_helper.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/components/svg_icon.dart';

class MultiSelectBottomActions extends StatelessWidget {
  final MessageController controller;

  const MultiSelectBottomActions({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isMultiSelectMode.value || controller.selectedCount == 0) {
        return const SizedBox.shrink();
      }

      final bool kbOpen = MediaQuery.of(context).viewInsets.bottom > 0;

      return Container(
        color: Colors.white.withOpacity(0.90),
        child: SafeArea(
          top: false,
          bottom: !kbOpen,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 6.0,
              bottom: kbOpen ? 0.0 : 40.0, // igual que la barra de mensajes
            ),
            child: SizedBox(
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Eliminar (izquierda)
                  _buildActionButton(
                    context,
                    icon: const SvgIcon(
                      'assets/icons/streamline-ultimate--bin-1.svg',
                      width: 28,
                      height: 28,
                      color: Colors.red,
                    ),
                    onTap: () => _showDeleteConfirmation(context),
                  ),
                  // Compartir (centro)
                  _buildActionButton(
                    context,
                    icon: const SvgIcon(
                      'assets/icons/famicons--share-outline.svg',
                      width: 28,
                      height: 28,
                      color: Color(0xFF00A884),
                    ),
                    onTap: () {},
                  ),
                  // Reenviar (derecha)
                  _buildActionButton(
                    context,
                    icon: const SvgIcon(
                      'assets/icons/icon-park-twotone--share-two.svg',
                      width: 28,
                      height: 28,
                      color: Color(0xFF00A884),
                    ),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildActionButton(
    BuildContext context, {
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: icon,
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    DialogHelper.showAlertDialog(
      title: const Text('Eliminar mensajes'),
      content: Text(
        '¿Estás seguro de que quieres eliminar ${controller.selectedCount} mensaje${controller.selectedCount != 1 ? 's' : ''}?'
      ),
      actionText: 'Eliminar',
      action: () {
        Get.back();
        controller.deleteSelectedMessages();
      },
    );
  }

  void _forwardSelectedMessages() {}

  void _shareSelectedMessages() {}
} 