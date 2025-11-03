import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../services/transaction_verifier.dart';

class TransactionVerificationScreen extends StatefulWidget {
  const TransactionVerificationScreen({super.key});

  @override
  State<TransactionVerificationScreen> createState() =>
      _TransactionVerificationScreenState();
}

class _TransactionVerificationScreenState
    extends State<TransactionVerificationScreen> {
  final _txHashController = TextEditingController();
  final _verifier = TransactionVerifier();

  TransactionStatus? _currentStatus;
  bool _isVerifying = false;

  @override
  void dispose() {
    _txHashController.dispose();
    _verifier.dispose();
    super.dispose();
  }

  Future<void> _verifyTransaction() async {
    final txHash = _txHashController.text.trim();

    if (txHash.isEmpty || !txHash.startsWith('0x') || txHash.length != 66) {
      try {
        // Notificaciones generales deshabilitadas
      } catch (e) {
        // Fallback con ScaffoldMessenger si Get.snackbar falla
        debugPrint('Error con Get.snackbar: $e');
        // Notificaciones generales deshabilitadas
      }
      return;
    }

    setState(() {
      _isVerifying = true;
      _currentStatus = null;
    });

    try {
      final status = await _verifier.checkTransactionStatus(txHash);
      setState(() {
        _currentStatus = status;
      });
    } catch (e) {
      // Notificaciones generales deshabilitadas
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  Widget _buildStatusCard() {
    if (_currentStatus == null) return const SizedBox.shrink();

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (_currentStatus!.status) {
      case TxStatus.confirmed:
        statusColor = const Color(0xFF25E198);
        statusIcon = Icons.check_circle;
        statusText = 'CONFIRMADA ✅';
        break;
      case TxStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'PENDIENTE ⏳';
        break;
      case TxStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'FALLÓ ❌';
        break;
      case TxStatus.notFound:
        statusColor = Colors.grey;
        statusIcon = Icons.search_off;
        statusText = 'NO ENCONTRADA ❓';
        break;
      case TxStatus.error:
        statusColor = Colors.red;
        statusIcon = Icons.warning;
        statusText = 'ERROR ⚠️';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A5C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 24),
              const SizedBox(width: 12),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _currentStatus!.message,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF17182D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            try {
              // Cerrar cualquier snackbar activo antes de navegar
              if (Get.isSnackbarOpen) {
                Get.closeCurrentSnackbar();
              }

              // Navegación segura
              if (Navigator.canPop(context)) {
                Get.back();
              } else {
                // Fallback si no se puede hacer pop
                Navigator.of(context).pop();
              }
            } catch (e) {
              // Fallback directo con Navigator
              debugPrint('Error en Get.back(): $e');
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text(
          'Verificar Transacción WOOP',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Descripción
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4A63E7).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4A63E7).withOpacity(0.3),
                ),
              ),
              child: const Text(
                '🔍 Verifica si tu transferencia de tokens WOOP se completó exitosamente en BSC.',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),

            const SizedBox(height: 24),

            // Campo de hash
            const Text(
              'Hash de Transacción',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _txHashController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '0x...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                filled: true,
                fillColor: const Color(0xFF2A2A5C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF4A63E7),
                    width: 2,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste, color: Color(0xFF4A63E7)),
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null) {
                      _txHashController.text = data!.text!;
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Botón verificar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _verifyTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A63E7),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isVerifying
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Verificando...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        '🔍 Verificar Transacción',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Estado de la transacción
            _buildStatusCard(),

            const SizedBox(height: 24),

            // Consejos
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
                  const Text(
                    '💡 Posibles Problemas',
                    style: TextStyle(
                      color: Color(0xFFE12525),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Balance BNB insuficiente (mínimo 0.001 BNB)\n'
                    '• Problemas de red durante el envío\n'
                    '• Transacción muy lenta (gas price bajo)\n'
                    '• Dirección incorrecta del destinatario',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
