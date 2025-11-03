import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EthPriceService {
  static const String _cacheKey = 'eth_price_cache';
  static const int _cacheDuration = 30; // minutes

  /// Obtiene el precio actual de ETH desde CoinGecko
  Future<(double, double?)> getEthPrice() async {
    try {
      // Intentar cargar desde caché primero
      final cachedData = await _loadFromCache();
      if (cachedData != null) {
        return cachedData;
      }

      // Si no hay caché válido, consultar la API
      final response = await http
          .get(
            Uri.parse(
              'https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd&include_24hr_change=true',
            ),
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'AirousETH/1.0.0',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ethData = data['ethereum'];

        if (ethData != null) {
          final price = (ethData['usd'] as num?)?.toDouble() ?? 0.0;
          final priceChange = (ethData['usd_24h_change'] as num?)?.toDouble();

          if (price > 0) {
            // Guardar en caché
            await _saveToCache(price, priceChange);
            return (price, priceChange);
          }
        }
      }

      // Si falla, devolver precio por defecto
      return (3420.50, 2.34);
    } catch (e) {
      debugPrint('Error fetching ETH price: $e');
      // Intentar cargar de caché aunque sea viejo
      final cachedData = await _loadFromCache(ignoreExpiry: true);
      if (cachedData != null) {
        return cachedData;
      }
      // Fallback al precio por defecto
      return (3420.50, 2.34);
    }
  }

  /// Carga datos del precio desde caché
  Future<(double, double?)?> _loadFromCache({bool ignoreExpiry = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);

      if (cachedData != null) {
        final data = json.decode(cachedData);
        final timestamp = DateTime.parse(data['timestamp']);
        final isExpired =
            DateTime.now().difference(timestamp).inMinutes > _cacheDuration;

        if (!isExpired || ignoreExpiry) {
          final price = (data['price'] as num?)?.toDouble();
          final priceChange = (data['priceChange'] as num?)?.toDouble();

          if (price != null && price > 0) {
            return (price, priceChange);
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error loading ETH price cache: $e');
      return null;
    }
  }

  /// Guarda datos del precio en caché
  Future<void> _saveToCache(double price, double? priceChange) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'price': price,
        'priceChange': priceChange,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_cacheKey, json.encode(data));
    } catch (e) {
      debugPrint('Error saving ETH price cache: $e');
    }
  }
}
