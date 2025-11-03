import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/global_wallet_service.dart';
import '../routes/app_routes.dart';

class WalletStatusIndicator extends StatelessWidget {
  final bool showInAppBar;
  final double? size;

  const WalletStatusIndicator({super.key, this.showInAppBar = true, this.size});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<GlobalWalletService>(tag: 'global_wallet_service')) {
      return const SizedBox.shrink();
    }
    
    final walletService = Get.find<GlobalWalletService>(tag: 'global_wallet_service');
    return Obx(() {
      if (!walletService.isInitialized || !walletService.hasConnectedWallet) {
        return const SizedBox.shrink();
      }
      return GestureDetector(
        onTap: () => _showWalletQuickView(context),
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF25E198).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF25E198).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: const Color(0xFF25E198),
                size: size ?? 20,
              ),
              if (!showInAppBar) ...[
                const SizedBox(width: 8),
                Text(
                  'Wallet Conectada',
                  style: TextStyle(
                    color: const Color(0xFF25E198),
                    fontSize: size != null ? size! * 0.8 : 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  void _showWalletQuickView(BuildContext context) {
    final walletService = Get.find<GlobalWalletService>(tag: 'global_wallet_service');
    final status = walletService.walletStatus;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A5C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Título
            const Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xFF25E198),
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Wallet Conectada',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Información de la wallet
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dirección: ${status['walletAddress'] ?? 'No disponible'}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  'Balance WOOP: ${status['airousBalance']?.toStringAsFixed(4) ?? '0.0000'}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  'Balance BNB: ${status['bnbBalance']?.toStringAsFixed(4) ?? '0.0000'}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Botón para ir a la pantalla de wallet
            ElevatedButton(
              onPressed: () {
                Get.back(); // Cerrar el modal
                Get.toNamed(AppRoutes.ethDashboard);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25E198),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Ver Detalles'),
            ),
          ],
        ),
      ),
    );
  }
}
