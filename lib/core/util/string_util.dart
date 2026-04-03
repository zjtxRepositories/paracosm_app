String truncateDouble(double value) {
  String str = value.toString();
  // 查找小数点的位置
  int dotIndex = str.indexOf('.');
  if (dotIndex == -1) {
    // 如果没有小数点，直接返回
    return str;
  }
  // 截取到小数点后两位（不含多余的0）
  String truncated = str.substring(0, (dotIndex + 3).clamp(0, str.length));
  return truncated
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}

String ellipsisMiddle(String text, {int head = 7, int tail = 7}) {
  if (text.length <= head + tail) return text;
  return '${text.substring(0, head)}...${text.substring(text.length - tail)}';
}