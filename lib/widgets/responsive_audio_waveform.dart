import 'package:flutter/material.dart';
import 'dart:math' as math;

class ResponsiveAudioWaveform extends StatefulWidget {
  final bool isPlaying;
  final double currentPosition;
  final double duration;
  final Color? barColor;
  final double height;
  final int barCount;
  final bool showAnimation;

  const ResponsiveAudioWaveform({
    super.key,
    this.isPlaying = false,
    this.currentPosition = 0.0,
    this.duration = 1.0,
    this.barColor,
    this.height = 40.0,
    this.barCount = 20,
    this.showAnimation = true,
  });

  @override
  State<ResponsiveAudioWaveform> createState() => _ResponsiveAudioWaveformState();
}

class _ResponsiveAudioWaveformState extends State<ResponsiveAudioWaveform>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<double> _barHeights;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _generateWaveformData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _generateWaveformData() {
    final random = math.Random();
    _barHeights = List.generate(widget.barCount, (index) {
      // Generar patrón de audio realista
      double height = 0.0;
      final position = index / widget.barCount;
      
      // Patrón variado que simula audio real
      if (position < 0.1) {
        height = 0.2 + (position * 0.5);
      } else if (position < 0.2) {
        height = 0.1 + (position * 0.3);
      } else if (position < 0.3) {
        height = 0.6 + (position * 0.2);
      } else if (position < 0.4) {
        height = 0.3 + (position * 0.4);
      } else if (position < 0.5) {
        height = 0.8 + (position * 0.1);
      } else if (position < 0.6) {
        height = 0.4 + (position * 0.3);
      } else if (position < 0.7) {
        height = 0.7 + (position * 0.2);
      } else if (position < 0.8) {
        height = 0.2 + (position * 0.5);
      } else if (position < 0.9) {
        height = 0.5 + (position * 0.3);
      } else {
        height = 0.3 * (1.0 - position);
      }
      
      // Agregar variación aleatoria sutil
      height += random.nextDouble() * 0.15;
      
      // Asegurar valores seguros
      height = height.clamp(0.0, 1.0);
      if (height.isNaN || height.isInfinite) {
        height = 0.3;
      }
      
      return height;
    });
    
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void didUpdateWidget(ResponsiveAudioWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying && widget.showAnimation) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // Manejar valores seguros para evitar NaN o Infinity
    double currentPosition = 0.0;
    if (widget.duration > 0) {
      currentPosition = widget.currentPosition / widget.duration;
      if (currentPosition.isNaN || currentPosition.isInfinite) {
        currentPosition = 0.0;
      }
    }
    
    final currentIndex = (currentPosition * _barHeights.length).floor();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final totalBars = _barHeights.length;
        
        // Calcular dimensiones dinámicas basadas en el espacio disponible
        final maxBarWidth = math.min(4.0, availableWidth / (totalBars * 2));
        final barWidth = math.max(1.5, maxBarWidth);
        final spacing = math.max(1.0, barWidth * 0.5);
        
        // Calcular espaciado total
        final totalBarWidth = totalBars * barWidth;
        final totalSpacing = (totalBars - 1) * spacing;
        final remainingWidth = availableWidth - totalSpacing - totalBarWidth;
        final extraSpacing = remainingWidth / (totalBars + 1);
        
        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_barHeights.length, (index) {
              final baseHeight = _barHeights[index];
              final isActive = widget.isPlaying && index == currentIndex;
              final isPlayed = index < currentIndex;
              
              return AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  double barHeight = baseHeight * widget.height;
                  
                  // Animar las barras cuando está reproduciendo
                  if (widget.isPlaying && isActive && widget.showAnimation) {
                    barHeight *= 1.0 + (_animationController.value * 0.4);
                  }
                  
                  // Asegurar valores seguros
                  if (barHeight.isNaN || barHeight.isInfinite) {
                    barHeight = widget.height * 0.3;
                  }
                  barHeight = barHeight.clamp(2.0, widget.height);
                  
                  return Container(
                    width: barWidth,
                    height: barHeight,
                    margin: EdgeInsets.symmetric(horizontal: extraSpacing / 2),
                    decoration: BoxDecoration(
                      color: _getBarColor(index, isActive, isPlayed),
                      borderRadius: BorderRadius.circular(barWidth / 2),
                    ),
                  );
                },
              );
            }),
          ),
        );
      },
    );
  }

  Color _getBarColor(int index, bool isActive, bool isPlayed) {
    final baseColor = widget.barColor ?? const Color(0xFF4CAF50);
    
    if (isActive) {
      return baseColor;
    } else if (isPlayed) {
      return baseColor.withOpacity(0.8);
    } else {
      return baseColor.withOpacity(0.6);
    }
  }
} 