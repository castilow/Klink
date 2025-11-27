import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:chat_messenger/components/cached_circle_avatar.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/controllers/preferences_controller.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/media/helpers/media_helper.dart';
import 'package:chat_messenger/helpers/dialog_helper.dart';
import 'package:chat_messenger/routes/app_routes.dart';
import 'package:chat_messenger/screens/home/controller/home_controller.dart';
import 'package:marquee/marquee.dart';
import 'controller/videos_controller.dart';

class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> with WidgetsBindingObserver {
  final VideosController controller = Get.put(VideosController());
  final PreferencesController prefsController = Get.find();
  final HomeController homeController = Get.find<HomeController>();
  late PageController horizontalPageController;
  late Worker _pageIndexWorker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    horizontalPageController = PageController(initialPage: 1);
    
    // Escuchar cambios en el índice de página del HomeController
    // El índice 2 corresponde a VideosScreen
    _pageIndexWorker = ever(homeController.pageIndex, (int index) {
      if (index != 2) {
        // Si no estamos en la pantalla de videos, pausar todos los videos
        controller.pauseAllVideos();
      } else {
        // Si acabamos de entrar a la sección de videos, reproducir el video actual automáticamente
        // Esperar un momento para asegurar que la UI está lista
        Future.delayed(const Duration(milliseconds: 300), () {
          controller.playCurrentVideoIfInSection();
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageIndexWorker.dispose();
    horizontalPageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Pausar videos cuando la app va a segundo plano
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      controller.pauseAllVideos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDarkMode = prefsController.isDarkMode.value;
      
      return Scaffold(
        backgroundColor: Colors.black,
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: PageView(
          controller: horizontalPageController,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          onPageChanged: (index) {
            // Si cambiamos a la página de cámara (index 0), pausar videos
            if (index == 0) {
              controller.pauseAllVideos();
            }
          },
          children: [
            // Page 0: Camera/Upload Screen
            _CameraUploadScreen(controller: controller, isDarkMode: isDarkMode),
            
            // Page 1: Video Feed
            _buildVideoFeed(context, controller, isDarkMode),
          ],
        ),
      );
    });
  }

  Widget _buildVideoFeed(BuildContext context, VideosController controller, bool isDarkMode) {
    if (controller.isLoading.value && controller.videos.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
      );
    }
    
    if (controller.videos.isEmpty) {
      return _buildEmptyState(context, controller, isDarkMode);
    }

    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: controller.videos.length,
      onPageChanged: (index) {
        controller.onPageChanged(index);
        // Asegurar que el video se reproduzca cuando cambiamos de página
        Future.delayed(const Duration(milliseconds: 200), () {
          controller.playCurrentVideoIfInSection();
        });
      },
      itemBuilder: (context, index) {
        final video = controller.videos[index];
        return _VideoPlayerWidget(
          video: video,
          controller: controller,
          isDarkMode: isDarkMode,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, VideosController controller, bool isDarkMode) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey[900]!,
                  Colors.black,
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    IconlyBold.video,
                    size: 64,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'No hay videos aún',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sé el primero en compartir un video',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 48),
                GestureDetector(
                  onTap: () => _showUploadVideoModal(context, controller, isDarkMode),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF00B0FF)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Crear Video',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  final VideoPost video;
  final VideosController controller;
  final bool isDarkMode;

  const _VideoPlayerWidget({
    required this.video,
    required this.controller,
    required this.isDarkMode,
  });

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> with SingleTickerProviderStateMixin {
  VideoPlayerController? _playerController;
  bool _isInitialized = false;
  bool _showHeart = false;
  bool _isPlaying = true;
  late AnimationController _heartAnimationController;
  late Animation<double> _heartScaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _heartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _heartScaleAnimation = Tween<double>(begin: 0.0, end: 1.2).animate(
      CurvedAnimation(parent: _heartAnimationController, curve: Curves.elasticOut),
    );
    
    _heartAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _heartAnimationController.reverse();
        });
      } else if (status == AnimationStatus.dismissed) {
        if (mounted) {
          setState(() {
            _showHeart = false;
          });
        }
      }
    });
    
    // Escuchar cambios en el índice de página del HomeController
    // para pausar videos cuando salimos de la sección
    final homeController = Get.find<HomeController>();
    ever(homeController.pageIndex, (int index) {
      if (index != 2) {
        // Si no estamos en la sección de videos, pausar este video
        if (_playerController != null && 
            _playerController!.value.isInitialized && 
            _playerController!.value.isPlaying) {
          _playerController!.pause();
          if (mounted) {
            setState(() {
              _isPlaying = false;
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _heartAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    _playerController = widget.controller.getVideoController(widget.video.id);
    
    if (_playerController != null && _playerController!.value.isInitialized) {
      setState(() {
        _isInitialized = true;
        _isPlaying = _playerController!.value.isPlaying;
      });
      _playerController!.addListener(_videoListener);
      
      // Solo incrementar visitas si este es el video actual y está reproduciéndose
      final currentIndex = widget.controller.currentVideoIndex.value;
      if (currentIndex < widget.controller.videos.length &&
          widget.controller.videos[currentIndex].id == widget.video.id &&
          _isPlaying) {
        widget.controller.incrementViews(widget.video.id);
      }
    } else {
      // Esperar a que se inicialice
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _initializePlayer();
        }
      });
    }
  }

  void _videoListener() {
    if (mounted && _playerController != null) {
      final isPlaying = _playerController!.value.isPlaying;
      if (isPlaying != _isPlaying) {
        setState(() {
          _isPlaying = isPlaying;
        });
      }
    }
  }

  void _handleDoubleTap() {
    if (!widget.video.isLiked) {
      widget.controller.toggleLike(widget.video.id);
    }
    setState(() {
      _showHeart = true;
    });
    _heartAnimationController.forward(from: 0.0);
    HapticFeedback.mediumImpact();
  }

  void _togglePlay() {
    if (_playerController != null && _playerController!.value.isInitialized) {
      if (_playerController!.value.isPlaying) {
        _playerController!.pause();
      } else {
        _playerController!.play();
      }
      setState(() {
        _isPlaying = _playerController!.value.isPlaying;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _playerController = widget.controller.getVideoController(widget.video.id);
    
    // NO usar addPostFrameCallback aquí - causa reproducción automática
    // La reproducción se maneja desde el controller cuando cambia de página
    // Solo verificar y pausar si no estamos en la sección de videos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_playerController != null && _playerController!.value.isInitialized) {
        // Verificar si estamos en la sección de videos (índice 2)
        try {
          final homeController = Get.find<HomeController>();
          final isInVideosSection = homeController.pageIndex.value == 2;
          
          final currentIndex = widget.controller.currentVideoIndex.value;
          final isCurrentVideo = currentIndex < widget.controller.videos.length &&
              widget.controller.videos[currentIndex].id == widget.video.id;
          
          // Solo pausar si NO estamos en la sección de videos O no es el video actual
          // NO reproducir aquí - la reproducción se maneja desde el controller
          if (!isInVideosSection || !isCurrentVideo) {
            if (_playerController!.value.isPlaying) {
              _playerController!.pause();
              if (mounted) {
                setState(() {
                  _isPlaying = false;
                });
              }
            }
          }
        } catch (e) {
          // Si hay error, pausar por seguridad
          if (_playerController!.value.isPlaying) {
            _playerController!.pause();
            if (mounted) {
              setState(() {
                _isPlaying = false;
              });
            }
          }
        }
      }
    });
    
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      onTap: _togglePlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video player
          if (_playerController != null && _playerController!.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _playerController!.value.size.width,
                  height: _playerController!.value.size.height,
                  child: VideoPlayer(_playerController!),
                ),
              ),
            )
          else
            Container(
              color: Colors.black,
              child: widget.video.thumbnailUrl != null
                  ? Image.network(
                      widget.video.thumbnailUrl!,
                      fit: BoxFit.cover,
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00E5FF),
                      ),
                    ),
            ),
          
          // Play/Pause overlay icon
          if (!_isPlaying)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),

          // Heart Animation
          if (_showHeart)
            Center(
              child: ScaleTransition(
                scale: _heartScaleAnimation,
                child: const Icon(
                  IconlyBold.heart,
                  color: Colors.red,
                  size: 100,
                  shadows: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          
          // Gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.9),
                  ],
                  stops: const [0.0, 0.2, 0.6, 0.85, 1.0],
                ),
              ),
            ),
          ),
          
          // Content overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Left side - User info and caption
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // User info
                          GestureDetector(
                            onTap: () {
                              if (widget.video.user != null) {
                                Get.toNamed(AppRoutes.profileView, arguments: {
                                  'user': widget.video.user!,
                                  'isGroup': false,
                                });
                              }
                            },
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                  child: CachedCircleAvatar(
                                    imageUrl: widget.video.user?.photoUrl ?? '',
                                    radius: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  widget.video.user?.fullname ?? 'Usuario',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black45,
                                        offset: Offset(0, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (true) // TODO: Check verified status
                                  const Icon(
                                    Icons.verified,
                                    color: Color(0xFF00E5FF),
                                    size: 16,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (widget.video.caption != null && widget.video.caption!.isNotEmpty)
                            Text(
                              widget.video.caption!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.3,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 12),
                          // Music/Audio indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.music_note_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 120,
                                  height: 20,
                                  child: Marquee(
                                    text: 'Sonido original - ${widget.video.user?.fullname ?? "Usuario"}   ',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    scrollAxis: Axis.horizontal,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    blankSpace: 20.0,
                                    velocity: 30.0,
                                    pauseAfterRound: const Duration(seconds: 1),
                                    startPadding: 0.0,
                                    accelerationDuration: const Duration(seconds: 1),
                                    accelerationCurve: Curves.linear,
                                    decelerationDuration: const Duration(milliseconds: 500),
                                    decelerationCurve: Curves.easeOut,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Right side - Action buttons
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _GlassActionButton(
                          icon: widget.video.isLiked ? IconlyBold.heart : IconlyLight.heart,
                          iconColor: widget.video.isLiked ? const Color(0xFFFF2D55) : Colors.white,
                          label: _formatCount(widget.video.likes),
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            widget.controller.toggleLike(widget.video.id);
                          },
                        ),
                        const SizedBox(height: 20), // Increased spacing
                        _GlassActionButton(
                          icon: IconlyLight.chat,
                          label: _formatCount(widget.video.comments),
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            _showCommentsModal(context, widget.controller, widget.video.id);
                          },
                        ),
                        const SizedBox(height: 20), // Increased spacing
                        _GlassActionButton(
                          icon: IconlyLight.send,
                          label: _formatCount(widget.video.shares),
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            _showShareModal(context, widget.controller, widget.video.id);
                          },
                        ),
                        const SizedBox(height: 20), // Increased spacing
                        _GlassActionButton(
                          icon: IconlyLight.moreCircle,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            _showVideoOptionsMenu(context, widget.video, widget.controller);
                          },
                        ),
                        const SizedBox(height: 40), // Adjusted bottom spacing
                        // Rotating Disc Animation
                        _RotatingDisc(imageUrl: widget.video.user?.photoUrl),
                        const SizedBox(height: 20), // Reduced bottom margin
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Progress Indicator
          if (_playerController != null && _playerController!.value.isInitialized)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _playerController!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Color(0xFF00E5FF),
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white10,
                ),
                padding: const EdgeInsets.only(top: 10),
              ),
            ),
        ],
      ),
    );
  }
}

class _GlassActionButton extends StatefulWidget {
  final IconData icon;
  final String? label;
  final Color? iconColor;
  final VoidCallback onTap;

  const _GlassActionButton({
    required this.icon,
    this.label,
    this.iconColor,
    required this.onTap,
  });

  @override
  State<_GlassActionButton> createState() => _GlassActionButtonState();
}

class _GlassActionButtonState extends State<_GlassActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              // Removed background and border
              child: Icon(
                widget.icon,
                color: widget.iconColor ?? Colors.white,
                size: 32, // Increased slightly from previous reduced size, but no padding
                shadows: const [
                  Shadow(
                    color: Colors.black45,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
            if (widget.label != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.label!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RotatingDisc extends StatefulWidget {
  final String? imageUrl;

  const _RotatingDisc({this.imageUrl});

  @override
  State<_RotatingDisc> createState() => _RotatingDiscState();
}

class _RotatingDiscState extends State<_RotatingDisc> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF222222),
          border: Border.all(color: Colors.grey[800]!, width: 8),
          image: widget.imageUrl != null
              ? DecorationImage(
                  image: NetworkImage(widget.imageUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: widget.imageUrl == null
            ? const Center(
                child: Icon(
                  Icons.music_note,
                  color: Colors.white,
                  size: 20,
                ),
              )
            : null,
      ),
    );
  }
}

String _formatCount(int count) {
  if (count < 1000) {
    return count.toString();
  } else if (count < 1000000) {
    return '${(count / 1000).toStringAsFixed(1)}K';
  } else {
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}

void _showUploadVideoModal(
  BuildContext context,
  VideosController controller,
  bool isDarkMode,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 24),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Text(
                'Crear nuevo post',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _UploadOption(
                  icon: IconlyBold.camera,
                  label: 'Cámara',
                  color: const Color(0xFF00E5FF),
                  onTap: () async {
                    Navigator.pop(context);
                    HapticFeedback.mediumImpact();
                    try {
                      final File? videoFile = await MediaHelper.getVideoFromCamera();
                      if (videoFile != null && Get.context != null) {
                        await _showCaptionDialog(Get.context!, controller, videoFile, isDarkMode);
                      }
                    } catch (e) {
                      DialogHelper.showSnackbarMessage(
                        SnackMsgType.error,
                        'Error al grabar video: ${e.toString()}',
                      );
                    }
                  },
                ),
                _UploadOption(
                  icon: IconlyBold.image,
                  label: 'Galería',
                  color: const Color(0xFFB345F1),
                  onTap: () async {
                    Navigator.pop(context);
                    HapticFeedback.mediumImpact();
                    try {
                      final File? videoFile = await MediaHelper.pickVideo();
                      if (videoFile != null && Get.context != null) {
                        await _showCaptionDialog(Get.context!, controller, videoFile, isDarkMode);
                      }
                    } catch (e) {
                      DialogHelper.showSnackbarMessage(
                        SnackMsgType.error,
                        'Error al seleccionar video: ${e.toString()}',
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  );
}

class _UploadOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _UploadOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showCaptionDialog(
  BuildContext context,
  VideosController controller,
  File videoFile,
  bool isDarkMode,
) async {
  final TextEditingController captionController = TextEditingController();
  
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Agregar descripción',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      content: TextField(
        controller: captionController,
        maxLines: 3,
        maxLength: 150,
        decoration: InputDecoration(
          hintText: 'Escribe una descripción para tu video...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
        ),
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: isDarkMode ? Colors.white60 : Colors.black54,
            ),
          ),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            try {
              await controller.uploadVideo(
                videoFile,
                caption: captionController.text.trim().isEmpty
                    ? null
                    : captionController.text.trim(),
              );
            } catch (e) {
              if (context.mounted) {
                DialogHelper.showSnackbarMessage(
                  SnackMsgType.error,
                  'Error al subir video. Por favor, intenta de nuevo.',
                );
              }
            }
          },
          child: const Text(
            'Subir',
            style: TextStyle(
              color: Color(0xFF00E5FF),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

void _showCommentsModal(BuildContext context, VideosController controller, String videoId) {
  controller.fetchComments(videoId);
  final TextEditingController commentController = TextEditingController();

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF050510), // Deep dark blue/black background
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Title
          const Padding(
            padding: EdgeInsets.only(bottom: 20.0),
            child: Text(
              'Comentarios',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          
          // Comments List
          Expanded(
            child: Obx(() {
              if (controller.isLoadingComments.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00E5FF),
                  ),
                );
              }
              
              if (controller.currentComments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(IconlyLight.chat, size: 64, color: Colors.white.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text(
                        'No hay comentarios aún',
                        style: TextStyle(color: Colors.white.withOpacity(0.5)),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.currentComments.length,
                itemBuilder: (context, index) {
                  final comment = controller.currentComments[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CachedCircleAvatar(
                          imageUrl: comment.user?.photoUrl ?? '',
                          radius: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    comment.user?.fullname ?? 'Usuario',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatTimeAgo(comment.createdAt),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                comment.text,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Like comment button
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 4),
                          child: Icon(
                            IconlyLight.heart,
                            size: 16,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
          
          // Input Area
          Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 16,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF050510),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                CachedCircleAvatar(
                  imageUrl: AuthController.instance.currentUser.photoUrl,
                  radius: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 0.5,
                      ),
                    ),
                    child: TextField(
                      controller: commentController,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: const Color(0xFF00E5FF),
                      decoration: InputDecoration(
                        hintText: 'Añadir un comentario...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    if (commentController.text.trim().isNotEmpty) {
                      HapticFeedback.mediumImpact();
                      controller.addComment(videoId, commentController.text);
                      commentController.clear();
                      FocusScope.of(context).unfocus();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF00E5FF),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x4000E5FF),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      IconlyBold.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

void _showShareModal(BuildContext context, VideosController controller, String videoId) {
  controller.fetchContacts();
  
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Compartir con',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          
          Expanded(
            child: Obx(() {
              if (controller.isLoadingContacts.value) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (controller.contacts.isEmpty) {
                return const Center(child: Text('No tienes contactos aún'));
              }
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.contacts.length,
                itemBuilder: (context, index) {
                  final user = controller.contacts[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CachedCircleAvatar(
                      imageUrl: user.photoUrl,
                      radius: 24,
                    ),
                    title: Text(
                      user.fullname,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Enviar',
                        style: TextStyle(
                          color: Color(0xFF00E5FF),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      
                      try {
                        // Mostrar indicador de carga
                        DialogHelper.showProcessingDialog(
                          title: 'Compartiendo video...',
                          barrierDismissible: false,
                        );
                        
                        // Compartir video usando el videoId pasado al modal
                        await controller.shareVideoWithUser(videoId, user);
                        
                        // Cerrar diálogo
                        Get.back();
                        
                        // Mostrar mensaje de éxito
                        DialogHelper.showSnackbarMessage(
                          SnackMsgType.success,
                          'Video enviado a ${user.fullname}',
                        );
                      } catch (e) {
                        // Cerrar diálogo
                        Get.back();
                        
                        // Mostrar mensaje de error
                        DialogHelper.showSnackbarMessage(
                          SnackMsgType.error,
                          'Error al compartir video: ${e.toString()}',
                        );
                      }
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    ),
  );
}

String _formatTimeAgo(DateTime dateTime) {
  final difference = DateTime.now().difference(dateTime);
  if (difference.inDays > 0) {
    return '${difference.inDays}d';
  } else if (difference.inHours > 0) {
    return '${difference.inHours}h';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes}m';
  } else {
    return 'ahora';
  }
}

void _showVideoOptionsMenu(
  BuildContext context,
  VideoPost video,
  VideosController controller,
) {
  final currentUserId = AuthController.instance.currentUser.userId;
  final isOwner = video.userId == currentUserId;
  
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (isOwner) ...[
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(IconlyBold.delete, color: Colors.red, size: 20),
                ),
                title: const Text(
                  'Eliminar video',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Eliminar video'),
                      content: const Text('¿Estás seguro de que quieres eliminar este video? Esta acción no se puede deshacer.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirm == true) {
                    try {
                      await controller.deleteVideo(video.id);
                      DialogHelper.showSnackbarMessage(
                        SnackMsgType.success,
                        'Video eliminado exitosamente',
                      );
                    } catch (e) {
                      DialogHelper.showSnackbarMessage(
                        SnackMsgType.error,
                        'Error al eliminar video: ${e.toString()}',
                      );
                    }
                  }
                },
              ),
              const Divider(height: 1),
            ],
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(IconlyLight.closeSquare, size: 20),
              ),
              title: const Text('Cerrar'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );
  }

class _CameraUploadScreen extends StatefulWidget {
  final VideosController controller;
  final bool isDarkMode;

  const _CameraUploadScreen({
    required this.controller,
    required this.isDarkMode,
  });

  @override
  State<_CameraUploadScreen> createState() => _CameraUploadScreenState();
}

class _CameraUploadScreenState extends State<_CameraUploadScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIdx = 0;
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isFlashOn = false;
  bool _hasError = false;
  String _errorMessage = '';
  Timer? _recordingTimer;
  int _recordingDuration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      // Request permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      if (statuses[Permission.camera] != PermissionStatus.granted ||
          statuses[Permission.microphone] != PermissionStatus.granted) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Se requieren permisos de cámara y micrófono';
          });
        }
        return;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'No se detectó ninguna cámara';
          });
        }
        return;
      }

      _initController(_cameras[_selectedCameraIdx]);
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Error al iniciar la cámara: $e';
        });
      }
    }
  }

  Future<void> _initController(CameraDescription cameraDescription) async {
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.jpeg : ImageFormatGroup.bgra8888,
    );

    _cameraController = cameraController;

    try {
      await cameraController.initialize();
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing camera controller: $e');
    }
  }

  void _switchCamera() {
    if (_cameras.length < 2) return;
    _selectedCameraIdx = (_selectedCameraIdx + 1) % _cameras.length;
    _initController(_cameras[_selectedCameraIdx]);
  }

  void _toggleFlash() {
    if (_cameraController == null) return;
    _isFlashOn = !_isFlashOn;
    _cameraController!.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_isRecording) return;

    try {
      await _cameraController!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
      });
      
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration++;
        });
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (_cameraController == null || !_isRecording) return;

    try {
      final XFile videoFile = await _cameraController!.stopVideoRecording();
      _recordingTimer?.cancel();
      setState(() {
        _isRecording = false;
      });

      if (mounted) {
        await _showCaptionDialog(context, widget.controller, File(videoFile.path), widget.isDarkMode);
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final File? videoFile = await MediaHelper.pickVideo();
      if (videoFile != null && mounted) {
        await _showCaptionDialog(context, widget.controller, videoFile, widget.isDarkMode);
      }
    } catch (e) {
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'Error al seleccionar video: ${e.toString()}',
      );
    }
  }

  String _formatDuration(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(IconlyBold.image),
                label: const Text('Subir de Galería'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _errorMessage = '';
                  });
                  _initializeCamera();
                },
                child: const Text('Reintentar', style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _cameraController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          Center(
            child: CameraPreview(_cameraController!),
          ),

          // Top Controls
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Flash Toggle
                    IconButton(
                      icon: Icon(
                        _isFlashOn ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: _toggleFlash,
                    ),
                    
                    // Recording Timer
                    if (_isRecording)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _formatDuration(_recordingDuration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                    // Placeholder for symmetry or settings
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Controls
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32, left: 24, right: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Gallery Button
                    if (!_isRecording)
                    GestureDetector(
                      onTap: _pickFromGallery,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(8),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/app_logo.png'), // Placeholder or last image
                            fit: BoxFit.cover,
                            opacity: 0.8,
                          ),
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ) else const SizedBox(width: 48),

                    // Record Button
                    GestureDetector(
                      onTap: () {
                        if (_isRecording) {
                          _stopRecording();
                        } else {
                          _startRecording();
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _isRecording ? 80 : 72,
                        height: _isRecording ? 80 : 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                        ),
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: _isRecording ? 40 : 60,
                            height: _isRecording ? 40 : 60,
                            decoration: BoxDecoration(
                              color: _isRecording ? Colors.red : const Color(0xFF00E5FF),
                              shape: _isRecording ? BoxShape.rectangle : BoxShape.circle,
                              borderRadius: _isRecording ? BorderRadius.circular(8) : null,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Switch Camera Button
                    if (!_isRecording)
                    IconButton(
                      icon: const Icon(
                        Icons.flip_camera_ios_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: _switchCamera,
                    ) else const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
          
          // Back Hint
          if (!_isRecording)
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'Desliza para volver',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BigOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BigOptionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


