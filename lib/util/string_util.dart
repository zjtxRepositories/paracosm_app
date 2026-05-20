import 'dart:convert';
import 'dart:typed_data';

import 'package:paracosm/widgets/base/app_localizations.dart';

String truncateDouble(double value, {int digits = 8}) {
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

String formatTrim(double value, {int fractionDigits = 8}) {
  return value.toStringAsFixed(8).replaceFirst(RegExp(r'\.?0*$'), '');
}

String formatIMTime(int timestamp) {
  final now = DateTime.now();

  final dateTime = timestamp < 1000000000000
      ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
      : DateTime.fromMillisecondsSinceEpoch(timestamp);

  final diff = now.difference(dateTime);

  /// 今天
  if (_isSameDay(now, dateTime)) {
    if (diff.inMinutes < 1) {
      return AppLocalizations.currentText('time_just_now');
    }
    if (diff.inMinutes < 60) {
      return AppLocalizations.currentText('time_minutes_ago', {
        'count': diff.inMinutes,
      });
    }
    return _formatTime(dateTime); // HH:mm
  }

  /// 昨天
  final yesterday = now.subtract(const Duration(days: 1));
  if (_isSameDay(yesterday, dateTime)) {
    return AppLocalizations.currentText('time_yesterday_time', {
      'time': _formatTime(dateTime),
    });
  }

  /// 本周
  if (diff.inDays < 7) {
    return _weekDay(dateTime);
  }

  /// 今年
  if (now.year == dateTime.year) {
    return '${_two(dateTime.month)}-${_two(dateTime.day)}';
  }

  /// 跨年
  return '${dateTime.year}-${_two(dateTime.month)}-${_two(dateTime.day)}';
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _formatTime(DateTime dt) {
  return '${_two(dt.hour)}:${_two(dt.minute)}';
}

String _two(int n) => n.toString().padLeft(2, '0');

String _weekDay(DateTime dt) {
  final list = [
    AppLocalizations.currentText('time_weekday_monday'),
    AppLocalizations.currentText('time_weekday_tuesday'),
    AppLocalizations.currentText('time_weekday_wednesday'),
    AppLocalizations.currentText('time_weekday_thursday'),
    AppLocalizations.currentText('time_weekday_friday'),
    AppLocalizations.currentText('time_weekday_saturday'),
    AppLocalizations.currentText('time_weekday_sunday'),
  ];
  return list[dt.weekday - 1];
}

Uint8List base64ToBytes(String base64String) {
  final cleaned = base64String.contains(',')
      ? base64String.split(',').last
      : base64String;

  return base64Decode(cleaned);
}

String formatDurationFromMs(int ms) {
  return _formatSeconds(ms ~/ 1000);
}

String formatDurationFromSeconds(int seconds) {
  return _formatSeconds(seconds);
}

String _formatSeconds(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;

  return '${m.toString().padLeft(2, '0')}:'
      '${s.toString().padLeft(2, '0')}';
}

String formatFileSize(int bytes) {
  final kb = bytes / 1000;
  return '${kb.round()}KB';
}
