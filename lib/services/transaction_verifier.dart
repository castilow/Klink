import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class TransactionVerifier {
  static const _bscRpcUrl = 'https://bsc-dataseed1.binance.org/';
  static const _bscScanApiUrl = 'https://api.bscscan.com/api';

  final Web3Client _client = Web3Client(_bscRpcUrl, Client());

  /// Verifica el estado de una transacción por hash
  Future<TransactionStatus> checkTransactionStatus(String txHash) async {
    try {
      if (kDebugMode) {
        print('🔍 Verificando transacción: $txHash');
      }

      // Intentar obtener el recibo de la transacción
      final receipt = await _client.getTransactionReceipt(txHash);

      if (receipt == null) {
        // La transacción aún está pendiente o no existe
        final pendingTx = await _client.getTransactionByHash(txHash);

        if (pendingTx == null) {
          return TransactionStatus(
            hash: txHash,
            status: TxStatus.notFound,
            message: 'Transacción no encontrada',
          );
        } else {
          return TransactionStatus(
            hash: txHash,
            status: TxStatus.pending,
            message: 'Transacción pendiente de confirmación',
          );
        }
      }

      // Verificar si la transacción fue exitosa
      final success = receipt.status == true;

      if (success) {
        // Obtener detalles adicionales
        final blockNumber = receipt.blockNumber != null
            ? BigInt.from(receipt.blockNumber!.blockNum)
            : null;
        final gasUsed = receipt.gasUsed;

        return TransactionStatus(
          hash: txHash,
          status: TxStatus.confirmed,
          message: 'Transacción confirmada exitosamente',
          blockNumber: blockNumber,
          gasUsed: gasUsed,
        );
      } else {
        return TransactionStatus(
          hash: txHash,
          status: TxStatus.failed,
          message: 'Transacción falló - revertida',
          gasUsed: receipt.gasUsed,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error verificando transacción: $e');
      }

      return TransactionStatus(
        hash: txHash,
        status: TxStatus.error,
        message: 'Error al verificar transacción: $e',
      );
    }
  }

  /// Verifica múltiples transacciones
  Future<List<TransactionStatus>> checkMultipleTransactions(
    List<String> txHashes,
  ) async {
    final results = <TransactionStatus>[];

    for (final hash in txHashes) {
      final status = await checkTransactionStatus(hash);
      results.add(status);
    }

    return results;
  }

  /// Obtiene el balance actual de WOOP de una dirección
  Future<double> getCurrentWoopBalance(String address) async {
    const contractAddress = '0xD686E8DFECFd976D80E5641489b7A18Ac16d965D';
    const abi = '''
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

    try {
      final contract = DeployedContract(
        ContractAbi.fromJson(abi, 'WOOP'),
        EthereumAddress.fromHex(contractAddress),
      );

      final balanceFunction = contract.function('balanceOf');
      final result = await _client.call(
        contract: contract,
        function: balanceFunction,
        params: [EthereumAddress.fromHex(address)],
      );

      final balance = result.first as BigInt;
      return _weiToWoop(balance);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error obteniendo balance WOOP: $e');
      }
      throw Exception('Error al obtener balance: $e');
    }
  }

  /// Convierte Wei a WOOP
  double _weiToWoop(BigInt wei) {
    return wei.toDouble() / BigInt.from(10).pow(18).toDouble();
  }

  /// Busca transacciones WOOP recientes de una dirección
  Future<List<WoopTransaction>> getRecentWoopTransactions(
    String address, {
    int limit = 10,
  }) async {
    // Esta función usaría BSCScan API para obtener transacciones
    // Por ahora retornamos una lista vacía
    return [];
  }

  /// Libera recursos
  void dispose() {
    _client.dispose();
  }
}

/// Estado de una transacción
class TransactionStatus {
  final String hash;
  final TxStatus status;
  final String message;
  final BigInt? blockNumber;
  final BigInt? gasUsed;

  TransactionStatus({
    required this.hash,
    required this.status,
    required this.message,
    this.blockNumber,
    this.gasUsed,
  });

  bool get isConfirmed => status == TxStatus.confirmed;
  bool get isFailed => status == TxStatus.failed;
  bool get isPending => status == TxStatus.pending;
}

/// Estados posibles de una transacción
enum TxStatus { pending, confirmed, failed, notFound, error }

/// Información de una transacción WOOP
class WoopTransaction {
  final String hash;
  final String from;
  final String to;
  final double amount;
  final DateTime timestamp;
  final bool isIncoming;

  WoopTransaction({
    required this.hash,
    required this.from,
    required this.to,
    required this.amount,
    required this.timestamp,
    required this.isIncoming,
  });
}
