import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/token_controller.dart';
import 'package:chat_messenger/config/theme_config.dart';

class WoopTransactionScreen extends GetView<TokenController> {
  const WoopTransactionScreen({super.key});

  /// Convierte Wei a tokens de forma segura manejando números grandes
  double _safeWeiToToken(BigInt wei) {
    try {
      // Dividir como BigInt primero para evitar overflow en la conversión a double
      final divisor = BigInt.from(10).pow(18);
      final integerPart = wei ~/ divisor;
      final fractionalPart = wei % divisor;

      // Convertir la parte entera y fraccionaria por separado
      final integerDouble = integerPart.toDouble();
      final fractionalDouble = fractionalPart.toDouble() / divisor.toDouble();

      return integerDouble + fractionalDouble;
    } catch (e) {
      print('⚠️ Error en conversión segura, usando conversión simple: $e');
      // Fallback: intentar conversión simple
      try {
        return wei.toDouble() / BigInt.from(10).pow(18).toDouble();
      } catch (e2) {
        print('❌ Error crítico en conversión de balance: $e2');
        // En caso de error total, retornar 0
        return 0.0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WOOP Wallet'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Obx(() {
                if (controller.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Balance WOOP',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      controller.woopBalance != null
                          ? '${_safeWeiToToken(controller.woopBalance!).toStringAsFixed(2)} WOOP'
                          : '0.00 WOOP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (controller.bnbBalance != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Gas disponible: ${_safeWeiToToken(controller.bnbBalance!).toStringAsFixed(4)} BNB',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                );
              }),
            ),
            const SizedBox(height: 32),

            // Transaction Section
            ElevatedButton(
              onPressed: () async {
                final result = await controller.sendWoopTokens(
                  fromPk: "0xPRIVATE_KEY_EXAMPLE",
                  to: "0xDESTINATION_ADDRESS",
                  amount: BigInt.from(100 * 1e18), // 100 WOOP
                );

                if (result != null) {
                  // Notificaciones deshabilitadas
                } else {
                  // Notificaciones deshabilitadas
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Enviar WOOP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
