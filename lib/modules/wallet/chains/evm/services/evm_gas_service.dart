import '../../../model/chain_account.dart';
import '../../model/gas_fee.dart';
import '../client/evm_client_manager.dart';

/// =============================
/// Gas 费用服务
/// =============================
class EvmGasService {
  static final BigInt _gwei = BigInt.from(1000000000);
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
            const Duration(seconds: 5),
            onTimeout: () {
              throw Exception("节点 ${chain.chainId} 获取区块信息超时");
            },
          );

          // legacy 链（没有 baseFeePerGas）
          if (block.baseFeePerGas == null) {
            final gasPrice = await client.getGasPrice().timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                throw Exception("节点 ${chain.chainId} 获取 gasPrice 超时");
              },
            );

            final base = gasPrice.getInWei;
            final gasLevel = _buildLegacyGasLevel(base);

            _gasCache[chain.chainId] = gasLevel;
            _gasCacheTime[chain.chainId] = now;
            return gasLevel;
          }

          // EIP-1559 链
          final base = block.baseFeePerGas!.getInWei;

          final gasLevel = base > BigInt.zero
              ? _buildEip1559GasLevel(base)
              : await _buildZeroBaseFeeGasLevel(chain.chainId, client);

          _gasCache[chain.chainId] = gasLevel;
          _gasCacheTime[chain.chainId] = now;
          return gasLevel;
        },
      );

      return result;
    } catch (e) {
      final fallback = _buildFallbackGasLevel(chain.chainId);

      _gasCache[chain.chainId] = fallback;
      _gasCacheTime[chain.chainId] = now;
      return fallback;
    }
  }

  static GasLevel _buildLegacyGasLevel(BigInt base) {
    GasFee build(int numerator, int denominator) {
      final gasPrice =
          base * BigInt.from(numerator) ~/ BigInt.from(denominator);
      return GasFee(
        gasPrice: gasPrice,
        maxFeePerGas: gasPrice,
        maxPriorityFeePerGas: BigInt.zero,
      );
    }

    return GasLevel(
      slow: build(1, 1),
      medium: build(12, 10),
      fast: build(15, 10),
    );
  }

  static GasLevel _buildEip1559GasLevel(BigInt baseFee) {
    GasFee build({required int baseMultiplier, required int tipGwei}) {
      final priority = BigInt.from(tipGwei) * _gwei;
      final maxFee = (baseFee * BigInt.from(baseMultiplier)) + priority;
      return GasFee(maxFeePerGas: maxFee, maxPriorityFeePerGas: priority);
    }

    return GasLevel(
      slow: build(baseMultiplier: 2, tipGwei: 1),
      medium: build(baseMultiplier: 2, tipGwei: 2),
      fast: build(baseMultiplier: 3, tipGwei: 3),
    );
  }

  static Future<GasLevel> _buildZeroBaseFeeGasLevel(
    int chainId,
    dynamic client,
  ) async {
    try {
      final gasPrice = await client.getGasPrice().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception("节点 $chainId 获取 gasPrice 超时");
        },
      );
      final base = gasPrice.getInWei;
      if (base > BigInt.zero) {
        return _buildLegacyGasLevel(base);
      }
    } catch (_) {}
    return _buildFallbackGasLevel(chainId);
  }

  static GasLevel _buildFallbackGasLevel(int chainId) {
    final baseGwei = switch (chainId) {
      1 => 5,
      56 || 97 => 3,
      137 || 80001 || 80002 => 30,
      42161 || 421614 => 0.1,
      10 || 11155420 => 0.01,
      8453 || 84532 => 0.01,
      _ => 5,
    };

    final slow = _gweiFromNumber(baseGwei);
    final medium = _gweiFromNumber(baseGwei * 1.2);
    final fast = _gweiFromNumber(baseGwei * 1.5);
    final slowPriority = _fallbackPriority(slow, 1);
    final mediumPriority = _fallbackPriority(medium, 2);
    final fastPriority = _fallbackPriority(fast, 3);

    return GasLevel(
      slow: GasFee(
        gasPrice: slow,
        maxFeePerGas: slow,
        maxPriorityFeePerGas: slowPriority,
      ),
      medium: GasFee(
        gasPrice: medium,
        maxFeePerGas: medium,
        maxPriorityFeePerGas: mediumPriority,
      ),
      fast: GasFee(
        gasPrice: fast,
        maxFeePerGas: fast,
        maxPriorityFeePerGas: fastPriority,
      ),
    );
  }

  static BigInt _gweiFromNumber(num value) {
    return BigInt.from((value * 1000000000).round());
  }

  static BigInt _fallbackPriority(BigInt maxFee, int preferredGwei) {
    final preferred = BigInt.from(preferredGwei) * _gwei;
    final halfMaxFee = maxFee ~/ BigInt.from(2);
    if (halfMaxFee <= BigInt.zero) return maxFee;
    return preferred < halfMaxFee ? preferred : halfMaxFee;
  }
}
