import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paracosm/core/models/moment_message_model.dart';
import 'package:paracosm/core/models/user_display_model.dart';
import 'package:paracosm/core/network/api/social_circle_user_api.dart';
import 'package:paracosm/core/network/friend_circle/moment_message_cache.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/im/listener/user_display_state_center.dart';
import 'package:paracosm/pages/chat/chat_session_args.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';
import 'package:paracosm/widgets/common/app_empty_view.dart';
import 'package:paracosm/widgets/common/app_toast.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

class MessageCenterPage extends StatefulWidget {
  const MessageCenterPage({super.key});

  @override
  State<MessageCenterPage> createState() => _MessageCenterPageState();
}

class _MessageCenterPageState extends State<MessageCenterPage> {
  final Map<String, UserDisplayModel> _users = {};
  final Set<String> _followingUserIds = {};
  final Set<String> _followLoadingUserIds = {};
  final Set<String> _unreadMessageKeys = {};
  final MomentMessageCache _messageCache = MomentMessageCache();
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
      final accountId =
          AccountManager().currentAccount?.accountId.toLowerCase() ?? '';
      final results = await Future.wait<dynamic>([
        SocialCircleUserApi.getMomentMessages(),
        SocialCircleUserApi.getSocialCircleUserFollow().catchError(
          (_) => <String>[],
        ),
        _messageCache.read(accountId),
      ]);
      final items = results[0] as List<MomentMessageModel>;
      final followingUserIds = results[1] as List<String>;
      final seenMessageKeys = results[2] as Set<String>;
      final unreadMessageKeys = items
          .where(
            (item) => !item.isRead && !seenMessageKeys.contains(item.cacheKey),
          )
          .map((item) => item.cacheKey)
          .toSet();
      await _messageCache.save(accountId, items);
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
        _unreadMessageKeys
          ..clear()
          ..addAll(unreadMessageKeys);
        _followingUserIds
          ..clear()
          ..addAll(followingUserIds.map(_normalizeUserId));
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
          isFollowing: _followingUserIds.contains(
            _normalizeUserId(item.fromUserId),
          ),
          isFollowLoading: _followLoadingUserIds.contains(
            _normalizeUserId(item.fromUserId),
          ),
          isUnread: _unreadMessageKeys.contains(item.cacheKey),
          onFollow: item.action == MomentMessageAction.follow
              ? () => _followUser(item.fromUserId)
              : null,
          onMessage: item.action == MomentMessageAction.follow
              ? () => _openChat(item)
              : null,
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

  Future<void> _followUser(String userId) async {
    final normalizedUserId = _normalizeUserId(userId);
    if (normalizedUserId.isEmpty ||
        _followingUserIds.contains(normalizedUserId) ||
        _followLoadingUserIds.contains(normalizedUserId)) {
      return;
    }

    setState(() => _followLoadingUserIds.add(normalizedUserId));
    var success = false;
    try {
      success = await SocialCircleUserApi.socialCircleUserFollowToggle(
        userId,
        true,
      );
    } catch (_) {
      success = false;
    }
    if (!mounted) return;

    setState(() {
      _followLoadingUserIds.remove(normalizedUserId);
      if (success) _followingUserIds.add(normalizedUserId);
    });
    if (!success) {
      AppToast.show(
        AppLocalizations.of(context)!.translate('moments_follow_failed'),
      );
    }
  }

  void _openChat(MomentMessageModel item) {
    final targetId = item.fromUserId.trim();
    if (targetId.isEmpty) return;
    final user = _users[targetId];
    final name = user?.name.trim().isNotEmpty == true
        ? user!.name.trim()
        : targetId;
    context.push(
      '/chat-detail/${Uri.encodeComponent(name)}',
      extra: ChatSessionArgs(
        targetId: targetId,
        conversationType: RCIMIWConversationType.private,
        isGroup: false,
        name: name,
        avatar: user?.avatar,
      ),
    );
  }

  String _normalizeUserId(String userId) => userId.trim().toLowerCase();
}

class _MessageCenterListItem extends StatelessWidget {
  const _MessageCenterListItem({
    required this.item,
    required this.user,
    required this.l10n,
    required this.isFollowing,
    required this.isFollowLoading,
    required this.isUnread,
    this.onFollow,
    this.onMessage,
    this.onTap,
  });

  final MomentMessageModel item;
  final UserDisplayModel? user;
  final AppLocalizations l10n;
  final bool isFollowing;
  final bool isFollowLoading;
  final bool isUnread;
  final VoidCallback? onFollow;
  final VoidCallback? onMessage;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread ? Colors.white : Colors.transparent,
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
                  if (item.action == MomentMessageAction.follow) ...[
                    const SizedBox(width: 12),
                    _MessageCenterActionButton(
                      text: l10n.translate(
                        isFollowing ? 'moments_message' : 'moments_follow',
                      ),
                      isFilled: !isFollowing,
                      isLoading: isFollowLoading,
                      onTap: isFollowing ? onMessage : onFollow,
                    ),
                  ] else if (onTap != null)
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
    if (!isUnread) return const SizedBox(width: 14);
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
      'HH:mm yyyy/MM/dd',
    ).format(DateTime.fromMillisecondsSinceEpoch(milliseconds));
  }
}

class _MessageCenterActionButton extends StatelessWidget {
  const _MessageCenterActionButton({
    required this.text,
    required this.isFilled,
    required this.isLoading,
    required this.onTap,
  });

  final String text;
  final bool isFilled;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 86,
        height: 30,
        decoration: BoxDecoration(
          color: isFilled ? AppColors.grey900 : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: isFilled
              ? null
              : Border.all(color: AppColors.grey200, width: 1.5),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isFilled ? Colors.white : AppColors.grey900,
                ),
              )
            : Text(
                text,
                style: AppTextStyles.caption.copyWith(
                  color: isFilled ? Colors.white : AppColors.grey900,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
      ),
    );
  }
}
