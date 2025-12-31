import 'package:flutter/material.dart';

/// Widget que muestra tres puntos animados para indicar que la IA está escribiendo
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({
    super.key,
    this.color,
    this.size = 8.0,
  });

  final Color? color;
  final double size;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Crear animaciones escalonadas para cada punto
    _animations = List.generate(3, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.25,
            0.5 + (index * 0.25),
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Colors.grey[600]!;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.only(
                right: index < 2 ? 4.0 : 0,
              ),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: color.withOpacity(
                  0.3 + (_animations[index].value * 0.7),
                ),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}















