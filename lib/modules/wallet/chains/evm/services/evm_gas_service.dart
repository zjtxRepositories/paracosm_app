
import '../../../model/chain_account.dart';
import '../../model/gas_fee.dart';
import '../client/evm_client_manager.dart';

class EvmGasService {

  static final Map<int, GasLevel> _gasCache = {};
  static final Map<int, int> _gasCacheTime = {};


  /// =========================
  /// Gas
  /// =========================
  static Future<GasLevel> getGasLevels(ChainAccount chain) async {
    final now = DateTime
        .now()
        .millisecondsSinceEpoch;

    if (_gasCache.containsKey(chain.chainId) &&
        now - _gasCacheTime[chain.chainId]! < 10000) {
      return _gasCache[chain.chainId]!;
    }

    try {
      final result =
      await EvmClientManager.withFallback(chain.chainId, chain.nodes, (client) async {
        final block = await client.getBlockInformation();

        /// legacy链
        if (block.baseFeePerGas == null) {
          final gasPrice = await client.getGasPrice();

          final base = gasPrice.getInWei;

          return GasLevel(
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
        }

        /// EIP-1559
        final base = block.baseFeePerGas!.getInWei;

        GasFee build(int multiplier, int tipGwei) {
          final priority =
              BigInt.from(tipGwei) * BigInt.from(1000000000);
          final maxFee =
              (base * BigInt.from(multiplier) ~/ BigInt.from(1)) + priority;

          return GasFee(
            maxFeePerGas: maxFee,
            maxPriorityFeePerGas: priority,
          );
        }

        return GasLevel(
          slow: build(12, 1),
          medium: build(15, 2),
          fast: build(20, 3),
        );
      });

      _gasCache[chain.chainId] = result;
      _gasCacheTime[chain.chainId] = now;

      return result;
    } catch (_) {
      return GasLevel(
        slow: GasFee(
          maxFeePerGas: BigInt.from(20000000000),
          maxPriorityFeePerGas: BigInt.from(1000000000),
        ),
        medium: GasFee(
          maxFeePerGas: BigInt.from(30000000000),
          maxPriorityFeePerGas: BigInt.from(2000000000),
        ),
        fast: GasFee(
          maxFeePerGas: BigInt.from(40000000000),
          maxPriorityFeePerGas: BigInt.from(3000000000),
        ),
      );
    }
  }

}