import 'dart:async';
import 'package:paracosm/modules/wallet/model/chain_account.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

class EvmChainService {
  static final Map<String, Web3Client> _clients = {};

  /// 获取或创建 client（复用）
  static Web3Client _getClient(String rpc) {
    return _clients.putIfAbsent(
      rpc,
          () => Web3Client(rpc, Client()),
    );
  }

  /// 🚀 RPC容灾（自动切换）
  static Future<T> _withFallback<T>(
      List<String> rpcs,
      Future<T> Function(Web3Client client) action,
      ) async {
    Exception? lastError;

    for (final rpc in rpcs) {
      try {
        final client = _getClient(rpc);
        return await action(client);
      } catch (e) {
        lastError = Exception("RPC失败: $rpc -> $e");
      }
    }

    throw lastError ?? Exception("所有RPC失败");
  }

  /// =========================
  /// 获取原生余额（多RPC容灾）
  /// =========================
  static Future<BigInt> getNativeBalance(
      ChainAccount chain,
      String address,
      ) async {
    return _withFallback<BigInt>(
      chain.nodes,
          (client) async {
        final balance = await client.getBalance(
          EthereumAddress.fromHex(address),
        );
        return balance.getInWei;
      },
    );
  }

  /// =========================
  /// 获取 ERC20 余额
  /// =========================
  static Future<BigInt> getTokenBalance(
      ChainAccount chain,
      String contractAddress,
      String address,
      ) async {
    return _withFallback<BigInt>(
      chain.nodes,
          (client) async {
        final contract = DeployedContract(
          ContractAbi.fromJson(_erc20Abi, 'ERC20'),
          EthereumAddress.fromHex(contractAddress),
        );

        final function = contract.function('balanceOf');

        final result = await client.call(
          contract: contract,
          function: function,
          params: [EthereumAddress.fromHex(address)],
        );
        return result.first as BigInt;
      },
    );
  }

  /// =========================
  /// 🚀 多链获取原生余额（并发）
  /// =========================
  static Future<Map<String, BigInt>> getAllNativeBalances(
      List<ChainAccount> chains,
      String address,
      ) async {
    final futures = chains.map((node) async {
      final balance = await getNativeBalance(node, address);
      return MapEntry(node.symbol, balance);
    });

    final results = await Future.wait(futures);

    return Map.fromEntries(results);
  }

  /// =========================
  /// 🚀 多链 Token（可扩展）
  /// =========================
  static Future<Map<String, Map<String, BigInt>>> getAllTokenBalances(
      List<ChainAccount> chains,
      Map<int, List<String>> tokenMap, // chainId -> contracts
      String address,
      ) async {
    final result = <String, Map<String, BigInt>>{};

    await Future.wait(chains.map((node) async {
      final tokens = tokenMap[node.chainId] ?? [];

      final balances = <String, BigInt>{};

      await Future.wait(tokens.map((contract) async {
        final balance = await getTokenBalance(node, contract, address);
        balances[contract] = balance;
      }));

      result[node.symbol] = balances;
    }));

    return result;
  }
}

/// ERC20 ABI
const String _erc20Abi = '''
[
  {"constant":true,"inputs":[{"name":"owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"","type":"uint256"}],"type":"function"}
]
''';