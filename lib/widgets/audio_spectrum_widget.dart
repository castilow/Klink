import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'dart:math' as math;

class AudioSpectrumWidget extends StatefulWidget {
  final String audioPath;
  final bool isPlaying;
  final double currentPosition;
  final double duration;
  final Color? barColor;
  final Color? backgroundColor;
  final double height;
  final int barCount;
  final bool showWaveform;
  final bool showBars;

  const AudioSpectrumWidget({
    super.key,
    required this.audioPath,
    this.isPlaying = false,
    this.currentPosition = 0.0,
    this.duration = 1.0,
    this.barColor,
    this.backgroundColor,
    this.height = 60.0,
    this.barCount = 20,
    this.showWaveform = true,
    this.showBars = true,
  });

  @override
  State<AudioSpectrumWidget> createState() => _AudioSpectrumWidgetState();
}

class _AudioSpectrumWidgetState extends State<AudioSpectrumWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  List<double> _waveformData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _loadWaveformData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadWaveformData() async {
    // Por ahora, usamos datos simulados ya que la API de audio_waveforms
    // puede variar entre versiones
    _generateSimulatedData();
  }

  void _generateSimulatedData() {
    final random = math.Random();
    _waveformData = List.generate(widget.barCount, (index) {
      // Simular patrón de audio más variado como en la imagen
      double amplitude = 0.0;
      final position = index / widget.barCount;
      
      // Patrón más variado con diferentes alturas
      if (position < 0.1) {
        amplitude = 0.3 + (position * 0.4);
      } else if (position < 0.2) {
        amplitude = 0.1 + (position * 0.2);
      } else if (position < 0.3) {
        amplitude = 0.6 + (position * 0.3);
      } else if (position < 0.4) {
        amplitude = 0.2 + (position * 0.1);
      } else if (position < 0.5) {
        amplitude = 0.8 + (position * 0.1);
      } else if (position < 0.6) {
        amplitude = 0.4 + (position * 0.2);
      } else if (position < 0.7) {
        amplitude = 0.7 + (position * 0.2);
      } else if (position < 0.8) {
        amplitude = 0.3 + (position * 0.1);
      } else if (position < 0.9) {
        amplitude = 0.5 + (position * 0.3);
      } else {
        amplitude = 0.2 * (1.0 - position);
      }
      
      // Agregar variaciones aleatorias más sutil
      amplitude += random.nextDouble() * 0.1;
      
      // Asegurar valores seguros
      amplitude = amplitude.clamp(0.0, 1.0);
      if (amplitude.isNaN || amplitude.isInfinite) {
        amplitude = 0.3;
      }
      
      return amplitude;
    });
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void didUpdateWidget(AudioSpectrumWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (widget.showWaveform) ...[
            Expanded(
              flex: 2,
              child: _buildWaveform(),
            ),
            const SizedBox(width: 16),
          ],
          if (widget.showBars) ...[
            Expanded(
              flex: 3,
              child: _buildSpectrumBars(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    // Por ahora, mostramos un placeholder para el waveform
    // ya que la API de audio_waveforms puede variar
    return Container(
      width: MediaQuery.of(context).size.width * 0.4,
      height: widget.height,
      decoration: BoxDecoration(
        color: (widget.barColor ?? Theme.of(context).primaryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          Icons.graphic_eq,
          color: widget.barColor ?? Theme.of(context).primaryColor,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildSpectrumBars() {
    final currentPosition = widget.currentPosition / widget.duration;
    final currentIndex = (currentPosition * _waveformData.length).floor();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(_waveformData.length, (index) {
        final amplitude = _waveformData[index];
        final isActive = widget.isPlaying && index == currentIndex;
        final isPlayed = index < currentIndex;
        
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            double barHeight = amplitude * widget.height * 0.8;
            
            // Animar las barras cuando está reproduciendo
            if (widget.isPlaying && isActive) {
              barHeight *= 1.0 + (_animationController.value * 0.3);
            }
            
            return Container(
              width: 2,
              height: barHeight,
              decoration: BoxDecoration(
                color: _getBarColor(index, isActive, isPlayed),
                borderRadius: BorderRadius.circular(1),
              ),
            );
          },
        );
      }),
    );
  }

  Color _getBarColor(int index, bool isActive, bool isPlayed) {
    // Usar verde como color base para el espectro
    final baseColor = const Color(0xFF4CAF50);
    
    if (isActive) {
      return baseColor;
    } else if (isPlayed) {
      return baseColor.withOpacity(0.8);
    } else {
      return baseColor.withOpacity(0.6);
    }
  }
}

// Widget simplificado para mostrar solo las barritas del espectro
class AudioSpectrumBars extends StatefulWidget {
  final bool isPlaying;
  final double currentPosition;
  final double duration;
  final Color? barColor;
  final double height;
  final int barCount;

  const AudioSpectrumBars({
    super.key,
    this.isPlaying = false,
    this.currentPosition = 0.0,
    this.duration = 1.0,
    this.barColor,
    this.height = 40.0,
    this.barCount = 15,
  });

  @override
  State<AudioSpectrumBars> createState() => _AudioSpectrumBarsState();
}

class _AudioSpectrumBarsState extends State<AudioSpectrumBars>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<double> _barHeights;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _generateBarHeights();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _generateBarHeights() {
    final random = math.Random();
    _barHeights = List.generate(widget.barCount, (index) {
      // Simular patrón de audio más realista como en la imagen
      double height = 0.0;
      final position = index / widget.barCount;
      
      // Patrón más variado con alturas diferentes
      if (position < 0.1) {
        height = 0.3 + (position * 0.4);
      } else if (position < 0.2) {
        height = 0.1 + (position * 0.2);
      } else if (position < 0.3) {
        height = 0.6 + (position * 0.3);
      } else if (position < 0.4) {
        height = 0.2 + (position * 0.1);
      } else if (position < 0.5) {
        height = 0.8 + (position * 0.1);
      } else if (position < 0.6) {
        height = 0.4 + (position * 0.2);
      } else if (position < 0.7) {
        height = 0.7 + (position * 0.2);
      } else if (position < 0.8) {
        height = 0.3 + (position * 0.1);
      } else if (position < 0.9) {
        height = 0.5 + (position * 0.3);
      } else {
        height = 0.2 * (1.0 - position);
      }
      
      // Agregar variación aleatoria más sutil
      height += random.nextDouble() * 0.1;
      
      // Asegurar valores seguros
      height = height.clamp(0.0, 1.0);
      if (height.isNaN || height.isInfinite) {
        height = 0.3;
      }
      
      return height;
    });
  }

  @override
  void didUpdateWidget(AudioSpectrumBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Manejar valores seguros para evitar NaN o Infinity
    double currentPosition = 0.0;
    if (widget.duration > 0) {
      currentPosition = widget.currentPosition / widget.duration;
      if (currentPosition.isNaN || currentPosition.isInfinite) {
        currentPosition = 0.0;
      }
    }
    
    final currentIndex = (currentPosition * _barHeights.length).floor();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(_barHeights.length, (index) {
        final baseHeight = _barHeights[index];
        final isActive = widget.isPlaying && index == currentIndex;
        final isPlayed = index < currentIndex;
        
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            double barHeight = baseHeight * widget.height;
            
            // Animar las barras activas
            if (widget.isPlaying && isActive) {
              barHeight *= 1.0 + (_animationController.value * 0.4);
            }
            
            // Asegurar valores seguros
            if (barHeight.isNaN || barHeight.isInfinite) {
              barHeight = widget.height * 0.3;
            }
            barHeight = barHeight.clamp(2.0, widget.height);
            
            return Container(
              width: 2,
              height: barHeight,
              decoration: BoxDecoration(
                color: _getBarColor(index, isActive, isPlayed),
                borderRadius: BorderRadius.circular(1),
              ),
            );
          },
        );
      }),
    );
  }

  Color _getBarColor(int index, bool isActive, bool isPlayed) {
    // Usar verde como color base para el espectro
    final baseColor = const Color(0xFF4CAF50);
    
    if (isActive) {
      return baseColor;
    } else if (isPlayed) {
      return baseColor.withOpacity(0.8);
    } else {
      return baseColor.withOpacity(0.6);
    }
  }
} 