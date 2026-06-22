import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/core/models/social_circle_relation_model.dart';
import 'package:paracosm/core/network/api/social_circle_user_api.dart';
import 'package:paracosm/modules/im/listener/user_display_state_center.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/util/string_util.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';
import 'package:paracosm/widgets/common/app_empty_view.dart';
import 'package:paracosm/widgets/common/app_loading.dart';
import 'package:paracosm/widgets/common/app_toast.dart';

enum MomentRelationListType { following, fans }

class MomentRelationListPage extends StatefulWidget {
  final MomentRelationListType type;
  final String userId;

  const MomentRelationListPage({
    super.key,
    required this.type,
    required this.userId,
  });

  @override
  State<MomentRelationListPage> createState() => _MomentRelationListPageState();
}

class _MomentRelationListPageState extends State<MomentRelationListPage> {
  static const int _pageSize = 20;

  final List<SocialCircleRelationModel> _items = [];
  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _refreshing = false;
  bool _hasMore = true;
  int _page = 0;
  final Set<String> _followedUserIds = {};
  final Set<String> _togglingFollowIds = {};

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _initialLoading = true;
      _page = 0;
      _hasMore = true;
      _items.clear();
    });

    try {
      final list = await _fetchPage(0);
      if (!mounted) return;
      setState(() {
        _items.addAll(list);
        _syncFollowedIds(list);
        _hasMore = list.length >= _pageSize;
        _page = 1;
        _initialLoading = false;
      });
    } catch (e) {
      debugPrint('load moment relation list failed: $e');
      if (!mounted) return;
      setState(() {
        _initialLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
    });

    try {
      final list = await _fetchPage(0);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(list);
        _followedUserIds.clear();
        _syncFollowedIds(list);
        _hasMore = list.length >= _pageSize;
        _page = 1;
      });
    } catch (e) {
      debugPrint('refresh moment relation list failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _refreshing = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;

    setState(() {
      _loadingMore = true;
    });

    try {
      final list = await _fetchPage(_page);
      if (!mounted) return;
      setState(() {
        _items.addAll(list);
        _syncFollowedIds(list);
        _hasMore = list.length >= _pageSize;
        _page += 1;
      });
    } catch (e) {
      debugPrint('load more moment relation list failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingMore = false;
        });
      }
    }
  }

  Future<List<SocialCircleRelationModel>> _fetchPage(int page) {
    switch (widget.type) {
      case MomentRelationListType.following:
        return SocialCircleUserApi.getSocialCircleUserFollowRecords(
          userId: widget.userId,
          page: page,
          size: _pageSize,
        );
      case MomentRelationListType.fans:
        return SocialCircleUserApi.getSocialCircleUserFansRecords(
          userId: widget.userId,
          page: page,
          size: _pageSize,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppPage(
      title: _title(l10n),
      backgroundColor: AppColors.white,
      navBackgroundColor: AppColors.white,
      showNavBorder: true,
      child: _buildBody(l10n),
    );
  }

  String _title(AppLocalizations l10n) {
    switch (widget.type) {
      case MomentRelationListType.following:
        return l10n.translate('moments_following');
      case MomentRelationListType.fans:
        return l10n.translate('moments_followers');
    }
  }

  String _emptyText(AppLocalizations l10n) {
    switch (widget.type) {
      case MomentRelationListType.following:
        return l10n.translate('moments_no_following');
      case MomentRelationListType.fans:
        return l10n.translate('moments_no_followers');
    }
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: _items.isEmpty
          ? _buildEmptyBody(l10n)
          : NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (scrollInfo.metrics.pixels >=
                        scrollInfo.metrics.maxScrollExtent - 100 &&
                    !_loadingMore &&
                    !_refreshing) {
                  _loadMore();
                }
                return false;
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                itemCount: _items.length + (_loadingMore ? 1 : 0),
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: AppColors.grey200),
                itemBuilder: (context, index) {
                  if (index == _items.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return _RelationListItem(
                    item: _items[index],
                    type: widget.type,
                    isFollowed: _followedUserIds.contains(
                      _displayUserIdFor(_items[index]),
                    ),
                    isTogglingFollow: _togglingFollowIds.contains(
                      _displayUserIdFor(_items[index]),
                    ),
                    onOpenProfile: () => _openUserProfile(_items[index]),
                    onUnfollow: widget.type == MomentRelationListType.following
                        ? () => _toggleFollow(_items[index])
                        : null,
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyBody(AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [
            SizedBox(
              height: constraints.maxHeight,
              child: AppEmptyView(text: _emptyText(l10n), bottomOffset: 80),
            ),
          ],
        );
      },
    );
  }

  void _syncFollowedIds(List<SocialCircleRelationModel> list) {
    if (widget.type != MomentRelationListType.following) return;
    _followedUserIds.addAll(
      list
          .map((item) => item.getFollowingUserId())
          .where((userId) => userId.isNotEmpty),
    );
  }

  String _displayUserIdFor(SocialCircleRelationModel item) {
    switch (widget.type) {
      case MomentRelationListType.following:
        return item.getFollowingUserId();
      case MomentRelationListType.fans:
        return item.getFanUserId();
    }
  }

  void _openUserProfile(SocialCircleRelationModel item) {
    final userId = _displayUserIdFor(item);
    if (userId.isEmpty) return;
    context.push(
      '/moment-user-profile',
      extra: {'userId': userId},
    );
  }

  Future<void> _toggleFollow(SocialCircleRelationModel item) async {
    final userId = item.getFollowingUserId();
    if (userId.isEmpty || _togglingFollowIds.contains(userId)) return;

    final nextIsFollowing = !_followedUserIds.contains(userId);
    final l10n = AppLocalizations.of(context)!;
    final failureText = nextIsFollowing
        ? l10n.momentsFollowFailed
        : l10n.momentsUnfollowFailed;
    setState(() {
      _togglingFollowIds.add(userId);
    });

    var success = false;
    try {
      AppLoading.show();
      success = await SocialCircleUserApi.socialCircleUserFollowToggle(
        userId,
        nextIsFollowing,
      );
    } catch (e) {
      debugPrint('toggle relation follow failed: $e');
    } finally {
      AppLoading.dismiss();
    }

    if (!mounted) return;

    setState(() {
      _togglingFollowIds.remove(userId);
      if (success) {
        if (nextIsFollowing) {
          _followedUserIds.add(userId);
        } else {
          _followedUserIds.remove(userId);
        }
      }
    });

    if (!success) {
      AppToast.show(failureText);
    }
  }
}

class _RelationListItem extends StatelessWidget {
  final SocialCircleRelationModel item;
  final MomentRelationListType type;
  final bool isFollowed;
  final bool isTogglingFollow;
  final VoidCallback onOpenProfile;
  final VoidCallback? onUnfollow;

  const _RelationListItem({
    required this.item,
    required this.type,
    required this.isFollowed,
    required this.isTogglingFollow,
    required this.onOpenProfile,
    this.onUnfollow,
  });

  @override
  Widget build(BuildContext context) {
    final userId = _displayUserId;
    final cachedUser = UserDisplayStateCenter().getDisplayModel(userId);

    return FutureBuilder(
      future: UserDisplayStateCenter().getUser(userId),
      builder: (context, snapshot) {
        final user = snapshot.data ?? cachedUser;
        final name = user.name.isNotEmpty ? user.name : _shortAddress(userId);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onOpenProfile,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                UserAvatarWidget(
                  userId: userId,
                  avatarUrl: user.avatar,
                  size: 44,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.grey900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatIMTime(item.timestamp),
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          color: AppColors.grey400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onUnfollow != null) ...[
                  const SizedBox(width: 12),
                  _UnfollowButton(
                    isFollowed: isFollowed,
                    isLoading: isTogglingFollow,
                    onTap: onUnfollow!,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String get _displayUserId {
    switch (type) {
      case MomentRelationListType.following:
        return item.getFollowingUserId();
      case MomentRelationListType.fans:
        return item.getFanUserId();
    }
  }

  String _shortAddress(String value) {
    if (value.length <= 12) return value;
    return '${value.substring(0, 6)}...${value.substring(value.length - 4)}';
  }
}

class _UnfollowButton extends StatelessWidget {
  final bool isFollowed;
  final bool isLoading;
  final VoidCallback onTap;

  const _UnfollowButton({
    required this.isFollowed,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isLoading ? null : onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 76),
        child: Container(
          height: 32,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isFollowed ? AppColors.white : AppColors.grey900,
            borderRadius: BorderRadius.circular(16),
            border: isFollowed ? Border.all(color: AppColors.grey200) : null,
          ),
          child: isLoading
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isFollowed ? AppColors.grey900 : AppColors.white,
                  ),
                )
              : Text(
                  isFollowed
                      ? l10n.translate('moments_unfollow')
                      : l10n.translate('moments_follow'),
                  style: AppTextStyles.caption.copyWith(
                    color: isFollowed ? AppColors.grey900 : AppColors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }
}
