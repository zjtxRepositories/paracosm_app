import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paracosm/core/network/api/red_packet_api.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';
import 'package:paracosm/widgets/common/app_empty_view.dart';

import '../../core/models/user_display_model.dart';
import '../../modules/im/listener/user_display_state_center.dart';
import '../../theme/app_colors.dart';
import '../../widgets/base/app_localizations.dart';
import '../../widgets/base/app_page.dart';

class RedPacketRecordPage extends StatefulWidget {
  const RedPacketRecordPage({super.key, required this.userId, this.groupId});

  final String userId;
  final String? groupId;

  @override
  State<RedPacketRecordPage> createState() => _RedPacketRecordPageState();
}

class _RedPacketRecordPageState extends State<RedPacketRecordPage> {
  int _selectedIndex = 0;
  List<RedPacketMineItem> _sentRecords = const [];
  List<RedPacketMineItem> _receivedRecords = const [];
  UserDisplayModel? _user;
  bool _loadingRecords = false;

  @override
  void initState() {
    super.initState();
    fetchData();
    _loadRecords();
  }

  Future<void> fetchData() async {
    final user = await UserDisplayStateCenter().getUser(widget.userId);
    if (!mounted) return;
    setState(() {
      _user = user;
    });
  }

  Future<void> _loadRecords() async {
    final groupId = widget.groupId?.trim() ?? '';
    setState(() => _loadingRecords = true);
    try {
      if (groupId.isNotEmpty) {
        await _loadGroupRecords(groupId);
        return;
      }

      final results = await Future.wait([
        RedPacketApi.mine(),
        RedPacketApi.received(),
      ]);
      if (!mounted) return;
      setState(() {
        _sentRecords = results[0];
        _receivedRecords = results[1];
        _loadingRecords = false;
      });
    } catch (e) {
      debugPrint('_loadRecords failed: $e');
      if (!mounted) return;
      setState(() => _loadingRecords = false);
    }
  }

  Future<void> _loadGroupRecords(String groupId) async {
    final records = await RedPacketApi.groupList(groupId: groupId);
    if (!mounted) return;
    setState(() {
      _sentRecords = records.sent;
      _receivedRecords = records.received;
      _loadingRecords = false;
    });
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/chat');
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      showNav: false,
      isAddBottomMargin: false,
      backgroundColor: AppColors.white,
      child: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  InkWell(
                    onTap: _handleBack,
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Image.asset(
                        'assets/images/common/back-icon.png',
                        width: 32,
                        height: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Center(child: _buildTopTab())),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildHeader(),
            const SizedBox(height: 14),
            Container(height: 10, color: AppColors.grey100),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _selectedIndex == 0 ? _buildReceived() : _buildSent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTab() {
    final l10n = AppLocalizations.of(context)!;
    final tabs = [l10n.chatRedPacketReceivedTab, l10n.chatRedPacketSentTab];

    return SizedBox(
      width: 180,
      height: 42,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.32)),
        ),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final selected = _selectedIndex == index;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (_selectedIndex == index) return;
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      color: selected ? AppColors.error : AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isReceived = _selectedIndex == 0;
    final records = isReceived ? _receivedRecords : _sentRecords;
    final l10n = AppLocalizations.of(context)!;
    final summaryText = isReceived
        ? l10n.chatRedPacketReceivedSummary(records.length)
        : l10n.chatRedPacketSentSummary(records.length);
    final total = records.length.toString();

    return Column(
      children: [
        UserAvatarWidget(
          userId: _user?.userId ?? widget.userId,
          avatarUrl: _user?.avatar,
          size: 80,
        ),
        const SizedBox(height: 10),
        Text(
          _user?.name ?? _shortAddress(widget.userId),
          style: const TextStyle(color: AppColors.black, fontSize: 16),
        ),
        const SizedBox(height: 6),
        Text(
          summaryText,
          style: const TextStyle(color: AppColors.black, fontSize: 16),
        ),
        const SizedBox(height: 14),
        Text(
          total,
          style: const TextStyle(
            color: Color(0xFFFFD54F),
            fontSize: 44,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildReceived() {
    if (_loadingRecords) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_receivedRecords.isEmpty) {
      return _buildEmpty();
    }
    return _buildRecordList(_receivedRecords, received: true);
  }

  Widget _buildSent() {
    if (_loadingRecords) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_sentRecords.isEmpty) {
      return _buildEmpty();
    }
    return _buildRecordList(_sentRecords, received: false);
  }

  Widget _buildEmpty() {
    return AppEmptyView(
      text: AppLocalizations.of(context)!.chatSearchNoData,
      bottomOffset: 0,
    );
  }

  Widget _buildRecordList(
    List<RedPacketMineItem> records, {
    required bool received,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: records.length,
      itemBuilder: (_, i) {
        final item = records[i];
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.grey100)),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFF1473E),
                child: Icon(
                  Icons.wallet_giftcard,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_modeText(item.mode)),
                    const SizedBox(height: 4),
                    Text(
                      received
                          ? '${_formatTime(item.receiveTime ?? item.createTime)}  ${_statusText(item.status)}'
                          : '${_formatTime(item.createTime)}  ${item.receivedCount}/${item.count}  ${_statusText(item.status)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                '${received ? item.receiveDisplay ?? item.receiveAmount ?? '0' : item.totalDisplay ?? item.totalAmount} ${item.symbol ?? item.assetId}',
                style: const TextStyle(
                  color: Color(0xFFFF3B30),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _modeText(String mode) {
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case 'lucky':
        return l10n.chatRedPacketLucky;
      case 'even':
      case 'normal':
        return l10n.chatRedPacketNormal;
      case 'p2p':
      case 'exclusive':
        return l10n.chatRedPacketExclusive;
      default:
        return l10n.chatDetailRedPacket;
    }
  }

  String _statusText(String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'active':
        return l10n.chatRedPacketStatusActive;
      case 'finished':
        return l10n.chatRedPacketStatusFinished;
      case 'expired':
        return l10n.chatRedPacketStatusExpired;
      case 'pending':
        return l10n.chatRedPacketStatusPending;
      case 'void':
        return l10n.chatRedPacketStatusVoid;
      default:
        return status;
    }
  }

  String _formatTime(int? seconds) {
    if (seconds == null || seconds <= 0) return '';
    return DateFormat(
      'MM-dd HH:mm',
    ).format(DateTime.fromMillisecondsSinceEpoch(seconds * 1000));
  }

  String _shortAddress(String value) {
    final text = value.trim();
    if (text.length <= 10) return text;
    return '${text.substring(0, 6)}...${text.substring(text.length - 4)}';
  }
}
