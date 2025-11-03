import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:web3dart/web3dart.dart';

/// Servicio para obtener el precio WOOP de múltiples fuentes
class WoopPriceService {
  WoopPriceService._internal();
  static final WoopPriceService _instance = WoopPriceService._internal();
  factory WoopPriceService() => _instance;

  static const String _woopContract =
      '0xD686E8DFECFd976D80E5641489b7A18Ac16d965D';

  // Headers comunes para las APIs
  static final Map<String, String> _headers = {
    'Accept': 'application/json',
            'User-Agent': 'Arious/1.0',
  };

  // APIs endpoints
  static const String _dexScreenerApi =
      'https://api.dexscreener.com/latest/dex/tokens/0xD686E8DFECFd976D80E5641489b7A18Ac16d965D';

  static const String _pancakeApi =
      'https://api.pancakeswap.info/api/v2/tokens/0xD686E8DFECFd976D80E5641489b7A18Ac16d965D';

  bool _isUsingFallbackPrice = false;
  String _priceSource = '';

  /// Devuelve (precio, variacion24h) desde múltiples fuentes
  Future<(double, double?)> getPrice() async {
    List<String> errors = [];
    _isUsingFallbackPrice = false;
    _priceSource = '';

    try {
      debugPrint('🔍 Iniciando búsqueda de precio WOOP...');

      // 1. DexScreener (primera opción - más confiable y con pares específicos)
      debugPrint('1️⃣ Intentando obtener precio de DexScreener...');
      final dexScreenerPrice = await _getPriceFromDexScreener();
      if (dexScreenerPrice.$1 > 0) {
        _priceSource = 'DexScreener';
        debugPrint(
          '✅ Precio obtenido de DexScreener: \$${dexScreenerPrice.$1}',
        );
        return dexScreenerPrice;
      }
      debugPrint('❌ DexScreener falló o devolvió precio 0');

      // 2. PancakeSwap API (segunda opción)
      debugPrint('2️⃣ Intentando obtener precio de PancakeSwap API...');
      final pancakePrice = await _getPriceFromPancakeApi();
      if (pancakePrice.$1 > 0) {
        _priceSource = 'PancakeSwap API';
        debugPrint(
          '✅ Precio obtenido de PancakeSwap API: \$${pancakePrice.$1}',
        );
        return pancakePrice;
      }
      debugPrint('❌ PancakeSwap API falló o devolvió precio 0');

      // 3. PancakeSwap Contract (última opción)
      debugPrint(
        '3️⃣ Intentando obtener precio del contrato de PancakeSwap...',
      );
      final contractPrice = await _getPriceFromPancakeSwap();
      if (contractPrice.$1 > 0) {
        _priceSource = 'PancakeSwap Contract';
        debugPrint(
          '✅ Precio obtenido del contrato de PancakeSwap: \$${contractPrice.$1}',
        );
        return contractPrice;
      }
      debugPrint('❌ Contrato de PancakeSwap falló o devolvió precio 0');
    } catch (e, stack) {
      debugPrint('❌ Error obteniendo precio: $e');
      debugPrint('📚 Stack trace: $stack');
      errors.add(e.toString());
    }

    // Si todo falla, usar último precio conocido
    _isUsingFallbackPrice = true;
    _priceSource = 'Fallback';
    debugPrint('⚠️ USANDO PRECIO FALLBACK - Todas las fuentes fallaron');
    debugPrint('📝 Errores encontrados: ${errors.join(", ")}');
    return (0.002041, 0.0); // Último precio verificado del par WOOP/BUSD
  }

  Future<(double, double?)> _getPriceFromDexScreener() async {
    try {
      final response = await http
          .get(Uri.parse(_dexScreenerApi), headers: _headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('📡 DexScreener response code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint(
          '📊 DexScreener pairs encontrados: ${data['pairs']?.length ?? 0}',
        );

        if (data['pairs'] != null && data['pairs'].isNotEmpty) {
          // Buscar específicamente el par WOOP/BUSD en PancakeSwap v2
          final pair = data['pairs'].firstWhere(
            (p) =>
                p['dexId'] == 'pancakeswap' &&
                p['labels']?.contains('v2') == true &&
                p['quoteToken']?['symbol'] == 'BUSD',
            orElse: () => data['pairs'].firstWhere(
              (p) => p['quoteToken']?['symbol'] == 'BUSD',
              orElse: () => data['pairs'][0],
            ),
          );

          debugPrint(
            '🔍 Par encontrado: ${pair['baseToken']['symbol']}/${pair['quoteToken']['symbol']} en ${pair['dexId']}',
          );

          final price =
              double.tryParse(pair['priceUsd']?.toString() ?? '') ?? 0.0;
          final priceChange = double.tryParse(
            pair['priceChange']?['h24']?.toString() ?? '',
          );

          if (price > 0) {
            debugPrint('💰 Precio válido encontrado en DexScreener: \$$price');
            return (price, priceChange);
          }
        }
      }
      debugPrint('📄 DexScreener response body: ${response.body}');
    } catch (e) {
      debugPrint('❌ DexScreener API error: $e');
    }
    return (0.0, null);
  }

  Future<(double, double?)> _getPriceFromPancakeApi() async {
    try {
      final response = await http
          .get(Uri.parse(_pancakeApi), headers: _headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('📡 PancakeSwap API response code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          final price =
              double.tryParse(data['data']['price']?.toString() ?? '') ?? 0.0;
          final priceChange = double.tryParse(
            data['data']['price_change_24h']?.toString() ?? '',
          );

          if (price > 0) {
            debugPrint(
              '💰 Precio válido encontrado en PancakeSwap API: \$$price',
            );
            return (price, priceChange);
          }
        }
      }
      debugPrint('📄 PancakeSwap API response body: ${response.body}');
    } catch (e) {
      debugPrint('❌ PancakeSwap API error: $e');
    }
    return (0.0, null);
  }

  Future<(double, double?)> _getPriceFromPancakeSwap() async {
    try {
      debugPrint('🔗 Conectando con el contrato de PancakeSwap...');
      final client = Web3Client(
        'https://bsc-dataseed1.binance.org',
        http.Client(),
      );

      final contract = DeployedContract(
        ContractAbi.fromJson(_routerAbi, 'PancakeRouter'),
        EthereumAddress.fromHex(_routerContract),
      );

      final function = contract.function('getAmountsOut');
      final amount = BigInt.from(10).pow(18); // 1 WOOP
      final path = [
        EthereumAddress.fromHex(_woopContract),
        EthereumAddress.fromHex(_busdContract),
      ];

      debugPrint('📤 Enviando llamada al contrato...');
      final result = await client.call(
        contract: contract,
        function: function,
        params: [amount, path],
      );

      await client.dispose();

      if (result.isNotEmpty && result[0] is List) {
        final amounts = result[0] as List;
        if (amounts.length == 2) {
          final outAmount = amounts[1] as BigInt;
          final price = _safeWeiToToken(outAmount);
          debugPrint('💰 Precio calculado del contrato: \$$price');
          return (price, null);
        }
      }
      debugPrint('📄 PancakeSwap contract result: $result');
    } catch (e) {
      debugPrint('❌ PancakeSwap contract error: $e');
    }
    return (0.0, null);
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
      debugPrint('⚠️ Error en conversión segura, usando conversión simple: $e');
      // Fallback: intentar conversión simple
      try {
        return wei.toDouble() / BigInt.from(10).pow(18).toDouble();
      } catch (e2) {
        debugPrint('❌ Error crítico en conversión de balance: $e2');
        // En caso de error total, retornar 0
        return 0.0;
      }
    }
  }

  // Getters para información de depuración
  bool get isUsingFallbackPrice => _isUsingFallbackPrice;
  String get priceSource => _priceSource;

  // Constantes para PancakeSwap
  static const String _routerContract =
      '0x10ED43C718714eb63d5aA57B78B54704E256024E';
  static const String _busdContract =
      '0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56';
  static const String _routerAbi = '''
[{"inputs":[{"internalType":"uint256","name":"amountIn","type":"uint256"},
{"internalType":"address[]","name":"path","type":"address[]"}],
"name":"getAmountsOut","outputs":[{"internalType":"uint256[]","name":"amounts",
"type":"uint256[]"}],"stateMutability":"view","type":"function"}]''';
}
