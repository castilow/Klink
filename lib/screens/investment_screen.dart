import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:get/get.dart';
import '../controllers/investment_controller.dart';

class InvestmentScreen extends StatefulWidget {
  const InvestmentScreen({super.key});

  @override
  State<InvestmentScreen> createState() => _InvestmentScreenState();
}

class _InvestmentScreenState extends State<InvestmentScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _counterController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _counterAnimation;
  
  // Variables para controlar si las animaciones ya se ejecutaron
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Portfolio principal
                _buildPortfolioCounter(isDark),
                const SizedBox(height: 20),
                
                // Grid de criptomonedas principales
                _buildCryptoGrid(isDark),
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

  Widget _buildPortfolioCounter(bool isDark) {
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
      border: Border.all(
        color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        width: 1,
      ),
    ),
    child: Column(
      children: [
        // GIF animado del token
        Container(
          width: 80,
          height: 80,
                      decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.black,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                width: 1,
              ),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/coin.gif',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback si no se puede cargar el GIF
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.black, // También cambiar aquí a negro
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '📈',
                      style: TextStyle(fontSize: 36),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 28),
        
        // Contador animado - COLOR SIEMPRE NEGRO
        AnimatedBuilder(
          animation: _counterAnimation,
          builder: (context, child) {
            final displayAmount = _investmentController.isConnected.value
                ? _investmentController.portfolioValue.value
                : (_hasAnimatedOnce 
                    ? 0.00 
                    : (0.00 * _counterAnimation.value));
            return Text(
              '${displayAmount.toStringAsFixed(2).replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (Match m) => '${m[1]}.',
              )} €',
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
          'Portfolio Total'.tr, // Siempre el mismo texto
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            letterSpacing: -0.2,
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

  Widget _buildCryptoGrid(bool isDark) {
    return Obx(() => Column(
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
                child: Center(
                  child: Icon(
                    Icons.trending_up,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Criptomonedas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.grey[900],
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _investmentController.isLoadingPrices.value 
                    ? null 
                    : () => _investmentController.refreshPrices(),
                icon: _investmentController.isLoadingPrices.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                        ),
                      )
                    : const Icon(
                        Icons.refresh,
                        color: Colors.grey,
                        size: 20,
                      ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(child: _buildCryptoCard(
              'Bitcoin',
              'BTC',
              _investmentController.cryptoPrices['BTC'] ?? 0.0,
              _investmentController.getFormattedChange('BTC'),
              'assets/images/crypto/bitcoin.png',
              const Color(0xFFF7931A), // Color oficial Bitcoin
              isDark,
            )),
            const SizedBox(width: 16),
            Expanded(child: _buildCryptoCard(
              'Ethereum',
              'ETH',
              _investmentController.cryptoPrices['ETH'] ?? 0.0,
              _investmentController.getFormattedChange('ETH'),
              'assets/images/crypto/ethereum.png',
              const Color(0xFF627EEA), // Color oficial Ethereum
              isDark,
            )),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildCryptoCard(
              'Binance Coin',
              'BNB',
              _investmentController.cryptoPrices['BNB'] ?? 0.0,
              _investmentController.getFormattedChange('BNB'),
              'assets/images/crypto/binance.png',
              const Color(0xFFF3BA2F), // Color oficial BNB
              isDark,
            )),
            const SizedBox(width: 16),
            Expanded(child: _buildCryptoCard(
              'Cardano',
              'ADA',
              _investmentController.cryptoPrices['ADA'] ?? 0.0,
              _investmentController.getFormattedChange('ADA'),
              'assets/images/crypto/cardano.png',
              const Color(0xFF0033AD), // Color oficial Cardano
              isDark,
            )),
          ],
        ),
      ],
    ));
  }

  Widget _buildCryptoCard(String name, String symbol, double price, String change, String imagePath, Color brandColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: brandColor.withOpacity(0.1),
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
        border: Border.all(
          color: brandColor.withOpacity(0.2),
          width: 1,
        ),
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      brandColor.withOpacity(0.1),
                      brandColor.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: brandColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: ClipOval(
                    child: Image.asset(
                      imagePath,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback si no existe la imagen
                        return Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: brandColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              symbol[0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      brandColor,
                      brandColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: brandColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  change,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            symbol,
            style: TextStyle(
              fontSize: 16,
              color: brandColor,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _investmentController.getFormattedPrice(symbol),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w600,
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
                'Transacciones Recientes'.tr,
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
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildTransactionItem('assets/images/crypto/bitcoin.png', 'Compra Bitcoin', 'Hoy, 15:30', 0.00, 'BTC', isDark),
              _buildTransactionItem('assets/images/crypto/ethereum.png', 'Venta Ethereum', 'Hoy, 12:15', 0.00, 'ETH', isDark),
              _buildTransactionItem('🪙', 'Intercambio ARS', 'Ayer, 18:45', 0.00, 'ARS', isDark),
              _buildTransactionItem('assets/images/crypto/binance.png', 'Compra BNB', 'Ayer, 14:20', 0.00, 'BNB', isDark),
              _buildTransactionItem('assets/images/crypto/cardano.png', 'Staking ADA', '23 Jul', 0.00, 'ADA', isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(String icon, String title, String date, double amount, String crypto, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
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
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Center(
              child: icon.contains('.png')
                  ? ClipOval(
                      child: Image.asset(
                        icon,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback si no existe la imagen
                          return Text(
                            crypto[0],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          );
                        },
                      ),
                    )
                  : Text(icon, style: const TextStyle(fontSize: 20)),
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
                Row(
                  children: [
                    Text(
                      date,
                                          style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        crypto,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            amount > 0
              ? '+${amount.toStringAsFixed(2)} €'
              : '${amount.toStringAsFixed(2)} €',
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
