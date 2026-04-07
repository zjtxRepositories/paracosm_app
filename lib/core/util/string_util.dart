
String truncateDouble(double value) {
  if (value == 0) return '0';

  // 小于1时，保留更多精度
  if (value < 1) {
    return _truncate(value, 8);
  }

  // 大于1，保留2位
  return _truncate(value, 2);
}

String _truncate(double value, int digits) {
  String str = value.toStringAsFixed(18);
  final parts = str.split('.');

  String decimal = parts.length > 1 ? parts[1] : '';

  decimal = decimal.substring(0, digits.clamp(0, decimal.length));
  decimal = decimal.replaceAll(RegExp(r'0+$'), '');

  return decimal.isEmpty ? parts[0] : '${parts[0]}.$decimal';
}

String ellipsisMiddle(String text, {int head = 7, int tail = 7}) {
  if (text.length <= head + tail) return text;
  return '${text.substring(0, head)}...${text.substring(text.length - tail)}';
}