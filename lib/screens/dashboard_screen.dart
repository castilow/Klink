import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import '../config/theme_config.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';
import '../controllers/investment_controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _counterController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _counterAnimation;

  // Variable para controlar si las animaciones ya se ejecutaron
  bool _hasAnimatedOnce = false;

  // Controlador de inversión
  late InvestmentController _investmentController;

  @override
  void initState() {
    super.initState();
    
    // Inicializar controlador de inversión
    _investmentController = Get.put(InvestmentController());
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _counterController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _counterAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _counterController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();

    // Solo animar los contadores si no se ha hecho antes
    if (!_hasAnimatedOnce) {
      _counterController.forward().then((_) {
        _hasAnimatedOnce = true;
      });
    } else {
      // Si ya se animó antes, ir directamente al final
      _counterController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _counterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Force light theme styles for this screen to ensure visibility on white background
    const bool isDark = false;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contadores principales estilo premium
                _buildCountersGrid(isDark),
                const SizedBox(height: 24),

                // Sección de premio total con bandera (ancho completo)
                _buildPrizeSection(isDark),
                const SizedBox(height: 24),

                // Movimientos recientes
                _buildRecentTransactions(isDark),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountersGrid(bool isDark) {
    return Column(
      children: [
        // Contador principal - Total acumulado
        _buildMainCounter(isDark),
        const SizedBox(height: 20),

        // Grid de contadores secundarios
        Row(
          children: [
            Expanded(
              child: _buildSecondaryCounter(
                'Restaurantes'.tr,
                0.00,
                '🍽️',
                '+0.0%',
                isDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSecondaryCounter('Compras'.tr, 0.00, '🛍️', '+0.0%', isDark),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSecondaryCounter(
                'Transporte'.tr,
                0.00,
                '🚗',
                '+0.0%',
                isDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSecondaryCounter(
                'Entretenimiento'.tr,
                0.00,
                '🎬',
                '+0.0%',
                isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainCounter(bool isDark) {
    return Obx(() => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!, width: 1),
      ),
      child: Column(
        children: [
          // Icono principal
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
              shape: BoxShape.circle,
              border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 1),
            ),
            child: const Center(
              child: Text('💰', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 28),

          // Contador animado - Mostrar valor de portfolio si está conectado
          AnimatedBuilder(
            animation: _counterAnimation,
            builder: (context, child) {
              final displayAmount = _investmentController.isConnected.value
                  ? _investmentController.portfolioValue.value
                  : (_hasAnimatedOnce 
                      ? 0.00 
                      : (0.00 * _counterAnimation.value));
              return Text(
                '${displayAmount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} €',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -1.2,
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          Text(
            'Patrimonio Total'.tr,
            style: TextStyle(
              fontSize: 18,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          
          // Mostrar balance de BNB si está conectado
          if (_investmentController.isConnected.value) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.currency_bitcoin,
                    color: isDark ? Colors.grey[300] : Colors.grey[600],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_investmentController.bnbBalance.value.toStringAsFixed(6)} BNB',
                    style: TextStyle(
                      color: isDark ? Colors.grey[300] : Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Indicador de crecimiento cuando está conectado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.trending_up,
                      color: Colors.grey[900],
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '+0.0% este mes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Botón de conectar wallet cuando NO está conectado
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: _investmentController.isConnecting.value 
                      ? null 
                      : () => _investmentController.connectWallet(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_investmentController.isConnecting.value)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        else ...[
                          const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Conectar Wallet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ));
  }

  Widget _buildSecondaryCounter(
    String title,
    double amount,
    String emoji,
    String percentage,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 1),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 20)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  percentage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _counterAnimation,
            builder: (context, child) {
              final displayAmount = _hasAnimatedOnce
                  ? amount
                  : (amount * _counterAnimation.value);
              return Text(
                '${displayAmount.toStringAsFixed(0)} €',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.5,
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrizeSection(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Icono de premio
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(
              child: Text('🏆', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 24),

          // Premio total
          const Text(
            '€0',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Premio Total'.tr,
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[300],
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24),

          // Bandera y país
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: const Text('🇪🇸', style: TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'España',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 20),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  IconlyLight.activity,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Movimientos Recientes'.tr,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111111) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
            border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!, width: 1),
          ),
          child: Column(
            children: [
              _buildTransactionItem(
                'assets/logos/companies/pizza_hut.png',
                'Pizza Hut',
                'Hoy, 14:30',
                0.00,
                isDark,
              ),
              _buildTransactionItem(
                'assets/logos/companies/starbucks.png',
                'Starbucks',
                'Hoy, 09:15',
                0.00,
                isDark,
              ),
              _buildTransactionItem(
                'assets/logos/companies/uber.png',
                'Uber',
                'Ayer, 18:45',
                0.00,
                isDark,
              ),
              _buildTransactionItem('💰', 'Salario', '25 Jul', 0.00, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(
    String emoji,
    String title,
    String date,
    double amount,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
              shape: BoxShape.circle,
              border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 1),
            ),
            child: Center(
              child: emoji.contains('assets/')
                  ? ClipOval(
                      child: Image.asset(
                        emoji,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Text(
                          emoji.contains('pizza')
                              ? '🍕'
                              : emoji.contains('starbucks')
                              ? '☕'
                              : emoji.contains('uber')
                              ? '🚗'
                              : '❓',
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    )
                  : Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${amount > 0 ? '+' : ''}${amount.abs().toStringAsFixed(2)} €',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : (amount > 0 ? Colors.black : Colors.black),
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
