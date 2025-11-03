import 'package:http/http.dart' as http;
import 'dart:convert';

class CryptoPriceService {
  static const String _baseUrl = 'https://api.coingecko.com/api/v3';
  
  // IDs de las criptomonedas en CoinGecko
  static const Map<String, String> _coinIds = {
    'BTC': 'bitcoin',
    'ETH': 'ethereum',
    'BNB': 'binancecoin',
    'ADA': 'cardano',
  };

  /// Obtiene los precios actuales de las criptomonedas
  Future<Map<String, double>> getPrices(List<String> symbols) async {
    try {
      final List<String> ids = [];
      for (final symbol in symbols) {
        if (_coinIds.containsKey(symbol)) {
          ids.add(_coinIds[symbol]!);
        }
      }

      if (ids.isEmpty) {
        throw Exception('No se encontraron IDs válidos para las criptomonedas');
      }

      final String idsParam = ids.join(',');
      final response = await http.get(
        Uri.parse('$_baseUrl/simple/price?ids=$idsParam&vs_currencies=usd,eur&include_24hr_change=true'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Map<String, double> prices = {};
        
        for (final symbol in symbols) {
          final String? coinId = _coinIds[symbol];
          if (coinId != null && data.containsKey(coinId)) {
            final coinData = data[coinId];
            prices[symbol] = (coinData['eur'] as num).toDouble();
            prices['${symbol}_CHANGE'] = (coinData['eur_24h_change'] as num).toDouble();
          }
        }
        
        print('✅ Precios obtenidos: $prices');
        return prices;
      } else {
        throw Exception('Error al obtener precios: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting crypto prices: $e');
      rethrow;
    }
  }

  /// Obtiene el precio de una criptomoneda específica
  Future<double> getPrice(String symbol) async {
    try {
      final String? coinId = _coinIds[symbol];
      if (coinId == null) {
        throw Exception('Símbolo no soportado: $symbol');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/simple/price?ids=$coinId&vs_currencies=eur'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final price = (data[coinId]['eur'] as num).toDouble();
        print('✅ Precio de $symbol: €$price');
        return price;
      } else {
        throw Exception('Error al obtener precio de $symbol: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting price for $symbol: $e');
      rethrow;
    }
  }

  /// Obtiene el cambio porcentual de 24h
  Future<double> get24hChange(String symbol) async {
    try {
      final String? coinId = _coinIds[symbol];
      if (coinId == null) {
        throw Exception('Símbolo no soportado: $symbol');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/simple/price?ids=$coinId&vs_currencies=eur&include_24hr_change=true'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final change = (data[coinId]['eur_24h_change'] as num).toDouble();
        print('✅ Cambio 24h de $symbol: ${change.toStringAsFixed(2)}%');
        return change;
      } else {
        throw Exception('Error al obtener cambio de $symbol: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting 24h change for $symbol: $e');
      rethrow;
    }
  }

  /// Obtiene información completa de una criptomoneda
  Future<Map<String, dynamic>> getCryptoInfo(String symbol) async {
    try {
      final String? coinId = _coinIds[symbol];
      if (coinId == null) {
        throw Exception('Símbolo no soportado: $symbol');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/coins/$coinId?localization=false&tickers=false&market_data=true&community_data=false&developer_data=false'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final marketData = data['market_data'];
        
        return {
          'price_eur': (marketData['current_price']['eur'] as num).toDouble(),
          'price_usd': (marketData['current_price']['usd'] as num).toDouble(),
          'change_24h': (marketData['price_change_percentage_24h'] as num).toDouble(),
          'market_cap': (marketData['market_cap']['eur'] as num).toDouble(),
          'volume_24h': (marketData['total_volume']['eur'] as num).toDouble(),
          'name': data['name'],
          'symbol': data['symbol'].toUpperCase(),
        };
      } else {
        throw Exception('Error al obtener información de $symbol: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting crypto info for $symbol: $e');
      rethrow;
    }
  }
} 