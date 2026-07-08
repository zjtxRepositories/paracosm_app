import 'dart:async';

import 'package:flutter/material.dart';
import 'package:paracosm/core/network/api/red_packet_api.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/util/string_util.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_empty_view.dart';
import 'package:paracosm/widgets/common/app_toast.dart';

class RedPacketBalanceDetailPage extends StatefulWidget {
  const RedPacketBalanceDetailPage({super.key});

  @override
  State<RedPacketBalanceDetailPage> createState() =>
      _RedPacketBalanceDetailPageState();
}

class _RedPacketBalanceDetailPageState
    extends State<RedPacketBalanceDetailPage> {
  static const int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();
  final List<RedPacketLedgerEntry> _entries = [];

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_loadInitial());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loading || _loadingMore) return;
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 160) {
      unawaited(_loadMore());
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _hasMore = true;
    });

    try {
      final result = await RedPacketApi.ledgerList(limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _entries
          ..clear()
          ..addAll(result.entries);
        _hasMore = _canLoadMore(result.entries);
        _loading = false;
      });
    } catch (e) {
      debugPrint('load red packet ledger failed: $e');
      if (!mounted) return;
      setState(() => _loading = false);
      AppToast.show(
        AppLocalizations.of(context)!.profileRedPacketBalanceDetailsLoadFailed,
      );
    }
  }

  Future<void> _loadMore() async {
    final before = _entries.isEmpty ? null : _entries.last.createTime;
    if (before == null || before <= 0) {
      setState(() => _hasMore = false);
      return;
    }

    setState(() => _loadingMore = true);
    try {
      final result = await RedPacketApi.ledgerList(
        limit: _pageSize,
        before: before,
      );
      if (!mounted) return;
      setState(() {
        _entries.addAll(result.entries);
        _hasMore = _canLoadMore(result.entries);
        _loadingMore = false;
      });
    } catch (e) {
      debugPrint('load more red packet ledger failed: $e');
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  bool _canLoadMore(List<RedPacketLedgerEntry> page) {
    return page.length >= _pageSize && (page.last.createTime ?? 0) > 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppPage(
      title: l10n.profileRedPacketBalanceDetails,
      backgroundColor: AppColors.white,
      child: RefreshIndicator(
        onRefresh: _loadInitial,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _entries.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 160),
                  AppEmptyView(
                    text: l10n.profileRedPacketNoBalanceDetails,
                    bottomOffset: 0,
                  ),
                ],
              )
            : ListView.separated(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: _entries.length + (_loadingMore ? 1 : 0),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == _entries.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return _buildEntryItem(_entries[index]);
                },
              ),
      ),
    );
  }

  Widget _buildEntryItem(RedPacketLedgerEntry entry) {
    final l10n = AppLocalizations.of(context)!;
    final amountColor = entry.isExpense
        ? AppColors.error
        : entry.isIncome
        ? AppColors.primaryDark
        : AppColors.grey900;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: amountColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  entry.isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                  color: amountColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _entryTypeText(entry.type),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.grey900,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(entry.createTime),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grey500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _amountText(entry),
                textAlign: TextAlign.right,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: amountColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (entry.memo.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _infoRow(l10n.profileRedPacketLedgerMemo, entry.memo.trim()),
          ],
          if (entry.ref.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _infoRow(
              l10n.profileRedPacketLedgerRef,
              ellipsisMiddle(entry.ref.trim(), head: 10, tail: 8),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 42,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.grey500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.grey700,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  String _entryTypeText(String type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case 'deposit':
        return l10n.profileRedPacketLedgerTypeDeposit;
      case 'withdraw':
        return l10n.profileRedPacketLedgerTypeWithdraw;
      case 'withdraw_fee':
        return l10n.profileRedPacketLedgerTypeWithdrawFee;
      case 'red_send':
        return l10n.profileRedPacketLedgerTypeRedSend;
      case 'red_grab':
        return l10n.profileRedPacketLedgerTypeRedGrab;
      case 'red_refund':
        return l10n.profileRedPacketLedgerTypeRedRefund;
      default:
        return type.trim().isEmpty
            ? l10n.profileRedPacketLedgerTypeUnknown
            : type;
    }
  }

  String _amountText(RedPacketLedgerEntry entry) {
    final display = entry.display.trim();
    final symbol = entry.symbol.trim().isNotEmpty
        ? entry.symbol.trim()
        : _symbolFromAssetId(entry.assetId);
    if (display.isEmpty) return symbol.isEmpty ? '-' : '- $symbol';
    final signed = display.startsWith('-') || display.startsWith('+')
        ? display
        : entry.isIncome
        ? '+$display'
        : display;
    return symbol.isEmpty ? signed : '$signed $symbol';
  }

  String _formatTime(int? seconds) {
    if (seconds == null || seconds <= 0) return '-';
    return formatTransactionTime(seconds);
  }

  String _symbolFromAssetId(String assetId) {
    final parts = assetId.split('-');
    if (parts.length > 1) return parts.last.toUpperCase();
    return assetId.toUpperCase();
  }
}
