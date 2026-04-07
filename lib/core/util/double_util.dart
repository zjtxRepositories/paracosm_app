BigInt doubleToBigInt(
    double value, {
      required int decimals,
    }) {
  final factor = BigInt.from(10).pow(decimals);
  return BigInt.parse((value * factor.toDouble()).toStringAsFixed(0));
}