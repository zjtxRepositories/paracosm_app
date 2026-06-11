import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:paracosm/core/network/api/ave_api.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/wallet/chains/model/coin_market_model.dart';
import 'package:paracosm/modules/wallet/manager/wallet_manager.dart';
import '../../model/token_model.dart';
import 'balance_service.dart';

typedef PortfolioBalanceFetcher = Future<TokenModel> Function(TokenModel token);
typedef PortfolioAvePriceFetcher =
    Future<Map<String, dynamic>> Function(List<String> tokenIds);
typedef PortfolioMarketSyncer =
    Future<void> Function(String walletId, List<TokenModel> tokens);

class PortfolioService {
  static final PortfolioService _instance = PortfolioService._internal();
  factory PortfolioService() => _instance;
  PortfolioService._internal({
    BalanceService? balanceService,
    PortfolioBalanceFetcher? balanceFetcher,
    PortfolioAvePriceFetcher? avePriceFetcher,
    PortfolioMarketSyncer? marketSyncer,
    String Function()? ownerIdProvider,
  }) : _balanceService = balanceService ?? BalanceService(),
       _balanceFetcher = balanceFetcher,
       _avePriceFetcher =
           avePriceFetcher ??
           ((tokenIds) => AveApi.getTokenPrices(tokenIds: tokenIds)),
       _marketSyncer = marketSyncer ?? WalletManager.syncTokenMarkets,
       _ownerIdProvider =
           ownerIdProvider ?? (() => AccountManager().currentUserId);

  factory PortfolioService.forTesting({
    BalanceService? balanceService,
    PortfolioBalanceFetcher? balanceFetcher,
    PortfolioAvePriceFetcher? avePriceFetcher,
    PortfolioMarketSyncer? marketSyncer,
    String Function()? ownerIdProvider,
  }) {
    return PortfolioService._internal(
      balanceService: balanceService,
      balanceFetcher: balanceFetcher,
      avePriceFetcher: avePriceFetcher,
      marketSyncer: marketSyncer,
      ownerIdProvider: ownerIdProvider,
    );
  }

  static const String _nativeAveToken =
      '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';

  final BalanceService _balanceService;
  final PortfolioBalanceFetcher? _balanceFetcher;
  final PortfolioAvePriceFetcher _avePriceFetcher;
  final PortfolioMarketSyncer _marketSyncer;
  final String Function() _ownerIdProvider;

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
    final currentOwnerId = _ownerIdProvider();
    return generation == _generation &&
        ownerId == _ownerId &&
        ownerId == currentOwnerId;
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

      final fetchBalance = _balanceFetcher ?? _balanceService.getTokenBalance;
      fetchBalance(sourceToken)
          .then((token) {
            if (!_isCurrent(generation, ownerId)) return;
            if (index >= results.length) return;
            results[index] = token;
            _controller.add(List.from(results));
          })
          .catchError((e) {
            debugPrint("刷新余额失败: $symbol -> $e");
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
      final tokensByAveId = <String, List<TokenModel>>{};
      for (final token in tokens) {
        final tokenId = _buildAveTokenId(token);
        if (tokenId == null) continue;
        tokensByAveId.putIfAbsent(tokenId, () => <TokenModel>[]).add(token);
      }
      if (tokensByAveId.isEmpty) {
        _emitPriceSnapshot(tokens);
        return;
      }

      final priceMap = <String, dynamic>{};
      final tokenIds = tokensByAveId.keys.toList();
      for (var i = 0; i < tokenIds.length; i += 200) {
        final end = i + 200 > tokenIds.length ? tokenIds.length : i + 200;
        final chunk = tokenIds.sublist(i, end);
        final data = await _avePriceFetcher(chunk);
        priceMap.addAll(data);
      }
      if (!_isCurrent(generation, ownerId)) return;

      final updatedTokens = <TokenModel>[];
      for (final entry in tokensByAveId.entries) {
        final quote = _asMap(priceMap[entry.key]);
        final price = _parseAveDouble(quote?['current_price_usd']);
        if (price == null) continue;
        final change = _parseAveDouble(quote?['price_change_24h']) ?? 0;
        for (final token in entry.value) {
          token.price = price;
          token.market = _marketFromAveQuote(token, price, change);
          updatedTokens.add(token);
        }
      }

      _emitPriceSnapshot(tokens);
      if (updatedTokens.isNotEmpty) {
        await _syncTokenMarkets(ownerId, updatedTokens);
      }
    } catch (e) {
      debugPrint("价格刷新失败: $e");
    }
  }

  Future<void> _syncTokenMarkets(
    String ownerId,
    List<TokenModel> updatedTokens,
  ) async {
    try {
      await _marketSyncer(ownerId, updatedTokens);
    } catch (e) {
      debugPrint('同步钱包行情失败: $e');
    }
  }

  void _emitPriceSnapshot(List<TokenModel> tokens) {
    _controller.add(List.from(tokens)); // 更新价格

    // 更新总资产
    double total = 0;
    for (final t in tokens) {
      total += t.usdValue;
    }
    _totalUsdController.add(total);
  }

  String? _buildAveTokenId(TokenModel token) {
    final aveChain = AveApi.resolveAveChain(token.chainId, token.symbol);
    if (aveChain == null) return null;
    final address = token.address.trim();
    final isNative = token.isNative || address.isEmpty;
    final aveToken = isNative
        ? _nativeAveToken
        : _normalizeContractAddress(token, address);
    if (aveToken.isEmpty) return null;
    return AveApi.tokenId(token: aveToken, aveChain: aveChain);
  }

  String _normalizeContractAddress(TokenModel token, String address) {
    final aveChain = AveApi.resolveAveChain(token.chainId, token.symbol);
    if (aveChain == 'solana' || aveChain == 'tron') {
      return address;
    }
    return address.toLowerCase();
  }

  CoinMarketModel _marketFromAveQuote(
    TokenModel token,
    double price,
    double change,
  ) {
    final previous = token.market;
    return CoinMarketModel(
      symbol: previous?.symbol ?? '${token.symbol}/USDT',
      high: previous?.high ?? price,
      low: previous?.low ?? price,
      close: price,
      chg: change,
      change: change,
      volume: previous?.volume ?? 0,
      turnover: previous?.turnover ?? 0,
      coinImg: previous?.coinImg ?? token.logo,
    );
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  double? _parseAveDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  /// =========================
  /// 启动定时刷新
  /// =========================
  void start(List<TokenModel> tokens, {int interval = 60, String? ownerId}) {
    final nextOwnerId = ownerId ?? _ownerIdProvider();
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
