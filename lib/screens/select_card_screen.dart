import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/theme/app_theme.dart';
import 'package:chat_messenger/routes/app_routes.dart';

class SelectCardScreen extends StatefulWidget {
  const SelectCardScreen({super.key});

  @override
  State<SelectCardScreen> createState() => _SelectCardScreenState();
}

class _SelectCardScreenState extends State<SelectCardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = AppTheme.of(context).isDarkMode;

    final cardDesigns = [
      {
        'id': 'classic',
        'name': 'Clásica',
        'description': 'Diseño elegante y minimalista',
        'image': 'assets/images/crypto/visa_grey.png',
        'color': const Color(0xFF1A1A1A),
      },
      {
        'id': 'premium',
        'name': 'Premium',
        'description': 'Acabado dorado exclusivo',
        'image': 'assets/images/crypto/mastercard_gold.png',
        'color': const Color(0xFFD4AF37),
      },
      {
        'id': 'ultra',
        'name': 'Ultra',
        'description': 'Diseño futurista y moderno',
        'image': 'assets/images/crypto/ultra_grey.png',
        'color': const Color(0xFF2C2C2E),
      },
    ];

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF000000) : Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Get.back();
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF1C1C1E)
                                : const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(12),
                            border: isDarkMode
                                ? Border.all(
                                    color: const Color(0xFF404040).withOpacity(0.6),
                                    width: 1,
                                  )
                                : Border.all(
                                    color: const Color(0xFFE5E5EA),
                                    width: 1,
                                  ),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: isDarkMode
                                ? const Color(0xFF8E8E93)
                                : const Color(0xFF6D6D70),
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Personaliza tu tarjeta',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Elige el diseño que más te guste',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF6D6D70),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Card Designs
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ListView.separated(
                      itemCount: cardDesigns.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final cardDesign = cardDesigns[index];
                        return _buildCardDesignItem(
                          cardDesign,
                          index,
                          isDarkMode,
                        );
                      },
                    ),
                  ),
                ),

                // Continue Button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      // Notificaciones generales deshabilitadas
                      Future.delayed(const Duration(seconds: 2), () {
                        Get.back();
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDarkMode
                              ? [const Color(0xFF007AFF), const Color(0xFF5856D6)]
                              : [const Color(0xFF007AFF), const Color(0xFF5856D6)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF007AFF).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Continuar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardDesignItem(
    Map<String, dynamic> cardDesign,
    int index,
    bool isDarkMode,
  ) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final delay = index * 0.1;
        final animationValue = (_animationController.value - delay).clamp(0.0, 1.0);
        
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animationValue)),
          child: Opacity(
            opacity: animationValue,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                // Handle card design selection
              },
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF1C1C1E)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: isDarkMode
                      ? Border.all(
                          color: const Color(0xFF404040).withOpacity(0.6),
                          width: 1,
                        )
                      : Border.all(
                          color: const Color(0xFFE5E5EA),
                          width: 1,
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Card Preview
                    Container(
                      width: 80,
                      height: 50,
                      decoration: BoxDecoration(
                        color: cardDesign['color'],
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: cardDesign['color'].withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          cardDesign['image']!,
                          width: 80,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 50,
                              decoration: BoxDecoration(
                                color: cardDesign['color'],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.credit_card,
                                color: Colors.white,
                                size: 24,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cardDesign['name']!,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cardDesign['description']!,
                            style: TextStyle(
                              color: isDarkMode
                                  ? const Color(0xFF8E8E93)
                                  : const Color(0xFF6D6D70),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Selection Indicator
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDarkMode
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF6D6D70),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == 0 // First card selected by default
                                ? const Color(0xFF007AFF)
                                : Colors.transparent,
                          ),
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
} 