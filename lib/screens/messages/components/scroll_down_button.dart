import 'package:chat_messenger/components/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:chat_messenger/theme/app_theme.dart';

class ScrollDownButton extends StatelessWidget {
  const ScrollDownButton({
    super.key,
    required this.onPress,
  });

  // Params
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = AppTheme.of(context).isDarkMode;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100), // Animación rápida como Telegram
      curve: Curves.easeOutCubic,
      child: Material(
        elevation: 12.0, // Mayor elevación para estar por encima de todo
        shape: const CircleBorder(),
        shadowColor: Colors.black.withOpacity(0.3),
        child: Container(
          width: 40, // Más pequeño (antes 48)
          height: 40, // Más pequeño (antes 48) 
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 6, // Reducido para un botón más pequeño
                offset: const Offset(0, 3),
                spreadRadius: 0,
              ),
            ],
            border: Border.all(
              color: isDarkMode 
                ? Colors.white.withOpacity(0.1) 
                : Colors.grey.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPress,
              borderRadius: BorderRadius.circular(20), // Ajustado al nuevo tamaño
              child: Center(
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: 22, // Más pequeño (antes 28)
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
