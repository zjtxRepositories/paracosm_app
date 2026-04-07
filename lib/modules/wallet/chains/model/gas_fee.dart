import 'package:web3dart/web3dart.dart';

class GasFee {
  final BigInt maxFeePerGas;        // EIP-1559
  final BigInt maxPriorityFeePerGas;
  final BigInt? gasPrice;           // 兼容老链

  GasFee({
    required this.maxFeePerGas,
    required this.maxPriorityFeePerGas,
    this.gasPrice,
  });
}

class GasLevel {
  final GasFee slow;
  final GasFee medium;
  final GasFee fast;
  GasLevel({
    required this.slow,
    required this.medium,
    required this.fast,
  });
}

class GasCalculator {
  /// 计算预估手续费（ETH）
  static double calculateEthFee({
    required BigInt gasLimit,
    required GasFee fee,
  }) {
    final gasPrice = fee.gasPrice ?? fee.maxFeePerGas;

    final totalWei = gasLimit * gasPrice;

    return EtherAmount.inWei(totalWei).getValueInUnit(EtherUnit.ether);
  }

  /// 转 Gwei 显示
  static double toGwei(BigInt wei) {
    return EtherAmount.inWei(wei).getValueInUnit(EtherUnit.gwei);
  }

  /// 计算 BTC 手续费（单位 BTC）
  static double calculateBtcFee({
    required int vBytes,
    required int feeRate, // sat/vB
  }) {
    final satoshi = vBytes * feeRate;

    return satoshi / 100000000; // 转 BTC
  }

  /// satoshi → BTC
  static double satoshiToBtc(int satoshi) {
    return satoshi / 100000000;
  }

  static BigInt btcToSatoshi(String amountStr) {
    // 转 double 再乘以 1e8，然后转换为 BigInt
    final btc = double.tryParse(amountStr);
    if (btc == null) throw Exception("Invalid BTC amount: $amountStr");
    return BigInt.from((btc * 100000000).round());
  }
}

class BtcFeeRate {
  final int slow;    // sat/vByte
  final int medium;
  final int fast;

  BtcFeeRate({
    required this.slow,
    required this.medium,
    required this.fast,
  });
}

abstract class ChainFee {
  double get displayFee;
}

class EvmFee extends ChainFee {
  late final GasFee gasFee;
  late final BigInt gasLimit;

  @override
  double get displayFee =>
      GasCalculator.calculateEthFee(
        gasLimit: gasLimit,
        fee: gasFee,
      );
}