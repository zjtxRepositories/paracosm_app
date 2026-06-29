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
  const RedPacketRecordPage({super.key, required this.userId});

  final String userId;

  @override
  State<RedPacketRecordPage> createState() => _RedPacketRecordPageState();
}

class _RedPacketRecordPageState extends State<RedPacketRecordPage> {
  int _selectedIndex = 0;
  List<RedPacketMineItem> _sentRecords = const [];
  UserDisplayModel? _user;
  bool _loadingSent = false;

  @override
  void initState() {
    super.initState();
    fetchData();
    _loadSentRecords();
  }

  Future<void> fetchData() async {
    final user = await UserDisplayStateCenter().getUser(widget.userId);
    if (!mounted) return;
    setState(() {
      _user = user;
    });
  }

  Future<void> _loadSentRecords() async {
    setState(() => _loadingSent = true);
    try {
      final records = await RedPacketApi.mine();
      if (!mounted) return;
      setState(() {
        _sentRecords = records;
        _loadingSent = false;
      });
    } catch (e) {
      print('_loadSentRecords-----$e');
      if (!mounted) return;
      setState(() => _loadingSent = false);
    }
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
    const tabs = ['收到', '发出'];

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
    final summaryText = isReceived ? '共收到 0 个' : '共发出 ${_sentRecords.length} 个';
    final total = isReceived ? '0' : _sentRecords.length.toString();

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
    return _buildEmpty();
  }

  Widget _buildSent() {
    if (_loadingSent) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_sentRecords.isEmpty) {
      return _buildEmpty();
    }
    return _buildSentList(_sentRecords);
  }

  Widget _buildEmpty() {
    return AppEmptyView(
      text: AppLocalizations.of(context)!.chatSearchNoData,
      bottomOffset: 0,
    );
  }

  Widget _buildSentList(List<RedPacketMineItem> records) {
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
                      '${_formatTime(item.createTime)}  ${item.receivedCount}/${item.count}  ${_statusText(item.status)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                '${item.totalDisplay ?? item.totalAmount} ${item.symbol ?? item.assetId}',
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
    switch (mode) {
      case 'lucky':
        return '拼手气红包';
      case 'even':
      case 'normal':
        return '普通红包';
      case 'p2p':
      case 'exclusive':
        return '专属红包';
      default:
        return '红包';
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'active':
        return '进行中';
      case 'finished':
        return '已领完';
      case 'expired':
        return '已过期';
      case 'pending':
        return '待生效';
      case 'void':
        return '已失效';
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
