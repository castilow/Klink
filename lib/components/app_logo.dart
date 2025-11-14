import 'package:flutter/material.dart';
import 'package:chat_messenger/config/theme_config.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.width, this.height, this.color});

  final double? width;
  final double? height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = width ?? height ?? (screenWidth * 0.3);
    
    // Detectar el tema actual
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;

    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(isDarkMode ? 0.2 : 0.1),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/app_icon.png',
          width: logoSize,
          height: logoSize,
          fit: BoxFit.cover,
          // Si se proporciona un color, lo aplica; si no, usa el original
          color: color,
          colorBlendMode: color != null ? BlendMode.srcIn : null,
        ),
      ),
    );
  }
}
