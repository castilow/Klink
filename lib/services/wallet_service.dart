import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class WalletService {
  static const String BSC_RPC_URL = 'https://bsc-dataseed1.binance.org:443';
  static const String WOOP_CONTRACT_ADDRESS =
      '0xD686E8DFECFd976D80E5641489b7A18Ac16d965D';

  final Web3Client _web3client;
  EthereumAddress? _userAddress;

  static final WalletService _instance = WalletService._internal();

  factory WalletService() {
    return _instance;
  }

  WalletService._internal()
    : _web3client = Web3Client(BSC_RPC_URL, http.Client());

  bool get isConnected => _userAddress != null;

  Future<void> connectWallet(String address) async {
    try {
      _userAddress = EthereumAddress.fromHex(address);
    } catch (e) {
      throw Exception('Invalid wallet address');
    }
  }

  Future<double> getWoopBalance() async {
    if (_userAddress == null) {
      throw Exception('Wallet not connected');
    }

    // ERC20 Token ABI for balanceOf function
    const String abiJson = '''
    [
      {
        "constant": true,
        "inputs": [{"name": "_owner", "type": "address"}],
        "name": "balanceOf",
        "outputs": [{"name": "balance", "type": "uint256"}],
        "type": "function"
      }
    ]
    ''';

    final contract = DeployedContract(
      ContractAbi.fromJson(abiJson, 'WOOP'),
      EthereumAddress.fromHex(WOOP_CONTRACT_ADDRESS),
    );

    final balanceFunction = contract.function('balanceOf');

    try {
      final result = await _web3client.call(
        contract: contract,
        function: balanceFunction,
        params: [_userAddress],
      );

      if (result.isEmpty) return 0.0;

      // Convert balance from Wei to WOOP (assuming 18 decimals)
      final balance = result[0] as BigInt;
      return _safeWeiToToken(balance);
    } catch (e) {
      throw Exception('Failed to get WOOP balance: $e');
    }
  }

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

  void disconnect() {
    _userAddress = null;
  }

  Future<void> dispose() async {
    _web3client.dispose();
  }
}
