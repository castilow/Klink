import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/eth_wallet_controller.dart';
import '../services/global_wallet_service.dart';

class SendEthScreen extends StatefulWidget {
  const SendEthScreen({super.key});

  @override
  State<SendEthScreen> createState() => _SendEthScreenState();
}

class _SendEthScreenState extends State<SendEthScreen> {
  // Usar el controlador global persistente
  late final AirousWalletController _airousWalletController;
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();

  bool _isLoading = false;
  String? _estimatedGasFee;

  @override
  void initState() {
    super.initState();

    // Obtener el controlador global
    _airousWalletController = GlobalWalletService.to.airousWallet;

    _amountController.addListener(_updateGasEstimate);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  /// Actualiza la estimación de gas cuando cambia la cantidad
  void _updateGasEstimate() async {
    final amountText = _amountController.text.trim();

    if (amountText.isEmpty) {
      setState(() {
        _estimatedGasFee = null;
      });
      return;
    }

    try {
      final amount = double.tryParse(amountText);
      if (amount != null && amount > 0) {
        // Cálculo más preciso del gas basado en la cantidad
        double estimatedGas;

        if (amount <= 10) {
          estimatedGas = 0.0005; // Transacciones pequeñas
        } else if (amount <= 100) {
          estimatedGas = 0.001; // Transacciones medianas
        } else if (amount <= 1000) {
          estimatedGas = 0.0015; // Transacciones grandes
        } else {
          estimatedGas = 0.002; // Transacciones muy grandes
        }

        // Verificar si hay suficiente BNB
        final currentBnb = _airousWalletController.bnbBalance.value;
        final hasEnoughGas = currentBnb >= estimatedGas;

        setState(() {
          _estimatedGasFee =
              "${estimatedGas.toStringAsFixed(4)} BNB${hasEnoughGas ? '' : ' (Insuficiente)'}";
        });
      } else {
        setState(() {
          _estimatedGasFee = null;
        });
      }
    } catch (e) {
      setState(() {
        _estimatedGasFee = "Error calculando gas";
      });
    }
  }

  /// Envía la transacción Klink
  Future<void> _sendTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Verificar conexión de wallet antes de proceder
      if (!_airousWalletController.isConnected) {
        throw Exception(
          'Tu wallet no está conectada. Por favor reconéctala desde el dashboard.',
        );
      }

      final amount = double.parse(_amountController.text);
      final address = _addressController.text.trim();

      // Validar cantidad
      final amountError = _airousWalletController.validateAmount(
        _amountController.text,
      );
      if (amountError != null) {
        throw Exception(amountError);
      }

      // Validar gas
      final gasError = await _airousWalletController.validateGasRequirement(
        amount,
      );
      if (gasError != null) {
        throw Exception(gasError);
      }

      // Confirmar transacción
      final confirm = await _showConfirmationDialog(address, amount);
      if (!confirm) return;

      // Mostrar indicador de envío
      _showSendingDialog();

      // Enviar transacción
      final txHash = await _airousWalletController.sendAirous(
        to: address,
        amount: amount,
      );

      // Cerrar diálogo de envío
      Navigator.of(context).pop();

      if (txHash != null) {
        // Mostrar éxito
        _showSuccessDialog(txHash);
      }
    } catch (e) {
      // Cerrar diálogo de envío si está abierto
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Mostrar error específico
      String errorMessage = _getReadableErrorMessage(e.toString());

      // Notificaciones deshabilitadas
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Convierte errores técnicos en mensajes legibles para el usuario
  String _getReadableErrorMessage(String error) {
    final lowerError = error.toLowerCase();

    if (lowerError.contains('session topic doesn\'t exist') ||
        lowerError.contains('no matching key') ||
        lowerError.contains('walletconnecterror(code: 2')) {
      return 'Tu wallet se desconectó. La aplicación intentará reconectar automáticamente, o puedes reconectar manualmente desde el dashboard.';
    }

    if (lowerError.contains('session expired')) {
      return 'La sesión de tu wallet expiró. Por favor reconecta tu wallet desde el dashboard.';
    }

    if (lowerError.contains('user rejected') ||
        lowerError.contains('user denied')) {
      return 'Transacción cancelada por el usuario.';
    }

    if (lowerError.contains('insufficient funds')) {
      return 'Fondos insuficientes para completar la transacción (incluyendo gas).';
    }

    if (lowerError.contains('gas')) {
      return 'Error relacionado con gas. Verifica que tengas suficiente BNB para cubrir las comisiones.';
    }

    if (lowerError.contains('network')) {
      return 'Error de red. Verifica tu conexión a internet y vuelve a intentarlo.';
    }

    // Error genérico con parte del mensaje original
    if (error.length > 100) {
      return 'Error: ${error.substring(0, 100)}...';
    }

    return error;
  }

  /// Muestra diálogo mientras se procesa la transacción
  void _showSendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF2A2A5C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A63E7)),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Procesando Transacción',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Por favor confirma la transacción en tu wallet...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
    );
  }

  /// Muestra diálogo de éxito con hash de transacción
  void _showSuccessDialog(String txHash) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF2A2A5C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF25E198), size: 24),
            SizedBox(width: 12),
            Text(
              'Transacción Enviada',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tu transacción ha sido enviada exitosamente a la red BSC.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF14142B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hash de Transacción:',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          txHash,
                          style: const TextStyle(
                            color: Color(0xFF4A63E7),
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.copy,
                          color: Color(0xFF4A63E7),
                          size: 16,
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: txHash));
                          // Notificaciones deshabilitadas
                        },
                      ),
                    ],
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
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF25E198), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'La transacción puede tardar unos minutos en confirmarse en BSC.',
                      style: TextStyle(color: Color(0xFF25E198), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // Cerrar diálogo
              Get.back(); // Volver a dashboard
            },
            child: const Text(
              'Volver al Dashboard',
              style: TextStyle(color: Color(0xFF4A63E7)),
            ),
          ),
        ],
      ),
    );
  }

  /// Muestra diálogo de confirmación
  Future<bool> _showConfirmationDialog(String address, double amount) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xFF2A2A5C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirmar Transacción',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfirmationRow('Cantidad:', '$amount WOOP'),
            const SizedBox(height: 8),
            _buildConfirmationRow(
              'Destinatario:',
              '${address.substring(0, 10)}...${address.substring(address.length - 8)}',
            ),
            const SizedBox(height: 8),
            _buildConfirmationRow(
              'Gas Estimado:',
              _estimatedGasFee ?? '~0.001 BNB',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6C1D1D).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFE12525).withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Color(0xFFE12525), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta acción no se puede deshacer. Verifica que la dirección sea correcta.',
                      style: TextStyle(color: Color(0xFFE12525), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A63E7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Confirmar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
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
          'Enviar Klink',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Balance disponible
                Obx(
                  () => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2A2A5C), Color(0xFF1E1E3F)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Balance Disponible',
                          style: TextStyle(
                            color: Color(0xFF8E8EA9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_airousWalletController.woonlyBalance.value.toStringAsFixed(6)} WOOP',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'BNB para gas: ${_airousWalletController.bnbBalance.value.toStringAsFixed(6)} BNB',
                          style: const TextStyle(
                            color: Color(0xFFF0B90B),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Dirección destinatario
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dirección del Destinatario',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _addressController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '0x...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2A2A5C),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4A63E7),
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.qr_code_scanner,
                            color: Color(0xFF4A63E7),
                          ),
                          onPressed: () {
                            // TODO: Implementar escáner QR
                          // Notificaciones deshabilitadas
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa una dirección válida';
                        }

                        final cleanValue = value.trim();
                        if (!cleanValue.startsWith('0x') ||
                            cleanValue.length != 42) {
                          return 'Dirección BSC inválida';
                        }

                        final regex = RegExp(r'^0x[a-fA-F0-9]{40}$');
                        if (!regex.hasMatch(cleanValue)) {
                          return 'Formato de dirección inválido';
                        }

                        return null;
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Cantidad
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Cantidad a Enviar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Usar máximo disponible menos buffer para gas
                            final maxAmount =
                                _airousWalletController.woonlyBalance.value *
                                0.999;
                            _amountController.text = maxAmount.toStringAsFixed(
                              6,
                            );
                            _updateGasEstimate();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A63E7).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF4A63E7).withOpacity(0.3),
                              ),
                            ),
                            child: const Text(
                              'MAX',
                              style: TextStyle(
                                color: Color(0xFF4A63E7),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.000000',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2A2A5C),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4A63E7),
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                        suffixText: 'WOOP',
                        suffixStyle: const TextStyle(
                          color: Color(0xFF25E198),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      validator: (value) {
                        return _airousWalletController.validateAmount(
                          value ?? '',
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Gas fee estimado
                if (_estimatedGasFee != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D6C42).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF25E198).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_gas_station,
                          color: Color(0xFF25E198),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Gas Estimado: ',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          _estimatedGasFee!,
                          style: const TextStyle(
                            color: Color(0xFF25E198),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                // Botón enviar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A63E7),
                      disabledBackgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text(
                              'Enviar Klink',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                  ),
                ),

                const SizedBox(height: 16),

                // Información adicional
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A5C).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFF4A63E7),
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Información Importante',
                            style: TextStyle(
                              color: Color(0xFF4A63E7),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Las transacciones en BSC son generalmente más rápidas y baratas que en Ethereum\n'
                        '• Necesitas BNB para pagar las comisiones de gas\n'
                        '• Verifica siempre la dirección del destinatario antes de enviar\n'
                        '• Las transacciones no se pueden revertir una vez confirmadas',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
