import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/wc_service.dart';
import '../services/bnb_service.dart';
import '../services/crypto_price_service.dart';

class InvestmentController extends GetxController {
  final wc = WCService();
  final bnb = BnbService();
  final cryptoPrice = CryptoPriceService();

  // Estados observables
  final Rx<String?> connectedAddress = Rx<String?>(null);
  final RxBool isConnected = false.obs;
  final RxBool isConnecting = false.obs;
  final RxDouble bnbBalance = 0.0.obs;
  final RxDouble portfolioValue = 0.0.obs;
  final RxBool isLoadingBalance = false.obs;
  
  // Precios de criptomonedas
  final RxMap<String, double> cryptoPrices = <String, double>{}.obs;
  final RxMap<String, double> cryptoChanges = <String, double>{}.obs;
  final RxBool isLoadingPrices = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Verificar si ya hay una wallet conectada
    _checkExistingConnection();
    // Cargar precios de criptomonedas
    loadCryptoPrices();
  }

  /// Verifica si ya existe una conexión previa
  Future<void> _checkExistingConnection() async {
    try {
      await wc.init();
      if (wc.isConnected) {
        connectedAddress.value = wc.connectedAddress;
        isConnected.value = true;
        await _loadWalletData();
      }
    } catch (e) {
      print('❌ Error checking existing connection: $e');
    }
  }

  /// Conecta la wallet con MetaMask
  Future<void> connectWallet() async {
    if (isConnecting.value) return;

    try {
      isConnecting.value = true;
      
      print('🔗 Conectando wallet...');
      
      // Agregar timeout para evitar que se quede colgado
      final session = await wc.connect().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout: La conexión tardó demasiado');
        },
      );

      // Extraer la dirección de la cuenta desde los namespaces
      final accounts = session.namespaces['eip155']?.accounts;
      if (accounts != null && accounts.isNotEmpty) {
        // El formato es "eip155:56:0x..." para BSC (chain ID 56)
        connectedAddress.value = accounts.first.split(':').last;
        isConnected.value = true;
        print('✅ Wallet conectada: ${connectedAddress.value}');

        // Notificaciones deshabilitadas

        // Cargar datos de la wallet
        await _loadWalletData();
      } else {
        throw Exception('No se encontraron cuentas en la sesión');
      }
    } catch (e) {
      print('❌ Error connecting wallet: $e');
      String errorMessage = 'No se pudo conectar con MetaMask.';
      
      if (e.toString().contains('Timeout')) {
        errorMessage = 'La conexión tardó demasiado. Intenta de nuevo.';
      } else if (e.toString().contains('User rejected')) {
        errorMessage = 'Conexión cancelada por el usuario.';
      } else if (e.toString().contains('No se encontraron cuentas')) {
        errorMessage = 'No se encontraron cuentas en MetaMask.';
      }
      
      // Notificaciones deshabilitadas
    } finally {
      isConnecting.value = false;
    }
  }

  /// Desconecta la wallet
  Future<void> disconnectWallet() async {
    try {
      await wc.disconnect();
      connectedAddress.value = null;
      isConnected.value = false;
      bnbBalance.value = 0.0;
      portfolioValue.value = 0.0;
      
      // Notificaciones deshabilitadas
    } catch (e) {
      print('❌ Error disconnecting wallet: $e');
    }
  }

  /// Carga los datos de la wallet conectada
  Future<void> _loadWalletData() async {
    if (connectedAddress.value == null) return;

    try {
      isLoadingBalance.value = true;
      
      print('🔄 Cargando balance de BNB...');
      
      // Obtener balance de BNB con timeout
      final balanceWei = await bnb.getBalance(connectedAddress.value!).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout: No se pudo obtener el balance');
        },
      );
      
      final balanceBnb = bnb.weiToBnb(balanceWei);
      bnbBalance.value = balanceBnb;
      
      // Calcular valor del portfolio con precio real
      if (cryptoPrices.containsKey('BNB')) {
        portfolioValue.value = balanceBnb * cryptoPrices['BNB']!;
      } else {
        // Fallback a precio simulado si no hay precio real
        portfolioValue.value = balanceBnb * 300;
      }
      
      print('✅ Balance cargado: ${bnbBalance.value} BNB');
      
      // Notificaciones deshabilitadas
    } catch (e) {
      print('❌ Error loading wallet data: $e');
      String errorMessage = 'No se pudieron cargar los datos de la wallet';
      
      if (e.toString().contains('Timeout')) {
        errorMessage = 'La carga del balance tardó demasiado. Intenta de nuevo.';
      } else if (e.toString().contains('Network')) {
        errorMessage = 'Error de red. Verifica tu conexión.';
      }
      
      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoadingBalance.value = false;
    }
  }

  /// Actualiza los balances
  Future<void> refreshBalances() async {
    await _loadWalletData();
  }

  /// Obtiene la dirección formateada para mostrar
  String get formattedAddress {
    if (connectedAddress.value == null) return '';
    final address = connectedAddress.value!;
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  /// Carga los precios de las criptomonedas
  Future<void> loadCryptoPrices() async {
    try {
      isLoadingPrices.value = true;
      
      print('🔄 Cargando precios de criptomonedas...');
      
      final symbols = ['BTC', 'ETH', 'BNB', 'ADA'];
      final prices = await cryptoPrice.getPrices(symbols);
      
      // Separar precios y cambios
      for (final symbol in symbols) {
        if (prices.containsKey(symbol)) {
          cryptoPrices[symbol] = prices[symbol]!;
        }
        if (prices.containsKey('${symbol}_CHANGE')) {
          cryptoChanges[symbol] = prices['${symbol}_CHANGE']!;
        }
      }
      
      print('✅ Precios cargados: ${cryptoPrices.length} criptomonedas');
      
      // Actualizar valor del portfolio si está conectado
      if (isConnected.value) {
        await _updatePortfolioValue();
      }
      
    } catch (e) {
      print('❌ Error loading crypto prices: $e');
      // Notificaciones deshabilitadas
    } finally {
      isLoadingPrices.value = false;
    }
  }

  /// Actualiza el valor del portfolio basado en los precios reales
  Future<void> _updatePortfolioValue() async {
    if (connectedAddress.value == null || !cryptoPrices.containsKey('BNB')) return;
    
    try {
      final bnbPrice = cryptoPrices['BNB']!;
      portfolioValue.value = bnbBalance.value * bnbPrice;
      
      print('✅ Portfolio actualizado: ${portfolioValue.value} € (${bnbBalance.value} BNB × €$bnbPrice)');
    } catch (e) {
      print('❌ Error updating portfolio value: $e');
    }
  }

  /// Actualiza los precios de las criptomonedas
  Future<void> refreshPrices() async {
    await loadCryptoPrices();
  }

  /// Obtiene el precio formateado de una criptomoneda
  String getFormattedPrice(String symbol) {
    final price = cryptoPrices[symbol];
    if (price == null) return '€0.0000';
    
    if (price >= 1) {
      return '€${price.toStringAsFixed(2)}';
    } else {
      return '€${price.toStringAsFixed(4)}';
    }
  }

  /// Obtiene el cambio formateado de una criptomoneda
  String getFormattedChange(String symbol) {
    final change = cryptoChanges[symbol];
    if (change == null) return '+0.0%';
    
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(1)}%';
  }

  /// Verifica si la wallet está conectada
  bool get hasWallet => isConnected.value && connectedAddress.value != null;
} 