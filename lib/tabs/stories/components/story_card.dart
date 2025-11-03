import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:chat_messenger/components/cached_card_image.dart';
import 'package:chat_messenger/components/cached_circle_avatar.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/helpers/date_helper.dart';
import 'package:chat_messenger/models/story/story.dart';
import 'package:chat_messenger/models/story/submodels/story_image.dart';
import 'package:chat_messenger/models/story/submodels/story_text.dart';
import 'package:chat_messenger/models/story/submodels/story_video.dart';
import 'package:chat_messenger/routes/app_routes.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:get/get.dart';
import 'dart:ui';

class StoryCard extends StatefulWidget {
  const StoryCard(this.story, {super.key});

  final Story story;

  @override
  State<StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<StoryCard> with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onTapDown() {
    _hoverController.forward();
  }

  void _onTapUp() {
    _hoverController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;

    final currentUser = AuthController.instance.currentUser;
    final isViewed = widget.story.viewers.contains(currentUser.userId);
    final isOwner = widget.story.userId == currentUser.userId;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _onTapDown(),
            onTapUp: (_) => _onTapUp(),
            onTapCancel: () => _onTapUp(),
            onTap: () {
              Get.toNamed(
                AppRoutes.storyView,
                arguments: {'story': widget.story},
              );
            },
            child: Container(
              margin: EdgeInsets.all(isTablet ? 6 : 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
                child: Stack(
                  children: [
                    // Main story content
                    _buildStoryContent(),
                    
                    // Subtle gradient overlay
                    if (widget.story.type != StoryType.text)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.25),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.7, 1.0],
                            ),
                          ),
                        ),
                      ),

                    // User info overlay - Minimalista
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(isTablet ? 20 : 16),
                        child: Row(
                          children: [
                            // User avatar minimalista
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: !isViewed && !isOwner 
                                      ? primaryColor 
                                      : Colors.white.withValues(alpha: 0.8),
                                  width: !isViewed && !isOwner ? 2.5 : 2,
                                ),
                              ),
                              child: CachedCircleAvatar(
                                radius: isTablet ? 18 : 15,
                                imageUrl: widget.story.user!.photoUrl,
                              ),
                            ),
                            SizedBox(width: isTablet ? 12 : 10),

                            // User name and time
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.story.user!.fullname,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isLargeScreen ? 15 : (isTablet ? 14 : 13),
                                      fontWeight: FontWeight.w600,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.5),
                                          offset: const Offset(0, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    widget.story.updatedAt != null 
                                        ? widget.story.updatedAt!.formatDateTime
                                        : 'now'.tr,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: isLargeScreen ? 11 : (isTablet ? 10 : 9),
                                      fontWeight: FontWeight.w400,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.5),
                                          offset: const Offset(0, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // New story indicator - Minimalista
                    if (!isViewed && !isOwner)
                      Positioned(
                        top: isTablet ? 16 : 12,
                        right: isTablet ? 16 : 12,
                        child: Container(
                          width: isTablet ? 10 : 8,
                          height: isTablet ? 10 : 8,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Story type indicator - Sutil
                    Positioned(
                      top: isTablet ? 16 : 12,
                      left: isTablet ? 16 : 12,
                      child: Container(
                        padding: EdgeInsets.all(isTablet ? 6 : 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getStoryTypeIcon(),
                          color: Colors.white.withValues(alpha: 0.9),
                          size: isTablet ? 12 : 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStoryContent() {
    switch (widget.story.type) {
      case StoryType.text:
        final StoryText storyText = widget.story.texts.last;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                storyText.bgColor,
                storyText.bgColor.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                storyText.text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );

      case StoryType.image:
        final StoryImage storyImage = widget.story.images.last;
        return CachedCardImage(storyImage.imageUrl);

      case StoryType.video:
        final StoryVideo storyVideo = widget.story.videos.last;
        return Stack(
          children: [
            CachedCardImage(storyVideo.thumbnailUrl),
            Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  IconlyBold.play,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        );
    }
  }

  IconData _getStoryTypeIcon() {
    switch (widget.story.type) {
      case StoryType.text:
        return IconlyBold.editSquare;
      case StoryType.image:
        return IconlyBold.image;
      case StoryType.video:
        return IconlyBold.video;
    }
  }
}

class AnimatedBottomBackground extends StatelessWidget {
  const AnimatedBottomBackground({super.key, required this.isHovered});

  final bool isHovered;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(defaultRadius),
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.transparent,
            Colors.transparent,
            isHovered
                                  ? Colors.black.withValues(alpha: 0.9)
                : Colors.black.withValues(alpha: 0.8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

class BottomBackground extends StatelessWidget {
  const BottomBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(defaultRadius),
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

// Nuevo componente para efectos de parallax
class ParallaxStoryCard extends StatefulWidget {
  const ParallaxStoryCard({
    super.key,
    required this.story,
    required this.scrollController,
  });

  final Story story;
  final ScrollController scrollController;

  @override
  State<ParallaxStoryCard> createState() => _ParallaxStoryCardState();
}

class _ParallaxStoryCardState extends State<ParallaxStoryCard> with TickerProviderStateMixin {
  late AnimationController _parallaxController;
  late Animation<double> _parallaxAnimation;

  @override
  void initState() {
    super.initState();
    _parallaxController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _parallaxAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _parallaxController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _parallaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _parallaxAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _parallaxAnimation.value * 20),
          child: StoryCard(widget.story),
        );
      },
    );
  }
}

// Componente para efectos de glassmorphism mejorados
class GlassmorphismContainer extends StatelessWidget {
  const GlassmorphismContainer({
    super.key,
    required this.child,
    this.blurRadius = 10.0,
    this.opacity = 0.1,
    this.borderRadius = 20.0,
  });

  final Widget child;
  final double blurRadius;
  final double opacity;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Colors.white.withValues(alpha: opacity),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: blurRadius,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurRadius, sigmaY: blurRadius),
          child: child,
        ),
      ),
    );
  }
}

// Componente para efectos de neumorphism
class NeumorphicContainer extends StatelessWidget {
  const NeumorphicContainer({
    super.key,
    required this.child,
    this.depth = 8.0,
    this.borderRadius = 20.0,
    this.isPressed = false,
  });

  final Widget child;
  final double depth;
  final double borderRadius;
  final bool isPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Colors.grey[100],
        boxShadow: isPressed
            ? [
                BoxShadow(
                  color: Colors.grey[400]!,
                  blurRadius: depth * 0.5,
                  offset: const Offset(2, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.grey[300]!,
                  blurRadius: depth,
                  offset: Offset(-depth * 0.5, -depth * 0.5),
                ),
                BoxShadow(
                  color: Colors.white,
                  blurRadius: depth,
                  offset: Offset(depth * 0.5, depth * 0.5),
                ),
              ],
      ),
      child: child,
    );
  }
}

// Componente para efectos de shimmer mejorados
class EnhancedShimmerEffect extends StatefulWidget {
  const EnhancedShimmerEffect({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 2000),
    this.shimmerColor,
  });

  final Widget child;
  final Duration duration;
  final Color? shimmerColor;

  @override
  State<EnhancedShimmerEffect> createState() => _EnhancedShimmerEffectState();
}

class _EnhancedShimmerEffectState extends State<EnhancedShimmerEffect>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: widget.duration,
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
    return Stack(
      children: [
        widget.child,
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
                      (widget.shimmerColor ?? Colors.white).withValues(alpha: 0.3),
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
      ],
    );
  }
}

// Componente para efectos de partículas flotantes
class FloatingParticles extends StatefulWidget {
  const FloatingParticles({
    super.key,
    this.particleCount = 20,
    this.particleColor,
  });

  final int particleCount;
  final Color? particleColor;

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with TickerProviderStateMixin {
  late List<AnimationController> _particleControllers;
  late List<Animation<double>> _particleAnimations;

  @override
  void initState() {
    super.initState();
    _particleControllers = List.generate(
      widget.particleCount,
      (index) => AnimationController(
        duration: Duration(
          milliseconds: (3000 + (index * 200)).clamp(2000, 5000),
        ),
        vsync: this,
      ),
    );

    _particleAnimations = _particleControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    for (final controller in _particleControllers) {
      controller.repeat();
    }
  }

  @override
  void dispose() {
    for (final controller in _particleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(widget.particleCount, (index) {
        return AnimatedBuilder(
          animation: _particleAnimations[index],
          builder: (context, child) {
            final animationValue = _particleAnimations[index].value;
            final offsetX = (animationValue * 100 - 50) * (index % 2 == 0 ? 1 : -1);
            final offsetY = (animationValue * 50 - 25) * (index % 3 == 0 ? 1 : -1);
            final opacity = (0.3 + 0.7 * animationValue).clamp(0.0, 1.0);
            final scale = (0.5 + 0.5 * animationValue).clamp(0.5, 1.0);

            return Positioned(
              left: 50 + (index * 20) % 200,
              top: 50 + (index * 15) % 150,
              child: Transform.translate(
                offset: Offset(offsetX, offsetY),
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: (widget.particleColor ?? primaryColor).withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

// Componente para efectos de ondas de sonido
class SoundWaveEffect extends StatefulWidget {
  const SoundWaveEffect({
    super.key,
    this.isActive = false,
    this.waveCount = 3,
    this.waveColor,
  });

  final bool isActive;
  final int waveCount;
  final Color? waveColor;

  @override
  State<SoundWaveEffect> createState() => _SoundWaveEffectState();
}

class _SoundWaveEffectState extends State<SoundWaveEffect>
    with TickerProviderStateMixin {
  late List<AnimationController> _waveControllers;
  late List<Animation<double>> _waveAnimations;

  @override
  void initState() {
    super.initState();
    _waveControllers = List.generate(
      widget.waveCount,
      (index) => AnimationController(
        duration: Duration(milliseconds: 1000 + (index * 200)),
        vsync: this,
      ),
    );

    _waveAnimations = _waveControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
    }).toList();
  }

  @override
  void didUpdateWidget(SoundWaveEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        for (final controller in _waveControllers) {
          controller.repeat();
        }
      } else {
        for (final controller in _waveControllers) {
          controller.stop();
        }
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _waveControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: List.generate(widget.waveCount, (index) {
        return AnimatedBuilder(
          animation: _waveAnimations[index],
          builder: (context, child) {
            final animationValue = _waveAnimations[index].value;
            final scale = (1.0 + animationValue * 2.0).clamp(1.0, 3.0);
            final opacity = (1.0 - animationValue).clamp(0.0, 1.0);

            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: (widget.waveColor ?? primaryColor).withValues(alpha: 0.6),
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
