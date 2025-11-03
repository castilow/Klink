import 'package:chat_messenger/config/theme_config.dart';
import 'package:flutter/material.dart';

class SelectionCircle extends StatelessWidget {
  const SelectionCircle({
    super.key,
    required this.isSelected,
    required this.onTap,
    required this.isVisible,
  });

  final bool isSelected;
  final bool isVisible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: primaryColor,
          width: 2,
        ),
        color: isSelected ? primaryColor : Colors.transparent,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: isSelected ? 1.0 : 0.0,
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}