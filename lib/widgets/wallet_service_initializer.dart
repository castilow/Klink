import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/global_wallet_service.dart';

class WalletServiceInitializer extends StatefulWidget {
  final Widget child;

  const WalletServiceInitializer({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<WalletServiceInitializer> createState() => _WalletServiceInitializerState();
}

class _WalletServiceInitializerState extends State<WalletServiceInitializer> {
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    // Evitar tocar Firebase/servicios antes del arranque: inicializar en segundo plano luego del primer frame
    _initializationFuture = Future<void>.delayed(Duration.zero, _initializeWalletService);
  }

  Future<void> _initializeWalletService() async {
    try {
      if (!Get.isRegistered<GlobalWalletService>(tag: 'global_wallet_service')) {
        print('🚀 Initializing Global Wallet Service...');
        final walletService = await Get.putAsync(
          () => GlobalWalletService().init(),
          permanent: true,
          tag: 'global_wallet_service',
        );
        await walletService.ensureInitialized();
        print('✅ Global Wallet Service initialized successfully');
      } else {
        final walletService = Get.find<GlobalWalletService>(tag: 'global_wallet_service');
        if (!walletService.isInitialized) {
          print('🔄 Resetting Global Wallet Service...');
          await walletService.reset();
          print('✅ Global Wallet Service reset successfully');
        } else {
          print('✅ Global Wallet Service already initialized');
        }
      }
    } catch (e) {
      print('❌ Error initializing Global Wallet Service: $e');
      // Try to recover by resetting the service
      try {
        if (Get.isRegistered<GlobalWalletService>(tag: 'global_wallet_service')) {
          final walletService = Get.find<GlobalWalletService>(tag: 'global_wallet_service');
          print('🔄 Attempting to reset Global Wallet Service...');
          await walletService.reset();
          print('✅ Global Wallet Service reset successfully');
        } else {
          print('⚠️ Global Wallet Service not registered, creating new instance...');
          final walletService = await Get.putAsync(
            () => GlobalWalletService().init(),
            permanent: true,
            tag: 'global_wallet_service',
          );
          await walletService.ensureInitialized();
          print('✅ Global Wallet Service initialized successfully');
        }
      } catch (e) {
        print('❌ Fatal error in Global Wallet Service: $e');
        rethrow;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // No bloquear el primer frame: devolver el child siempre
    // La inicialización se realiza en background desde initState
    return widget.child;
  }
} 