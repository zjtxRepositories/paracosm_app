
String truncateDouble(double value,{int digits = 8}) {
  if (value == 0) return '0';

  // 小于1时，保留更多精度
  if (value < 1) {
    return _truncate(value, digits);
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

String formatTrim(double value,{int fractionDigits = 8}) {
  return value.toStringAsFixed(8).replaceFirst(RegExp(r'\.?0*$'), '');
}

String formatTimeAgo(int timestamp) {
  final now = DateTime.now();
  // 判断是秒还是毫秒
  final dateTime = timestamp < 1000000000000
      ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
      : DateTime.fromMillisecondsSinceEpoch(timestamp);
  final difference = now.difference(dateTime);

  if (difference.inMinutes < 1) {
    return '刚刚';
  } else if (difference.inMinutes < 60) {
    return "${difference.inMinutes}分钟前";
  } else if (difference.inHours < 24) {
    return "${difference.inHours}小时前";
  } else if (difference.inDays < 7) {
    return "${difference.inDays}天前";
  } else if (difference.inDays < 30) {
    return '一周前';
  } else if (difference.inDays < 365) {
    return '一个月前';
  } else {
    return '一年前';
  }
}
