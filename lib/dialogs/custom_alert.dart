import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/config/theme_config.dart';

class CustomAlert extends StatelessWidget {
  const CustomAlert({
    super.key,
    required this.title,
    this.titleColor = primaryColor,
    this.icon,
    this.content,
    this.actionText,
    this.action,
    this.showCancelButton = true,
    this.barrierDismissible = true,
    this.cancelAction,
  });

  final Widget title;
  final Color titleColor;
  final Widget? icon, content;
  final String? actionText;
  final Function()? action;
  final Function()? cancelAction;
  final bool showCancelButton, barrierDismissible;

  @override
  Widget build(BuildContext context) {
    final actionsStyle =
        TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: titleColor);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(defaultRadius * 2)),
      ),
      title: Row(
        children: [
          icon ?? const SizedBox.shrink(),
          if (icon != null) const SizedBox(width: 8),
          Expanded(child: title),
        ],
      ),
      titleTextStyle:
          Theme.of(context).textTheme.titleLarge!.copyWith(color: titleColor),
      content: content != null ? DefaultTextStyle(
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        child: content!,
      ) : null,
      actions: [
        if (showCancelButton)
          TextButton(
            onPressed: cancelAction ?? () => Get.back(),
            child: Text('CANCEL'.tr,
                style: actionsStyle.copyWith(color: isDarkMode ? Colors.grey[400] : greyColor)),
          ),
        if (actionText != null)
          TextButton(
            onPressed: action,
            child: Text(actionText!, style: actionsStyle),
          ),
      ],
    );
  }
}
