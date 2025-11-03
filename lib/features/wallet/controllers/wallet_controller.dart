import 'package:get/get.dart';
import '../data/woop_token_service.dart';
import '../../../services/woop_price_service.dart';
import 'package:flutter/foundation.dart';

class WalletController extends GetxController {
  final _svc = WoopTokenService();
  final _priceService = WoopPriceService();
  final balance = 0.0.obs;
  final price = 0.0.obs;
  final priceChange = 0.0.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _updatePrice();
    // Start periodic price updates
    ever(price, (_) => _updatePrice());
  }

  Future<void> _updatePrice() async {
    try {
      final (newPrice, change) = await _priceService.getPrice();
      price.value = newPrice;
      priceChange.value = change ?? 0.0;
    } catch (e) {
      debugPrint('Error updating price: $e');
    }
  }

  Future<void> loadBalance(String hexAddr) async {
    if (hexAddr.isEmpty) return;

    isLoading.value = true;
    try {
      balance.value = await _svc.getBalance(hexAddr);
    } finally {
      isLoading.value = false;
    }
  }
}
