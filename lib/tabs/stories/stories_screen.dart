import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:chat_messenger/config/theme_config.dart';

import 'package:get/get.dart';
import 'dart:math' as math;
import 'components/story_card.dart';
import 'controller/story_controller.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'story_camera_screen.dart';

class StoriesScreen extends GetView<StoryController> {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: PassportSection(),
      ),
    );
  }
}

class PassportSection extends StatefulWidget {
  const PassportSection({super.key});

  @override
  State<PassportSection> createState() => _PassportSectionState();
}

class _PassportSectionState extends State<PassportSection>
    with TickerProviderStateMixin {
  late AnimationController _passportController;
  late AnimationController _passportShimmerController;
  late AnimationController _transitionController;
  late Animation<double> _passportFlipAnimation;
  late Animation<double> _passportShimmerAnimation;
  late Animation<double> _interiorOpacityAnimation;
  late Animation<double> _storiesOpacityAnimation;
  late Animation<Offset> _passportScrollAnimation;
  late Animation<double> _storiesScaleAnimation;
  
  bool _isPassportOpen = false;
  bool _showStories = false;

  @override
  void initState() {
    super.initState();
    
    _passportController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _passportShimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _passportFlipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _passportController, curve: Curves.easeInOut),
    );
    _passportShimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _passportShimmerController, curve: Curves.easeInOut),
    );
    _interiorOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _passportController, 
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );
    _storiesOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _transitionController, 
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );
    // Animación de scroll hacia arriba (en lugar de zoom)
    _passportScrollAnimation = Tween<Offset>(
      begin: Offset.zero, 
      end: const Offset(0, -2.0), // Se mueve hacia arriba hasta salir de pantalla
    ).animate(
      CurvedAnimation(
        parent: _transitionController, 
        curve: const Interval(0.0, 0.8, curve: Curves.easeInCubic),
      ),
    );
    _storiesScaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _transitionController, 
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Iniciar animación de brillo del pasaporte
    _passportShimmerController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _passportController.dispose();
    _passportShimmerController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_transitionController, _passportController]),
      builder: (context, child) {
        return Stack(
          children: [
            // Stories (aparecen desde abajo cuando el pasaporte se va hacia arriba)
            if (_showStories)
              Transform.scale(
                scale: _storiesScaleAnimation.value,
                child: Opacity(
                  opacity: _storiesOpacityAnimation.value,
                  child: BuildStories(showAddButton: _transitionController.isCompleted),
                ),
              ),
            
            // Pasaporte (se desplaza hacia arriba como scroll)
            SlideTransition(
              position: _passportScrollAnimation,
              child: Opacity(
                opacity: (1.0 - _transitionController.value * 0.3).clamp(0.0, 1.0),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Posición del pasaporte
                        Transform.translate(
                          offset: const Offset(0, -10),
                          child: _buildWorldIDPassport(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWorldIDPassport() {
    // Calcular altura para que ocupe más espacio
    final screenHeight = MediaQuery.of(context).size.height;
    final passportHeight = (screenHeight * 0.6).clamp(500.0, 700.0);
    
    return GestureDetector(
      onTap: _handlePassportTap,
      child: Stack(
        children: [
          // Página interior (debajo)
          AnimatedBuilder(
            animation: _interiorOpacityAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _interiorOpacityAnimation.value,
                child: Container(
                  width: double.infinity,
                  height: passportHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        // Imagen de la página interior
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/worldcoin-passport-interior.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                        
                        // Efecto de brillo sutil en la página interior
                        AnimatedBuilder(
                          animation: _passportShimmerAnimation,
                          builder: (context, child) {
                            return Positioned.fill(
                              child: Transform.translate(
                                offset: Offset(_passportShimmerAnimation.value * MediaQuery.of(context).size.width * 0.5, 0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withOpacity(0.05),
                                        Colors.white.withOpacity(0.1),
                                        Colors.white.withOpacity(0.05),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Portada del pasaporte (encima)
          AnimatedBuilder(
            animation: _passportFlipAnimation,
            builder: (context, child) {
              return Transform(
                alignment: Alignment.centerLeft,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(_passportFlipAnimation.value * math.pi * 0.6),
                child: Container(
                  width: double.infinity,
                  height: passportHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey[900]!,
                        Colors.black,
                        Colors.grey[800]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        // Imagen del pasaporte (portada)
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/worldcoin-passport.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                        
                        // Efecto de brillo en la portada
                        AnimatedBuilder(
                          animation: _passportShimmerAnimation,
                          builder: (context, child) {
                            return Positioned.fill(
                              child: Transform.translate(
                                offset: Offset(_passportShimmerAnimation.value * MediaQuery.of(context).size.width, 0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withOpacity(0.1),
                                        Colors.white.withOpacity(0.2),
                                        Colors.white.withOpacity(0.1),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handlePassportTap() {
    HapticFeedback.lightImpact();
    
    if (_isPassportOpen) {
      return; // No permitir cerrar una vez abierto
    }

    _passportController.forward().then((_) {
      // Inmediatamente después de abrir el pasaporte, hacer scroll hacia arriba y mostrar stories
      if (mounted) {
        setState(() {
          _showStories = true;
        });
        _transitionController.forward();
      }
    });
    
    setState(() {
      _isPassportOpen = true;
    });
    
    // Notificaciones deshabilitadas
  }
}

class BuildStories extends GetView<StoryController> {
  const BuildStories({super.key, required this.showAddButton});
  
  final bool showAddButton;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Determine responsive grid parameters with improved spacing
    int crossAxisCount;
    double childAspectRatio;
    double crossAxisSpacing;
    double mainAxisSpacing;
    EdgeInsets padding;
    
    if (screenWidth > 900) {
      // Large tablets/desktop
      crossAxisCount = 4;
      childAspectRatio = 0.75;
      crossAxisSpacing = 20;
      mainAxisSpacing = 20;
      padding = const EdgeInsets.all(28);
    } else if (screenWidth > 600) {
      // Tablets
      crossAxisCount = 3;
      childAspectRatio = 0.78;
      crossAxisSpacing = 18;
      mainAxisSpacing = 18;
      padding = const EdgeInsets.all(24);
    } else if (screenWidth > 400) {
      // Large phones
      crossAxisCount = 2;
      childAspectRatio = 0.76;
      crossAxisSpacing = 16;
      mainAxisSpacing = 16;
      padding = const EdgeInsets.all(20);
    } else {
      // Small phones
      crossAxisCount = 2;
      childAspectRatio = 0.72;
      crossAxisSpacing = 14;
      mainAxisSpacing = 14;
      padding = const EdgeInsets.all(16);
    }

    return Obx(() {
      // Check loading status
      if (controller.isLoading.value) {
        return EnhancedLoadingGrid(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          padding: padding,
          childAspectRatio: childAspectRatio,
          showAddButton: true, // Siempre mostrar botón en loading
        );
      } else if (controller.stories.isEmpty) {
        // Cuando no hay stories, mostrar mensaje + botón grande
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Mensaje de no data
              EnhancedNoData(iconData: IconlyBold.video, text: 'no_stories'.tr),
            ],
          ),
        );
      }

      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: EnhancedStoriesGrid(
          stories: controller.stories,
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          padding: padding,
          childAspectRatio: childAspectRatio,
          showAddButton: true, // Siempre mostrar botón cuando hay stories
        ),
      );
    });
  }
}

class EnhancedStoriesGrid extends StatelessWidget {
  const EnhancedStoriesGrid({
    super.key,
    required this.stories,
    required this.crossAxisCount,
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
    required this.padding,
    required this.childAspectRatio,
    required this.showAddButton,
  });

  final List stories;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsets padding;
  final double childAspectRatio;
  final bool showAddButton;

  @override
  Widget build(BuildContext context) {
    // Crear lista con botón de agregar al inicio si debe mostrarse
    final List<dynamic> items = [];
    if (showAddButton) {
      items.add('add_button'); // Marcador especial para el botón
    }
    items.addAll(stories);

    return GridView.builder(
      itemCount: items.length,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        
        return TweenAnimationBuilder<double>(
          duration: Duration(
            milliseconds: (800 + (index * 150)).clamp(200, 2500),
          ),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            final animationValue = value.clamp(0.0, 1.0).toDouble();
            final scale = (0.3 + 0.7 * animationValue).clamp(0.3, 1.0).toDouble();
            final opacity = animationValue.clamp(0.0, 1.0).toDouble();
            final offsetY = (50 * (1 - animationValue)).clamp(0.0, 50.0).toDouble();
            
            return Transform.translate(
              offset: Offset(0, offsetY),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: item == 'add_button' 
                      ? AddStoryButton()
                      : StoryCard(item),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class AddStoryButton extends StatelessWidget {
  const AddStoryButton({super.key});

  Future<void> _handleCreateStory(BuildContext context) async {
    HapticFeedback.lightImpact();
    
    // Mostrar opciones para crear story
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildStoryOptionsSheet(context),
    );
  }

  Widget _buildStoryOptionsSheet(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Crear Nueva Story',
                  style: TextStyle(
                    fontSize: isTablet ? 22 : 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Elige cómo quieres crear tu story',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _buildStoryOption(
                  context: context,
                  icon: IconlyBold.camera,
                  title: 'Grabar Video',
                  subtitle: 'Graba un video para tu story',
                  color: const Color(0xFFEF4444),
                  onTap: () => _openCamera(context, isVideo: true),
                ),
                const SizedBox(height: 16),
                _buildStoryOption(
                  context: context,
                  icon: IconlyBold.image,
                  title: 'Tomar Foto',
                  subtitle: 'Captura una foto para tu story',
                  color: const Color(0xFF000000),
                  onTap: () => _openCamera(context, isVideo: false),
                ),
                const SizedBox(height: 16),
                _buildStoryOption(
                  context: context,
                  icon: IconlyBold.folder,
                  title: 'Desde Galería',
                  subtitle: 'Selecciona desde tu galería',
                  color: const Color(0xFF10B981),
                  onTap: () => _openGallery(context),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStoryOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color,
                    color.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCamera(BuildContext context, {required bool isVideo}) async {
    Navigator.pop(context); // Cerrar el bottom sheet
    
    // Verificar permisos
    final cameraPermission = await Permission.camera.request();
    final microphonePermission = isVideo ? await Permission.microphone.request() : PermissionStatus.granted;
    
    if (cameraPermission.isDenied || (isVideo && microphonePermission.isDenied)) {
      // Notificaciones deshabilitadas
      return;
    }
    
    try {
      // Obtener cámaras disponibles
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        // Notificaciones deshabilitadas
        return;
      }
      
      // Navegar a la pantalla de cámara
      Get.to(
        () => StoryCamera(
          cameras: cameras,
          isVideo: isVideo,
        ),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 300),
      );
      
    } catch (e) {
      // Notificaciones deshabilitadas
    }
  }

  Future<void> _openGallery(BuildContext context) async {
    Navigator.pop(context); // Cerrar el bottom sheet
    
    // Verificar permisos de galería
    final permission = await Permission.photos.request();
    
    if (permission.isDenied) {
      // Notificaciones deshabilitadas
      return;
    }
    
    // TODO: Implementar selección de galería
    // Notificaciones deshabilitadas
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;
    final borderRadius = isLargeScreen ? 24.0 : (isTablet ? 20.0 : 18.0);

    return GestureDetector(
      onTap: () => _handleCreateStory(context),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Colors.grey[900]!,
            ],
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: () => _handleCreateStory(context),
            child: Container(
              padding: EdgeInsets.all(isLargeScreen ? 24 : (isTablet ? 20 : 16)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: isLargeScreen ? 80 : (isTablet ? 70 : 60),
                    height: isLargeScreen ? 80 : (isTablet ? 70 : 60),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      IconlyBold.plus,
                      color: Colors.white,
                      size: isLargeScreen ? 40 : (isTablet ? 35 : 30),
                    ),
                  ),
                  SizedBox(height: isLargeScreen ? 16 : (isTablet ? 14 : 12)),
                  Text(
                    'Crear Story',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isLargeScreen ? 16 : (isTablet ? 14 : 12),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}



class EnhancedLoadingGrid extends StatelessWidget {
  const EnhancedLoadingGrid({
    super.key,
    required this.crossAxisCount,
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
    required this.padding,
    required this.childAspectRatio,
    required this.showAddButton,
  });

  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsets padding;
  final double childAspectRatio;
  final bool showAddButton;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: GridView.builder(
        itemCount: crossAxisCount * 3, // Show 3 rows of loading cards
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: padding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          childAspectRatio: childAspectRatio,
        ),
        itemBuilder: (context, index) {
          return TweenAnimationBuilder<double>(
            duration: Duration(
              milliseconds: (600 + (index * 100)).clamp(200, 2000),
            ),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              final animationValue = value.clamp(0.0, 1.0).toDouble();
              final scale = (0.5 + 0.5 * animationValue).clamp(0.5, 1.0).toDouble();
              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: animationValue,
                  child: AnimatedLoadingCard(isTablet: isTablet, isLargeScreen: isLargeScreen),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AnimatedLoadingCard extends StatefulWidget {
  const AnimatedLoadingCard({
    super.key,
    required this.isTablet,
    required this.isLargeScreen,
  });

  final bool isTablet;
  final bool isLargeScreen;

  @override
  State<AnimatedLoadingCard> createState() => _AnimatedLoadingCardState();
}

class _AnimatedLoadingCardState extends State<AnimatedLoadingCard>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.isLargeScreen ? 24.0 : (widget.isTablet ? 20.0 : 18.0);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          colors: [
            Colors.grey[200]!,
            Colors.grey[100]!,
            Colors.grey[200]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            // Shimmer effect
            AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shimmerAnimation.value * 200, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                );
              },
            ),
            // Content placeholder
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey[300]!,
                      Colors.grey[200]!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EnhancedNoData extends StatelessWidget {
  const EnhancedNoData({
    super.key,
    required this.iconData,
    required this.text,
  });

  final IconData iconData;
  final String text;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;

    return Center(
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 1200),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          final animationValue = value.clamp(0.0, 1.0).toDouble();
          final scale = (0.5 + 0.5 * animationValue).clamp(0.5, 1.0).toDouble();
          final offsetY = (100 * (1 - animationValue)).clamp(0.0, 100.0).toDouble();
          return Transform.translate(
            offset: Offset(0, offsetY),
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: animationValue,
                child: Container(
                  padding: EdgeInsets.all(isLargeScreen ? 40 : (isTablet ? 32 : 24)),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.9),
                        Colors.white.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(isLargeScreen ? 32 : (isTablet ? 28 : 24)),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: isLargeScreen ? 120 : (isTablet ? 100 : 80),
                        height: isLargeScreen ? 120 : (isTablet ? 100 : 80),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor.withValues(alpha: 0.1),
                              primaryColor.withValues(alpha: 0.05),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          iconData,
                          color: primaryColor.withValues(alpha: 0.6),
                          size: isLargeScreen ? 60 : (isTablet ? 50 : 40),
                        ),
                      ),
                      SizedBox(height: isLargeScreen ? 24 : (isTablet ? 20 : 16)),
                      Text(
                        text,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.grey[700],
                          fontSize: isLargeScreen ? 24 : (isTablet ? 20 : 18),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isLargeScreen ? 16 : (isTablet ? 12 : 8)),
                      Text(
                        'create_first_story'.tr,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                          fontSize: isLargeScreen ? 16 : (isTablet ? 14 : 12),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
