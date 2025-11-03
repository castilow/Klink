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

    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
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
        ),
      ),
    );
  }
}
