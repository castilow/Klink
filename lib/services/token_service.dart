import 'dart:async';

class TokenService {
  /// Devuelve el saldo de WOOP (mock).
  Future<BigInt> getWoopBalance(String address) async {
    // TODO: reemplazar por llamada web3 real
    await Future.delayed(const Duration(milliseconds: 400));
    return BigInt.from(1500 * 1e18); // 1 500 WOOP
  }

  /// Devuelve el saldo de BNB para gas (mock).
  Future<BigInt> getBnbBalance(String address) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return BigInt.from((0.07 * 1e18).round()); // 0,07 BNB
  }

  /// Envía WOOP y devuelve el hash de la transacción (mock).
  Future<String> sendWoop({
    required String fromPk, // private key del remitente
    required String to, // dirección destino
    required BigInt amount, // cantidad en wei
  }) async {
    // TODO: implementar transacción real
    await Future.delayed(const Duration(seconds: 2));
    return '0xMOCK_TX_HASH';
  }
}
