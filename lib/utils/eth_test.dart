import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:flutter/foundation.dart';

class EthConnectionTest {
  static const _testAddress =
      '0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045'; // Vitalik's address

  static const _rpcUrls = [
    'https://mainnet.infura.io/v3/f36f7f706a58477884ce6fe89165666c',
    'https://ethereum.publicnode.com',
    'https://rpc.ankr.com/eth',
    'https://cloudflare-eth.com',
  ];

  /// Prueba la conectividad con todos los RPCs disponibles
  static Future<Map<String, dynamic>> testAllRPCs() async {
    final results = <String, dynamic>{};

    for (String rpcUrl in _rpcUrls) {
      if (kDebugMode) {
        print('🧪 Probando RPC: $rpcUrl');
      }

      results[rpcUrl] = await _testSingleRPC(rpcUrl);
    }

    return results;
  }

  /// Prueba un solo RPC endpoint
  static Future<Map<String, dynamic>> _testSingleRPC(String rpcUrl) async {
    try {
      final client = Web3Client(rpcUrl, Client());

      // Test 1: Verificar conectividad básica
      final startTime = DateTime.now();
      final balance = await client.getBalance(
        EthereumAddress.fromHex(_testAddress),
      );
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;

      client.dispose();

      if (kDebugMode) {
        print('✅ RPC $rpcUrl: Balance obtenido (${responseTime}ms)');
        print('   Balance: ${balance.getValueInUnit(EtherUnit.ether)} ETH');
      }

      return {
        'success': true,
        'responseTime': responseTime,
        'balance': balance.getValueInUnit(EtherUnit.ether),
        'error': null,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ RPC $rpcUrl falló: $e');
      }

      return {
        'success': false,
        'responseTime': null,
        'balance': null,
        'error': e.toString(),
      };
    }
  }

  /// Encuentra el RPC más rápido y confiable
  static Future<String?> findBestRPC() async {
    final results = await testAllRPCs();

    String? bestRpc;
    int? fastestTime;

    for (final entry in results.entries) {
      final rpcUrl = entry.key;
      final result = entry.value as Map<String, dynamic>;

      if (result['success'] == true) {
        final responseTime = result['responseTime'] as int;

        if (bestRpc == null || responseTime < fastestTime!) {
          bestRpc = rpcUrl;
          fastestTime = responseTime;
        }
      }
    }

    if (kDebugMode) {
      if (bestRpc != null) {
        print('🏆 Mejor RPC: $bestRpc (${fastestTime}ms)');
      } else {
        print('❌ No se encontró ningún RPC funcional');
      }
    }

    return bestRpc;
  }

  /// Prueba rápida de un balance específico
  static Future<double?> quickBalanceTest(String address) async {
    final bestRpc = await findBestRPC();
    if (bestRpc == null) return null;

    try {
      final client = Web3Client(bestRpc, Client());
      final balance = await client.getBalance(EthereumAddress.fromHex(address));
      client.dispose();

      return balance.getValueInUnit(EtherUnit.ether);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error en prueba rápida de balance: $e');
      }
      return null;
    }
  }
}
