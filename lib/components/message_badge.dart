import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/models/message.dart';
import 'package:chat_messenger/screens/messages/components/rich_text_message.dart';
import 'package:get/get.dart';

class MessageBadge extends StatelessWidget {
  const MessageBadge({
    super.key,
    required this.type,
    required this.textMsg,
    this.maxLines,
    this.textStyle,
  });

  final MessageType type;
  final String textMsg;
  final TextStyle? textStyle;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      MessageType.text => rowInfo(title: textMsg),
      MessageType.image => rowInfo(icon: IconlyBold.image, title: 'photo'.tr),
      MessageType.gif => rowInfo(icon: Icons.gif_box, title: 'GIF'),
      MessageType.video => rowInfo(icon: IconlyBold.video, title: 'video'.tr),
      MessageType.doc =>
        rowInfo(icon: IconlyBold.document, title: 'document'.tr),
      MessageType.location =>
        rowInfo(icon: IconlyBold.location, title: 'location'.tr),
      _ => const SizedBox.shrink(),
    };
  }

  Widget rowInfo({
    IconData? icon,
    required String title,
  }) {
    return Row(
      children: [
        if (icon != null)
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Icon(icon, size: 20, color: greyColor),
          ),
        Expanded(
          child: RichTexMessage(
            text: title,
            maxLines: maxLines,
            defaultStyle: textStyle ??
                const TextStyle(
                  fontSize: 16,
                  overflow: TextOverflow.ellipsis,
                ),
          ),
        ),
      ],
    );
  }
}

class MessageDeleted extends StatelessWidget {
  const MessageDeleted({
    super.key,
    required this.isSender,
    this.iconColor,
    this.iconSize,
    this.style,
  });

  final bool isSender;
  final Color? iconColor;
  final double? iconSize;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final String deletedMsg = isSender
        ? 'you_deleted_this_message'.tr
        : 'this_message_was_deleted'.tr;
    
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color defaultIconColor = iconColor ?? 
        (isDarkMode ? Colors.grey[500]! : Colors.grey[600]!);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSender 
            ? (isDarkMode ? Colors.grey[800]!.withValues(alpha: 0.4) : Colors.grey[100]!.withValues(alpha: 0.9))
            : (isDarkMode ? Colors.grey[700]!.withValues(alpha: 0.4) : Colors.grey[50]!.withValues(alpha: 0.9)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey[600]! : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: defaultIconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              size: iconSize ?? 18,
              color: defaultIconColor,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              deletedMsg,
              style: style?.copyWith(
                fontStyle: FontStyle.italic,
                color: style?.color ?? defaultIconColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ) ?? TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: defaultIconColor,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
