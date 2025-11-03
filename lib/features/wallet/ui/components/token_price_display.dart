import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/wallet_controller.dart';

class TokenPriceDisplay extends StatelessWidget {
  const TokenPriceDisplay({super.key, this.showBalance = true});

  final bool showBalance;

  @override
  Widget build(BuildContext context) {
    final WalletController c = Get.find<WalletController>();

    return Obx(() {
      final price = c.price.value;
      final balance = c.balance.value;

      if (c.isLoading.value) {
        return const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        );
      }

      return Column(
        children: [
          if (showBalance) ...[
            Text(
              '${balance.toStringAsFixed(4)} WOOP',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '1 WOOP = \$${price.toStringAsFixed(4)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (showBalance) ...[
            const SizedBox(height: 4),
            Text(
              'Total: \$${(balance * price).toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      );
    });
  }
}
