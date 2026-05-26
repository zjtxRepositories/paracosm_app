import 'package:paracosm/modules/wallet/chains/evm/client/evm_client_manager.dart';
import 'package:paracosm/modules/wallet/chains/evm/services/evm_token_info_service.dart';
import 'package:paracosm/modules/wallet/model/chain_account.dart';
import 'package:paracosm/modules/wallet/model/trade_model.dart';

class EvmErc20RpcScanService {
  static const String _transferTopic =
      '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef';
  static const int _defaultScanBlockCount = 100000;
  static const int _defaultChunkSize = 5000;

  /// 通过 RPC eth_getLogs 扫 ERC20 Transfer 事件。
  ///
  /// 注意：普通 RPC 没有交易索引能力，这里只能按最近区块范围扫描。
  /// 如果需要完整历史，仍建议后端接入 OKLink/Alchemy/自建索引器。
  static Future<List<TradeModel>> getErc20Transactions({
    required ChainAccount chain,
    required String walletAddress,
    required String contractAddress,
    int limit = 20,
    int scanBlockCount = _defaultScanBlockCount,
    int chunkSize = _defaultChunkSize,
  }) {
    return EvmClientManager.withFallback(chain.chainId, chain.nodes, (
      client,
    ) async {
      final latestBlockHex = await client.makeRPCCall('eth_blockNumber');
      final latestBlock = _hexToInt(latestBlockHex?.toString() ?? '0x0');
      final fromBlock = latestBlock - scanBlockCount > 0
          ? latestBlock - scanBlockCount
          : 0;

      final tokenInfo = await EvmTokenInfoService.getTokenInfo(
        client: client,
        contractAddress: contractAddress,
        chainId: chain.chainId,
      );
      final symbol = tokenInfo?.symbol ?? 'ERC20';
      final tokenName = tokenInfo?.name;
      final decimals = tokenInfo?.decimals ?? 18;

      final logs = <Map<String, dynamic>>[];
      final seenLogIds = <String>{};
      final userTopic = _addressToTopic(walletAddress);

      for (var end = latestBlock; end >= fromBlock; end -= chunkSize) {
        final start = end - chunkSize + 1 > fromBlock
            ? end - chunkSize + 1
            : fromBlock;

        final outgoing = await _getTransferLogs(
          fromBlock: start,
          toBlock: end,
          contractAddress: contractAddress,
          topics: [_transferTopic, userTopic],
          clientCall: client.makeRPCCall,
        );
        final incoming = await _getTransferLogs(
          fromBlock: start,
          toBlock: end,
          contractAddress: contractAddress,
          topics: [_transferTopic, null, userTopic],
          clientCall: client.makeRPCCall,
        );

        for (final log in [...outgoing, ...incoming]) {
          final id = '${log['transactionHash']}_${log['logIndex']}';
          if (seenLogIds.add(id)) {
            logs.add(log);
          }
        }

        logs.sort(_compareLogDesc);
        if (logs.length >= limit) break;
      }

      final blockTimeCache = <int, int>{};
      final trades = <TradeModel>[];
      for (final log in logs.take(limit)) {
        final topics = log['topics'] as List? ?? [];
        if (topics.length < 3) continue;

        final from = _topicToAddress(topics[1]?.toString() ?? '');
        final to = _topicToAddress(topics[2]?.toString() ?? '');
        final value = _hexToBigInt(log['data']?.toString() ?? '0x0');
        final amount = _formatBigIntAmount(value, decimals);
        final blockNumber = _hexToInt(log['blockNumber']?.toString() ?? '0x0');
        final blockTime = await _getBlockTimestamp(
          blockNumber,
          blockTimeCache,
          client.makeRPCCall,
        );
        final direction = from.toLowerCase() == walletAddress.toLowerCase()
            ? TradeDirection.sell
            : TradeDirection.buy;

        trades.add(
          TradeModel(
            symbol: symbol,
            price: 0.0,
            amount: amount,
            buyTurnover: 0.0,
            direction: direction,
            time: blockTime,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            from: from,
            to: to,
            contractAddress: contractAddress,
            tokenName: tokenName,
          ),
        );
      }

      return trades;
    });
  }

  static Future<List<Map<String, dynamic>>> _getTransferLogs({
    required int fromBlock,
    required int toBlock,
    required String contractAddress,
    required List<String?> topics,
    required Future<dynamic> Function(String, [List<dynamic>?]) clientCall,
  }) async {
    final result = await clientCall('eth_getLogs', [
      {
        'fromBlock': _intToHex(fromBlock),
        'toBlock': _intToHex(toBlock),
        'address': contractAddress,
        'topics': topics,
      },
    ]);

    return (result as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<int> _getBlockTimestamp(
    int blockNumber,
    Map<int, int> cache,
    Future<dynamic> Function(String, [List<dynamic>?]) clientCall,
  ) async {
    if (cache.containsKey(blockNumber)) return cache[blockNumber]!;

    final block = await clientCall('eth_getBlockByNumber', [
      _intToHex(blockNumber),
      false,
    ]);
    final timestamp = block is Map
        ? _hexToInt(block['timestamp']?.toString() ?? '0x0')
        : 0;
    cache[blockNumber] = timestamp;
    return timestamp;
  }

  static int _compareLogDesc(Map<String, dynamic> a, Map<String, dynamic> b) {
    final blockCompare = _hexToInt(
      b['blockNumber']?.toString() ?? '0x0',
    ).compareTo(_hexToInt(a['blockNumber']?.toString() ?? '0x0'));
    if (blockCompare != 0) return blockCompare;

    return _hexToInt(
      b['logIndex']?.toString() ?? '0x0',
    ).compareTo(_hexToInt(a['logIndex']?.toString() ?? '0x0'));
  }

  static String _addressToTopic(String address) {
    final cleanAddress = _stripHexPrefix(address).toLowerCase();
    return '0x${cleanAddress.padLeft(64, '0')}';
  }

  static String _topicToAddress(String topic) {
    final cleanTopic = _stripHexPrefix(topic);
    if (cleanTopic.length < 40) return '';
    return '0x${cleanTopic.substring(cleanTopic.length - 40)}';
  }

  static String _intToHex(int value) => '0x${value.toRadixString(16)}';

  static int _hexToInt(String value) {
    return _hexToBigInt(value).toInt();
  }

  static BigInt _hexToBigInt(String value) {
    final cleanValue = _stripHexPrefix(value);
    if (cleanValue.isEmpty) return BigInt.zero;
    return BigInt.parse(cleanValue, radix: 16);
  }

  static String _stripHexPrefix(String value) {
    return value.startsWith('0x') || value.startsWith('0X')
        ? value.substring(2)
        : value;
  }

  static double _formatBigIntAmount(BigInt value, int decimals) {
    if (value == BigInt.zero) return 0;
    if (decimals <= 0) return value.toDouble();

    final valueString = value.toString().padLeft(decimals + 1, '0');
    final integer = valueString.substring(0, valueString.length - decimals);
    var fraction = valueString.substring(valueString.length - decimals);
    fraction = fraction.replaceFirst(RegExp(r'0+$'), '');
    final amountString = '$integer${fraction.isEmpty ? '' : '.$fraction'}';

    return double.tryParse(amountString) ?? 0;
  }
}
