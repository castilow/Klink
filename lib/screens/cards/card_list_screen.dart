import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/theme/app_theme.dart';
import 'package:chat_messenger/models/cards/card_model.dart';
import 'package:chat_messenger/routes/app_routes.dart';

class CardListScreen extends StatefulWidget {
  const CardListScreen({super.key});

  @override
  State<CardListScreen> createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen>
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
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
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
    final cards = CardModel.sampleCards;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF000000) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF000000) : const Color(0xFFF8FAFC),
        elevation: 0,
        leadingWidth: 72, // Espacio justo para la alineación perfecta
        leading: Padding(
          padding: const EdgeInsets.only(left: 24), // Alineado con el texto "Tarjetas"
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
                Icons.close,
                color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF64748B),
                size: 20,
              ),
            ),
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Text(
                        'Tarjetas',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),

                    // Cards List
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: isDarkMode 
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: isDarkMode
                                ? Border.all(
                                    color: const Color(0xFF404040).withOpacity(0.2),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: cards.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final card = cards[index];
                              return _buildCardItem(card, index, isDarkMode);
                            },
                          ),
                        ),
                      ),
                    ),

                    // Add Button
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Get.toNamed(AppRoutes.addCard);
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
                            foregroundColor: isDarkMode ? Colors.white : Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                              side: BorderSide(
                                color: isDarkMode 
                                    ? const Color(0xFF404040).withOpacity(0.6)
                                    : const Color(0xFFE5E7EB),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                size: 20,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Añadir',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardItem(CardModel card, int index, bool isDarkMode) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: isDarkMode
                    ? Border.all(
                        color: const Color(0xFF404040).withOpacity(0.3),
                        width: 1,
                      )
                    : null,
              ),
              child: Row(
                children: [
                  // Card Image
                  Container(
                    width: 64,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        card.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                            child: Icon(
                              Icons.credit_card,
                              color: isDarkMode ? Colors.white54 : Colors.black54,
                              size: 24,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Card Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Badge or Status
                  if (card.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        card.badge!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : const Color(0xFF374151),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}