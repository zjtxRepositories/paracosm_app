import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/core/models/moment_post_model.dart';
import 'package:paracosm/core/models/social_Invitation_model.dart';
import 'package:paracosm/core/models/social_wallet_address.dart';
import 'package:paracosm/core/network/api/get_uer_info_api.dart';
import 'package:paracosm/core/network/api/social_circle_note_api.dart';
import 'package:paracosm/core/network/api/social_circle_user_api.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/im/listener/im_data_center.dart';
import 'package:paracosm/modules/im/listener/user_display_state_center.dart';
import 'package:paracosm/modules/im/message/moment_post_share_message.dart';
import 'package:paracosm/modules/im/message/send/im_sender.dart';
import 'package:paracosm/modules/moments/moment_profile_identity.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/util/string_util.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/chat/chat_forward_target_modal.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';
import 'package:paracosm/widgets/common/app_action_pop_menu.dart';
import 'package:paracosm/widgets/common/app_action_sheet.dart';
import 'package:paracosm/widgets/common/app_loading.dart';
import 'package:paracosm/widgets/common/app_toast.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../core/models/user_display_model.dart';
import 'moment_post_card.dart';

/// 个人主页详情页
/// 保留社区详情页的主体结构，只显示看板下面的内容列表，移除 TabController 和其他 Tab 区域。
class MomentUserProfilePage extends StatefulWidget {
  final String userId;
  final String mode;

  const MomentUserProfilePage({
    super.key,
    required this.userId,
    this.mode = 'friend',
  });

  @override
  State<MomentUserProfilePage> createState() => _MomentUserProfilePageState();
}

class _MomentUserProfilePageState extends State<MomentUserProfilePage> {
  static const double _sendMomentSize = 80;
  static const double _coverHeight = 140;
  static const double _navBackgroundThreshold = 48;
  final List<MomentPostModel> _posts = [];
  final ScrollController _scrollController = ScrollController();
  Offset? _sendMomentOffset;
  bool _sendMomentInitialized = false;
  bool _showNavBackground = false;
  bool _isLoading = true;
  bool _isFollowLoading = false;
  bool _isFollowingUser = false;
  int _followingCount = 0;
  int _followersCount = 0;
  _MomentProfileHeaderData? _profileHeader;

  bool get _isSelf {
    if (widget.mode == 'self') return true;

    final userId = widget.userId.trim().toLowerCase();
    final account = AccountManager().currentAccount;
    if (userId.isEmpty || account == null) return false;

    return userId == account.userId.toLowerCase() ||
        userId == account.accountId.toLowerCase();
  }

  String get _profileUserId {
    final userId = widget.userId.trim().toLowerCase();
    if (userId.isNotEmpty) return userId;
    if (_userId.isNotEmpty) return _userId;
    if (_isSelf) {
      return _currentUserId;
    }
    return '';
  }

  String get _currentUserId =>
      AccountManager().currentAccount?.accountId.toLowerCase() ?? '';

  String get _profileWalletAddress {
    final headerAccount = SocialWalletAddress.normalize(
      _profileHeader?.account,
    );
    if (headerAccount.isNotEmpty) return headerAccount;
    return SocialWalletAddress.normalize(_profileUserId);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadPosts();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    final nextShowNavBackground =
        _scrollController.hasClients &&
        _scrollController.offset > _navBackgroundThreshold;
    if (nextShowNavBackground == _showNavBackground) return;

    setState(() {
      _showNavBackground = nextShowNavBackground;
    });
  }

  @override
  void didUpdateWidget(covariant MomentUserProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.mode != widget.mode) {
      _loadPosts();
    }
  }

  String _userId = '';

  Future<void> _loadPosts() async {
    _userId = widget.userId.trim().toLowerCase();
    String userId = _profileUserId;
    setState(() {
      _isLoading = true;
      _profileHeader = null;
      _posts.clear();
      _followingCount = 0;
      _followersCount = 0;
      _isFollowingUser = false;
      _isFollowLoading = false;
    });
    if (userId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      return;
    }

    Future<_MomentProfileSocialStats>? socialStatsFuture;
    try {
      final profileHeader = await _loadProfileHeader(userId);
      if (!mounted || _profileUserId != userId) return;
      setState(() {
        _profileHeader = profileHeader ?? _profileHeader;
      });

      final profileWalletAddress = _profileWalletAddress;
      if (profileWalletAddress.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        return;
      }

      socialStatsFuture = _loadSocialStats(profileWalletAddress);
      final posts = await SocialCircleNoteApi.getSocialCircleUserNoteList(
        profileWalletAddress,
      );
      final hydratedPosts = await _hydratePostInteractionStates(posts);
      final postModels = hydratedPosts
          .map((post) => MomentPostModel(item: post))
          .toList();
      await MomentsResolver().resolve(postModels);
      final socialStats = await socialStatsFuture;
      if (!mounted || _profileUserId != userId) return;
      setState(() {
        _applySocialStats(socialStats);
        _posts
          ..clear()
          ..addAll(postModels);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('load moment user posts failed: $e');
      final socialStats = await socialStatsFuture;
      if (!mounted) return;
      setState(() {
        if (socialStats != null) {
          _applySocialStats(socialStats);
        }
        _isLoading = false;
      });
    }
  }

  Future<_MomentProfileSocialStats> _loadSocialStats(String userId) async {
    final profileFollowingFuture = _loadUserIdListSafely(
      SocialCircleUserApi.getSocialCircleUserFollow(userId: userId),
    );
    final profileFollowersFuture = _loadUserIdListSafely(
      SocialCircleUserApi.getSocialCircleUserFans(userId: userId),
    );
    final currentFollowingFuture = _isSelf
        ? Future<List<String>>.value(const [])
        : _loadUserIdListSafely(
            SocialCircleUserApi.getSocialCircleUserFollow(),
          );

    final profileFollowing = await profileFollowingFuture;
    final profileFollowers = await profileFollowersFuture;
    final currentFollowing = await currentFollowingFuture;
    final normalizedUserId = userId.toLowerCase();

    return _MomentProfileSocialStats(
      followingCount: profileFollowing.length,
      followersCount: profileFollowers.length,
      isFollowingUser:
          !_isSelf &&
          currentFollowing
              .map((id) => id.trim().toLowerCase())
              .contains(normalizedUserId),
    );
  }

  Future<List<String>> _loadUserIdListSafely(
    Future<List<String>> future,
  ) async {
    try {
      return await future;
    } catch (e) {
      debugPrint('load moment user relation list failed: $e');
      return const [];
    }
  }

  void _applySocialStats(_MomentProfileSocialStats stats) {
    _followingCount = stats.followingCount;
    _followersCount = stats.followersCount;
    _isFollowingUser = stats.isFollowingUser;
  }

  Future<_MomentProfileHeaderData?> _loadProfileHeader(
    String userId,
  ) async {
    final account = AccountManager().currentAccount;
    if (_isSelf && account != null) {
      return _MomentProfileHeaderData(
        userId: account.userId,
        nickname: account.name,
        avatar: account.avatar,
        account: account.accountId,
      );
    }

    try {
      final normalizedImUserId = userId.trim();
      if (normalizedImUserId.isNotEmpty) {
        final user = await UserDisplayStateCenter().getUser(normalizedImUserId);

        if (user != null) {
          return _MomentProfileHeaderData.fromUserDisplay(
            user,
            fallbackUserId: userId,
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('load moment user profile failed: $e');
      return null;
    }
  }

  Future<List<SocialInvitationModel>> _hydratePostInteractionStates(
    List<SocialInvitationModel> posts,
  ) {
    return Future.wait(posts.map(_hydratePostInteractionState));
  }

  Future<SocialInvitationModel> _hydratePostInteractionState(
    SocialInvitationModel post,
  ) async {
    if (post.noteId.isEmpty) return post;

    try {
      final detail = await SocialCircleNoteApi.getSocialCircleNoteInfo(
        post.noteId,
      );
      if (detail != null) {
        _applyPostInteractionInfo(post, detail);
      }
    } catch (e) {
      debugPrint('load moment post interaction failed (${post.noteId}): $e');
    }

    return post;
  }

  void _applyPostInteractionInfo(
    SocialInvitationModel target,
    SocialInvitationModel source,
  ) {
    target.isLike = source.isLike;
    target.isCollect = source.isCollect;
    target.likes = source.likes;
    target.collects = source.collects;
    target.reviews = source.reviews;
    target.shares = source.shares;
    target.forwards = source.forwards;
    target.reviewInfo = source.reviewInfo;
  }

  Future<void> _toggleLike(SocialInvitationModel post) async {
    final nextIsLiked = !post.isLike;
    final failureText = AppLocalizations.of(context)!.momentsLikeFailed;
    var success = false;
    try {
      AppLoading.show();
      success = await SocialCircleNoteApi.socialCircleNoteLikeToggle(
        post.noteId,
        nextIsLiked,
      );
    } catch (e) {
      debugPrint('toggle moment like failed: $e');
    } finally {
      AppLoading.dismiss();
    }

    if (!success) {
      AppToast.show(failureText);
      return;
    }
    if (!mounted) return;

    setState(() {
      post.isLike = nextIsLiked;
      post.likes = _nextCount(post.likes, nextIsLiked);
    });
  }

  Future<void> _toggleCollect(SocialInvitationModel post) async {
    final nextIsCollected = !post.isCollect;
    final failureText = AppLocalizations.of(context)!.momentsCollectFailed;
    var success = false;
    try {
      AppLoading.show();
      success = await SocialCircleNoteApi.socialCircleNoteCollectToggle(
        post.noteId,
        nextIsCollected,
      );
    } catch (e) {
      debugPrint('toggle moment collect failed: $e');
    } finally {
      AppLoading.dismiss();
    }

    if (!success) {
      AppToast.show(failureText);
      return;
    }
    if (!mounted) return;

    setState(() {
      post.isCollect = nextIsCollected;
      post.collects = _nextCount(post.collects, nextIsCollected);
    });
  }

  void _openComments(MomentPostModel model) {
    context.push(
      '/moment-post-detail',
      extra: {'item': model, 'isFollowing': false, 'isBlock': false},
    );
  }

  Future<void> _sharePost(SocialInvitationModel post) async {
    final targets = await ChatForwardTargetModal.show(
      context,
      friends: ImDataCenter().friendListSnapshot,
      groups: ImDataCenter().groupListSnapshot,
    );
    if (!mounted || targets == null || targets.isEmpty) {
      return;
    }

    final shareData = MomentPostShareData.fromPost(post);
    if (!shareData.isValid) {
      AppToast.show(AppLocalizations.of(context)!.momentsShareFailed);
      return;
    }

    var successCount = 0;
    AppLoading.show();
    try {
      for (final target in targets) {
        final sent = await ImSender.instance.send(
          message: MomentPostShareMessage(
            conversationType: target.conversationType,
            targetId: target.targetId,
            channelId: target.channelId,
            data: shareData,
          ),
        );
        if (!sent) continue;

        successCount++;
        if (target.conversationType == RCIMIWConversationType.private) {
          unawaited(_recordShare(post, target.targetId));
        }
      }
    } catch (e) {
      debugPrint('share moment profile post failed: $e');
    } finally {
      AppLoading.dismiss();
    }

    if (!mounted) return;
    AppToast.show(
      successCount > 0
          ? AppLocalizations.of(context)!.momentsShareSuccess
          : AppLocalizations.of(context)!.momentsShareFailed,
    );
    if (successCount == 0) return;

    setState(() {
      post.shares += successCount;
    });
  }

  Future<void> _recordShare(SocialInvitationModel post, String toUserId) async {
    final fromUserId = AccountManager().currentAccount?.accountId ?? '';
    if (fromUserId.isEmpty || toUserId.isEmpty) {
      return;
    }

    try {
      await SocialCircleNoteApi.socialCircleNoteShare(
        fromUserId,
        toUserId,
        post.noteId,
      );
    } catch (e) {
      debugPrint('record moment profile post share failed: $e');
    }
  }

  Future<void> _forwardPost(SocialInvitationModel post) async {
    await _sendShareAction(
      action: () => SocialCircleNoteApi.socialCircleNoteForward(
        _currentUserId,
        post.walletAddress,
        post.noteId,
      ),
      successText: AppLocalizations.of(context)!.momentsForwardSuccess,
      failureText: AppLocalizations.of(context)!.momentsForwardFailed,
      onSuccess: () {
        setState(() {
          post.forwards += 1;
        });
      },
    );
  }

  Future<void> _sendShareAction({
    required Future<bool> Function() action,
    required String successText,
    required String failureText,
    required VoidCallback onSuccess,
  }) async {
    if (_currentUserId.isEmpty) {
      AppToast.show(AppLocalizations.of(context)!.momentsUserNotLoggedIn);
      return;
    }

    var success = false;
    try {
      AppLoading.show();
      success = await action();
    } catch (e) {
      debugPrint('send moment share action failed: $e');
    } finally {
      AppLoading.dismiss();
    }

    if (!success) {
      AppToast.show(failureText);
      return;
    }
    if (!mounted) return;

    onSuccess();
    AppToast.show(successText);
  }

  Future<void> _toggleProfileFollow() async {
    if (_isSelf || _isFollowLoading) return;

    final userId = _profileWalletAddress;
    if (userId.isEmpty) {
      AppToast.show(AppLocalizations.of(context)!.momentsUserInfoEmpty);
      return;
    }

    final nextIsFollowing = !_isFollowingUser;
    var success = false;

    setState(() {
      _isFollowLoading = true;
    });

    try {
      AppLoading.show();
      success = await SocialCircleUserApi.socialCircleUserFollowToggle(
        userId,
        nextIsFollowing,
      );
    } catch (e) {
      debugPrint('toggle moment user follow failed: $e');
    } finally {
      AppLoading.dismiss();
    }

    if (!mounted) return;

    if (!success) {
      setState(() {
        _isFollowLoading = false;
      });
      AppToast.show(
        nextIsFollowing
            ? AppLocalizations.of(context)!.momentsFollowFailed
            : AppLocalizations.of(context)!.momentsUnfollowFailed,
      );
      return;
    }

    setState(() {
      _isFollowingUser = nextIsFollowing;
      _followersCount = nextIsFollowing
          ? _followersCount + 1
          : (_followersCount > 0 ? _followersCount - 1 : 0);
      _isFollowLoading = false;
    });
  }

  int _nextCount(int count, bool increment) {
    if (increment) return count + 1;
    return count > 0 ? count - 1 : 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sendMomentInitialized) {
      return;
    }

    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.of(context).padding;
    _sendMomentOffset = Offset(
      size.width - 20 - _sendMomentSize,
      size.height - padding.bottom - 50 - _sendMomentSize,
    );
    _sendMomentInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppPage(
      showNav: true,
      isCustomHeader: true,
      renderCustomHeader: _buildCustomHeader(context),
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.white,
      navBackgroundColor: Colors.transparent,
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: AppColors.white)),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _coverHeight,
            child: Image.asset(
              'assets/images/moments/moment-bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: _coverHeight),
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight:
                          MediaQuery.of(context).size.height - _coverHeight,
                    ),
                    decoration: const BoxDecoration(color: AppColors.white),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAvatarAndJoinAction(context, l10n),
                              const SizedBox(height: 16),
                              _buildCommunityTitleAndAddress(),
                              const SizedBox(height: 16),
                              _buildFollowStats(),
                              const SizedBox(height: 16),
                              const Divider(
                                height: 1,
                                color: AppColors.grey200,
                              ),
                              const SizedBox(height: 16),
                              _buildDynamicSection(),
                            ],
                          ),
                        ),
                        _buildDashboardContent(l10n),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_isSelf && _sendMomentOffset != null)
            Positioned(
              left: _sendMomentOffset!.dx,
              top: _sendMomentOffset!.dy,
              child: GestureDetector(
                onTap: () async {
                  await context.push('/new-post?retweet=0');
                  _loadPosts();
                },
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) {
                  final size = MediaQuery.sizeOf(context);
                  final padding = MediaQuery.of(context).padding;
                  final maxX = size.width - _sendMomentSize;
                  final maxY = size.height - padding.bottom - _sendMomentSize;
                  final nextOffset = Offset(
                    (_sendMomentOffset!.dx + details.delta.dx).clamp(0.0, maxX),
                    (_sendMomentOffset!.dy + details.delta.dy).clamp(0.0, maxY),
                  );

                  setState(() {
                    _sendMomentOffset = nextOffset;
                  });
                },
                child: Image.asset(
                  'assets/images/moments/send-moment.png',
                  width: _sendMomentSize,
                  height: _sendMomentSize,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 自定义导航栏
  Widget _buildCustomHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      foregroundDecoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _showNavBackground ? AppColors.grey100 : Colors.transparent,
            width: 1,
          ),
        ),
      ),
      color: _showNavBackground ? AppColors.white : Colors.transparent,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Image.asset(
              'assets/images/community/back.png',
              width: 32,
              height: 32,
            ),
          ),
          _buildMoreButton(l10n),
        ],
      ),
    );
  }

  Widget _buildMoreButton(AppLocalizations l10n) {
    return Builder(
      builder: (context) {
        final moreButtonKey = GlobalKey();

        return GestureDetector(
          key: moreButtonKey,
          onTap: () {
            AppActionPopMenu.show(
              context,
              buttonKey: moreButtonKey,
              width: _isSelf ? 168 : 152,
              rightOffset: 5,
              items: _isSelf
                  ? _buildSelfMoreItems(l10n)
                  : _buildOtherUserMoreItems(l10n),
            );
          },
          child: Image.asset(
            'assets/images/moments/black-more.png',
            width: 32,
            height: 32,
          ),
        );
      },
    );
  }

  List<AppActionPopMenuItem> _buildSelfMoreItems(AppLocalizations l10n) {
    return [
      AppActionPopMenuItem(
        icon: 'assets/images/moments/block.png',
        label: l10n.translate('moments_my_blocked'),
        onTap: () => context.push('/moment-blocked-users'),
      ),
      AppActionPopMenuItem(
        icon: 'assets/images/moments/my-collections.png',
        label: l10n.translate('moments_my_collections'),
        onTap: () => context.push('/moment-collections'),
      ),
      AppActionPopMenuItem(
        icon: 'assets/images/moments/message-list.png',
        label: l10n.translate('moments_message_list'),
        onTap: () => context.push('/message-center'),
        showDivider: false,
      ),
    ];
  }

  List<AppActionPopMenuItem> _buildOtherUserMoreItems(AppLocalizations l10n) {
    return [
      AppActionPopMenuItem(
        icon: 'assets/images/moments/block.png',
        label: l10n.translate('moments_block_this_user'),
        onTap: () {},
      ),
      AppActionPopMenuItem(
        icon: 'assets/images/moments/report.png',
        label: l10n.translate('moments_report'),
        onTap: () {},
        showDivider: false,
      ),
    ];
  }

  /// 头像与操作按钮
  Widget _buildAvatarAndJoinAction(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return SizedBox(
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -16,
            left: 0,
            child: _buildProfileAvatar(showPhotoIcon: _isSelf),
          ),
          if (!_isSelf)
            Positioned(
              right: 0,
              bottom: 16,
              child: _ProfileFollowButton(
                isFollowing: _isFollowingUser,
                isLoading: _isFollowLoading,
                onTap: _toggleProfileFollow,
                l10n: l10n,
              ),
            ),
        ],
      ),
    );
  }

  /// 社区标题和地址
  Widget _buildProfileAvatar({required bool showPhotoIcon}) {
    final header = _profileHeader;
    if (header == null) {
      return const SizedBox(
        width: 64,
        height: 64,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final avatar = SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          UserAvatarWidget(
            userId: header.avatarSeed,
            avatarUrl: header.avatar,
            size: 64,
            borderRadius: BorderRadius.circular(8),
          ),
          // if (showPhotoIcon)
          //   Positioned(
          //     right: -8,
          //     bottom: -8,
          //     child: Image.asset(
          //       'assets/images/community/photo.png',
          //       width: 24,
          //       height: 24,
          //     ),
          //   ),
        ],
      ),
    );

    if (!showPhotoIcon) {
      return avatar;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _showSelfAvatarSheet,
      child: avatar,
    );
  }

  void _showSelfAvatarSheet() {
    AppActionSheet.show(
      context,
      items: [
        AppActionSheetItem(
          label: AppLocalizations.of(context)!.momentsDefaultAvatar,
          onTap: () {},
        ),
        AppActionSheetItem(
          label: AppLocalizations.of(context)!.commonChooseFromAlbum,
          onTap: () {},
        ),
      ],
      cancelText: AppLocalizations.of(context)!.commonCancel,
    );
  }

  Widget _buildCommunityTitleAndAddress() {
    return _buildProfileTitleAndAddress();
  }

  Widget _buildProfileTitleAndAddress() {
    final header = _profileHeader;
    if (header == null) {
      return const SizedBox(
        height: 48,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                header.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.h1.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey900,
                ),
              ),
            ),
            if (_isSelf) ...[
              const SizedBox(width: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  context.push('/user-profile', extra: header.account);
                },
                child: Image.asset(
                  'assets/images/moments/edit.png',
                  width: 16,
                  height: 16,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        _ProfileAddressChip(
          value: header.address,
          icon: _isSelf
              ? 'assets/images/moments/copy.png'
              : 'assets/images/common/copy-black.png',
        ),
      ],
    );
  }

  /// 关注数与粉丝数
  Widget _buildFollowStats() {
    final l10n = AppLocalizations.of(context)!;
    if (_isSelf) {
      return Row(
        children: [
          _buildFollowStatColumn(
            '$_followingCount',
            l10n.translate('moments_following'),
            onTap: _openFollowingList,
          ),
          const SizedBox(width: 24),
          _buildFollowStatColumn(
            '$_followersCount',
            l10n.translate('moments_followers'),
            onTap: _openFollowersList,
          ),
        ],
      );
    }

    return Row(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openFollowingList,
          child: Row(
            children: [
              Text(
                '$_followingCount',
                style: AppTextStyles.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                l10n.translate('moments_following'),
                style: AppTextStyles.body.copyWith(
                  fontSize: 10,
                  color: AppColors.grey400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        const SizedBox(width: 7),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openFollowersList,
          child: Row(
            children: [
              Text(
                '$_followersCount',
                style: AppTextStyles.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                l10n.translate('moments_followers'),
                style: AppTextStyles.body.copyWith(
                  fontSize: 10,
                  color: AppColors.grey400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFollowStatColumn(
    String value,
    String label, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              fontSize: 10,
              color: AppColors.grey400,
            ),
          ),
        ],
      ),
    );
  }

  void _openFollowingList() {
    final userId = _profileWalletAddress;
    if (userId.isEmpty) return;
    context.push('/moment-following?userId=$userId');
  }

  void _openFollowersList() {
    final userId = _profileWalletAddress;
    if (userId.isEmpty) return;
    context.push('/moment-followers?userId=$userId');
  }

  /// Dynamic 区域
  Widget _buildDynamicSection() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Image.asset('assets/images/moments/mike.png', width: 20, height: 20),
        const SizedBox(width: 4),
        Text(
          l10n.translate('moments_dynamic'),
          style: AppTextStyles.body.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.grey900,
          ),
        ),
      ],
    );
  }

  /// 内容列表
  Widget _buildDashboardContent(AppLocalizations l10n) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_posts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: _NoContentPlaceholder(),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      itemCount: _posts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final post = _posts[index];
        return Column(
          children: [
            _buildPostItem(post),
            const SizedBox(height: 12),
            _buildPostInteraction(post),
          ],
        );
      },
    );
  }

  /// 帖子内容
  Widget _buildPostItem(MomentPostModel model) {
    final post = model.item;
    final header = _postHeaderFor(model);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            UserAvatarWidget(
              userId: header?.avatarSeed,
              avatarUrl: header?.avatar,
              size: 36,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  header?.displayName ?? '',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  formatIMTime(post.timestamp),
                  style: AppTextStyles.body.copyWith(
                    fontSize: 10,
                    color: AppColors.grey400,
                  ),
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          post.content,
          style: AppTextStyles.body.copyWith(
            fontSize: 14,
            color: const Color(0xFF404040),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        ImageGrid(medias: post.media),
        const SizedBox(height: 12),
      ],
    );
  }

  _MomentProfileHeaderData? _postHeaderFor(MomentPostModel model) {
    if (model.user != null) {
      return _MomentProfileHeaderData.fromUserDisplay(
        model.user!,
        fallbackUserId: model.item.userId,
      );
    }

    final post = model.item;
    final userInfo = post.userInfoModel;
    if (userInfo != null) {
      return _MomentProfileHeaderData(
        userId: userInfo.userId.isNotEmpty ? userInfo.userId : post.userId,
        nickname: userInfo.nickname,
        avatar: userInfo.avatar,
        account: userInfo.account,
      );
    }

    return _profileHeader;
  }

  /// 帖子互动区
  Widget _buildPostInteraction(MomentPostModel model) {
    final post = model.item;
    return _PostActionBar(
      isLiked: post.isLike,
      isCollected: post.isCollect,
      likeCount: post.likes,
      collectCount: post.collects,
      commentCount: post.reviews,
      shareCount: post.shares,
      forwardCount: post.forwards,
      onLike: () => _toggleLike(post),
      onCollect: () => _toggleCollect(post),
      onComment: () => _openComments(model),
      onShare: () => _sharePost(post),
      onForward: () => _forwardPost(post),
    );
  }
}

class _MomentProfileHeaderData {
  final String userId;
  final String nickname;
  final String avatar;
  final String account;

  const _MomentProfileHeaderData({
    required this.userId,
    required this.nickname,
    required this.avatar,
    required this.account,
  });

  factory _MomentProfileHeaderData.fromUserDisplay(
    UserDisplayModel userInfo, {
    required String fallbackUserId,
  }) {
    return _MomentProfileHeaderData(
      userId: fallbackUserId,
      nickname: userInfo.name,
      avatar: userInfo.avatar,
      account: userInfo.userId,
    );
  }

  String get displayName {
    final name = nickname.trim();
    if (name.isNotEmpty) return name;

    final accountText = account.trim();
    if (accountText.isNotEmpty) {
      return ellipsisMiddle(accountText, head: 4, tail: 4);
    }

    final id = userId.trim();
    if (id.isEmpty) return '';
    return ellipsisMiddle(id, head: 4, tail: 4);
  }

  String get address {
    final accountText = account.trim();
    if (accountText.isNotEmpty) return accountText;
    return userId.trim();
  }

  String get avatarSeed {
    final accountText = account.trim();
    if (accountText.isNotEmpty) return accountText;
    return userId.trim();
  }

  UserDisplayModel get user {
    return UserDisplayModel(
      profile: RCIMIWUserProfile.create(
        userId: userId,
        portraitUri: avatar,
        name: nickname,
      ),
    );
  }
}

class _MomentProfileSocialStats {
  final int followingCount;
  final int followersCount;
  final bool isFollowingUser;

  const _MomentProfileSocialStats({
    required this.followingCount,
    required this.followersCount,
    required this.isFollowingUser,
  });
}

class _ProfileFollowButton extends StatelessWidget {
  final bool isFollowing;
  final bool isLoading;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  const _ProfileFollowButton({
    required this.isFollowing,
    required this.isLoading,
    required this.onTap,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final text = isFollowing
        ? l10n.translate('moments_following')
        : l10n.translate('moments_follow');

    return Opacity(
      opacity: isLoading ? 0.65 : 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isLoading ? null : onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 85),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isFollowing ? AppColors.white : AppColors.grey900,
              borderRadius: BorderRadius.circular(28),
              border: isFollowing
                  ? Border.all(color: AppColors.grey200, width: 1)
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: isFollowing ? AppColors.grey900 : AppColors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileAddressChip extends StatelessWidget {
  final String value;
  final String icon;

  const _ProfileAddressChip({required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final address = value.trim();
    if (address.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: address));
        if (!context.mounted) return;
        AppToast.show(AppLocalizations.of(context)!.commonCopied);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.grey200, width: 1),
          borderRadius: BorderRadius.circular(61),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(icon, width: 12, height: 12),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                ellipsisMiddle(address),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  fontSize: 10,
                  color: AppColors.grey900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoContentPlaceholder extends StatelessWidget {
  const _NoContentPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Center(
        child: Text(
          AppLocalizations.of(context)!.momentsNoContent,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            fontSize: 14,
            color: AppColors.grey400,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _PostActionBar extends StatelessWidget {
  final bool isLiked;
  final bool isCollected;
  final int likeCount;
  final int collectCount;
  final int commentCount;
  final int shareCount;
  final int forwardCount;
  final VoidCallback? onLike;
  final VoidCallback? onCollect;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onForward;

  const _PostActionBar({
    required this.isLiked,
    required this.isCollected,
    required this.likeCount,
    required this.collectCount,
    required this.commentCount,
    required this.shareCount,
    required this.forwardCount,
    this.onLike,
    this.onCollect,
    this.onComment,
    this.onShare,
    this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionIconTextButton(
          icon: isLiked
              ? 'assets/images/moments/like-active.png'
              : 'assets/images/moments/like.png',
          text: '$likeCount',
          onTap: onLike,
        ),
        const SizedBox(width: 24),
        _ActionIconTextButton(
          icon: isCollected
              ? 'assets/images/moments/collect-active.png'
              : 'assets/images/moments/collect.png',
          text: '$collectCount',
          onTap: onCollect,
        ),
        const SizedBox(width: 24),
        _ActionIconTextButton(
          icon: 'assets/images/moments/comment.png',
          text: '$commentCount',
          onTap: onComment,
        ),
        // const SizedBox(width: 24),
        // _ActionIconTextButton(
        //   icon: 'assets/images/moments/share-pop.png',
        //   text: '$forwardCount',
        //   onTap: onForward,
        // ),
        const Spacer(),
        _ActionIconTextButton(
          icon: 'assets/images/moments/share.png',
          text: '$shareCount',
          onTap: onShare,
        ),
      ],
    );
  }
}

class _ActionIconTextButton extends StatelessWidget {
  final String icon;
  final String text;
  final VoidCallback? onTap;

  const _ActionIconTextButton({
    required this.icon,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(icon, width: 16, height: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.grey900,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    if (onTap == null) return content;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: content,
      ),
    );
  }
}
