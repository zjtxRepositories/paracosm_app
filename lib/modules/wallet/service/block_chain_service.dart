import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:paracosm/modules/wallet/chains/evm/services/evm_erc20_rpc_scan_service.dart';
import 'package:paracosm/modules/wallet/chains/tron/tron_chain_service.dart';
import 'package:paracosm/modules/wallet/chains/tron/tron_service.dart';
import 'package:paracosm/modules/wallet/model/chain_account.dart';

import '../model/trade_model.dart';

class BlockChainService {
  static const String _solanaRpc = 'https://api.mainnet-beta.solana.com';
  static const String _evmApiUrl = 'https://api.etherscan.io/v2/api';
  static const String _evmApiKey = 'AJYYQC9NT6NV5WGPDSDNXXQHDRF375RQ4Q';

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 15),
    ),
  );

  /// 统一入口：获取代币/主币交易记录（EVM、Solana、BTC）
  Future<List<TradeModel>> getTokenTransactions(
    ChainAccount chain,
    String address, {
    String? contractAddress,
    int limit = 20,
  }) async {
    switch (chain.chainType) {
      case ChainType.solana:
        final rawTxs = await _getTokenTransactionsSolana(
          address,
          contractAddress: contractAddress,
          limit: limit,
        );
        return _parseSolanaTxsToTradeModel(
          rawTxs,
          address,
          contractAddress: contractAddress,
        );
      case ChainType.bitcoin:
        final rawTxs = await _getTokenTransactionsBtc(address, limit: limit);
        return _parseBtcTxsToTradeModel(rawTxs, address);
      case ChainType.evm:
        if (_hasValue(contractAddress)) {
          return EvmErc20RpcScanService.getErc20Transactions(
            chain: chain,
            walletAddress: address,
            contractAddress: contractAddress!,
            limit: limit,
          );
        }

        final rawTxs = await _getTokenTransactionsEvm(
          chain,
          address,
          contractAddress: contractAddress,
          limit: limit,
        );
        return _parseEvmTxsToTradeModel(rawTxs, address, chain: chain);
      case ChainType.tron:
        final txs = await TronChainService().getTransactions(
          address,
          contractAddress: contractAddress ?? '',
          node: chain.nodes.isNotEmpty
              ? chain.nodes.first
              : 'https://api.trongrid.io',
          limit: limit,
        );
        return _parseTronTxsToTradeModel(
          txs,
          address,
          chain: chain,
          contractAddress: contractAddress,
        );
    }
  }

  /// 获取 ERC20 / BEP20 / EVM 主币交易记录（Etherscan V2 兼容接口）
  Future<List<Map<String, dynamic>>> _getTokenTransactionsEvm(
    ChainAccount chain,
    String address, {
    String? contractAddress,
    int limit = 20,
  }) async {
    final isToken = _hasValue(contractAddress);
    final action = isToken ? 'tokentx' : 'txlist';
    final baseUrl = _resolveEvmApiUrl(chain.txApiUrl);
    final apiKey = _hasValue(chain.apiKey) ? chain.apiKey! : _evmApiKey;

    final queryParameters = <String, String>{
      'chainid': chain.chainId.toString(),
      'module': 'account',
      'action': action,
      'address': address,
      'startblock': '0',
      'endblock': '99999999',
      'page': '1',
      'offset': limit.toString(),
      'sort': 'desc',
      'apikey': apiKey,
      if (isToken) 'contractaddress': contractAddress!,
    };

    final url = Uri.parse(baseUrl).replace(queryParameters: queryParameters);
    late final Response<dynamic> res;
    try {
      res = await _dio.getUri(
        url,
        options: Options(headers: {'User-Agent': 'Mozilla/5.0'}),
      );
    } on DioException catch (e) {
      if (_isTimeoutException(e)) return [];
      rethrow;
    }

    if (res.statusCode != 200) {
      throw Exception('EVM 请求失败: ${res.statusCode}');
    }
    final data = _decodeResponseData(res.data);
    if (data is! Map<String, dynamic>) return [];

    final status = data['status']?.toString();
    final message = data['message']?.toString();
    if (status != '1') {
      // Etherscan 无交易时常返回 status=0,message=No transactions found。
      if (message == 'No transactions found') return [];
      return [];
    }

    final result = data['result'];
    if (result is List) {
      return List<Map<String, dynamic>>.from(result);
    }
    if (result is Map && result['transactions'] is List) {
      return List<Map<String, dynamic>>.from(result['transactions']);
    }
    return [];
  }

  /// 获取 Solana SPL Token 交易记录。
  ///
  /// 这里先取钱包地址签名，再拉取交易详情；后续解析时按 pre/post token balance
  /// 的差值计算买入/卖出。
  Future<List<Map<String, dynamic>>> _getTokenTransactionsSolana(
    String address, {
    String? contractAddress,
    int limit = 20,
  }) async {
    late final Response<dynamic> sigRes;
    try {
      sigRes = await _dio.post(
        _solanaRpc,
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: {
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'getSignaturesForAddress',
          'params': [
            address,
            {'limit': limit},
          ],
        },
      );
    } on DioException catch (e) {
      if (_isTimeoutException(e)) return [];
      rethrow;
    }

    if (sigRes.statusCode != 200) {
      throw Exception('Solana 签名请求失败: ${sigRes.statusCode}');
    }

    final sigData = _decodeResponseData(sigRes.data);
    final signatures = sigData is Map ? sigData['result'] as List? ?? [] : [];
    final txs = <Map<String, dynamic>>[];

    for (final sig in signatures) {
      final signature = sig is Map ? sig['signature']?.toString() : null;
      if (!_hasValue(signature)) continue;

      late final Response<dynamic> txRes;
      try {
        txRes = await _dio.post(
          _solanaRpc,
          options: Options(headers: {'Content-Type': 'application/json'}),
          data: {
            'jsonrpc': '2.0',
            'id': 1,
            'method': 'getTransaction',
            'params': [
              signature,
              {'encoding': 'jsonParsed', 'maxSupportedTransactionVersion': 0},
            ],
          },
        );
      } on DioException catch (e) {
        if (_isTimeoutException(e)) continue;
        rethrow;
      }

      if (txRes.statusCode != 200) continue;

      final txData = _decodeResponseData(txRes.data);
      final tx = txData is Map ? txData['result'] : null;
      if (tx is! Map) continue;

      final meta = tx['meta'];
      if (meta is! Map) continue;

      txs.add({
        'signature': signature,
        'blockTime': tx['blockTime'],
        'preTokenBalances': meta['preTokenBalances'] ?? [],
        'postTokenBalances': meta['postTokenBalances'] ?? [],
      });
    }

    return txs;
  }

  Future<List<Map<String, dynamic>>> _getTokenTransactionsBtc(
    String address, {
    int limit = 20,
  }) async {
    final url = Uri.parse(
      'https://api.blockcypher.com/v1/btc/main/addrs/$address/full?limit=$limit',
    );
    late final Response<dynamic> res;
    try {
      res = await _dio.getUri(url);
    } on DioException catch (e) {
      if (_isTimeoutException(e)) return [];
      rethrow;
    }

    if (res.statusCode != 200) {
      throw Exception('BTC 请求失败: ${res.statusCode}');
    }

    final data = _decodeResponseData(res.data);
    if (data is! Map<String, dynamic>) return [];
    return List<Map<String, dynamic>>.from(data['txs'] ?? []);
  }

  /// EVM 交易转 TradeModel
  List<TradeModel> _parseEvmTxsToTradeModel(
    List<Map<String, dynamic>> txs,
    String userAddress, {
    required ChainAccount chain,
  }) {
    return txs.map((tx) {
      final isTokenTx = _hasValue(tx['tokenSymbol']);
      final decimals =
          int.tryParse(
            tx['tokenDecimal']?.toString() ?? (isTokenTx ? '18' : '18'),
          ) ??
          18;
      final rawValue =
          BigInt.tryParse(tx['value']?.toString() ?? '0') ?? BigInt.zero;
      final amount = _formatBigIntAmount(rawValue, decimals);
      final from = tx['from']?.toString();
      final to = tx['to']?.toString();
      final direction = from?.toLowerCase() == userAddress.toLowerCase()
          ? TradeDirection.sell
          : TradeDirection.buy;
      final time = int.tryParse(tx['timeStamp']?.toString() ?? '0') ?? 0;
      final symbol = tx['tokenSymbol']?.toString().isNotEmpty == true
          ? tx['tokenSymbol'].toString()
          : chain.symbol;

      return TradeModel(
        symbol: symbol,
        price: 0.0,
        amount: amount,
        buyTurnover: 0.0,
        direction: direction,
        time: time,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        from: from,
        to: to,
        contractAddress: tx['contractAddress']?.toString(),
        tokenName: tx['tokenName']?.toString(),
      );
    }).toList();
  }

  /// Solana 交易转 TradeModel
  List<TradeModel> _parseSolanaTxsToTradeModel(
    List<Map<String, dynamic>> txs,
    String userAddress, {
    String? contractAddress,
  }) {
    final trades = <TradeModel>[];
    final lowerUserAddress = userAddress.toLowerCase();
    final lowerContractAddress = contractAddress?.toLowerCase();

    for (final tx in txs) {
      final blockTime =
          int.tryParse(tx['blockTime']?.toString() ?? '') ??
          DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final preBalances = tx['preTokenBalances'] as List? ?? [];
      final postBalances = tx['postTokenBalances'] as List? ?? [];
      final balanceKeys = <String>{};

      for (final item in [...preBalances, ...postBalances]) {
        if (item is! Map) continue;
        final mint = item['mint']?.toString() ?? '';
        final owner = item['owner']?.toString() ?? '';
        final accountIndex = item['accountIndex']?.toString() ?? '';
        if (!_hasValue(mint) || owner.toLowerCase() != lowerUserAddress) {
          continue;
        }
        if (_hasValue(lowerContractAddress) &&
            mint.toLowerCase() != lowerContractAddress) {
          continue;
        }
        balanceKeys.add('$mint|$owner|$accountIndex');
      }

      for (final key in balanceKeys) {
        final parts = key.split('|');
        final mint = parts[0];
        final owner = parts[1];
        final accountIndex = parts[2];
        final preAmount = _findSolanaTokenAmount(
          preBalances,
          mint: mint,
          owner: owner,
          accountIndex: accountIndex,
        );
        final postAmount = _findSolanaTokenAmount(
          postBalances,
          mint: mint,
          owner: owner,
          accountIndex: accountIndex,
        );
        final delta = postAmount - preAmount;
        if (delta == 0) continue;

        final direction = delta > 0 ? TradeDirection.buy : TradeDirection.sell;

        trades.add(
          TradeModel(
            symbol: mint,
            price: 0.0,
            amount: delta.abs(),
            buyTurnover: 0.0,
            direction: direction,
            time: blockTime,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            from: direction == TradeDirection.sell ? userAddress : null,
            to: direction == TradeDirection.buy ? userAddress : null,
            contractAddress: mint,
            tokenName: null,
          ),
        );
      }
    }

    return trades;
  }

  List<TradeModel> _parseBtcTxsToTradeModel(
    List<Map<String, dynamic>> txs,
    String userAddress,
  ) {
    final trades = <TradeModel>[];

    for (final tx in txs) {
      final time =
          DateTime.tryParse(
            tx['confirmed']?.toString() ?? '',
          )?.millisecondsSinceEpoch ??
          0;
      var totalReceived = 0.0;
      var totalSent = 0.0;

      for (final output in tx['outputs'] as List? ?? []) {
        if (output is! Map) continue;
        final addresses = (output['addresses'] as List? ?? []).map(
          (e) => e.toString(),
        );
        final value = ((output['value'] as num?) ?? 0) / 1e8;
        if (addresses.contains(userAddress)) {
          totalReceived += value;
        }
      }

      for (final input in tx['inputs'] as List? ?? []) {
        if (input is! Map) continue;
        final addresses = (input['addresses'] as List? ?? []).map(
          (e) => e.toString(),
        );
        final value = ((input['output_value'] as num?) ?? 0) / 1e8;
        if (addresses.contains(userAddress)) {
          totalSent += value;
        }
      }

      if (totalReceived == 0 && totalSent == 0) continue;

      final direction = totalSent > 0
          ? TradeDirection.sell
          : TradeDirection.buy;
      final amount = direction == TradeDirection.sell
          ? totalSent
          : totalReceived;

      trades.add(
        TradeModel(
          symbol: 'BTC',
          price: 0.0,
          amount: amount,
          buyTurnover: 0.0,
          direction: direction,
          time: (time / 1000).toInt(),
          createdAt: DateTime.now().millisecondsSinceEpoch,
          from: direction == TradeDirection.sell ? userAddress : null,
          to: direction == TradeDirection.buy ? userAddress : null,
          contractAddress: null,
          tokenName: null,
        ),
      );
    }

    return trades;
  }

  List<TradeModel> _parseTronTxsToTradeModel(
    List<Map<String, dynamic>> txs,
    String userAddress, {
    required ChainAccount chain,
    String? contractAddress,
  }) {
    if (_hasValue(contractAddress)) {
      return txs.map((tx) {
        final tokenInfo = tx['token_info'];
        final decimals = tokenInfo is Map
            ? int.tryParse(tokenInfo['decimals']?.toString() ?? '6') ?? 6
            : 6;
        final from = _normalizeTronAddress(tx['from']);
        final to = _normalizeTronAddress(tx['to']);
        final rawValue =
            BigInt.tryParse(tx['value']?.toString() ?? '') ?? BigInt.zero;
        return TradeModel(
          symbol: tokenInfo is Map
              ? tokenInfo['symbol']?.toString() ?? chain.symbol
              : chain.symbol,
          price: 0,
          amount: _formatBigIntAmount(rawValue, decimals),
          buyTurnover: 0,
          direction: from == userAddress
              ? TradeDirection.sell
              : TradeDirection.buy,
          time:
              (int.tryParse(tx['block_timestamp']?.toString() ?? '') ?? 0) ~/
              1000,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          from: from,
          to: to,
          contractAddress: contractAddress,
          tokenName: tokenInfo is Map ? tokenInfo['name']?.toString() : null,
        );
      }).toList();
    }

    final trades = <TradeModel>[];
    for (final tx in txs) {
      final contracts = tx['raw_data']?['contract'];
      if (contracts is! List || contracts.isEmpty) continue;
      final contract = contracts.first;
      if (contract is! Map || contract['type'] != 'TransferContract') continue;
      final value = contract['parameter']?['value'];
      if (value is! Map) continue;
      final from = _normalizeTronAddress(value['owner_address']);
      final to = _normalizeTronAddress(value['to_address']);
      final amount =
          BigInt.tryParse(value['amount']?.toString() ?? '') ?? BigInt.zero;
      trades.add(
        TradeModel(
          symbol: chain.symbol,
          price: 0,
          amount: _formatBigIntAmount(amount, 6),
          buyTurnover: 0,
          direction: from == userAddress
              ? TradeDirection.sell
              : TradeDirection.buy,
          time:
              (int.tryParse(tx['block_timestamp']?.toString() ?? '') ?? 0) ~/
              1000,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          from: from,
          to: to,
        ),
      );
    }
    return trades;
  }

  double _findSolanaTokenAmount(
    List balances, {
    required String mint,
    required String owner,
    required String accountIndex,
  }) {
    for (final item in balances) {
      if (item is! Map) continue;
      if (item['mint']?.toString() != mint ||
          item['owner']?.toString() != owner ||
          item['accountIndex']?.toString() != accountIndex) {
        continue;
      }

      final uiTokenAmount = item['uiTokenAmount'];
      if (uiTokenAmount is! Map) return 0;

      final amount = BigInt.tryParse(uiTokenAmount['amount']?.toString() ?? '');
      final decimals =
          int.tryParse(uiTokenAmount['decimals']?.toString() ?? '0') ?? 0;
      if (amount == null) {
        return double.tryParse(
              uiTokenAmount['uiAmountString']?.toString() ?? '0',
            ) ??
            0;
      }
      return _formatBigIntAmount(amount, decimals);
    }

    return 0;
  }

  String _normalizeTronAddress(dynamic address) {
    final value = address?.toString() ?? '';
    if (RegExp(r'^41[0-9a-fA-F]{40}$').hasMatch(value)) {
      return TronService.hexToAddress(value);
    }
    return value;
  }

  double _formatBigIntAmount(BigInt value, int decimals) {
    if (value == BigInt.zero) return 0;
    if (decimals <= 0) return value.toDouble();

    final negative = value.isNegative;
    final valueString = value.abs().toString().padLeft(decimals + 1, '0');
    final integer = valueString.substring(0, valueString.length - decimals);
    var fraction = valueString.substring(valueString.length - decimals);
    fraction = fraction.replaceFirst(RegExp(r'0+$'), '');
    final amountString =
        '${negative ? '-' : ''}$integer${fraction.isEmpty ? '' : '.$fraction'}';

    return double.tryParse(amountString) ?? 0;
  }

  bool _hasValue(Object? value) => value != null && value.toString().isNotEmpty;

  bool _isTimeoutException(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout;
  }

  String _resolveEvmApiUrl(String? txApiUrl) {
    if (!_hasValue(txApiUrl)) return _evmApiUrl;

    final uri = Uri.tryParse(txApiUrl!);
    final host = uri?.host.toLowerCase() ?? '';
    final isEtherscanV2 = host == 'api.etherscan.io' && uri?.path == '/v2/api';
    if (isEtherscanV2) return txApiUrl;

    const deprecatedV1Hosts = {
      'api.etherscan.io',
      'api.bscscan.com',
      'api-testnet.bscscan.com',
      'api.polygonscan.com',
      'api.arbiscan.io',
      'api-optimistic.etherscan.io',
      'api.snowtrace.io',
      'api.basescan.org',
    };

    if (deprecatedV1Hosts.contains(host)) {
      return _evmApiUrl;
    }

    return txApiUrl;
  }

  dynamic _decodeResponseData(dynamic data) {
    if (data is String) return jsonDecode(data);
    return data;
  }
}
