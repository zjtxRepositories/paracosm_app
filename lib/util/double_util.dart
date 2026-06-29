import 'package:paracosm/util/string_util.dart';

BigInt doubleToBigInt(double value, {required int decimals}) {
  final factor = BigInt.from(10).pow(decimals);
  return BigInt.parse((value * factor.toDouble()).toStringAsFixed(0));
}

String formatTokenAdvanced(
  BigInt amount,
  int decimals, {
  int fractionDigits = 4,
  bool showLessThan = true,
}) {
  return formatTokenUnits(
    amount,
    decimals,
    fractionDigits: fractionDigits,
    showLessThan: showLessThan,
  );
}
