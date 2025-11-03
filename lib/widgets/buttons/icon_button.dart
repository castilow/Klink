import 'package:flutter/material.dart';

class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final double size;

  const CustomIconButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.color = Colors.white,
    this.size = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        icon,
        color: color,
        size: size,
      ),
      onPressed: onPressed,
    );
  }
} 