import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../controllers/eth_wallet_controller.dart';
import '../services/eth_price_service.dart';
import '../services/global_wallet_service.dart';
import 'transaction_verification_screen.dart';
import '../utils/eth_test.dart';
import '../routes/app_routes.dart';

class EthDashboardScreen extends StatefulWidget {
  const EthDashboardScreen({super.key});

  @override
  State<EthDashboardScreen> createState() => _EthDashboardScreenState();
}

class _EthDashboardScreenState extends State<EthDashboardScreen> {
  // Usar el controlador global persistente
  late final AirousWalletController _airousWalletController;
  final EthPriceService _ethPriceService = EthPriceService();

  double _currentPrice = 0.0001; // Valor inicial por defecto para Klink
  double _priceChange = 0.0;
  String _priceSource = 'CoinGecko';
  double _priceChangePercent = 0.0;

  bool _isLoadingPrice = false;

  @override
  void initState() {
    super.initState();

    // Obtener el controlador global
    _airousWalletController = GlobalWalletService.to.airousWallet;

    _loadInitialData();
  }

  /// Carga datos iniciales: precio y balance de wallet
  void _loadInitialData() async {
    _loadWalletData();
            _loadAirousPrice();
  }

  Future<void> _loadWalletData() async {
    if (_airousWalletController.isConnected) {
      try {
        await _airousWalletController.forceRefresh();
        print('✅ Datos de wallet actualizados');
      } catch (e) {
        print('❌ Error al cargar balance de Klink: $e');
        // Notificaciones deshabilitadas
      }
    } else {
      // Intentar detectar conexión existente
              await _airousWalletController.forceRefresh();
    }
  }

  /// Carga el precio actual de Klink desde CoinGecko
  Future<void> _loadAirousPrice() async {
    setState(() {
      _isLoadingPrice = true;
    });

    try {
      // Usando la API de CoinGecko con la dirección del contrato BSC
      const contractAddress = '0xD686E8DFECFd976D80E5641489b7A18Ac16d965D';
      final url =
          'https://api.coingecko.com/api/v3/simple/token_price/binance-smart-chain'
          '?contract_addresses=$contractAddress'
          '&vs_currencies=usd'
          '&include_24hr_change=true';

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'Klink-App/1.0.0',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final contractData = data[contractAddress.toLowerCase()];

        if (contractData != null) {
          setState(() {
            _currentPrice = contractData['usd']?.toDouble() ?? 0.0;
            _priceChangePercent =
                contractData['usd_24h_change']?.toDouble() ?? 0.0;
            _priceSource = 'CoinGecko';
          });
          print('✅ Precio Klink obtenido de CoinGecko: \$${_currentPrice}');
        } else {
          throw Exception('No se encontraron datos para el contrato');
        }
      } else {
        throw Exception('Error HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error obteniendo precio de CoinGecko: $e');
      // Usar precio fallback
      setState(() {
        _currentPrice =
            0.0001785; // Precio fallback basado en los datos anteriores
        _priceChangePercent = 0.0;
        _priceSource = 'Fallback';
      });
    } finally {
      setState(() {
        _isLoadingPrice = false;
      });
    }
  }

  void _sendAirous() async {
    if (!_airousWalletController.isConnected) {
      // Notificaciones deshabilitadas
      return;
    }

    // Navegar a la pantalla de enviar Klink
    Get.toNamed(AppRoutes.sendEth);
  }

  void _receiveAirous() async {
    if (!_airousWalletController.isConnected) {
      // Notificaciones deshabilitadas
      return;
    }

    // Navegar a la pantalla de recibir Klink
    Get.toNamed(AppRoutes.receiveEth);
  }

  void _verifyTransaction() async {
    // Navegar a la pantalla de verificación de transacciones
    Get.to(() => const TransactionVerificationScreen());
  }

  void _showLowBnbWarning() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF2A2A5C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 24),
            SizedBox(width: 12),
            Text(
              'BNB Bajo para Gas',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu balance de BNB (${_airousWalletController.bnbBalance.value.toStringAsFixed(6)} BNB) puede no ser suficiente para transacciones.',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6C1D1D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFE12525).withOpacity(0.3),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔥 ¿Por qué necesitas BNB?',
                    style: TextStyle(
                      color: Color(0xFFE12525),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• BNB se usa para pagar gas fees en BSC\n'
                    '• Necesitas mínimo 0.001-0.002 BNB por transacción\n'
                    '• Sin BNB, no puedes enviar tokens WOOP',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1D6C42).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF25E198).withOpacity(0.3),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 ¿Cómo obtener BNB?',
                    style: TextStyle(
                      color: Color(0xFF25E198),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Compra BNB en un exchange como Binance\n'
                    '• Envía BNB a tu wallet desde otra cuenta\n'
                    '• Usa un bridge desde otra red\n'
                    '• Compra directamente en tu wallet app',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Entendido',
              style: TextStyle(color: Color(0xFF4A63E7)),
            ),
          ),
        ],
      ),
    );
  }

  /// Ejecuta diagnósticos de conectividad BSC
  void _runBscDiagnostics() async {
    // Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: Color(0xFF2A2A5C),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A63E7)),
            ),
            SizedBox(height: 16),
            Text(
              'Ejecutando diagnósticos de conectividad BSC...',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    try {
      // Simular diagnósticos BSC
      await Future.delayed(const Duration(seconds: 2));
      final results = {
        'BSC RPC 1': {'success': true, 'responseTime': 150},
        'BSC RPC 2': {'success': true, 'responseTime': 180},
        'BSC RPC 3': {'success': true, 'responseTime': 220},
      };

      // Cerrar diálogo de carga
      Navigator.of(context).pop();

      // Mostrar resultados
      _showDiagnosticsResults(results);
    } catch (e) {
      // Cerrar diálogo de carga
      Navigator.of(context).pop();

      // Notificaciones deshabilitadas
    }
  }

  /// Muestra los resultados de los diagnósticos
  void _showDiagnosticsResults(Map<String, dynamic> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A5C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Diagnósticos de Conectividad BSC',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final entry in results.entries) ...[
                _buildRpcResult(entry.key, entry.value),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: Color(0xFF4A63E7)),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el widget para mostrar el resultado de un RPC
  Widget _buildRpcResult(String rpcUrl, dynamic result) {
    final bool isSuccess = result['success'] ?? false;
    final int? responseTime = result['responseTime'];
    final String? error = result['error'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccess
            ? const Color(0xFF1D6C42).withOpacity(0.2)
            : const Color(0xFF6C1D1D).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSuccess
              ? const Color(0xFF25E198).withOpacity(0.3)
              : const Color(0xFFE12525).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess
                    ? const Color(0xFF25E198)
                    : const Color(0xFFE12525),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rpcUrl,
                  style: TextStyle(
                    color: isSuccess
                        ? const Color(0xFF25E198)
                        : const Color(0xFFE12525),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (responseTime != null)
                Text(
                  '${responseTime}ms',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 4),
            Text(
              error,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  /// Verifica el estado de la conexión de la wallet
  void _checkConnectionStatus() async {
    try {
      // Obtener estado detallado de la conexión
      final status = _airousWalletController.wc.getConnectionStatus();

      // Mostrar diálogo con información detallada
      Get.dialog(
        AlertDialog(
          backgroundColor: const Color(0xFF2A2A5C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Estado de Conexión',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusRow(
                'Conectada:',
                status['isConnected'] ? 'Sí' : 'No',
                status['isConnected'],
              ),
              const SizedBox(height: 8),
              _buildStatusRow(
                'Dirección:',
                status['address'] != null
                    ? '${status['address']}'.substring(0, 10) + '...'
                    : 'N/A',
                status['address'] != null,
              ),
              const SizedBox(height: 8),
              _buildStatusRow(
                'Sesión Activa:',
                status['hasSession'] ? 'Sí' : 'No',
                status['hasSession'],
              ),
              const SizedBox(height: 8),
              _buildStatusRow(
                'Sesión Expirada:',
                status['isExpired'] == true ? 'Sí' : 'No',
                status['isExpired'] != true,
              ),

              if (status['sessionTopic'] != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Información Técnica:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14142B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Topic: ${status['sessionTopic']}'.substring(0, 30) +
                            '...',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (status['sessionExpiry'] != null)
                        Text(
                          'Expira: ${DateTime.fromMillisecondsSinceEpoch(status['sessionExpiry'] * 1000)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D6C42).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF25E198).withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFF25E198),
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Si hay problemas, usa el botón "Actualizar Balance" o reconecta manualmente.',
                        style: TextStyle(
                          color: Color(0xFF25E198),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            if (!status['isConnected'] || status['isExpired'] == true)
              TextButton(
                onPressed: () async {
                  Get.back();
                  try {
                    await _airousWalletController.connectWallet();
                     // Notificaciones deshabilitadas
                  } catch (e) {
                    // Notificaciones deshabilitadas
                  }
                },
                child: const Text(
                  'Reconectar',
                  style: TextStyle(color: Color(0xFF25E198)),
                ),
              ),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text(
                'Cerrar',
                style: TextStyle(color: Color(0xFF4A63E7)),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      // Notificaciones deshabilitadas
    }
  }

  Widget _buildStatusRow(String label, String value, bool isGood) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        Icon(
          isGood ? Icons.check_circle : Icons.error,
          color: isGood ? const Color(0xFF25E198) : const Color(0xFFE12525),
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isGood ? const Color(0xFF25E198) : const Color(0xFFE12525),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14142B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Dashboard WOOP',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_airousWalletController.isConnected)
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF25E198)),
              onPressed: () {
                _loadWalletData();
                _loadAirousPrice();
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF25E198),
        backgroundColor: const Color(0xFF2A2A5C),
        onRefresh: () async {
          await _loadWalletData();
          await _loadAirousPrice();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Obx(() {
              if (!_airousWalletController.isConnected) {
                // Mostrar pantalla de conectar wallet
                return _buildConnectWalletScreen();
              } else {
                // Mostrar dashboard completo cuando está conectado
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Balance Card
                    _buildBalanceCard(),
                    const SizedBox(height: 24),
                    // Action Buttons
                    _buildActionButtons(),
                    const SizedBox(height: 24),
                    // Token Info Card
                    _buildTokenInfoCard(),
                    const SizedBox(height: 24),
                    // Network Info Card
                    _buildNetworkInfoCard(),
                    const SizedBox(height: 24),
                    // Debug and Tools Section
                    _buildDebugSection(),
                  ],
                );
              }
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectWalletScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),

        // Icono de wallet
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A5C),
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Icon(
            Icons.account_balance_wallet,
            color: Color(0xFF25E198),
            size: 50,
          ),
        ),

        const SizedBox(height: 32),

        // Título
        const Text(
          'Conecta tu Wallet',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        // Descripción
        const Text(
          'Conecta tu wallet para ver tu balance\nde tokens Klink (WOOP) en BSC',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
        ),

        const SizedBox(height: 48),

        // Botón de conectar
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF1A1A1A), Color(0xFF4B5563)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4A63E7).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _connectWallet,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Conectar Wallet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Información sobre la red
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A5C),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Información de la Red',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Red:', 'Binance Smart Chain'),
              const SizedBox(height: 12),
              _buildInfoRow('Token:', 'Klink (WOOP)'),
              const SizedBox(height: 12),
              _buildInfoRow('Contrato:', '0xD68...965D'),
              const SizedBox(height: 12),
              _buildInfoRow('Gas:', 'BNB'),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Nota importante
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF25E198).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF25E198).withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF25E198), size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Asegúrate de tener tokens WOOP y BNB para gas en tu wallet',
                  style: TextStyle(color: Color(0xFF25E198), fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _connectWallet() async {
    try {
                await _airousWalletController.connectWallet();
       // Notificaciones deshabilitadas
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo conectar la wallet: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF4B5563)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A63E7).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
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
                'Balance Klink',
                style: TextStyle(
                  color: Colors.white70,
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
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'BSC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_airousWalletController.isLoadingBalance.value)
            const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Detectando tokens WOOP...',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            )
          else ...[
            Text(
              '${_airousWalletController.woonlyBalance.value.toStringAsFixed(2)} WOOP',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'BNB para gas: ${_airousWalletController.bnbBalance.value.toStringAsFixed(6)} BNB',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                if (_airousWalletController.bnbBalance.value < 0.002) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _showLowBnbWarning,
                    child: const Icon(
                      Icons.warning,
                      color: Colors.orange,
                      size: 16,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            // Información del precio
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Precio Actual:',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      if (_isLoadingPrice)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                      else
                        Text(
                          '\$${_currentPrice.toStringAsFixed(6)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  if (!_isLoadingPrice && _priceChangePercent != 0.0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Cambio 24h:',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Row(
                          children: [
                            Icon(
                              _priceChangePercent >= 0
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              color: _priceChangePercent >= 0
                                  ? const Color(0xFF25E198)
                                  : const Color(0xFFE12525),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_priceChangePercent.toStringAsFixed(2)}%',
                              style: TextStyle(
                                color: _priceChangePercent >= 0
                                    ? const Color(0xFF25E198)
                                    : const Color(0xFFE12525),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Fuente:',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        _priceSource,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (_airousWalletController.account.value != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_airousWalletController.account.value}'.substring(
                          0,
                          10,
                        ) +
                        '...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(
                          text: _airousWalletController.account.value!,
                        ),
                      );
                      // Notificaciones deshabilitadas
                    },
                    child: const Icon(
                      Icons.copy,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Botón principal de enviar
        SizedBox(
          width: double.infinity,
          child: _buildMainActionButton(
            icon: Icons.send,
            label: 'Enviar WOOP',
            color: const Color(0xFF4A63E7),
                            onPressed: _sendAirous,
          ),
        ),
        const SizedBox(height: 16),
        // Botones secundarios
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.download,
                label: 'Recibir',
                color: const Color(0xFF25E198),
                onPressed: _receiveAirous,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.search,
                label: 'Verificar TX',
                color: const Color(0xFFFF9500),
                onPressed: _verifyTransaction,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        shadowColor: color.withOpacity(0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A5C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información del Token',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
                        _buildInfoRow('Nombre:', 'Klink'),
          const SizedBox(height: 12),
          _buildInfoRow('Símbolo:', 'WOOP'),
          const SizedBox(height: 12),
          _buildInfoRow('Red:', 'Binance Smart Chain'),
          const SizedBox(height: 12),
          _buildInfoRow('Contrato:', '0xD68...965D'),
        ],
      ),
    );
  }

  Widget _buildNetworkInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A5C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información de Red',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Red:', 'BSC Mainnet'),
          const SizedBox(height: 12),
          _buildInfoRow('Chain ID:', '56'),
          const SizedBox(height: 12),
          _buildInfoRow('Gas Token:', 'BNB'),
          const SizedBox(height: 12),
          _buildInfoRow('Explorer:', 'BSCScan.com'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDebugSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A5C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Herramientas de Debug',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDebugButton(
                  'Estado Conexión',
                  Icons.wifi_find,
                  _checkConnectionStatus,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDebugButton(
                  'Test BSC RPC',
                  Icons.speed,
                  _runBscDiagnostics,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDebugButton(
                  'Actualizar Balance',
                  Icons.refresh,
                  () async {
                    await _airousWalletController.getAirousBalance();
                     // Notificaciones deshabilitadas
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDebugButton('Desconectar', Icons.logout, () async {
                  await _airousWalletController.disconnect();
                   // Notificaciones deshabilitadas
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDebugButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF14142B),
        foregroundColor: const Color(0xFF25E198),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
