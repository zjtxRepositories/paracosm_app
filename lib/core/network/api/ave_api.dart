import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AveApi {
  static const apiKey =
      'kCp3eFx3ehmSa2pppSPBnygaguy100gYv4jm2jJqNVsQvdbrcXF8jXHCyWtURkUg';
  static const String _baseUrl = 'https://prod.ave-api.com/v2';

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
      headers: const {'X-API-KEY': apiKey, 'Content-Type': 'application/json'},
    ),
  );

  static String? resolveAveChain(int chainId, String symbol) {
    switch (chainId) {
      case 1:
        return 'eth';
      case 10:
        return 'optimism';
      case 56:
        return 'bsc';
      case 137:
        return 'polygon';
      case 8453:
        return 'base';
      case 42161:
        return 'arbitrum';
      case 43114:
        return 'avax';
      case 101:
        return 'solana';
      case 250:
        return 'ftm';
      case 324:
        return 'zksync';
      case 81457:
        return 'blast';
      case 4200:
        return 'merlin';
      case 59144:
        return 'linea';
      case 534352:
        return 'scroll';
      case 5000:
        return 'mantle';
      case 196:
        return 'xlayer';
      case 728126428:
        return 'tron';
      case 0:
        return 'btc';
      default:
        return null;
    }
  }

  /// token_id = {token}-{chain}，如 0x...-bsc、So111...-solana
  static String tokenId({required String token, required String aveChain}) {
    return '$token-$aveChain';
  }

  /// pair_id = {pair}-{chain}
  static String pairId({required String pair, required String chain}) {
    return '$pair-$chain';
  }

  /// 搜索 Token。
  static Future<List<Map<String, dynamic>>> searchTokens({
    required String keyword,
    String? chain,
    int limit = 100,
    String? orderby,
  }) async {
    final data = await _get<List<dynamic>>(
      '/tokens',
      params: _cleanParams({
        'keyword': keyword,
        'chain': chain,
        'limit': limit,
        'orderby': orderby,
      }),
    );
    return _toMapList(data);
  }

  /// 批量获取 Token 价格，最多 200 个 token_id。
  static Future<Map<String, dynamic>> getTokenPrices({
    required List<String> tokenIds,
    int? tvlMin,
    int? tx24hVolumeMin,
  }) async {
    final data = await _post<Map<String, dynamic>>(
      '/tokens/price',
      data: _cleanParams({
        'token_ids': tokenIds,
        'tvl_min': tvlMin,
        'tx_24h_volume_min': tx24hVolumeMin,
      }),
    );
    return Map<String, dynamic>.from(data);
  }

  /// 获取 Token 详情。
  static Future<Map<String, dynamic>> getTokenDetail(String tokenId) async {
    final data = await _get<Map<String, dynamic>>('/tokens/$tokenId');
    return Map<String, dynamic>.from(data);
  }

  /// 获取 Token Top100 持仓地址，可用于余额/持仓展示。
  static Future<List<Map<String, dynamic>>> getTokenTopHolders({
    required String tokenId,
    int limit = 100,
  }) async {
    final data = await _get<List<dynamic>>(
      '/tokens/top100/$tokenId',
      params: {'limit': limit},
    );
    return _toMapList(data);
  }

  /// 获取交易记录
  static Future<Map<String, dynamic>> getSwapTransactionsByTokenAddress({
    required String tokenAddress,
    required int chainId,
    required String symbol,
    int limit = 20,
    int? fromTime,
    int? toTime,
    String sort = 'desc',
  }) async {
    final aveChain = AveApi.resolveAveChain(chainId, symbol);
    if (aveChain == null) {
      throw Exception('AveApi unsupported chain: $chainId');
    }
    final tokenId = AveApi.tokenId(token: tokenAddress, aveChain: aveChain);
    final detail = await AveApi.getTokenDetail(tokenId);
    final pairId = _extractAvePairId(detail, aveChain);
    debugPrint('transactions-----$pairId');

    final data = await _get<Map<String, dynamic>>(
      '/txs/$pairId',
      params: _cleanParams({
        'limit': limit,
        'from_time': fromTime,
        'to_time': toTime,
        'sort': sort,
      }),
    );
    return Map<String, dynamic>.from(data);
  }

  /// 获取 K 线数据（按交易对）。
  static Future<Map<String, dynamic>> getKlinesByPair({
    required String pairId,
    int interval = 1,
    int limit = 100,
    String? category,
    int? fromTime,
    int? toTime,
  }) async {
    final data = await _get<Map<String, dynamic>>(
      '/klines/pair/$pairId',
      params: _cleanParams({
        'interval': interval,
        'limit': limit,
        'category': category,
        'from_time': fromTime,
        'to_time': toTime,
      }),
    );
    return Map<String, dynamic>.from(data);
  }

  /// 获取 K 线数据（按 Token）。
  static Future<Map<String, dynamic>> getKlinesByToken({
    required String tokenId,
    int interval = 1,
    int limit = 100,
    int? fromTime,
    int? toTime,
  }) async {
    final data = await _get<Map<String, dynamic>>(
      '/klines/token/$tokenId',
      params: _cleanParams({
        'interval': interval,
        'limit': limit,
        'from_time': fromTime,
        'to_time': toTime,
      }),
    );
    return Map<String, dynamic>.from(data);
  }

  /// 获取排行榜主题。
  static Future<List<Map<String, dynamic>>> getRankTopics() async {
    final data = await _get<List<dynamic>>('/ranks/topics');
    return _toMapList(data);
  }

  /// 按排行榜主题获取 Token 列表。
  static Future<List<Map<String, dynamic>>> getRankTokens({
    required String topic,
    int limit = 200,
  }) async {
    final data = await _get<List<dynamic>>(
      '/ranks',
      params: {'topic': topic, 'limit': limit},
    );
    return _toMapList(data);
  }

  /// 获取支持的链。
  static Future<List<Map<String, dynamic>>> getSupportedChains() async {
    final data = await _get<List<dynamic>>('/supported_chains');
    return _toMapList(data);
  }

  /// 获取链主流 Token。
  static Future<List<Map<String, dynamic>>> getChainMainTokens({
    required String chain,
  }) async {
    final data = await _get<List<dynamic>>(
      '/tokens/main',
      params: {'chain': chain},
    );
    return _toMapList(data);
  }

  /// 获取链趋势 Token 列表。
  static Future<Map<String, dynamic>> getChainTrendingTokens({
    required String chain,
    int currentPage = 0,
    int pageSize = 50,
  }) async {
    final data = await _get<Map<String, dynamic>>(
      '/tokens/trending',
      params: {
        'chain': chain,
        'current_page': currentPage,
        'page_size': pageSize,
      },
    );
    return Map<String, dynamic>.from(data);
  }

  /// 获取合约风险检测报告。
  static Future<Map<String, dynamic>> getContractRisk(String tokenId) async {
    final data = await _get<Map<String, dynamic>>('/contracts/$tokenId');
    return Map<String, dynamic>.from(data);
  }

  static Future<T> _get<T>(String path, {Map<String, dynamic>? params}) async {
    final res = await _dio.get(path, queryParameters: params);
    return _parseData<T>(res.data);
  }

  static Future<T> _post<T>(String path, {dynamic data}) async {
    final res = await _dio.post(path, data: data);
    return _parseData<T>(res.data);
  }

  static T _parseData<T>(dynamic json) {
    if (json is! Map<String, dynamic>) {
      throw Exception('AveApi response format error');
    }

    final status = json['status'];
    if (status != 1 && status != '1') {
      throw Exception(json['msg']?.toString() ?? 'AveApi request failed');
    }

    return json['data'] as T;
  }

  static List<Map<String, dynamic>> _toMapList(List<dynamic> data) {
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Map<String, dynamic> _cleanParams(Map<String, dynamic> params) {
    return Map<String, dynamic>.from(params)
      ..removeWhere((key, value) => value == null);
  }

  static String? _extractAvePairId(
    Map<String, dynamic> detail,
    String aveChain,
  ) {
    final directPairId = detail['pair_id']?.toString();
    if (directPairId != null && directPairId.isNotEmpty) {
      return directPairId;
    }

    final directPairAddress = detail['pair']?.toString().isNotEmpty == true
        ? detail['pair'].toString()
        : detail['pair_address']?.toString();
    if (directPairAddress != null && directPairAddress.isNotEmpty) {
      return AveApi.pairId(pair: directPairAddress, chain: aveChain);
    }

    final pairList = detail['pairs'];
    if (pairList is List && pairList.isNotEmpty) {
      final firstPair = pairList.first;
      if (firstPair is Map) {
        final pairId = firstPair['pair_id']?.toString();
        if (pairId != null && pairId.isNotEmpty) return pairId;

        final pairAddress = firstPair['pair']?.toString().isNotEmpty == true
            ? firstPair['pair'].toString()
            : firstPair['pair_address']?.toString();
        if (pairAddress != null && pairAddress.isNotEmpty) {
          return AveApi.pairId(pair: pairAddress, chain: aveChain);
        }
      }
    }

    return null;
  }

  static const String _v1BaseUrl = 'https://prod.ave-api.com/v1';

  static final Dio _v1Dio = Dio(
    BaseOptions(
      baseUrl: _v1BaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
      headers: const {'X-API-KEY': apiKey, 'Content-Type': 'application/json'},
    ),
  );

  /// v1 获取主币交易记录
  static Future<List<Map<String, dynamic>>> getNativeTransactionsV1({
    required String address,
    required int chainId,
    required String symbol,
    int page = 1,
    int pageSize = 20,
    int? startTime,
    int? endTime,
  }) async {
    final aveChain = resolveAveChain(chainId, symbol);
    if (aveChain == null) {
      throw Exception('AveApi unsupported chain: $chainId');
    }

    final data = await _v1Get<List<dynamic>>(
      '/txs',
      params: _cleanParams({
        'chain': aveChain,
        'address': address,
        'txType': 'native',
        'page': page,
        'pageSize': pageSize,
        'startTime': startTime,
        'endTime': endTime,
      }),
    );

    return _toMapList(data);
  }

  /// v1 获取代币交易记录（ERC20/BEP20）
  static Future<List<Map<String, dynamic>>> getTokenTransactionsV1({
    required String address, // 用户钱包地址
    required int chainId, // 链 ID，例如 56 = BSC
    required String symbol, // 链符号，如 BNB、ETH
    required String tokenAddress, // ERC20/BEP20 代币合约地址
    int page = 1,
    int pageSize = 20,
    int? startTime,
    int? endTime,
  }) async {
    final aveChain = resolveAveChain(chainId, symbol);
    if (aveChain == null) {
      throw Exception('AveApi unsupported chain: $chainId');
    }

    final data = await _v1Get<List<dynamic>>(
      '/txs',
      params: _cleanParams({
        'chain': aveChain,
        'address': address,
        'txType': 'erc20',
        'tokenAddress': tokenAddress,
        'page': page,
        'pageSize': pageSize,
        'startTime': startTime,
        'endTime': endTime,
      }),
    );

    return _toMapList(data);
  }

  /// 获取当前钱包某个币种的交易记录
  static Future<List<Map<String, dynamic>>> getWalletTokenTransactionsV1({
    required String walletAddress,
    required int chainId,
    required String chainSymbol,
    required String tokenAddress,
    int page = 1,
    int pageSize = 20,
  }) {
    return getTokenTransactionsV1(
      address: walletAddress,
      chainId: chainId,
      symbol: chainSymbol,
      tokenAddress: tokenAddress,
      page: page,
      pageSize: pageSize,
    );
  }

  static Future<List<Map<String, dynamic>>> getWalletransactionsV1({
    required String walletAddress,
    required int chainId,
    required String chainSymbol,
    required String tokenAddress,
    required bool isNative,
    int page = 1,
    int pageSize = 20,
  }) {
    if (isNative) {
      // BNB / ETH / MATIC
      return AveApi.getNativeTransactionsV1(
        address: walletAddress,
        chainId: chainId,
        symbol: chainSymbol,
      );
    } else {
      // USDT / USDC / 其他 ERC20
      return AveApi.getTokenTransactionsV1(
        address: walletAddress,
        chainId: chainId,
        symbol: chainSymbol,
        tokenAddress: tokenAddress,
      );
    }
  }

  static Future<T> _v1Get<T>(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    final res = await _v1Dio.get(path, queryParameters: params);
    return _parseData<T>(res.data);
  }
}
