import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

const _rpcUrl = 'https://bsc-dataseed.binance.org/';
const _contractAddr = '0xD686E8DFECFd976D80E5641489b7A18Ac16d965D';
const _abi = r'''
[ { "constant":true,"inputs":[{"name":"account","type":"address"}],
    "name":"balanceOf","outputs":[{"name":"","type":"uint256"}],
    "stateMutability":"view","type":"function"} ]
''';

class WoopTokenService {
  final _client = Web3Client(_rpcUrl, Client());
  final DeployedContract _contract;
  final ContractFunction _balanceOf;

  WoopTokenService()
    : _contract = DeployedContract(
        ContractAbi.fromJson(_abi, 'WOOP'),
        EthereumAddress.fromHex(_contractAddr),
      ),
      _balanceOf = ContractAbi.fromJson(
        _abi,
        'WOOP',
      ).functions.firstWhere((f) => f.name == 'balanceOf');

  String _normalizeAddress(String address) {
    // Eliminar espacios
    address = address.trim();

    // Añadir 0x si no está presente
    if (!address.startsWith('0x')) {
      address = '0x$address';
    }

    return address;
  }

  bool _isValidAddress(String address) {
    if (address.isEmpty) {
      // Notificaciones deshabilitadas
      return false;
    }

    // Normalizar la dirección
    address = _normalizeAddress(address);

    if (address.length != 42) {
      // Notificaciones deshabilitadas
      return false;
    }

    // Verificar si contiene solo caracteres hexadecimales válidos después del 0x
    final hexPart = address.substring(2);
    if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(hexPart)) {
      // Notificaciones deshabilitadas
      return false;
    }

    return true;
  }

  Future<double> getBalance(String wallet) async {
    print('Dirección original recibida: $wallet'); // Debug log

    // Normalizar la dirección
    wallet = _normalizeAddress(wallet);
    print('Dirección normalizada: $wallet'); // Debug log

    if (!_isValidAddress(wallet)) {
      return 0.0;
    }

    try {
      print('Consultando balance para dirección: $wallet'); // Debug log
      final addr = EthereumAddress.fromHex(wallet);
      final result = await _client.call(
        contract: _contract,
        function: _balanceOf,
        params: [addr],
      );

      print('Resultado raw: $result'); // Debug log

      final BigInt raw = result.first as BigInt;
      final balance = _safeWeiToToken(raw);

      print('Balance calculado: $balance WOOP'); // Debug log
      return balance;
    } catch (e) {
      print('Error al consultar balance: $e'); // Debug log
      // Notificaciones deshabilitadas
      return 0.0;
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

  void dispose() => _client.dispose();
}
