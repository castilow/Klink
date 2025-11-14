import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/eth_wallet_controller.dart';
import '../services/global_wallet_service.dart';

class ReceiveEthScreen extends StatefulWidget {
  const ReceiveEthScreen({super.key});

  @override
  State<ReceiveEthScreen> createState() => _ReceiveEthScreenState();
}

class _ReceiveEthScreenState extends State<ReceiveEthScreen> {
  // Usar el controlador global persistente
  late final AirousWalletController _airousWalletController;

  @override
  void initState() {
    super.initState();

    // Obtener el controlador global
    _airousWalletController = GlobalWalletService.to.airousWallet;
  }

  /// Copia la dirección al portapapeles
  void _copyAddress() {
    if (_airousWalletController.account.value != null) {
      Clipboard.setData(
        ClipboardData(text: _airousWalletController.account.value!),
      );
      // Notificaciones deshabilitadas
    }
  }

  /// Comparte la dirección
  void _shareAddress() {
    if (_airousWalletController.account.value != null) {
      // TODO: Implementar funcionalidad de compartir
      // Notificaciones deshabilitadas
    }
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
          'Recibir Klink',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          final address = _airousWalletController.account.value;

          if (address == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.wallet_outlined,
                    size: 64,
                    color: Color(0xFF8E8EA9),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Wallet No Conectada',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Por favor conecta tu wallet para recibir Klink',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Título principal
                const Text(
                  'Tu Dirección BSC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Comparte esta dirección para recibir Klink',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Código QR Card (Placeholder)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2A2A5C), Color(0xFF1E1E3F)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4A63E7).withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Placeholder QR
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.qr_code,
                              size: 80,
                              color: Color(0xFF4A63E7),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Código QR',
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.7),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Para implementar en futuras versiones',
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.5),
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Etiqueta del QR
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A63E7).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF4A63E7).withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.qr_code,
                              color: Color(0xFF4A63E7),
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Escanea este código QR',
                              style: TextStyle(
                                color: Color(0xFF4A63E7),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Dirección Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A5C),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF4A63E7).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet,
                            color: Color(0xFF4A63E7),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Dirección de la Wallet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14142B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          address,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'monospace',
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Botones de acción
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _copyAddress,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A63E7),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.copy, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Copiar',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _shareAddress,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25E198),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.share, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Compartir',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Información importante
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C1D1D).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE12525).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.warning_rounded,
                            color: Color(0xFFE12525),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Importante',
                            style: TextStyle(
                              color: Color(0xFFE12525),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• Solo envía Klink y otros tokens BEP-20 a esta dirección\n'
                        '• Enviar tokens de otras redes puede resultar en pérdida permanente\n'
                        '• Verifica siempre la dirección antes de enviar fondos\n'
                        '• Esta es una dirección de Binance Smart Chain (BSC)',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Balance actual
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D6C42).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF25E198).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: Color(0xFF25E198),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Balance Actual',
                            style: TextStyle(
                              color: Color(0xFF25E198),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_airousWalletController.woonlyBalance.value.toStringAsFixed(6)} WOOP',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'BNB: ${_airousWalletController.bnbBalance.value.toStringAsFixed(6)} BNB',
                        style: const TextStyle(
                          color: Color(0xFFF0B90B),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
