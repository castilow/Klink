import 'package:flutter/material.dart';

/// Widget de fondo para pantallas de autenticación
/// Muestra una imagen de fondo con la "K" decorativa animada
class KAuthBackground extends StatefulWidget {
  /// Ruta de la imagen de fondo. Si no se especifica, usa la imagen por defecto.
  final String? imagePath;
  
  /// Valor inicial del brillo (0.0 a 1.0). Por defecto 0.1 (10%).
  final double brightnessBegin;
  
  /// Valor final del brillo (0.0 a 1.0). Por defecto 0.4 (40%).
  final double brightnessEnd;
  
  /// Alineación de la imagen de fondo. Por defecto Alignment.center.
  final Alignment alignment;
  
  const KAuthBackground({
    super.key,
    this.imagePath,
    this.brightnessBegin = 0.1,
    this.brightnessEnd = 0.4,
    this.alignment = Alignment.center,
  });

  @override
  State<KAuthBackground> createState() => _KAuthBackgroundState();
}

class _KAuthBackgroundState extends State<KAuthBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _brightnessAnimation;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    
    // Controlador de animación con duración de 4 segundos
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true); // Repite la animación en reversa para un loop suave

    // Animación de brillo: oscila entre brightnessBegin y brightnessEnd
    _brightnessAnimation = Tween<double>(
      begin: widget.brightnessBegin,
      end: widget.brightnessEnd,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Animación de movimiento: desplazamiento más sutil y centrado para evitar que se salga
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(-0.01, -0.005), // Movimiento hacia la izquierda y arriba
      end: const Offset(0.01, 0.005), // Movimiento hacia la derecha y abajo
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF020617), // Fondo azul muy oscuro como fallback
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final screenSize = MediaQuery.of(context).size;
          // Usar un tamaño ligeramente mayor para evitar que se vean bordes al moverse
          final imageSize = Size(
            screenSize.width * 1.05, // 5% más grande para cubrir el movimiento
            screenSize.height * 1.05,
          );
          
          return Transform.translate(
            offset: Offset(
              _offsetAnimation.value.dx * screenSize.width,
              _offsetAnimation.value.dy * screenSize.height,
            ),
            child: Align(
              alignment: widget.alignment,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.white.withOpacity(_brightnessAnimation.value),
                  BlendMode.modulate,
                ),
                child: Image.asset(
                  widget.imagePath ?? 'assets/images/bg_klink_3x_1284x2778.png',
                  fit: BoxFit.cover,
                  width: imageSize.width,
                  height: imageSize.height,
                  alignment: widget.alignment,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF020617),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}



