import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _cardController;
  late AnimationController _shimmerController;
  late List<AnimationController> _flipControllers;
  late Animation<double> _cardAnimation;
  late Animation<double> _shimmerAnimation;
  late List<Animation<double>> _flipAnimations;
  
  int _currentCardIndex = 0;
  List<bool> _isCardFrozenList = [];
  List<bool> _showCVVList = [];
  List<bool> _showFullNumberList = [];

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
        
    // Controlador para animación de brillo
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
        
    // Inicializar controladores de flip para ambas tarjetas
    _flipControllers = List.generate(
      _mockCards.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      ),
    );
        
    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
    );
        
    // Animación de brillo
    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
        
    // Crear animaciones de flip para ambas tarjetas
    _flipAnimations = _flipControllers.map((controller) =>
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      ),
    ).toList();
    
    // Inicializar estados para ambas tarjetas
    _showCVVList = List.generate(_mockCards.length, (index) => false);
    _isCardFrozenList = List.generate(_mockCards.length, (index) => _mockCards[index]['isFrozen'] as bool);
    _showFullNumberList = List.generate(_mockCards.length, (index) => false);
    
    _cardController.forward();
        
    // Iniciar animación de brillo repetitiva
    _shimmerController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _cardController.dispose();
    _shimmerController.dispose();
    for (var controller in _flipControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Función para obtener dimensiones responsivas
  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 375.0; // Base iPhone size
    return baseSize * scaleFactor.clamp(0.8, 1.4);
  }

  // Altura exacta de la tarjeta basada en proporción de tarjeta de crédito real
  double _getCardHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = _getCardWidth(context);
    // Proporción estándar de tarjeta de crédito: 85.60 × 53.98 mm (ratio ~1.586)
    return cardWidth / 1.586;
  }

  double _getCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final viewportFraction = _getViewportFraction(context);
    return screenWidth * viewportFraction - 32; // Restamos márgenes
  }

  double _getViewportFraction(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
        
    if (screenWidth < 360) return 0.95; // Pantallas muy pequeñas
    if (screenWidth < 400) return 0.92; // Pantallas pequeñas
    if (screenWidth > 600) return 0.85; // Tablets
    return 0.9; // Pantallas normales
  }

  EdgeInsets _getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
        
    if (screenWidth < 360) return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
    if (screenWidth < 400) return const EdgeInsets.symmetric(horizontal: 20, vertical: 18);
    if (screenWidth > 600) return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
  }

  @override
  Widget build(BuildContext context) {
    final responsivePadding = _getResponsivePadding(context);
    final cardHeight = _getCardHeight(context);
    final viewportFraction = _getViewportFraction(context);
        
    // Inicializar PageController con viewport fraction responsivo
    _pageController = PageController(viewportFraction: viewportFraction);
    
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC),
      // Quitar completamente el appBar
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: _getResponsiveSize(context, 8)), // Reducido de 16 a 8
              // Cards Section - Sin contenedor limitante, con overflow visible
              AnimatedBuilder(
                animation: _cardAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.8 + (0.2 * _cardAnimation.value),
                    child: Container(
                      height: cardHeight + 100, // Espacio extra para animaciones
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentCardIndex = index;
                          });
                        },
                        itemCount: _mockCards.length,
                        itemBuilder: (context, index) {
                          return Container(
                            // Sin restricciones de altura, permitir overflow
                            child: _buildCreditCard(_mockCards[index], index, context),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
              
              // Indicadores de página
              SizedBox(height: _getResponsiveSize(context, 12)), // Reducido de 20 a 12
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _mockCards.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentCardIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                                          color: _currentCardIndex == index 
                        ? (isDark ? Colors.white : Colors.grey[800])
                        : (isDark ? Colors.grey[600] : Colors.grey[400]),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: _getResponsiveSize(context, 24)), // Reducido de 32 a 24
              // Quick Actions - Solo para la tarjeta actual
              Padding(
                padding: responsivePadding,
                child: _buildQuickActions(context, isDark),
              ),
              SizedBox(height: _getResponsiveSize(context, 24)), // Reducido de 32 a 24
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreditCard(Map<String, dynamic> cardData, int index, BuildContext context) {
    final isFrozen = _isCardFrozenList[index];
    final cardType = cardData['type'] as String;
    final cardWidth = _getCardWidth(context);
    final cardHeight = _getCardHeight(context);
        
    return Center(
      child: GestureDetector(
        onTap: () => _handleCardTap(index),
        child: AnimatedBuilder(
          animation: _flipAnimations[index],
          builder: (context, child) {
            final isShowingFront = _flipAnimations[index].value < 0.5;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(_flipAnimations[index].value * math.pi),
              child: isShowingFront
                   ? _buildCardFront(cardData, isFrozen, cardType, context, index, cardWidth, cardHeight)
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: _buildCardBack(cardData, context, index, cardWidth, cardHeight),
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardFront(Map<String, dynamic> cardData, bool isFrozen, String cardType, BuildContext context, int index, double cardWidth, double cardHeight) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardPadding = screenWidth < 400 ? 24.0 : 32.0;
    final borderRadius = 16.0; // Bordes más redondeados para tarjetas modernas
    final cardBackground = cardData['background'] as String; // Obtener imagen específica
        
    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: AnimatedBuilder(
          animation: _shimmerAnimation,
          builder: (context, child) {
            return Stack(
              children: [
                // Imagen de fondo de la tarjeta - específica para cada tarjeta
                Positioned.fill(
                  child: Image.asset(
                    cardBackground,
                    fit: BoxFit.cover,
                  ),
                ),
                                
                // Efecto de brillo
                Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(_shimmerAnimation.value * cardWidth, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.5),
                            Colors.white.withOpacity(0.3),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                                
                // Frozen overlay
                if (isFrozen)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(borderRadius),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              IconlyBold.lock,
                               color: Colors.white,
                               size: _getResponsiveSize(context, 48)
                            ),
                            SizedBox(height: _getResponsiveSize(context, 16)),
                            Text(
                              'TARJETA CONGELADA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: _getResponsiveSize(context, 18),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                              ),
                            ),
                            SizedBox(height: _getResponsiveSize(context, 8)),
                            Text(
                              'Transacciones bloqueadas',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: _getResponsiveSize(context, 14),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Card content - Solo mostrar si NO está congelada
                if (!isFrozen)
                  Positioned(
                    bottom: 16, // Reducido de cardPadding a 16 para bajar más los números
                    left: cardPadding,
                    right: cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Número de tarjeta
                        Text(
                          '..${(cardData['number'] as String).substring((cardData['number'] as String).length - 4)}',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth < 400 ? 12 : _getResponsiveSize(context, 14),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            shadows: const [
                              Shadow(
                                color: Colors.white,
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: _getResponsiveSize(context, 8)), // Reducido de 34 a 8 para bajar más
                        // Nombre del titular - solo mostrar si existe
                        if (cardData.containsKey('holderName'))
                          Text(
                            cardData['holderName'] as String,
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.8),
                              fontSize: _getResponsiveSize(context, 12),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                              shadows: const [
                                Shadow(
                                  color: Colors.white,
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardBack(Map<String, dynamic> cardData, BuildContext context, int index, double cardWidth, double cardHeight) {
    final screenWidth = MediaQuery.of(context).size.width;
    final borderRadius = 16.0;
    final cardPadding = screenWidth < 400 ? 24.0 : 32.0;
    final isFrozen = _isCardFrozenList[index];
    final cardBackground = cardData['background'] as String; // Obtener imagen específica
        
    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: AnimatedBuilder(
          animation: _shimmerAnimation,
          builder: (context, child) {
            return Stack(
              children: [
                // Imagen de fondo de la tarjeta - específica para cada tarjeta
                Positioned.fill(
                  child: Image.asset(
                    cardBackground,
                    fit: BoxFit.cover,
                  ),
                ),
                                
                // Overlay más oscuro para la parte trasera
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ),
                ),
                                
                // Efecto de brillo
                Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(_shimmerAnimation.value * cardWidth, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.2),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                // Magnetic stripe
                Positioned(
                  top: cardHeight * 0.15, // Posición proporcional
                  left: 0,
                  right: 0,
                  child: Container(
                    height: cardHeight * 0.12, // Altura proporcional
                    color: Colors.black,
                  ),
                ),
                // Frozen overlay para parte trasera
                if (isFrozen)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(borderRadius),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              IconlyBold.lock,
                               color: Colors.white,
                               size: _getResponsiveSize(context, 48)
                            ),
                            SizedBox(height: _getResponsiveSize(context, 16)),
                            Text(
                              'TARJETA CONGELADA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: _getResponsiveSize(context, 18),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                              ),
                            ),
                            SizedBox(height: _getResponsiveSize(context, 8)),
                            Text(
                              'Información oculta',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: _getResponsiveSize(context, 14),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Card content - Solo mostrar si NO está congelada
                if (!isFrozen)
                  Positioned(
                    bottom: cardPadding,
                    left: cardPadding,
                    right: cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Número de tarjeta
                        Text(
                          _showFullNumberList[index]
                               ? _formatFullCardNumber(cardData['number'] as String)
                              : _formatCardNumber(cardData['number'] as String),
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth < 400 ? 14 : _getResponsiveSize(context, 16),
                            fontWeight: FontWeight.w900,
                            letterSpacing: screenWidth < 400 ? 1.5 : 2,
                            shadows: const [
                              Shadow(
                                color: Colors.white,
                                offset: Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: _getResponsiveSize(context, 16)),
                        // Fecha de vencimiento y CVV juntos
                        Row(
                          children: [
                            // Fecha de vencimiento
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'VÁLIDA HASTA',
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.8),
                                    fontSize: _getResponsiveSize(context, 10),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                SizedBox(height: _getResponsiveSize(context, 4)),
                                Text(
                                  cardData['expiryDate'] as String,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: screenWidth < 400 ? 14 : _getResponsiveSize(context, 16),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.white,
                                        offset: Offset(0, 1),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                                                                        
                            SizedBox(width: cardWidth * 0.15), // Espacio proporcional
                                                                        
                            // CVV al lado de la fecha
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CVV',
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.8),
                                    fontSize: _getResponsiveSize(context, 10),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                SizedBox(height: _getResponsiveSize(context, 4)),
                                Text(
                                  cardData['cvv'] as String,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: _getResponsiveSize(context, 16),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.white,
                                        offset: Offset(0, 1),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.all(_getResponsiveSize(context, 28)),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: BorderRadius.circular(_getResponsiveSize(context, 28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: _getResponsiveSize(context, 32),
            offset: Offset(0, _getResponsiveSize(context, 16)),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _handleFreezeCard(_currentCardIndex),
              child: _buildQuickActionItem(
                context: context,
                icon: _isCardFrozenList[_currentCardIndex] ? IconlyBold.unlock : IconlyBold.lock,
                label: _isCardFrozenList[_currentCardIndex] ? 'Descongelar' : 'Congelar',
                color: _isCardFrozenList[_currentCardIndex]
                     ? const Color(0xFF10B981)
                     : const Color(0xFFF59E0B),
                isDark: isDark,
              ),
            ),
          ),
          SizedBox(width: _getResponsiveSize(context, 20)),
          Expanded(
            child: GestureDetector(
              onTap: () => _handleShowFullNumber(_currentCardIndex),
              child: _buildQuickActionItem(
                context: context,
                icon: IconlyBold.show,
                label: 'Ver Número',
                color: isDark ? Colors.grey[300]! : Colors.grey[800]!,
                isDark: isDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Container(
          width: _getResponsiveSize(context, 64),
          height: _getResponsiveSize(context, 64),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark ? [
                color.withOpacity(0.2),
                color.withOpacity(0.1),
              ] : [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20)),
            border: Border.all(
              color: isDark ? color.withOpacity(0.4) : color.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: _getResponsiveSize(context, 28),
          ),
        ),
        SizedBox(height: _getResponsiveSize(context, 16)),
        Text(
          label,
          style: TextStyle(
            fontSize: _getResponsiveSize(context, 15),
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatCardNumber(String number) {
    return '**** **** **** ${number.substring(number.length - 4)}';
  }

  String _formatFullCardNumber(String number) {
    return number.replaceAllMapped(
      RegExp(r'(\d{4})(?=\d)'),
      (match) => '${match.group(1)} ',
    );
  }

  void _handleCardTap(int cardIndex) {
    if (_showCVVList[cardIndex]) {
      _flipControllers[cardIndex].reverse();
      setState(() {
        _showCVVList[cardIndex] = false;
      });
    } else {
      _flipControllers[cardIndex].forward();
      setState(() {
        _showCVVList[cardIndex] = true;
      });
            
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted && _showCVVList[cardIndex]) {
          _flipControllers[cardIndex].reverse();
          setState(() {
            _showCVVList[cardIndex] = false;
          });
        }
      });
            
      // Notificaciones deshabilitadas
    }
  }

  void _handleFreezeCard(int cardIndex) {
    setState(() {
      _isCardFrozenList[cardIndex] = !_isCardFrozenList[cardIndex];
      _mockCards[cardIndex]['isFrozen'] = _isCardFrozenList[cardIndex];
    });
        
    // Notificaciones deshabilitadas
  }

  void _handleShowFullNumber(int cardIndex) {
    if (_isCardFrozenList[cardIndex]) {
      // Notificaciones deshabilitadas
      return;
    }
        
    setState(() {
      _showFullNumberList[cardIndex] = !_showFullNumberList[cardIndex];
    });
        
    if (_showFullNumberList[cardIndex]) {
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) {
          setState(() {
            _showFullNumberList[cardIndex] = false;
          });
        }
      });
            
      // Notificaciones deshabilitadas
    }
  }

  // Ahora con 4 tarjetas - Cada una con su imagen de fondo específica
  final List<Map<String, dynamic>> _mockCards = [
    {
      'type': 'ULTRA',
      'number': '1234567890123456',
      'expiryDate': '12/28',
      'cvv': '123',
      'limit': '€15.000,00',
      'monthlyUsed': '€3.456,78',
      'isFrozen': false,
      'background': 'assets/images/card_ultra_grey.png', // Imagen específica para la primera tarjeta
    },
    {
      'type': 'MASTERCARD',
      'number': '9876543210987654',
      'expiryDate': '06/29',
      'cvv': '456',
      'limit': '€20.000,00',
      'monthlyUsed': '€5.234,12',
      'isFrozen': false,
      'background': 'assets/images/card_mastercard_gold.png', // Imagen específica para la segunda tarjeta
    },
    {
      'type': 'VISA',
      'number': '4532123456789012',
      'expiryDate': '03/27',
      'cvv': '789',
      'limit': '€12.000,00',
      'monthlyUsed': '€2.890,45',
      'isFrozen': false,
      'background': 'assets/images/card_visa_grey.png', // Imagen específica para la tercera tarjeta
    },
    {
      'type': 'MASTERCARD',
      'number': '5555444433332222',
      'expiryDate': '09/26',
      'cvv': '321',
      'limit': '€8.500,00',
      'monthlyUsed': '€1.567,89',
      'isFrozen': false,
      'background': 'assets/images/card_mastercard_white.png', // Imagen específica para la cuarta tarjeta
    },
  ];
}