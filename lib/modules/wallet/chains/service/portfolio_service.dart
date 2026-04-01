import 'dart:async';
import 'package:dio/dio.dart';
import '../../model/token_model.dart';
import 'balance_service.dart';

class PortfolioService {
  static final PortfolioService _instance = PortfolioService._internal();
  factory PortfolioService() => _instance;
  PortfolioService._internal();

  final BalanceService _balanceService = BalanceService();
  final Dio _dio = Dio();

  Timer? _timer;

  ///  直接用 TokenModel 作为数据源
  final StreamController<List<TokenModel>> _controller =
  StreamController.broadcast();

  Stream<List<TokenModel>> get stream => _controller.stream;

  final _totalUsdController = StreamController<double>.broadcast();

  Stream<double> get totalUsdStream => _totalUsdController.stream;

  /// =========================
  /// 核心刷新
  /// =========================
  Future<void> _refresh(List<TokenModel> tokens) async {
    _refreshBalance(tokens);
    _refreshPrice(tokens);
  }
  Future<void> _refreshBalance(List<TokenModel> tokens) async {
    final List<TokenModel> results = List.from(tokens);

    for (int i = 0; i < tokens.length; i++) {
      final index = i;

      _balanceService.getTokenBalance(tokens[index]).then((token) {
        print('balance-------${token.symbol}--${token.displayBalance}');

        results[index] = token;

        /// ✅ 每个完成就更新
        _controller.add(List.from(results));
      }).catchError((e) {
        print("失败: ${tokens[index].symbol}");
      });
    }
  }

  Future<void> _refreshPrice(List<TokenModel> tokens) async {
    try {
      final symbols = tokens.map((e) => e.symbol).toSet().toList();

      final priceMap = await _fetchPrices(symbols);

      for (final t in tokens) {
        t.price = priceMap[t.symbol] ?? 0;
      }

      _controller.add(tokens); // ✅ 再更新价格

      /// 顺便更新总资产
      double total = 0;
      for (final t in tokens) {
        total += t.usdValue;
      }
      _totalUsdController.add(total);

    } catch (e) {
      print("价格刷新失败: $e");
    }
  }

  /// =========================
  /// 获取价格
  /// =========================
  Future<Map<String, double>> _fetchPrices(List<String> symbols) async {
    final ids = symbols.join(',');

    final res = await _dio.get(
      'https://api.coingecko.com/api/v3/simple/price',
      queryParameters: {
        'ids': ids,        // bitcoin,ethereum
        'vs_currencies': 'usd',
      },
    );

    final data = res.data;

    return data.map<String, double>((key, value) {
      return MapEntry(key, (value['usd'] as num).toDouble());
    });
  }

  /// =========================
  /// 启动定时刷新
  /// =========================
  void start(List<TokenModel> tokens, {int interval = 30}) {
    _timer?.cancel();

    _refresh(tokens); // 立即刷新

    _timer = Timer.periodic(Duration(seconds: interval), (_) {
      _refresh(tokens);
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _controller.close();
  }
}