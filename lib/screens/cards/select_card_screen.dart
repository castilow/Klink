import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/theme/app_theme.dart';
import 'package:chat_messenger/models/cards/card_model.dart';
import 'dart:math' as math;

class SelectCardScreen extends StatefulWidget {
  const SelectCardScreen({super.key});

  @override
  State<SelectCardScreen> createState() => _SelectCardScreenState();
}

class _SelectCardScreenState extends State<SelectCardScreen>
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  
  int _currentCardIndex = 0;
  PageController? _pageController;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    try {
      // Inicializar PageController
      _pageController = PageController(
        viewportFraction: 0.8,
        initialPage: _currentCardIndex,
      );
      
      // Inicializar AnimationController simple
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );

      // Crear animación fade simple
      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
      );

      // Iniciar animación después del primer frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _animationController != null) {
          _animationController!.forward();
        }
      });
    } catch (e) {
      debugPrint('Error initializing controllers: $e');
    }
  }

  @override
  void dispose() {
    _cleanupControllers();
    super.dispose();
  }

  void _cleanupControllers() {
    try {
      // Limpiar PageController
      if (_pageController != null) {
        _pageController!.dispose();
        _pageController = null;
      }

      // Limpiar AnimationController
      if (_animationController != null) {
        _animationController!.stop();
        _animationController!.dispose();
        _animationController = null;
      }

      // Limpiar referencia a la animación
      _fadeAnimation = null;
    } catch (e) {
      debugPrint('Error disposing controllers: $e');
    }
  }

  void _onPageChanged(int index) {
    if (!mounted) return;
    
    setState(() {
      _currentCardIndex = index;
    });
    
    // Activar animación simple
    _triggerCardAnimation();
    HapticFeedback.selectionClick();
  }

  void _triggerCardAnimation() {
    if (!mounted || _isAnimating) return;
    
    setState(() {
      _isAnimating = true;
    });
    
    // Animación simple sin controladores complejos
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _isAnimating = false;
        });
      }
    });
  }

  void _changeCard(int newIndex) {
    if (!mounted || _pageController == null || !_pageController!.hasClients) return;
    
    _pageController!.animateToPage(
      newIndex,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildCardItem(CardModel card, bool isActive, bool isDarkMode) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: isActive ? (0.85 + (0.15 * value)) : 0.82,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 25),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isActive ? 0.3 : 0.15),
                  blurRadius: isActive ? 25 : 15,
                  offset: Offset(0, isActive ? 15 : 8),
                  spreadRadius: isActive ? 5 : 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 1.586,
                child: Stack(
                  children: [
                    Image.asset(
                      card.imagePath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                          child: Icon(
                            Icons.credit_card,
                            color: isDarkMode ? Colors.white54 : Colors.black54,
                            size: 48,
                          ),
                        );
                      },
                    ),
                    if (_isAnimating && isActive)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.5),
                            width: 2,
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

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = AppTheme.of(context).isDarkMode;
    final cards = CardModel.selectableCards;
    final currentCard = cards[_currentCardIndex];

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF000000) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF000000) : const Color(0xFFF8FAFC),
        elevation: 0,
        leadingWidth: 72, // Espacio justo para la alineación perfecta
        leading: Padding(
          padding: const EdgeInsets.only(left: 24), // Alineado con el padding del contenido
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Get.back();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8), // Solo margin vertical
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(12),
                border: isDarkMode
                    ? Border.all(
                        color: const Color(0xFF404040).withOpacity(0.6),
                        width: 1,
                      )
                    : null,
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF64748B),
                size: 18,
              ),
            ),
          ),
        ),
      ),
      body: _animationController != null && _fadeAnimation != null
          ? AnimatedBuilder(
              animation: _animationController!,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation!,
                  child: _buildMainContent(isDarkMode, cards, currentCard),
                );
              },
            )
          : _buildMainContent(isDarkMode, cards, currentCard),
    );
  }

  Widget _buildMainContent(bool isDarkMode, List<CardModel> cards, CardModel currentCard) {
    return SafeArea(
      child: Column(
        children: [
          // Card Display Section
          Expanded(
            flex: 3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // PageView con scroll horizontal fluido
                          Container(
                            height: 250,
                            child: _pageController != null
                                ? PageView.builder(
                                    controller: _pageController!,
                                    onPageChanged: _onPageChanged,
                                    itemCount: cards.length,
                                    physics: const BouncingScrollPhysics(),
                                    clipBehavior: Clip.none,
                                    itemBuilder: (context, index) {
                                      final card = cards[index];
                                      final isActive = index == _currentCardIndex;
                                      
                                      return _buildCardItem(card, isActive, isDarkMode);
                                    },
                                  )
                                : const Center(child: CircularProgressIndicator()),
                          ),
                        
                        const SizedBox(height: 40),
                        
                        // Card Info
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  currentCard.name,
                                  key: ValueKey('${currentCard.id}-name'),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  currentCard.description,
                                  key: ValueKey('${currentCard.id}-desc'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF64748B),
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Navigation Dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: cards.asMap().entries.map((entry) {
                            int index = entry.key;
                            return GestureDetector(
                              onTap: () => _changeCard(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: _currentCardIndex == index ? 32 : 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: _currentCardIndex == index
                                      ? (isDarkMode ? Colors.white : Colors.black)
                                      : (isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Scroll Indicator
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDarkMode 
                                      ? const Color(0xFF404040).withOpacity(0.6)
                                      : const Color(0xFFE5E7EB),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.swipe,
                                    color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Desliza para explorar',
                                    style: TextStyle(
                                      color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Order Button
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _showOrderConfirmation(currentCard, isDarkMode);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
                          foregroundColor: isDarkMode ? Colors.white : Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: isDarkMode 
                                ? const Color(0xFF404040).withOpacity(0.6)
                                : const Color(0xFFE5E7EB),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          'Pedir tarjeta por ${currentCard.price}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
        ],
      ),
    );
  }

  void _showOrderConfirmation(CardModel card, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Success icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Color(0xFF10B981),
                  size: 30,
                ),
              ),
              
              const SizedBox(height: 20),
              
              Text(
                'Pedido confirmado',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'Tu tarjeta ${card.name} llegará en 3-5 días hábiles',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (mounted) {
                      Navigator.pop(context);
                      Get.back();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}