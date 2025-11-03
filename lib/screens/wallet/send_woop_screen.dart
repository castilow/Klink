import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/wallet_controller.dart';

class SendWoopScreen extends StatefulWidget {
  const SendWoopScreen({super.key});

  @override
  State<SendWoopScreen> createState() => _SendWoopScreenState();
}

class _SendWoopScreenState extends State<SendWoopScreen> {
  final _destinoController = TextEditingController();
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final WalletController controller = Get.put(WalletController());

  @override
  void dispose() {
    _destinoController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF17182D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Enviar WOOP',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF17182D),
              const Color(0xFF1E1F38),
              const Color(0xFF17182D).withOpacity(0.95),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Balance Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1A1A1A).withOpacity(0.2),
                          const Color(0xFF4B5563).withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Balance disponible',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Obx(
                          () => controller.isConnected
                              ? FutureBuilder<double?>(
                                  future: controller.getWoopBalance(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      );
                                    }
                                    final balance = snapshot.data ?? 0.0;
                                    return Text(
                                      '${balance.toStringAsFixed(4)} WOOP',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                )
                              : const Text(
                                  'Wallet no conectada',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Dirección destino
                  const Text(
                    'Dirección destino',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _destinoController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '0x742d35Cc6635C0532925a3b8D...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF1A1A1A),
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor ingrese una dirección';
                      }
                      // Validación estricta con regex ^0x[a-fA-F0-9]{40}$
                      final regex = RegExp(r'^0x[a-fA-F0-9]{40}$');
                      if (!regex.hasMatch(value.trim())) {
                        return 'Dirección Ethereum inválida (formato: 0x + 40 caracteres hex)';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Cantidad
                  const Text(
                    'Cantidad',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF1A1A1A),
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.token,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      suffixText: 'WOOP',
                      suffixStyle: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor ingrese una cantidad';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Cantidad inválida';
                      }
                      // La validación de balance se hará de forma asíncrona antes del envío
                      return null;
                    },
                  ),

                  const Spacer(),

                  // Connect Wallet Button (si no está conectado)
                  Obx(
                    () => !controller.isConnected
                        ? Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ElevatedButton(
                              onPressed: () async {
                                try {
                              await controller.connectWallet();
                              // Notificaciones deshabilitadas
                                } catch (e) {
                              // Notificaciones deshabilitadas
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A1A1A),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Conectar Wallet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // Send Button
                  Obx(
                    () => Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            controller.isSending.value ||
                                !controller.isConnected
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  try {
                                    // 🔍 Validaciones previas detalladas
                                    final to = _destinoController.text.trim();
                                    final amountStr = _amountController.text
                                        .trim();

                                    // Validar cantidad contra balance
                                    final amountValidation = await controller
                                        .validateAmount(amountStr);
                                    if (amountValidation != null) {
                                   // Notificaciones deshabilitadas
                                      return;
                                    }

                                    // Validar gas BNB
                                    final gasValidation = await controller
                                        .validateGasRequirement();
                                    if (gasValidation != null) {
                                      // Notificaciones deshabilitadas
                                      return;
                                    }

                                    final hash = await controller.sendWoop(
                                      to: to,
                                      amount: double.parse(amountStr),
                                    );

                                    if (hash != null) {
                                      // Notificaciones deshabilitadas

                                      // Limpiar campos después del envío
                                      _destinoController.clear();
                                      _amountController.clear();

                                      // Refrescar balance después de unos segundos
                                      Future.delayed(
                                        const Duration(seconds: 3),
                                        () {
                                          setState(
                                            () {},
                                          ); // Esto hará que se recargue el FutureBuilder del balance
                                        },
                                      );
                                    }
                                  } catch (e) {
                                    // Notificaciones deshabilitadas
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              controller.isSending.value ||
                                  !controller.isConnected
                              ? Colors.grey
                              : const Color(0xFF1A1A1A),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: controller.isSending.value
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
                                    'Enviando...',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'Enviar WOOP',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
