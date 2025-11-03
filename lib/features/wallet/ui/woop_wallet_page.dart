import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/woop_price_service.dart';
import '../../../controllers/wallet_controller.dart';
import '../../../screens/wallet/send_woop_screen.dart';

class WoopWalletPage extends StatefulWidget {
  const WoopWalletPage({super.key});

  @override
  State<WoopWalletPage> createState() => _WoopWalletPageState();
}

class _WoopWalletPageState extends State<WoopWalletPage>
    with SingleTickerProviderStateMixin {
  final _priceService = WoopPriceService();
  final WalletController _walletController = Get.put(WalletController());
  late final AnimationController _animationController;
  bool _isUpdating = false;
  double _price = 0.0;
  double? _priceChange;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fetchPrice();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 30), (_) => _fetchPrice());
  }

  Future<void> _fetchPrice() async {
    try {
      final (price, change) = await _priceService.getPrice();
      if (mounted) {
        setState(() {
          _price = price;
          _priceChange = change;
          _showUpdateAnimation();
        });
      }
    } catch (e) {
      debugPrint('Error fetching price: $e');
    }
  }

  void _showUpdateAnimation() {
    setState(() => _isUpdating = true);
    _animationController.forward(from: 0).then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _isUpdating = false);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  String _formatPrice(double price) {
    if (price < 0.0001) {
      return '\$0.0000${price.toStringAsFixed(8).substring(6)}';
    }
    return '\$${price.toStringAsFixed(8)}';
  }

  Widget _buildPriceDisplay() {
    final priceChange = _priceChange ?? 0.0;
    final isPositive = priceChange >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.centerRight,
          children: [
            AnimatedOpacity(
              opacity: _isUpdating ? 0.5 : 1.0,
              duration: const Duration(milliseconds: 500),
              child: Text(
                _formatPrice(_price),
                style: const TextStyle(
                  color: Color(0xFF4FD1C5),
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            if (_isUpdating)
              const Positioned(
                right: -30,
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF4FD1C5),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color:
                (isPositive ? const Color(0xFF00A389) : const Color(0xFFE53E3E))
                    .withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color:
                  (isPositive
                          ? const Color(0xFF00A389)
                          : const Color(0xFFE53E3E))
                      .withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPositive
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: isPositive
                    ? const Color(0xFF00A389)
                    : const Color(0xFFE53E3E),
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                '${isPositive ? "+" : ""}${priceChange.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: isPositive
                      ? const Color(0xFF00A389)
                      : const Color(0xFFE53E3E),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Actualización en tiempo real cada 30 minutos',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'WOOP Price',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0F1E), Color(0xFF1A1A2F)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2D),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Current Price',
                            style: TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4FD1C5).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF4FD1C5).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isUpdating
                                      ? Icons.sync
                                      : Icons.check_circle_rounded,
                                  color: const Color(0xFF4FD1C5),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'BSC',
                                  style: TextStyle(
                                    color: Color(0xFF4FD1C5),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildPriceDisplay(),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 🚀 Botones de acciones de wallet
                _buildWalletActions(),

                const SizedBox(height: 32),

                // 💰 Balance de WOOP
                _buildWoopBalance(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2D),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Acciones',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.arrow_downward_rounded,
                label: 'Recibir',
                onTap: () {
                  // TODO: Implementar recibir
                  // Notificaciones deshabilitadas
                },
              ),
              _buildActionButton(
                icon: Icons.arrow_upward_rounded,
                label: 'Enviar',
                onTap: () {
                  Get.to(() => const SendWoopScreen());
                },
              ),
                _buildActionButton(
                icon: Icons.swap_horiz_rounded,
                label: 'Intercambiar',
                onTap: () {
                  // Notificaciones deshabilitadas
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4FD1C5).withOpacity(0.2),
                  const Color(0xFF4FD1C5).withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF4FD1C5).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, color: const Color(0xFF4FD1C5), size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWoopBalance() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2D),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mi Balance WOOP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Obx(
                () => _walletController.isConnected
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Conectado',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning, color: Colors.orange, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Desconectado',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(
            () => _walletController.isConnected
                ? FutureBuilder<double?>(
                    future: _walletController.getWoopBalance(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Color(0xFF4FD1C5),
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Cargando balance...',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        );
                      }

                      final balance = snapshot.data ?? 0.0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${balance.toStringAsFixed(4)} WOOP',
                            style: const TextStyle(
                              color: Color(0xFF4FD1C5),
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Valor aprox: \$${(balance * _price).toStringAsFixed(6)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      );
                    },
                  )
                : Column(
                    children: [
                      const Text(
                        'Conecta tu wallet para ver tu balance',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await _walletController.connectWallet();
                              // Notificaciones deshabilitadas
                            } catch (e) {
                              // Notificaciones deshabilitadas
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4FD1C5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            '🔗 Conectar Wallet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
