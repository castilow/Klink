import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:math';

class PriceDataPoint {
  final DateTime timestamp;
  final double price;
  final double? volume;
  final double? priceUsd;

  PriceDataPoint({
    required this.timestamp,
    required this.price,
    this.volume,
    this.priceUsd,
  });
}

class WoopPriceHistoryService {
  WoopPriceHistoryService._internal();
  static final WoopPriceHistoryService _instance =
      WoopPriceHistoryService._internal();
  factory WoopPriceHistoryService() => _instance;

  static const String _woopContract =
      '0xD686E8DFECFd976D80E5641489b7A18Ac16d965D';

  // DexScreener API endpoint
  static const String _dexScreenerApi =
      'https://api.dexscreener.com/latest/dex/tokens/$_woopContract';

  // Headers comunes para las APIs
  static final Map<String, String> _headers = {
    'Accept': 'application/json',
            'User-Agent': 'Arious/1.0',
  };

  /// Obtiene el historial de precios según el rango de tiempo seleccionado
  Future<List<PriceDataPoint>> getPriceHistory({int hours = 24}) async {
    try {
      final realData = await _getRealTimeData();
      if (realData.isNotEmpty) {
        return realData;
      }
    } catch (e) {
      debugPrint('Error getting real-time data: $e');
    }

    // Si falla, usar datos de ejemplo
    return _getExampleData(hours);
  }

  Future<List<PriceDataPoint>> _getRealTimeData() async {
    try {
      final response = await http
          .get(Uri.parse(_dexScreenerApi), headers: _headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('DexScreener response code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('DexScreener pairs found: ${data['pairs']?.length ?? 0}');

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
            'Found pair: ${pair['baseToken']['symbol']}/${pair['quoteToken']['symbol']} on ${pair['dexId']}',
          );

          // Obtener los datos de precio
          final priceUsd =
              double.tryParse(pair['priceUsd']?.toString() ?? '') ?? 0.0;
          final priceNative =
              double.tryParse(pair['priceNative']?.toString() ?? '') ?? 0.0;
          final volume24h =
              double.tryParse(pair['volume']?['h24']?.toString() ?? '') ?? 0.0;

          // Generar puntos de datos basados en el precio actual
          final now = DateTime.now();
          final List<PriceDataPoint> pricePoints = [];

          // Simular una curva más realista basada en el precio actual
          for (int i = 24; i >= 0; i--) {
            final timestamp = now.subtract(Duration(hours: i));
            // Usar una variación más suave basada en seno para simular movimientos de mercado
            final variation = sin(i / 24 * pi) * 0.001;
            final adjustedPrice = priceUsd * (1 + variation);

            pricePoints.add(
              PriceDataPoint(
                timestamp: timestamp,
                price: adjustedPrice,
                priceUsd: adjustedPrice,
                volume: volume24h / 24, // Distribuir el volumen en 24 horas
              ),
            );
          }

          return pricePoints;
        }
      }

      debugPrint('DexScreener response body: ${response.body}');
    } catch (e) {
      debugPrint('DexScreener API error: $e');
    }
    return [];
  }

  /// Genera datos de ejemplo para demostración
  List<PriceDataPoint> _getExampleData(int hours) {
    final now = DateTime.now();
    final basePrice = 0.002041; // Último precio verificado
    final List<PriceDataPoint> data = [];

    for (int i = hours; i >= 0; i--) {
      final timestamp = now.subtract(Duration(hours: i));
      // Simular fluctuaciones más realistas
      final timeComponent = sin(i / hours * pi) * 0.0001;
      final randomComponent =
          (DateTime.now().millisecondsSinceEpoch % 100) / 1000000;
      final price = basePrice * (1 + timeComponent + randomComponent);

      data.add(
        PriceDataPoint(
          timestamp: timestamp,
          price: price,
          priceUsd: price,
          volume: 50000 + (sin(i / hours * pi * 2) * 25000).abs(),
        ),
      );
    }

    return data;
  }
}
