import 'package:intl/intl.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';

import '../../../util/double_util.dart';

class TransactionModel {
  final String hash;
  final String from;
  final String to;
  final String logo;
  final String symbol;
  final String? feeSymbol;

  /// 金额（单位：wei）
  final BigInt value;

  /// gas 相关
  final BigInt? fee; // gasUsed * gasPrice
  final DateTime? time;

  final int decimals;
  final int feeDecimals;
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
    this.feeSymbol,
    this.feeDecimals = 18,
    this.err,
  });

  String get valueDisplay =>
      formatTokenAdvanced(value, decimals, fractionDigits: 10);
  String get feeDisplay =>
      fee != null ? formatTokenAdvanced(fee!, feeDecimals) : "--";
  String get displayFeeSymbol => feeSymbol ?? symbol;
  String get timeDisplay {
    if (time == null) return "Pending";

    final now = DateTime.now();
    final diff = now.difference(time!);

    if (diff.inMinutes < 1) {
      return AppLocalizations.currentText('time_just_now');
    }
    if (diff.inMinutes < 60) {
      return AppLocalizations.currentText('time_minutes_ago', {
        'count': diff.inMinutes,
      });
    }
    if (diff.inHours < 24) {
      return AppLocalizations.currentText('time_hours_ago', {
        'count': diff.inHours,
      });
    }

    return DateFormat("MM-dd HH:mm").format(time!);
  }
}
