import 'package:dio/dio.dart';

import '../model/token_price.dart';

class PriceService {
  static final PriceService _instance = PriceService._internal();
  factory PriceService() => _instance;

  PriceService._internal();

  final Dio _dio = Dio();

  /// 缓存（symbol -> price）
  final Map<String, TokenPrice> _cache = {};

  /// 缓存时间（秒）
  final int _cacheDuration = 30;

  /// =========================
  /// 单个获取
  /// =========================
  Future<double> getPrice(String coinId) async {
    final upper = coinId.toUpperCase();

    /// 🔥 缓存命中
    if (_cache.containsKey(upper)) {
      final cache = _cache[upper]!;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      if (now - cache.timestamp < _cacheDuration) {
        return cache.price;
      }
    }

    /// 请求
    final price = await _fetchPrice(upper);

    /// 写缓存
    _cache[upper] = TokenPrice(
      symbol: upper,
      price: price,
      timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    return price;
  }

  /// =========================
  /// 批量获取（推荐🔥）
  /// =========================
  Future<Map<String, double>> getPrices(List<String> coinIds) async {
    final result = <String, double>{};
    final needFetch = <String>[];

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    /// 先走缓存
    for (var s in coinIds) {
      final upper = s.toUpperCase();

      if (_cache.containsKey(upper) &&
          now - _cache[upper]!.timestamp < _cacheDuration) {
        result[upper] = _cache[upper]!.price;
      } else {
        needFetch.add(upper);
      }
    }

    /// 批量请求
    if (needFetch.isNotEmpty) {
      final fetched = await _fetchPrices(needFetch);

      for (var entry in fetched.entries) {
        _cache[entry.key] = TokenPrice(
          symbol: entry.key,
          price: entry.value,
          timestamp: now,
        );

        result[entry.key] = entry.value;
      }
    }

    return result;
  }

  /// =========================
  /// CoinGecko 单个
  /// =========================
  Future<double> _fetchPrice(String coinId) async {
    final url =
        "https://api.coingecko.com/api/v3/simple/price?ids=$coinId&vs_currencies=usd";

    final res = await _dio.get(url);

    return (res.data[coinId]["usd"] as num).toDouble();
  }

  /// =========================
  /// CoinGecko 批量
  /// =========================
  Future<Map<String, double>> _fetchPrices(List<String> coinIds) async {
    final url =
        "https://api.coingecko.com/api/v3/simple/price?ids=$coinIds&vs_currencies=usd";

    final res = await _dio.get(url);

    final data = res.data;

    final result = <String, double>{};

    for (var s in coinIds) {
      if (data[s] != null) {
        result[s] = (data[s]["usd"] as num).toDouble();
      }
    }

    return result;
  }
}