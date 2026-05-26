import 'dart:async';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

import '../../../model/chain_account.dart';

/// =============================
/// EVM RPC 客户端管理
/// =============================
class EvmClientManager {
  static final Map<String, Web3Client> _clients = {};
  static final Map<int, String> _bestRpcCache = {};

  /// 获取或创建 Web3Client
  static Web3Client getClient(String rpc) {
    return _clients.putIfAbsent(rpc, () => Web3Client(rpc, Client()));
  }

  /// 清理客户端
  static Future<void> dispose() async {
    for (final client in _clients.values) {
      client.dispose();
    }
    _clients.clear();
  }

  /// 顺序遍历节点 + fallback + 超时
  static Future<T> withFallback<T>(
      int chainId,
      List<String> rpcs,
      Future<T> Function(Web3Client client) action,
      ) async {
    final sortedRpcs = [
      if (_bestRpcCache.containsKey(chainId)) _bestRpcCache[chainId]!,
      ...rpcs.where((e) => e != _bestRpcCache[chainId]),
    ];

    Exception? lastError;

    for (final rpc in sortedRpcs) {
      try {
        final client = getClient(rpc);

        // 对每个节点请求加超时
        final result = await action(client).timeout(
          Duration(seconds: 5),
          onTimeout: () {
            throw Exception("节点 $rpc 请求超时");
          },
        );

        // 成功记录最佳节点
        _bestRpcCache[chainId] = rpc;
        return result;
      } catch (e) {
        if (_isInvalidParamsError(e)) {
          throw Exception("RPC参数错误: $e");
        }
        lastError = Exception("RPC失败: $rpc -> $e");
        print(lastError);
        continue;
      }
    }

    throw lastError ?? Exception("所有RPC失败");
  }

  static bool _isInvalidParamsError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('code -32602') ||
        message.contains('invalid argument') ||
        message.contains('invalid address') ||
        message.contains('empty hex string');
  }

  /// 通用 RPC 调用
  static Future<dynamic> rpc({
    required ChainAccount chain,
    required String method,
    List? params,
  }) async {
    return withFallback(
      chain.chainId,
      chain.nodes,
          (client) async {
        print('rpc:method:$method params:$params');
        final result = await client.makeRPCCall(method, params ?? const []);
        print('rpc:result:$result');
        return result;
      },
    );
  }
}
