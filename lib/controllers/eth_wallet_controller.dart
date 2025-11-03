import 'package:get/get.dart';
import 'package:web3dart/web3dart.dart';
import '../services/wc_service.dart';
import '../services/eth_service.dart';
import '../services/network_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class AirousWalletController extends GetxController {
  final wc = WCService();
  final airous = AirousService();

  final Rx<String?> account = Rx<String?>(null);
  final isSending = false.obs;
  final woonlyBalance = 0.0.obs;
  final bnbBalance = 0.0.obs;
  final isLoadingBalance = false.obs;

  Timer? _sessionMaintenanceTimer;
  Timer? _balanceUpdateTimer;

  @override
  void onInit() {
    super.onInit();
    initializeService().then((_) {
      print('✅ AirousWalletController inicializado');
    }).catchError((error) {
      print('❌ Error en AirousWalletController.onInit(): $error');
      _retryInitialization();
    });
  }

  Future<void> initializeService() async {
    try {
      print('🚀 Inicializando AirousWalletController...');
      
      // Inicializar servicios necesarios
      await _initializeRequiredServices();
      
      // Configurar wallet para usuario nuevo si es necesario
      await _setupNewUserWalletIfNeeded();
      
      print('✅ AirousWalletController inicializado correctamente');
    } catch (e) {
      print('❌ Error en AirousWalletController.initializeService(): $e');
      throw Exception('Error inicializando AirousWalletController: $e');
    }
  }

  Future<void> _initializeRequiredServices() async {
    try {
      // Aquí inicializamos los servicios necesarios
      // Por ejemplo: conexión con la blockchain, servicios de wallet, etc.
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      print('❌ Error inicializando servicios requeridos: $e');
      rethrow;
    }
  }

  Future<void> _setupNewUserWalletIfNeeded() async {
    try {
      // Verificar si es un usuario nuevo y configurar su wallet
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Aquí configuramos la wallet para el nuevo usuario
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      print('❌ Error configurando wallet para usuario nuevo: $e');
      rethrow;
    }
  }

  Future<void> _retryInitialization() async {
    try {
      print('🔄 Reintentando inicialización de AirousWalletController...');
      await Future.delayed(const Duration(seconds: 1));
      await initializeService();
              print('✅ Reinicialización de AirousWalletController exitosa');
    } catch (e) {
              print('❌ Error en reinicialización de AirousWalletController: $e');
    }
  }

  /// Verifica si ya hay una conexión activa al inicializar
  Future<void> _checkExistingConnection() async {
    try {
      print('🔍 Verificando conexión existente...');

      // Forzar refresco de la conexión para verificar sesiones activas
      await wc.refreshConnection();

      if (wc.isConnected && wc.connectedAddress != null) {
        account.value = wc.connectedAddress;
        print('✅ Wallet ya conectada (restaurada): ${account.value}');

        // Obtener balance automáticamente
        await getAirousBalance();

        // Notificaciones deshabilitadas
      } else {
        print('❌ No hay wallet conectada');
      }
    } catch (e) {
      print('❌ Error verificando conexión existente: $e');
    }
  }

  /// Inicia el mantenimiento periódico de la sesión
  void _startSessionMaintenance() {
    // Cancelar timer existente si hay uno
    _sessionMaintenanceTimer?.cancel();

    // Verificar sesión cada 30 segundos
    _sessionMaintenanceTimer = Timer.periodic(const Duration(seconds: 30), (
      timer,
    ) async {
      try {
        await wc.maintainSession();

        // Verificar si la conexión se perdió
        if (account.value != null &&
            (!wc.isConnected || wc.connectedAddress == null)) {
          print('⚠️ Conexión perdida detectada');
          account.value = null;
          woonlyBalance.value = 0.0;
          bnbBalance.value = 0.0;
          _stopBalanceUpdates();

          // Notificaciones deshabilitadas
        }
      } catch (e) {
        print('❌ Error en mantenimiento de sesión: $e');
      }
    });
  }

  /// Inicia actualizaciones periódicas del balance
  void _startBalanceUpdates() {
    _stopBalanceUpdates(); // Asegurar que no hay timers duplicados

    // Actualizar balance cada 2 minutos
    _balanceUpdateTimer = Timer.periodic(const Duration(minutes: 2), (
      timer,
    ) async {
      if (isConnected) {
        try {
          print('🔄 Actualización automática de balance...');
          await getAirousBalance();
        } catch (e) {
          print('❌ Error en actualización automática de balance: $e');
        }
      } else {
        _stopBalanceUpdates();
      }
    });
  }

  /// Detiene las actualizaciones automáticas del balance
  void _stopBalanceUpdates() {
    _balanceUpdateTimer?.cancel();
    _balanceUpdateTimer = null;
  }

  /// Fuerza la recarga de la conexión y balance
  Future<void> forceRefresh() async {
    try {
      print('🔄 Verificando conectividad antes de recargar...');
      isLoadingBalance.value = true;

      // Verificar conectividad de red primero
      final networkService = Get.find<NetworkService>();
      await networkService.checkConnectivity();

      if (!networkService.isConnected) {
        print('📵 Sin conectividad de red, cancelando recarga');
        // Notificaciones deshabilitadas
        return;
      }

      print('🔄 Recargando datos con conectividad confirmada...');

      // Reinicializar servicio WC con menos frecuencia
      await wc.refreshConnection();

      if (wc.isConnected && wc.connectedAddress != null) {
        account.value = wc.connectedAddress;
        await getAirousBalance();

        // Reiniciar actualizaciones si no estaban activas
        if (_balanceUpdateTimer == null) {
          _startBalanceUpdates();
        }
      } else {
        print('❌ No hay wallet conectada después del refresh');
        account.value = null;
        woonlyBalance.value = 0.0;
        bnbBalance.value = 0.0;
        _stopBalanceUpdates();
      }
    } catch (e) {
      print('❌ Error en force refresh: $e');
        // Notificaciones deshabilitadas
    } finally {
      isLoadingBalance.value = false;
    }
  }

  Future<void> connectWallet() async {
    try {
      print('🔗 Conectando wallet...');
      await wc.init();
      final session = await wc.connect();

      // Extraer la dirección de la cuenta desde los namespaces
      final accounts = session.namespaces['eip155']?.accounts;
      if (accounts != null && accounts.isNotEmpty) {
        // El formato es "eip155:56:0x..." para BSC (chain ID 56)
        account.value = accounts.first.split(':').last;
        print('✅ Wallet conectada: ${account.value}');

        // Mostrar que está detectando tokens
        // Notificaciones deshabilitadas

        // Obtener balance inmediatamente
        await getAirousBalance();

        // Mostrar resultado de la detección
        if (woonlyBalance.value > 0) {
          // Notificaciones deshabilitadas
        } else {
          // Notificaciones deshabilitadas
        }

        // Iniciar actualizaciones automáticas
        _startBalanceUpdates();
      }
    } catch (e) {
      print('❌ Error connecting wallet: $e');
      rethrow;
    }
  }

  Future<String?> sendAirous({
    required String to,
    required double amount, // en WOOP
  }) async {
    if (account.value == null) return null;

    try {
      // 🔍 Validación 1: Dirección destino con regex
      final addressRegex = RegExp(r'^0x[a-fA-F0-9]{40}$');
      if (!addressRegex.hasMatch(to)) {
        throw Exception('Dirección destino inválida');
      }

      // 🔍 Validación 2: Cantidad > 0 y <= saldo
      if (amount <= 0) {
        throw Exception('La cantidad debe ser mayor a 0');
      }

      if (amount > woonlyBalance.value) {
        throw Exception(
          'Balance insuficiente. Tienes ${woonlyBalance.value.toStringAsFixed(6)} WOOP',
        );
      }

      // 🔍 Validación 3: Verificar que hay suficiente BNB para gas
      final bnbBalanceEth = await airous.getBnbBalance(account.value!);
      final bnbBalanceValue = bnbBalanceEth.getValueInUnit(EtherUnit.ether);

      if (bnbBalanceValue < 0.001) {
        // Mínimo 0.001 BNB para gas
        throw Exception(
          'Balance BNB insuficiente para gas. Necesitas al menos 0.001 BNB',
        );
      }

      final tx = airous.buildAirousTransferTransaction(
        from: account.value!,
        to: to,
        amount: amount,
      );

      isSending.value = true;

      // Intentar enviar transacción con manejo de sesión expirada
      final hash = await _sendTransactionWithRetry(tx);

      // Actualizar balance después de enviar
              await getAirousBalance();

      return hash;
    } catch (e) {
              print('❌ Error sending Arious: $e');
      rethrow;
    } finally {
      isSending.value = false;
    }
  }

  /// Envía transacción con reintentos automáticos en caso de sesión expirada
  Future<String> _sendTransactionWithRetry(Map<String, String> tx) async {
    try {
      // Primer intento
      return await wc.sendTx(tx);
    } catch (e) {
      print('❌ Error en primer intento de transacción: $e');

      // Verificar si es error de sesión expirada
      if (_isSessionExpiredError(e)) {
        print('🔄 Sesión expirada detectada, intentando reconectar...');

        // Notificaciones deshabilitadas

        try {
          // Intentar reconectar
          await _reconnectWallet();

          // Segundo intento después de reconectar
          print('🔄 Reintentando transacción después de reconectar...');
          return await wc.sendTx(tx);
        } catch (reconnectError) {
          print('❌ Error en reconexión: $reconnectError');
          throw Exception(
            'La sesión de tu wallet expiró. Por favor reconecta tu wallet manualmente desde el dashboard.',
          );
        }
      } else {
        // Si no es error de sesión, relanzar el error original
        rethrow;
      }
    }
  }

  /// Verifica si el error es debido a sesión expirada
  bool _isSessionExpiredError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('session topic doesn\'t exist') ||
        errorString.contains('no matching key') ||
        errorString.contains('walletconnecterror(code: 2') ||
        errorString.contains('session expired') ||
        errorString.contains('invalid session');
  }

  /// Intenta reconectar la wallet automáticamente
  Future<void> _reconnectWallet() async {
    try {
      print('🔄 Iniciando reconexión automática...');

      // Limpiar estado actual
      account.value = null;
      woonlyBalance.value = 0.0;
      bnbBalance.value = 0.0;

      // Reinicializar servicios
      await wc.init();
      await wc.refreshConnection();

      // Verificar si hay sesión activa después del refresh
      if (wc.isConnected && wc.connectedAddress != null) {
        account.value = wc.connectedAddress;
        print('✅ Reconexión automática exitosa: ${account.value}');

        // Obtener balance actualizado
        await getAirousBalance();

        // Notificaciones deshabilitadas
      } else {
        throw Exception('No se pudo restablecer la conexión automáticamente');
      }
    } catch (e) {
      print('❌ Fallo en reconexión automática: $e');
      rethrow;
    }
  }

  /// Verifica el estado de la conexión antes de operaciones importantes
  Future<bool> _ensureConnection() async {
    if (!isConnected) {
      return false;
    }

    try {
      // Verificar que la sesión aún sea válida
      await wc.refreshConnection();

      if (!wc.isConnected || wc.connectedAddress == null) {
        print('⚠️ Conexión perdida, limpiando estado...');
        account.value = null;
        woonlyBalance.value = 0.0;
        bnbBalance.value = 0.0;
        return false;
      }

      return true;
    } catch (e) {
      print('❌ Error verificando conexión: $e');
      return false;
    }
  }

  /// Obtiene el balance de Arious tokens del usuario conectado
  Future<void> getAirousBalance() async {
    if (account.value == null) {
      print('❌ No hay cuenta conectada, no se puede obtener balance');
      return;
    }

    try {
      print('💰 Obteniendo balance para: ${account.value}');
      isLoadingBalance.value = true;

      // Intento inicial
      await _attemptGetBalance();
    } catch (e) {
              print('❌ Error getting Arious balance: $e');

      // Si el primer intento falla, intentar después de 2 segundos
      print('🔄 Reintentando obtener balance en 2 segundos...');
      await Future.delayed(const Duration(seconds: 2));

      try {
        await _attemptGetBalance();
      } catch (e2) {
        print('❌ Segundo intento falló: $e2');

        // Tercer intento después de 5 segundos más
        print('🔄 Último intento en 5 segundos...');
        await Future.delayed(const Duration(seconds: 5));

        try {
          await _attemptGetBalance();
        } catch (e3) {
          print('❌ Todos los intentos fallaron: $e3');
          woonlyBalance.value = 0.0;
          bnbBalance.value = 0.0;

          // Notificaciones deshabilitadas
        }
      }
    } finally {
      isLoadingBalance.value = false;
    }
  }

  /// Intenta obtener el balance una vez
  Future<void> _attemptGetBalance() async {
    // Obtener balance de Arious tokens
    final newAirousBalance = await airous.getAirousBalance(account.value!);
    woonlyBalance.value = newAirousBalance;
    print('✅ Arious Balance actualizado: ${woonlyBalance.value} WOOP');

    // Obtener balance de BNB para gas fees
    final bnbBalanceWei = await airous.getBnbBalance(account.value!);
    final newBnbBalance = bnbBalanceWei.getValueInUnit(EtherUnit.ether);
    bnbBalance.value = newBnbBalance;
    print('✅ BNB Balance actualizado: ${bnbBalance.value} BNB');

    // Trigger UI update
    update();
  }

  /// Valida que la cantidad sea válida y no exceda el balance
  String? validateAmount(String amountStr) {
    if (amountStr.trim().isEmpty) {
      return 'Por favor ingrese una cantidad';
    }

    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      return 'Cantidad inválida';
    }

    if (amount > woonlyBalance.value) {
      return 'Cantidad excede el balance disponible (${woonlyBalance.value.toStringAsFixed(6)} WOOP)';
    }

    return null; // Validación exitosa
  }

  /// Valida que haya suficiente BNB para gas
  Future<String?> validateGasRequirement(double amount) async {
    if (account.value == null) return null;

    try {
      // Para tokens BEP-20, necesitamos BNB para gas
      if (bnbBalance.value < 0.001) {
        return 'Balance BNB insuficiente para gas. Necesitas al menos 0.001 BNB para las transacciones.';
      }

      return null; // Suficiente BNB para la transacción
    } catch (e) {
      print('❌ Error validating gas requirement: $e');
      return 'Error al verificar requisitos de gas';
    }
  }

  /// Verifica si hay una wallet conectada
  bool get isConnected => account.value != null && wc.isConnected;

  /// Desconecta la wallet
  Future<void> disconnect() async {
    try {
      await wc.disconnect();
      account.value = null;
      woonlyBalance.value = 0.0;
      bnbBalance.value = 0.0;

      // Detener actualizaciones automáticas
      _stopBalanceUpdates();

      // Notificaciones deshabilitadas
    } catch (e) {
      print('❌ Error disconnecting wallet: $e');
    }
  }

  @override
  void onClose() {
    _sessionMaintenanceTimer?.cancel();
    _balanceUpdateTimer?.cancel();
    airous.dispose();
    super.onClose();
  }
}
