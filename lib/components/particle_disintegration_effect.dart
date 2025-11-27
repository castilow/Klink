import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A widget that can disintegrate its child into particles.
/// Uses Overlay to ensure particles are not clipped by parent widgets.
class ParticleDisintegrationEffect extends StatefulWidget {
  final Widget child;
  final bool trigger;
  final Duration duration;
  final VoidCallback? onAnimationComplete;

  const ParticleDisintegrationEffect({
    super.key,
    required this.child,
    required this.trigger,
    this.duration = const Duration(milliseconds: 700),
    this.onAnimationComplete,
  });

  @override
  State<ParticleDisintegrationEffect> createState() =>
      _ParticleDisintegrationEffectState();
}

class _ParticleDisintegrationEffectState
    extends State<ParticleDisintegrationEffect> with SingleTickerProviderStateMixin {
  final GlobalKey _globalKey = GlobalKey();
  late AnimationController _controller;
  OverlayEntry? _overlayEntry;
  bool _isDisintegrating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _removeOverlay();
        widget.onAnimationComplete?.call();
      }
    });

    // Check if triggered initially
    if (widget.trigger) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startDisintegration();
      });
    }
  }

  @override
  void didUpdateWidget(ParticleDisintegrationEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger && !_isDisintegrating) {
      debugPrint('💥 ParticleDisintegrationEffect triggered!');
      _startDisintegration();
    }
  }

  Future<void> _startDisintegration() async {
    if (_isDisintegrating) return;

    try {
      debugPrint('📸 Capturing widget for disintegration...');
      // 1. Capture the widget as an image
      final renderObject = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (renderObject == null) {
        debugPrint('❌ RenderRepaintBoundary not found');
        return;
      }

      // Ensure the boundary has been laid out and painted
      if (renderObject.debugNeedsPaint) {
        await Future.delayed(Duration.zero);
      }

      final pixelRatio = MediaQuery.of(context).devicePixelRatio;
      final image = await renderObject.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

      if (byteData == null) {
        debugPrint('❌ Failed to get byte data');
        return;
      }

      // 2. Get position and size for the overlay
      final vector = renderObject.getTransformTo(null).getTranslation();
      final offset = Offset(vector.x, vector.y);
      final size = renderObject.paintBounds.size;

      debugPrint('✨ Creating particles overlay at $offset with size $size');

      // 3. Generate particles
      final particles = _generateParticles(image, byteData);

      // 4. Create and insert Overlay
      _createOverlay(image, particles, offset, size);

      setState(() {
        _isDisintegrating = true;
      });

      // 5. Start animation
      _controller.forward();
    } catch (e) {
      debugPrint('❌ Error starting disintegration: $e');
      widget.onAnimationComplete?.call();
    }
  }

  List<_Particle> _generateParticles(ui.Image image, ByteData bytes) {
    final width = image.width;
    final height = image.height;
    final particles = <_Particle>[];
    final random = Random();
    const int step = 3; 

    for (int y = 0; y < height; y += step) {
      for (int x = 0; x < width; x += step) {
        final offset = (y * width + x) * 4;
        if (offset + 3 >= bytes.lengthInBytes) continue;

        final r = bytes.getUint8(offset);
        final g = bytes.getUint8(offset + 1);
        final b = bytes.getUint8(offset + 2);
        final a = bytes.getUint8(offset + 3);

        if (a < 20) continue;

        final color = Color.fromARGB(a, r, g, b);
        
        // Explosion effect: move right and disperse
        final vx = (random.nextDouble() * 2.0 + 0.5) * 60; 
        final vy = (random.nextDouble() - 0.5) * 40;

        particles.add(_Particle(
          position: Offset(x.toDouble(), y.toDouble()),
          color: color,
          velocity: Offset(vx, vy),
          size: (random.nextDouble() * 2 + 1),
          randomDelay: random.nextDouble() * 0.2,
        ));
      }
    }
    return particles;
  }

  void _createOverlay(ui.Image image, List<_Particle> particles, Offset offset, Size size) {
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy,
        width: size.width + 200, // Allow extra space for particles to fly
        height: size.height + 100,
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _ParticlePainter(
                  particles: particles,
                  progress: _controller.value,
                  image: image,
                ),
                size: Size(size.width, size.height),
              );
            },
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.trigger) {
      debugPrint('🎨 ParticleDisintegrationEffect build: trigger is TRUE');
    }
    // When disintegrating, hide the original widget but keep it in tree to maintain layout
    return Opacity(
      opacity: _isDisintegrating ? 0.0 : 1.0,
      child: RepaintBoundary(
        key: _globalKey,
        child: widget.child,
      ),
    );
  }
}

class _Particle {
  Offset position;
  final Color color;
  final Offset velocity;
  final double size;
  final double randomDelay;

  _Particle({
    required this.position,
    required this.color,
    required this.velocity,
    required this.size,
    required this.randomDelay,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final ui.Image image;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.image,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final particle in particles) {
      double p = (progress - particle.randomDelay) / (1.0 - particle.randomDelay);
      if (p < 0) p = 0;
      if (p > 1) p = 1;

      if (p == 0) {
        paint.color = particle.color;
        canvas.drawRect(
          Rect.fromLTWH(particle.position.dx, particle.position.dy, particle.size, particle.size),
          paint,
        );
        continue;
      }

      final dx = particle.velocity.dx * p * 3;
      final dy = particle.velocity.dy * p * 3;
      
      final currentPos = particle.position + Offset(dx, dy);

      final opacity = (1.0 - p).clamp(0.0, 1.0);
      paint.color = particle.color.withValues(alpha: particle.color.a * opacity);

      canvas.drawRect(
        Rect.fromLTWH(currentPos.dx, currentPos.dy, particle.size, particle.size),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
