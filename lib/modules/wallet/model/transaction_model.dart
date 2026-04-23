import 'package:intl/intl.dart';

import '../../../util/double_util.dart';

class TransactionModel {
  final String hash;
  final String from;
  final String to;
  final String logo;
  final String symbol;

  /// 金额（单位：wei）
  final BigInt value;

  /// gas 相关
  final BigInt? fee; // gasUsed * gasPrice
  final DateTime? time;

  final int decimals;
  dynamic err;
  TransactionModel({
    required this.hash,
    required this.from,
    required this.to,
    required this.value,
    this.fee,
    required this.logo,
    this.time,
    required this.decimals,
    required this.symbol,
    this.err,

  });

  String get valueDisplay => formatTokenAdvanced(value, decimals);
  String get feeDisplay => fee != null ? formatTokenAdvanced(fee!, 18) : "--";
  String get timeDisplay {
    if (time == null) return "Pending";

    final now = DateTime.now();
    final diff = now.difference(time!);

    if (diff.inMinutes < 1) return "刚刚";
    if (diff.inMinutes < 60) return "${diff.inMinutes}分钟前";
    if (diff.inHours < 24) return "${diff.inHours}小时前";

    return DateFormat("MM-dd HH:mm").format(time!);
  }
}