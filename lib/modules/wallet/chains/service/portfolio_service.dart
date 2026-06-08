import 'dart:async';
import 'package:dio/dio.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import '../../model/token_model.dart';
import 'balance_service.dart';

class PortfolioService {
  static final PortfolioService _instance = PortfolioService._internal();
  factory PortfolioService() => _instance;
  PortfolioService._internal();

  final BalanceService _balanceService = BalanceService();
  final Dio _dio = Dio();

  Timer? _timer;
  int _generation = 0;
  String? _ownerId;

  /// 直接用 TokenModel 作为数据源
  final StreamController<List<TokenModel>> _controller =
      StreamController.broadcast();
  Stream<List<TokenModel>> get stream => _controller.stream;

  final StreamController<double> _totalUsdController =
      StreamController<double>.broadcast();
  Stream<double> get totalUsdStream => _totalUsdController.stream;

  List<TokenModel> _currentTokens = [];

  /// =========================
  /// 核心刷新
  /// =========================
  Future<void> _refresh(
    List<TokenModel> tokens,
    int generation,
    String ownerId,
  ) async {
    if (!_isCurrent(generation, ownerId)) return;
    _refreshBalance(tokens, generation, ownerId);
    _refreshPrice(tokens, generation, ownerId);
  }

  bool _isCurrent(int generation, String ownerId) {
    return generation == _generation &&
        ownerId == _ownerId &&
        ownerId == AccountManager().currentUserId;
  }

  Future<void> _refreshBalance(
    List<TokenModel> tokens,
    int generation,
    String ownerId,
  ) async {
    final List<TokenModel> results = List.from(tokens);

    for (int i = 0; i < tokens.length; i++) {
      if (!_isCurrent(generation, ownerId)) return;
      final index = i;
      final sourceToken = tokens[index];
      final symbol = sourceToken.symbol;

      _balanceService
          .getTokenBalance(sourceToken)
          .then((token) {
            if (!_isCurrent(generation, ownerId)) return;
            if (index >= results.length) return;
            results[index] = token;
            _controller.add(List.from(results));
          })
          .catchError((e) {
            print("刷新余额失败: $symbol -> $e");
          });
    }
  }

  Future<void> _refreshPrice(
    List<TokenModel> tokens,
    int generation,
    String ownerId,
  ) async {
    try {
      if (!_isCurrent(generation, ownerId)) return;
      final symbols = tokens.map((e) => e.symbol).toSet().toList();
      final priceMap = await _fetchPrices(symbols);
      if (!_isCurrent(generation, ownerId)) return;

      for (final t in tokens) {
        t.price = priceMap[t.symbol] ?? 0;
      }

      _controller.add(tokens); // 更新价格

      // 更新总资产
      double total = 0;
      for (final t in tokens) {
        total += t.usdValue;
      }
      _totalUsdController.add(total);
    } catch (e) {
      print("价格刷新失败: $e");
    }
  }

  Future<Map<String, double>> _fetchPrices(List<String> symbols) async {
    final ids = symbols.join(',');
    final res = await _dio.get(
      'https://api.coingecko.com/api/v3/simple/price',
      queryParameters: {'ids': ids, 'vs_currencies': 'usd'},
    );

    final data = res.data;
    return data.map<String, double>((key, value) {
      return MapEntry(key, (value['usd'] as num).toDouble());
    });
  }

  /// =========================
  /// 启动定时刷新
  /// =========================
  void start(List<TokenModel> tokens, {int interval = 60, String? ownerId}) {
    final nextOwnerId = ownerId ?? AccountManager().currentUserId;
    if (nextOwnerId.isEmpty) return;

    _generation++;
    final generation = _generation;
    _ownerId = nextOwnerId;
    _currentTokens = List.from(tokens);
    _timer?.cancel();
    _refresh(_currentTokens, generation, nextOwnerId); // 立即刷新

    _timer = Timer.periodic(Duration(seconds: interval), (_) {
      if (!_isCurrent(generation, nextOwnerId)) {
        stop();
        return;
      }
      _refresh(_currentTokens, generation, nextOwnerId);
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// =========================
  /// 清理 / reset
  /// =========================
  void clean() {
    _generation++;
    _ownerId = null;
    stop(); // 停止定时器
    _currentTokens.clear(); // 清空当前 tokens
    _controller.add([]); // 通知页面清空
    _totalUsdController.add(0); // 总资产清零
  }

  void dispose() {
    stop();
    _controller.close();
    _totalUsdController.close();
  }
}
