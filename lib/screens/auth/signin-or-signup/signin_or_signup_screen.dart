import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/components/app_logo.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'dart:ui';
import 'package:chat_messenger/routes/app_routes.dart';

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
  
  int _currentIndex = 0;
  
  final List<Map<String, String>> _greetings = [
    {'text': 'Hola Mundo', 'language': 'Español'},
    {'text': 'Hello World', 'language': 'English'},
    {'text': '你好世界', 'language': '中文'},
    {'text': 'Bonjour le Monde', 'language': 'Français'},
    {'text': 'Hallo Welt', 'language': 'Deutsch'},
    {'text': 'Ciao Mondo', 'language': 'Italiano'},
    {'text': 'こんにちは世界', 'language': '日本語'},
    {'text': '안녕하세요 세계', 'language': '한국어'},
    {'text': 'Привет мир', 'language': 'Русский'},
    {'text': 'مرحبا بالعالم', 'language': 'العربية'},
    {'text': 'Olá Mundo', 'language': 'Português'},
    {'text': 'Hej Världen', 'language': 'Svenska'},
    {'text': 'Hei Maailma', 'language': 'Suomi'},
    {'text': 'Γεια σου Κόσμε', 'language': 'Ελληνικά'},
    {'text': 'नमस्ते दुनिया', 'language': 'हिंदी'},
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

    _startAnimation();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkThemeBgColor,
      body: Stack(
        children: [
          // Dark background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    darkThemeBgColor,
                    darkPrimaryContainer,
                    darkPrimaryContainer,
                    darkThemeBgColor,
                  ],
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
                  const Spacer(flex: 2),
                  
                  // Custom logo image without shadow
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: Image.asset(
                      'assets/images/logologun.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Remove app name gradient headline (kept space subtle)
                  const SizedBox(height: 8),
                  
                  const SizedBox(height: 60),
                  
                  // Animated Hello World in different languages (restored)
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _slideAnimation.value),
                            child: Transform.scale(
                              scale: _scaleAnimation.value,
                              child: Opacity(
                                opacity: _fadeAnimation.value,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _greetings[_currentIndex]['text']!,
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w600,
                                        color: _colorAnimation.value,
                                        letterSpacing: 1,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _greetings[_currentIndex]['language']!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.grey[400],
                                        letterSpacing: 0.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  const Spacer(flex: 2),

                  // Continue Button with black gradient for dark mode
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF000000), Color(0xFF1A1A1A)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Get.toNamed(AppRoutes.signUpWithEmail),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Continuar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
