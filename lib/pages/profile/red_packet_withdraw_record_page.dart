import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paracosm/core/network/api/red_packet_api.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/util/string_util.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_empty_view.dart';
import 'package:paracosm/widgets/common/app_toast.dart';

class RedPacketWithdrawRecordPage extends StatefulWidget {
  const RedPacketWithdrawRecordPage({super.key});

  @override
  State<RedPacketWithdrawRecordPage> createState() =>
      _RedPacketWithdrawRecordPageState();
}

class _RedPacketWithdrawRecordPageState
    extends State<RedPacketWithdrawRecordPage> {
  bool _loading = true;
  List<RedPacketWithdrawOrder> _orders = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final orders = await RedPacketApi.withdrawQuery(limit: 50);
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (e) {
      debugPrint('load withdraw records failed: $e');
      if (!mounted) return;
      setState(() => _loading = false);
      AppToast.show(
        AppLocalizations.of(context)!.profileRedPacketWithdrawRecordsLoadFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppPage(
      title: l10n.profileRedPacketWithdrawRecords,
      backgroundColor: AppColors.white,
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _orders.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 160),
                  AppEmptyView(
                    text: l10n.profileRedPacketNoWithdrawRecords,
                    bottomOffset: 0,
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: _orders.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _buildOrderItem(_orders[index]),
              ),
      ),
    );
  }

  Widget _buildOrderItem(RedPacketWithdrawOrder order) {
    final l10n = AppLocalizations.of(context)!;
    final symbol = order.symbol ?? _symbolFromAssetId(order.assetId);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${order.display} $symbol',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.grey900,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildStatus(order.status),
            ],
          ),
          const SizedBox(height: 10),
          _infoRow(
            l10n.profileRedPacketWithdrawFee,
            '${_formatFee(order.feeAmount)} USDT',
          ),
          const SizedBox(height: 8),
          _copyRow(l10n.profileRedPacketWithdrawRecordAddress, order.to),
          if ((order.txHash ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            _copyRow('Tx', order.txHash!),
          ],
          const SizedBox(height: 8),
          _infoRow(
            l10n.profileRedPacketWithdrawRecordTime,
            _formatTime(order.createTime),
          ),
        ],
      ),
    );
  }

  Widget _buildStatus(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _statusText(status),
        style: AppTextStyles.caption.copyWith(
          color: AppColors.grey700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 54,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.grey500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption.copyWith(color: AppColors.grey700),
          ),
        ),
      ],
    );
  }

  Widget _copyRow(String label, String value) {
    final copiedText = AppLocalizations.of(context)!.commonCopied;
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: value));
        AppToast.show(copiedText);
      },
      child: _infoRow(label, _shortText(value)),
    );
  }

  String _formatFee(String value) {
    final amount = BigInt.tryParse(value);
    if (amount == null) return value;
    return formatTokenUnits(amount, 18);
  }

  String _symbolFromAssetId(String assetId) {
    final parts = assetId.split('-');
    if (parts.length > 1) return parts.last.toUpperCase();
    return assetId.toUpperCase();
  }

  String _statusText(String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'pending':
        return l10n.profileRedPacketWithdrawStatusPending;
      case 'sent':
        return l10n.profileRedPacketWithdrawStatusSent;
      case 'confirmed':
        return l10n.profileRedPacketWithdrawStatusConfirmed;
      case 'onhold':
        return l10n.profileRedPacketWithdrawStatusOnhold;
      case 'failed':
        return l10n.profileRedPacketWithdrawStatusFailed;
      default:
        return status.isEmpty ? '-' : status;
    }
  }

  String _formatTime(int? seconds) {
    if (seconds == null || seconds <= 0) return '-';
    final time = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}';
  }

  String _shortText(String value) {
    if (value.length <= 18) return value;
    return '${value.substring(0, 10)}...${value.substring(value.length - 6)}';
  }
}
