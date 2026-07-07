import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paracosm/core/network/api/red_packet_api.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';
import 'package:paracosm/widgets/common/app_empty_view.dart';

import '../../core/models/user_display_model.dart';
import '../../modules/im/listener/user_display_state_center.dart';
import '../../modules/im/message/base/im_message.dart';
import '../../widgets/base/app_localizations.dart';

class RedPacketDetailPage extends StatefulWidget {
  const RedPacketDetailPage({
    super.key,
    required this.userId,
    required this.data,
  });

  final String userId;
  final RedPacketData data;

  @override
  State<RedPacketDetailPage> createState() => _RedPacketDetailPageState();
}

class _RedPacketDetailPageState extends State<RedPacketDetailPage> {
  static const double _headerHeight = 220;
  static const double _contentTop = 188;
  static const double _avatarSize = 72;
  UserDisplayModel? _sender;
  RedPacketInfo? _info;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final info = await RedPacketApi.info(widget.data.redPacketId);
      final senderId = info.sender.isNotEmpty ? info.sender : widget.userId;
      final sender = await UserDisplayStateCenter().getUser(senderId);
      if (!mounted) return;
      setState(() {
        _info = info;
        _sender = sender;
        _loading = false;
      });
    } catch (e) {
      final sender = await UserDisplayStateCenter().getUser(widget.userId);
      if (!mounted) return;
      setState(() {
        _sender = sender;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final info = _info;
    final greeting =
        (info?.greeting.trim().isNotEmpty == true
                ? info!.greeting
                : widget.data.greeting)
            .trim();

    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          Positioned(
            top: _contentTop,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.only(top: _avatarSize),
              color: Colors.white,
              child: Column(
                children: [
                  Text(
                    _sender?.name ??
                        _shortAddress(info?.sender ?? widget.userId),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    greeting.isEmpty
                        ? l10n.chatRedPacketDefaultBlessing
                        : greeting,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    _statusText(info),
                    style: const TextStyle(
                      color: Color(0xFFFFB300),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(height: 10, color: AppColors.grey100),
                  const SizedBox(height: 20),
                  _buildTitle(info),
                  const SizedBox(height: 20),
                  Container(height: 1, color: AppColors.grey100),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildList(info?.receives ?? const []),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: _headerHeight,
            width: double.infinity,
            child: Image.asset(
              'assets/images/chat/red_packet/top_icon.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(child: _buildTopBar()),
          Positioned(
            top: _contentTop - 15,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: _avatarSize + 8,
                height: _avatarSize + 8,
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: UserAvatarWidget(
                  userId: _sender?.userId ?? info?.sender ?? widget.userId,
                  avatarUrl: _sender?.avatar,
                  size: _avatarSize,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              if (context.canPop()) {
                context.pop();
                return;
              }
              context.go('/chat');
            },
            child: Image.asset(
              'assets/images/common/back-icon.png',
              width: 30,
              height: 30,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              context.push(
                '/red-packet_record',
                extra: {'userId': widget.userId, 'groupId': _info?.groupId},
              );
            },
            icon: const Icon(
              Icons.history_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(RedPacketInfo? info) {
    final symbol =
        info?.symbol ?? widget.data.tokenSymbol ?? info?.assetId ?? '';
    final total = info?.totalDisplay ?? widget.data.amount ?? '0';
    final received = info?.receivedCount ?? 0;
    final count = info?.count ?? widget.data.count ?? 0;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          l10n.chatRedPacketClaimedSummary(
            received: received,
            count: count,
            total: total,
            symbol: symbol,
          ),
          style: const TextStyle(color: Colors.black54),
        ),
      ),
    );
  }

  Widget _buildList(List<RedPacketReceive> records) {
    if (records.isEmpty) {
      return AppEmptyView(
        text: AppLocalizations.of(context)!.chatSearchNoData,
        bottomOffset: 0,
      );
    }

    final symbol = _info?.symbol ?? widget.data.tokenSymbol ?? '';
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
              UserAvatarWidget(userId: item.receiver, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: FutureBuilder<UserDisplayModel?>(
                  future: UserDisplayStateCenter().getUser(item.receiver),
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? _shortAddress(item.receiver)),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(item.createTime),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Text(
                '${item.display} $symbol',
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

  String _statusText(RedPacketInfo? info) {
    if (info == null) return '';
    final l10n = AppLocalizations.of(context)!;
    if (info.isFinished) return l10n.chatRedPacketFinished;
    if (info.isExpired) return l10n.chatRedPacketExpired;
    return l10n.chatRedPacketRemainingCount(info.remainingCount);
  }

  String _formatTime(int? seconds) {
    if (seconds == null || seconds <= 0) return '';
    return DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(DateTime.fromMillisecondsSinceEpoch(seconds * 1000));
  }

  String _shortAddress(String value) {
    final text = value.trim();
    if (text.length <= 10) return text;
    return '${text.substring(0, 6)}...${text.substring(text.length - 4)}';
  }
}
