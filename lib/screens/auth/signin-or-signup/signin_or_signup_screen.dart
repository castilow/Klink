import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/routes/app_routes.dart';
import 'package:chat_messenger/screens/auth/signup/signup_with_email_screen.dart';
import 'package:chat_messenger/screens/auth/signup/controllers/signup_with_email_controller.dart';
import 'package:chat_messenger/screens/auth/signup/bindings/signup_with_email_binding.dart';
import 'package:video_player/video_player.dart';

class SigninOrSignupScreen extends StatefulWidget {
  const SigninOrSignupScreen({super.key});

  @override
  State<SigninOrSignupScreen> createState() => _SigninOrSignupScreenState();
}

class _SigninOrSignupScreenState extends State<SigninOrSignupScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  late AnimationController _arrowAnimationController;
  late Animation<double> _arrowAnimation;
  late AnimationController _hintAppearController;
  late Animation<double> _hintFadeAnimation;
  late Animation<double> _hintSlideAnimation;
  late AnimationController _swipeController;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _showSwipeHint = false;
  bool _isWelcomeHidden = false;
  Timer? _hintTimer;
  double _dragOffset = 0.0;
  bool _isDragging = false;
  
  int _currentIndex = 0;
  
  final List<Map<String, String>> _greetings = [
    {'text': 'Bienvenidos', 'language': 'Español'},
    {'text': 'Welcome', 'language': 'English'},
    {'text': '欢迎', 'language': '中文'},
    {'text': 'Bienvenue', 'language': 'Français'},
    {'text': 'Willkommen', 'language': 'Deutsch'},
    {'text': 'Benvenuti', 'language': 'Italiano'},
    {'text': 'いらっしゃいませ', 'language': '日本語'},
    {'text': '환영합니다', 'language': '한국어'},
    {'text': 'Добро пожаловать', 'language': 'Русский'},
    {'text': 'أهلاً وسهلاً', 'language': 'العربية'},
    {'text': 'Bem-vindos', 'language': 'Português'},
    {'text': 'Välkommen', 'language': 'Svenska'},
    {'text': 'Tervetuloa', 'language': 'Suomi'},
    {'text': 'Καλώς ήρθατε', 'language': 'Ελληνικά'},
    {'text': 'स्वागत है', 'language': 'हिंदी'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));

    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _colorAnimation = ColorTween(
      begin: Colors.grey[400],
      end: Colors.white,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));

    // Arrow animation controller
    _arrowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _arrowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _arrowAnimationController,
      curve: Curves.easeInOut,
    ));

    // Hint appear animation controller
    _hintAppearController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _hintFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hintAppearController,
      curve: Curves.easeOut,
    ));
    
    _hintSlideAnimation = Tween<double>(
      begin: 20.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _hintAppearController,
      curve: Curves.easeOut,
    ));

    // Swipe animation controller
    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _initializeVideo();
    _startAnimation();
    _startHintTimer();
  }

  void _startHintTimer() {
    _hintTimer = Timer(const Duration(seconds: 7), () {
      if (mounted) {
        setState(() {
          _showSwipeHint = true;
        });
        _hintAppearController.forward().then((_) {
          _arrowAnimationController.repeat(reverse: true);
        });
      }
    });
  }

  void _handleSwipeUp() {
    _hintTimer?.cancel();
    final screenHeight = MediaQuery.of(context).size.height;
    _swipeController.animateTo(1.0).then((_) {
      if (mounted) {
        // Ocultar la pantalla de inicio para mostrar la de registro que ya está detrás
        setState(() {
          _isWelcomeHidden = true;
        });
      }
    });
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (details.delta.dy < 0) { // Deslizando hacia arriba
      setState(() {
        _isDragging = true;
        _dragOffset += details.delta.dy;
        if (_dragOffset > 0) _dragOffset = 0; // No permitir deslizar hacia abajo
        final screenHeight = MediaQuery.of(context).size.height;
        _swipeController.value = (-_dragOffset / screenHeight).clamp(0.0, 1.0);
      });
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
    
    final screenHeight = MediaQuery.of(context).size.height;
    final progress = (-_dragOffset / screenHeight).clamp(0.0, 1.0);
    
    if (progress > 0.3 || (details.primaryVelocity != null && details.primaryVelocity! < -500)) {
      // Completar el deslizamiento
      _hintTimer?.cancel();
      _swipeController.animateTo(1.0).then((_) {
        if (mounted) {
          // Ocultar la pantalla de inicio para mostrar la de registro que ya está detrás
          setState(() {
            _isWelcomeHidden = true;
          });
        }
      });
    } else {
      // Volver a la posición inicial
      _swipeController.animateTo(0.0);
      setState(() {
        _dragOffset = 0.0;
      });
    }
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.asset('assets/videos/logo_grid_opposite_scroll_slow.mp4');
    await _videoController!.initialize();
    _videoController!.setLooping(true);
    _videoController!.setPlaybackSpeed(0.6); // Reproducir más lento pero manteniendo fluidez
    _videoController!.play();
    if (mounted) {
      setState(() {
        _isVideoInitialized = true;
      });
    }
  }

  void _startAnimation() {
    _animationController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _animationController.reverse().then((_) {
            if (mounted) {
              setState(() {
                _currentIndex = (_currentIndex + 1) % _greetings.length;
              });
              _startAnimation();
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _arrowAnimationController.dispose();
    _hintAppearController.dispose();
    _swipeController.dispose();
    _hintTimer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final currentOffset = _isDragging ? _dragOffset : -(_swipeController.value * screenHeight);
    
    return Scaffold(
      backgroundColor: darkThemeBgColor,
      body: Stack(
        children: [
          // Pantalla de registro detrás (solo se muestra cuando se desliza)
          if (_swipeController.value > 0.0 || _isDragging || _isWelcomeHidden)
            Positioned.fill(
              child: Builder(
                builder: (context) {
                  // Inicializar el controller solo una vez
                  if (!Get.isRegistered<SignUpWithEmailController>()) {
                    Get.put(SignUpWithEmailController());
                  }
                  return GetBuilder<SignUpWithEmailController>(
                    builder: (controller) {
                      return const SignUpWithEmailScreen();
                    },
                  );
                },
              ),
            ),
          
          // Pantalla actual (welcome) que se desliza hacia arriba
          if (!_isWelcomeHidden)
            GestureDetector(
              onVerticalDragUpdate: _onVerticalDragUpdate,
              onVerticalDragEnd: _onVerticalDragEnd,
              child: Transform.translate(
                offset: Offset(0, currentOffset),
                child: Container(
                  height: screenHeight,
                  width: double.infinity,
                  child: _buildWelcomeScreen(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Stack(
      children: [
          // Background video
          Positioned.fill(
            child: _isVideoInitialized && _videoController != null
                ? RepaintBoundary(
                    child: SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _videoController!.value.size.width,
                          height: _videoController!.value.size.height,
                          child: VideoPlayer(_videoController!),
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: darkThemeBgColor,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
          
          // Main content
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 1),
                  const SizedBox(height: 30),
                  
                  // Animated "Bienvenidos" in different languages - centered
                  Center(
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Opacity(
                              opacity: _fadeAnimation.value,
                              child: Text(
                                _greetings[_currentIndex]['text']!,
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w600,
                                  color: _colorAnimation.value,
                                  letterSpacing: 1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const Spacer(flex: 1),

                  // Swipe hint with animated arrows
                  if (_showSwipeHint)
                    AnimatedBuilder(
                      animation: Listenable.merge([_hintAppearController, _arrowAnimation]),
                      builder: (context, child) {
                        return Opacity(
                          opacity: _hintFadeAnimation.value * (0.7 + (_arrowAnimation.value * 0.3)),
                          child: Transform.translate(
                            offset: Offset(0, _hintSlideAnimation.value),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Animated arrows
                                Transform.translate(
                                  offset: Offset(0, -_arrowAnimation.value * 10),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.keyboard_arrow_up,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                      SizedBox(height: 4),
                                      Icon(
                                        Icons.keyboard_arrow_up,
                                        color: Colors.white.withOpacity(0.7),
                                        size: 28,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Text
                                Text(
                                  'Desliza hacia arriba',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  else
                    const SizedBox(height: 60),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
