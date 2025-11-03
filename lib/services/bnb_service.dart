import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

class BnbService {
  static const _rpc = 'https://bsc-dataseed.binance.org/';
  
  final Web3Client _client = Web3Client(_rpc, Client());

  /// Getter público para acceder al cliente Web3
  Web3Client get client => _client;

  /// Obtiene el balance de BNB de una dirección
  Future<BigInt> getBalance(String address) async {
    try {
      final balance = await _client.getBalance(EthereumAddress.fromHex(address));
      return balance.getInWei;
    } catch (e) {
      print('❌ Error getting BNB balance: $e');
      rethrow;
    }
  }

  /// Convierte Wei a BNB (18 decimales)
  double weiToBnb(BigInt weiAmount) {
    return weiAmount.toDouble() / 1e18;
  }

  /// Convierte BNB a Wei (18 decimales)
  BigInt bnbToWei(double bnbAmount) {
    return BigInt.from(bnbAmount * 1e18);
  }

  /// Cierra el cliente
  void dispose() {
    _client.dispose();
  }
} 