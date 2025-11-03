import 'package:flutter/material.dart';
import 'package:chat_messenger/config/theme_config.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
    this.size = 25,
    this.color = primaryColor,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Indicador sin animación: un punto estático
    final double dotSize = size.clamp(8, 60);
    return Container(
      width: dotSize,
      height: dotSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
