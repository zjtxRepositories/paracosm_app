import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:paracosm/modules/wallet/model/chain_account.dart';

import '../model/trade_model.dart';

class BlockChainService {
  final _solanaRpc = "https://api.mainnet-beta.solana.com";
  final _evmApiUrl = "https://api.etherscan.io/v2/api";
  final _evmApiKey = "AJYYQC9NT6NV5WGPDSDNXXQHDRF375RQ4Q";

  /// 统一入口: 获取代币交易记录 (ETH, BNB, Solana)
  Future<List<TradeModel>> getTokenTransactions(
      ChainAccount chain,
      String address, {
        String? contractAddress,
        int limit = 20,
      }) async {
    List<Map<String, dynamic>> rawTxs;
    switch (chain.chainType) {
      case ChainType.solana:
        rawTxs = await _getTokenTransactionsSolana(address, limit: limit);
        return _parseSolanaTxsToTradeModel(rawTxs, address);
      case ChainType.bitcoin:
        rawTxs = await _getTokenTransactionsBTC(address, limit: limit);
        return _parseBtcTxsToTradeModel(rawTxs, address);
      default:
        rawTxs = await _getTokenTransactionsEvm(
          chain,
          address,
          contractAddress: contractAddress,
        );
        return _parseEvmTxsToTradeModel(rawTxs, address);
    }
  }

  /// 获取 ERC20 / BEP20 代币交易记录（强制使用 V2 API）
  Future<List<Map<String, dynamic>>> _getTokenTransactionsEvm(
      ChainAccount chain,
      String address, {
        String? contractAddress,
      }) async {
    final isToken = contractAddress != null && contractAddress.isNotEmpty;
    final action = isToken ? "tokentx" : "txlist";

    String baseUrl = chain.txApiUrl ?? _evmApiUrl;
    String apiKey = chain.apiKey ?? _evmApiKey;
    final chainId = chain.chainId;

    final urlString = "$baseUrl"
        "?chainid=$chainId"
        "&module=account"
        "&action=$action"
        "&address=$address"
        "${isToken ? "&contractaddress=$contractAddress" : ""}"
        "&startblock=0&endblock=99999999"
        "&sort=desc"
        "&apikey=$apiKey";

    print('V2 API url: $urlString');

    final url = Uri.parse(urlString);
    final res = await http.get(url, headers: {"User-Agent": "Mozilla/5.0"});
    print('res: ${res.statusCode}');

    if (res.statusCode == 200) {
      print('response: ${res.body}');
      final data = jsonDecode(res.body);

      if (data['status'] == "1") {
        // V2 返回 result.transactions
        if (data['result'] is Map && data['result']['transactions'] != null) {
          return List<Map<String, dynamic>>.from(data['result']['transactions']);
        } else {
          return List<Map<String, dynamic>>.from(data['result']);
        }
      } else {
        print('获取交易记录失败: ${data['message']}');
        return [];
      }
    } else {
      throw Exception("请求失败: ${res.statusCode}");
    }
  }

  /// 获取 Solana SPL Token 交易记录
  Future<List<Map<String, dynamic>>> _getTokenTransactionsSolana(
      String address,
      {int limit = 5}) async {
    final sigRes = await http.post(
      Uri.parse(_solanaRpc),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "jsonrpc": "2.0",
        "id": 1,
        "method": "getSignaturesForAddress",
        "params": [address, {"limit": limit}]
      }),
    );

    final sigData = jsonDecode(sigRes.body);
    final signatures = sigData['result'] as List? ?? [];

    List<Map<String, dynamic>> txs = [];

    for (var sig in signatures) {
      final txRes = await http.post(
        Uri.parse(_solanaRpc),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "jsonrpc": "2.0",
          "id": 1,
          "method": "getTransaction",
          "params": [sig['signature'], {"encoding": "jsonParsed"}]
        }),
      );

      final txData = jsonDecode(txRes.body);
      if (txData['result'] != null) {
        final tx = txData['result'];
        final meta = tx['meta'];
        final preTokenBalances = meta?['preTokenBalances'] ?? [];
        final postTokenBalances = meta?['postTokenBalances'] ?? [];

        txs.add({
          "signature": sig['signature'],
          "blockTime": tx['blockTime'],
          "preTokenBalances": preTokenBalances,
          "postTokenBalances": postTokenBalances,
        });
      }
    }
    return txs;
  }

  /// EVM 交易转 TradeModel
  List<TradeModel> _parseEvmTxsToTradeModel(List<Map<String, dynamic>> txs, String userAddress) {
    return txs.map((tx) {
      final decimals = int.tryParse(tx["tokenDecimal"]?.toString() ?? "18") ?? 18;
      final rawValue = BigInt.tryParse(tx["value"]?.toString() ?? "0") ?? BigInt.zero;
      final amount = rawValue / BigInt.from(10).pow(decimals);

      final direction = tx["from"].toString().toLowerCase() == userAddress.toLowerCase()
          ? TradeDirection.sell
          : TradeDirection.buy;

      return TradeModel(
        symbol: tx["tokenSymbol"] ?? "ETH",
        price: 0.0,
        amount: amount.toDouble(),
        buyTurnover: 0.0,
        direction: direction,
        time: int.tryParse(tx["timeStamp"]?.toString() ?? "0") ?? 0,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        from: tx["from"],
        to: tx["to"],
        contractAddress: tx["contractAddress"],
        tokenName: tx["tokenName"],
      );
    }).toList();
  }

  /// Solana 交易转 TradeModel
  List<TradeModel> _parseSolanaTxsToTradeModel(List<Map<String, dynamic>> txs, String userAddress) {
    List<TradeModel> trades = [];

    for (var tx in txs) {
      final blockTime = tx['blockTime'] ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final postBalances = tx['postTokenBalances'] as List? ?? [];

      for (var token in postBalances) {
        final mint = token['mint'] ?? '';
        final amount = double.tryParse(token['uiTokenAmount']?['uiAmountString']?.toString() ?? "0") ?? 0.0;
        final direction = (token['owner']?.toString().toLowerCase() == userAddress.toLowerCase())
            ? TradeDirection.buy
            : TradeDirection.sell;

        trades.add(TradeModel(
          symbol: mint,
          price: 0.0,
          amount: amount,
          buyTurnover: 0.0,
          direction: direction,
          time: blockTime,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          from: direction == TradeDirection.sell ? userAddress : null,
          to: direction == TradeDirection.buy ? userAddress : null,
          contractAddress: mint,
          tokenName: null,
        ));
      }
    }
    return trades;
  }

  Future<List<Map<String, dynamic>>> _getTokenTransactionsBTC(
      String address, {
        int limit = 10,
      }) async {
    final url = Uri.parse("https://api.blockcypher.com/v1/btc/main/addrs/$address/full?limit=$limit");
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final txs = List<Map<String, dynamic>>.from(data['txs'] ?? []);
      return txs;
    } else {
      throw Exception("BTC 请求失败: ${res.statusCode}");
    }
  }
  List<TradeModel> _parseBtcTxsToTradeModel(
      List<Map<String, dynamic>> txs, String userAddress) {
    List<TradeModel> trades = [];

    for (var tx in txs) {
      final time = DateTime.tryParse(tx['confirmed'] ?? '')?.millisecondsSinceEpoch ?? 0;

      double totalReceived = 0;
      double totalSent = 0;

      // 输出
      for (var output in tx['outputs']) {
        final addresses = List<String>.from(output['addresses'] ?? []);
        final value = (output['value'] ?? 0) / 1e8; // satoshi -> BTC
        if (addresses.contains(userAddress)) {
          totalReceived += value;
        }
      }

      // 输入
      for (var input in tx['inputs']) {
        final addresses = List<String>.from(input['addresses'] ?? []);
        final value = (input['output_value'] ?? 0) / 1e8;
        if (addresses.contains(userAddress)) {
          totalSent += value;
        }
      }

      final direction = totalSent > 0 ? TradeDirection.sell : TradeDirection.buy;
      final amount = direction == TradeDirection.sell ? totalSent : totalReceived;

      trades.add(TradeModel(
        symbol: "BTC",
        price: 0.0,
        amount: amount,
        buyTurnover: 0.0,
        direction: direction,
        time: (time / 1000).toInt(), // 转成秒
        createdAt: DateTime.now().millisecondsSinceEpoch,
        from: direction == TradeDirection.sell ? userAddress : null,
        to: direction == TradeDirection.buy ? userAddress : null,
        contractAddress: null,
        tokenName: null,
      ));
    }

    return trades;
  }


}
