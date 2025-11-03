import 'package:get/get.dart';
import '../controllers/eth_wallet_controller.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class GlobalWalletService extends GetxService {
  static GlobalWalletService? _instance;
  
  static GlobalWalletService get to {
    if (_instance == null) {
      _instance = Get.find<GlobalWalletService>(tag: 'global_wallet_service');
    }
    return _instance!;
  }

  late AirousWalletController airousController;
  bool _initialized = false;
  final _initCompleter = Completer<void>();

  /// Verifica si el servicio está inicializado
  bool get isInitialized => _initialized;

  /// Inicializa el servicio global de wallets
  Future<GlobalWalletService> init() async {
    if (_initialized) return this;

    try {
      print('🚀 Inicializando Global Wallet Service...');

          // Crear el controlador Arious como singleton global
    if (!Get.isRegistered<AirousWalletController>()) {
      airousController = Get.put(AirousWalletController(), permanent: true);
      await airousController.initializeService();
    } else {
      airousController = Get.find<AirousWalletController>();
      }

      _initialized = true;
      _initCompleter.complete();
      
      print('✅ Global Wallet Service inicializado correctamente');
      return this;
    } catch (e) {
      print('❌ Error en GlobalWalletService.init(): $e');
      _initCompleter.completeError(e);
      throw Exception('Error inicializando GlobalWalletService: $e');
    }
  }

  /// Obtiene el controlador Arious global
  AirousWalletController get airousWallet {
    if (!_initialized) {
      throw Exception(
        'GlobalWalletService no ha sido inicializado. Llama a init() primero.',
      );
    }
    return airousController;
  }

  /// Mantiene compatibilidad con nombre anterior (ethWallet -> airousWallet)
  AirousWalletController get ethWallet => airousWallet;

  /// Verifica si hay alguna wallet conectada
  bool get hasConnectedWallet {
    if (!_initialized) return false;
    try {
      return airousController.isConnected;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error verificando wallet conectada: $e');
      }
      return false;
    }
  }

  /// Obtiene información de estado general
  Map<String, dynamic> get walletStatus {
    if (!_initialized) {
      return {
        'initialized': false,
        'airousConnected': false,
        'walletAddress': null,
        'airousBalance': 0.0,
        'bnbBalance': 0.0,
      };
    }

    try {
      return {
        'initialized': true,
        'airousConnected': airousController.isConnected,
        'walletAddress': airousController.account.value,
        'airousBalance': airousController.woonlyBalance.value,
        'bnbBalance': airousController.bnbBalance.value,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error obteniendo wallet status: $e');
      }
      return {
        'initialized': true,
        'airousConnected': false,
        'walletAddress': null,
        'airousBalance': 0.0,
        'bnbBalance': 0.0,
      };
    }
  }

  /// Limpia todos los datos de wallets (logout completo)
  Future<void> clearAllWallets() async {
    if (_initialized && airousController.isConnected) {
      await airousController.disconnect();
    }
  }

  /// Asegura que el servicio esté inicializado
  Future<void> ensureInitialized() async {
    if (!_initialized) {
      await _initCompleter.future;
    }
  }

  /// Reinicia el servicio
  Future<void> reset() async {
    _initialized = false;
    _instance = null;
    await init();
  }

  @override
  void onClose() {
    if (kDebugMode) {
      print('🧹 Global Wallet Service cerrado');
    }
    _initialized = false;
    _instance = null;
    super.onClose();
  }
}
