import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paracosm/core/models/moment_message_model.dart';
import 'package:paracosm/core/models/user_display_model.dart';
import 'package:paracosm/core/network/api/get_moment_messages_api.dart';
import 'package:paracosm/modules/im/listener/user_display_state_center.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';
import 'package:paracosm/widgets/common/app_empty_view.dart';

class MessageCenterPage extends StatefulWidget {
  const MessageCenterPage({super.key});

  @override
  State<MessageCenterPage> createState() => _MessageCenterPageState();
}

class _MessageCenterPageState extends State<MessageCenterPage> {
  final Map<String, UserDisplayModel> _users = {};
  List<MomentMessageModel> _items = const [];
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    if (!_loading && mounted) {
      setState(() => _loadFailed = false);
    }

    try {
      final items = await GetMomentMessagesApi.get();
      final userIds = items
          .map((item) => item.fromUserId)
          .where((id) => id.isNotEmpty)
          .toSet();
      final resolvedUsers = await Future.wait(
        userIds.map((id) async {
          try {
            final user = await UserDisplayStateCenter().getUser(id);
            return MapEntry(id, user);
          } catch (_) {
            return MapEntry<String, UserDisplayModel?>(id, null);
          }
        }),
      );
      if (!mounted) return;
      setState(() {
        _items = items;
        for (final entry in resolvedUsers) {
          final user = entry.value;
          if (user != null) _users[entry.key] = user;
        }
        _loading = false;
        _loadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppPage(
      title: l10n.translate('moments_message_center_title'),
      showNavBorder: false,
      child: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadFailed && _items.isEmpty) {
      return Center(
        child: TextButton(
          onPressed: () {
            setState(() => _loading = true);
            _loadMessages();
          },
          child: Text(l10n.translate('common_request_failed')),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMessages,
      child: _items.isEmpty ? _buildEmpty(l10n) : _buildList(l10n),
    );
  }

  Widget _buildEmpty(AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          SizedBox(
            height: constraints.maxHeight,
            child: AppEmptyView(
              text: l10n.translate('chat_search_no_data'),
              bottomOffset: 50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(AppLocalizations l10n) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return _MessageCenterListItem(
          item: item,
          user: _users[item.fromUserId],
          l10n: l10n,
          onTap: item.noteId.isEmpty
              ? null
              : () => context.push(
                  '/moment-post-detail',
                  extra: {'noteId': item.noteId},
                ),
        );
      },
    );
  }
}

class _MessageCenterListItem extends StatelessWidget {
  const _MessageCenterListItem({
    required this.item,
    required this.user,
    required this.l10n,
    this.onTap,
  });

  final MomentMessageModel item;
  final UserDisplayModel? user;
  final AppLocalizations l10n;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: item.isRead ? Colors.transparent : Colors.white,
        padding: const EdgeInsets.fromLTRB(6, 16, 20, 0),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  _buildUnreadDot(),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      UserAvatarWidget(
                        userId: item.fromUserId,
                        avatarUrl: user?.avatar,
                        width: 44,
                        height: 44,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      Positioned(
                        right: -3,
                        bottom: -3,
                        child: Image.asset(_badgeIcon, width: 16, height: 16),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.grey900,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: _messageText),
                              if (_dateText.isNotEmpty)
                                TextSpan(
                                  text: '  $_dateText',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.grey400,
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.grey700,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppColors.grey400,
                    ),
                ],
              ),
            ),
            Positioned(
              left: 68,
              right: 0,
              bottom: 0,
              child: Container(height: 1, color: AppColors.grey200),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnreadDot() {
    if (item.isRead) return const SizedBox(width: 14);
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(right: 6),
      decoration: const BoxDecoration(
        color: AppColors.error,
        shape: BoxShape.circle,
      ),
    );
  }

  String get _displayName {
    final name = user?.name.trim() ?? '';
    if (name.isNotEmpty) return name;
    final id = item.fromUserId;
    if (id.length <= 12) return id;
    return '${id.substring(0, 6)}...${id.substring(id.length - 4)}';
  }

  String get _messageText {
    switch (item.action) {
      case MomentMessageAction.like:
        return l10n.translate('moments_liked_you');
      case MomentMessageAction.collect:
        return l10n.translate('moments_collected_you');
      case MomentMessageAction.review:
        return item.content.isEmpty
            ? l10n.translate('moments_reviewed_you')
            : l10n.translate('moments_reviewed_you_with_content', {
                'content': item.content,
              });
      case MomentMessageAction.follow:
        return l10n.translate('moments_followed_you');
      case MomentMessageAction.unknown:
        return l10n.translate('moments_interacted_with_you');
    }
  }

  String get _badgeIcon {
    switch (item.action) {
      case MomentMessageAction.like:
        return 'assets/images/moments/center-like.png';
      case MomentMessageAction.collect:
        return 'assets/images/moments/center-collect.png';
      case MomentMessageAction.follow:
        return 'assets/images/moments/center-user.png';
      case MomentMessageAction.review:
      case MomentMessageAction.unknown:
        return 'assets/images/moments/center-msg.png';
    }
  }

  String get _dateText {
    if (item.createTimestamp <= 0) return '';
    final milliseconds = item.createTimestamp > 1000000000000
        ? item.createTimestamp
        : item.createTimestamp * 1000;
    return DateFormat(
      'yyyy/MM/dd',
    ).format(DateTime.fromMillisecondsSinceEpoch(milliseconds));
  }
}
