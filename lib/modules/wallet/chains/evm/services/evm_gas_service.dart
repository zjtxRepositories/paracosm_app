
import '../../../model/chain_account.dart';
import '../../model/gas_fee.dart';
import '../client/evm_client_manager.dart';

/// =============================
/// Gas 费用服务
/// =============================
class EvmGasService {
  static final Map<int, GasLevel> _gasCache = {};
  static final Map<int, int> _gasCacheTime = {};

  /// 获取 Gas Level（slow/medium/fast）
  static Future<GasLevel> getGasLevels(ChainAccount chain) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 使用缓存，10 秒有效
    if (_gasCache.containsKey(chain.chainId) &&
        now - _gasCacheTime[chain.chainId]! < 10000) {
      return _gasCache[chain.chainId]!;
    }

    try {
      final result = await EvmClientManager.withFallback(
        chain.chainId,
        chain.nodes,
            (client) async {
          // 获取区块信息，超时 5 秒
          final block = await client.getBlockInformation().timeout(
            Duration(seconds: 5),
            onTimeout: () {
              throw Exception("节点 ${chain.chainId} 获取区块信息超时");
            },
          );

          // legacy 链（没有 baseFeePerGas）
          if (block.baseFeePerGas == null) {
            final gasPrice = await client.getGasPrice().timeout(
              Duration(seconds: 5),
              onTimeout: () {
                throw Exception("节点 ${chain.chainId} 获取 gasPrice 超时");
              },
            );

            final base = gasPrice.getInWei;

            final gasLevel = GasLevel(
              slow: GasFee(
                gasPrice: base,
                maxFeePerGas: base,
                maxPriorityFeePerGas: BigInt.zero,
              ),
              medium: GasFee(
                gasPrice: base * BigInt.from(12) ~/ BigInt.from(10),
                maxFeePerGas: base * BigInt.from(12) ~/ BigInt.from(10),
                maxPriorityFeePerGas: BigInt.zero,
              ),
              fast: GasFee(
                gasPrice: base * BigInt.from(15) ~/ BigInt.from(10),
                maxFeePerGas: base * BigInt.from(15) ~/ BigInt.from(10),
                maxPriorityFeePerGas: BigInt.zero,
              ),
            );

            _gasCache[chain.chainId] = gasLevel;
            _gasCacheTime[chain.chainId] = now;
            return gasLevel;
          }

          // EIP-1559 链
          final base = block.baseFeePerGas!.getInWei;

          GasFee build(int multiplier, int tipGwei) {
            final priority = BigInt.from(tipGwei) * BigInt.from(1000000000);
            final maxFee = (base * BigInt.from(multiplier)) + priority;
            return GasFee(maxFeePerGas: maxFee, maxPriorityFeePerGas: priority);
          }

          final gasLevel = GasLevel(
            slow: build(12, 1),
            medium: build(15, 2),
            fast: build(20, 3),
          );

          _gasCache[chain.chainId] = gasLevel;
          _gasCacheTime[chain.chainId] = now;
          return gasLevel;
        },
      );

      return result;
    } catch (e) {
      print('获取 GasLevel 异常: $e');

      // 所有节点失败，返回默认值
      final slow = BigInt.from(20000000000);
      final medium = BigInt.from(30000000000);
      final fast = BigInt.from(40000000000);
      final fallback = GasLevel(
        slow: GasFee(
          gasPrice: slow,
          maxFeePerGas: slow,
          maxPriorityFeePerGas: BigInt.from(1000000000),
        ),
        medium: GasFee(
          gasPrice: medium,
          maxFeePerGas: medium,
          maxPriorityFeePerGas: BigInt.from(2000000000),
        ),
        fast: GasFee(
          gasPrice: fast,
          maxFeePerGas: fast,
          maxPriorityFeePerGas: BigInt.from(3000000000),
        ),
      );

      _gasCache[chain.chainId] = fallback;
      _gasCacheTime[chain.chainId] = now;
      return fallback;
    }
  }
}