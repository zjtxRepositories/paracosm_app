
import 'dart:async';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

import '../../../model/chain_account.dart';

class EvmClientManager {
  static final Map<String, Web3Client> _clients = {};
  static final Map<int, String> _bestRpcCache = {};

  /// =========================
  /// client
  /// =========================
  static Web3Client getClient(String rpc) {
    return _clients.putIfAbsent(rpc, () => Web3Client(rpc, Client()));
  }

  static Future<void> dispose() async {
    for (final client in _clients.values) {
      client.dispose();
    }
    _clients.clear();
  }

  /// =========================
  /// RPC容灾（优化）
  /// =========================
  static Future<T> withFallback<T>(int chainId,
      List<String> rpcs,
      Future<T> Function(Web3Client client) action,) async {
    final sortedRpcs = [
      if (_bestRpcCache.containsKey(chainId))
        _bestRpcCache[chainId]!,
      ...rpcs.where((e) => e != _bestRpcCache[chainId]),
    ];

    Exception? lastError;

    for (final rpc in sortedRpcs) {
      try {
        final client = getClient(rpc);
        final result = await action(client);
        _bestRpcCache[chainId] = rpc;
        return result;
      } catch (e) {
        lastError = Exception("RPC失败: $rpc -> $e");
      }
    }

    throw lastError ?? Exception("所有RPC失败");
  }

  /// =========================
  /// RPC
  /// =========================
  static Future<dynamic> rpc({
    required ChainAccount chain,
    required String method,
    List? params,
  }) async {
    return withFallback(
      chain.chainId,
      chain.nodes,
          (client) => client.makeRPCCall(method, params ?? []),
    );
  }
}