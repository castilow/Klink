import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/theme/app_theme.dart';
import 'package:chat_messenger/models/cards/card_type_model.dart';
import 'package:chat_messenger/routes/app_routes.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String _activeTab = "debito";

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
    final cardTypes = CardTypeModel.cardTypes;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF000000) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF000000) : Colors.white,
        elevation: 0,
        leadingWidth: 72, // Espacio justo para la alineación perfecta
        leading: Padding(
          padding: const EdgeInsets.only(left: 24), // Alineado con el texto "Escoge tus tarjetas"
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
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      child: Text(
                        'Escoge tus tarjetas',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),

                    // Tabs
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      child: Row(
                        children: [
                          _buildTab("debito", "Débito", isDarkMode),
                        ],
                      ),
                    ),

                    // Card Types
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            ...cardTypes.asMap().entries.map((entry) {
                              int index = entry.key;
                              CardTypeModel cardType = entry.value;
                              return _buildCardTypeItem(cardType, index, isDarkMode);
                            }).toList(),
                          ],
                        ),
                      ),
                    ),

                    // Link Existing Card
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            // Handle link existing card
                          },
                          child: Text(
                            '¿Tienes una tarjeta? Vincular ahora',
                            style: TextStyle(
                              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF64748B),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
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

  Widget _buildTab(String id, String text, bool isDarkMode) {
    final bool isActive = _activeTab == id;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _activeTab = id;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
              ? (isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7))
              : (isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode 
                ? const Color(0xFF404040).withOpacity(0.6)
                : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isDarkMode ? Colors.white : const Color(0xFF374151),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCardTypeItem(CardTypeModel cardType, int index, bool isDarkMode) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 150)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Get.toNamed(AppRoutes.selectCard);
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
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
                          : Border.all(
                              color: const Color(0xFFE5E7EB),
                              width: 1,
                            ),
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
                              cardType.imagePath,
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
                        
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cardType.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                cardType.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF64748B),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Arrow
                        Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}