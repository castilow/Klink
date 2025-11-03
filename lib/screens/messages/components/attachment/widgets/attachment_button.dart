import 'package:flutter/material.dart';
import 'package:chat_messenger/config/theme_config.dart';

class AttachmentButton extends StatelessWidget {
  const AttachmentButton({
    super.key,
    this.onPress,
    this.icon,
    this.title,
    this.color,
  });

  // Params
  final Function()? onPress;
  final IconData? icon;
  final String? title;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Button
        RawMaterialButton(
          onPressed: onPress,
          fillColor: isDarkMode ? const Color(0xFF2A2A2A) : color,
          padding: const EdgeInsets.all(16),
          shape: const CircleBorder(),
          elevation: 0.0,
          child: Icon(
            icon, 
            color: isDarkMode ? Colors.white : primaryColor,
          ),
        ),
        const SizedBox(height: 5),
        // Title
        Text(
          title ?? '',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
