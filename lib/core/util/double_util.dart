BigInt doubleToBigInt(
    double value, {
      required int decimals,
    }) {
  final factor = BigInt.from(10).pow(decimals);
  return BigInt.parse((value * factor.toDouble()).toStringAsFixed(0));
}

String formatTokenAdvanced(
    BigInt amount,
    int decimals, {
      int fractionDigits = 6,
      bool showLessThan = true,
    }) {
  final divisor = BigInt.from(10).pow(decimals);

  final integerPart = amount ~/ divisor;
  final decimalPart = amount % divisor;

  String decimalStr = decimalPart
      .toString()
      .padLeft(decimals, '0')
      .substring(0, fractionDigits);

  decimalStr = decimalStr.replaceFirst(RegExp(r'0+$'), '');

  // 小于最小显示值
  if (showLessThan &&
      integerPart == BigInt.zero &&
      decimalStr.isNotEmpty &&
      BigInt.parse(decimalStr) == BigInt.zero) {
    return "<0.${'0' * (fractionDigits - 1)}1";
  }

  if (decimalStr.isEmpty) {
    return integerPart.toString();
  }

  return "$integerPart.$decimalStr";
}