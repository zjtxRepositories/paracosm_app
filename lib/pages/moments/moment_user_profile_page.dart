import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/core/models/social_Invitation_model.dart';
import 'package:paracosm/core/network/api/social_circle_note_api.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/util/string_util.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_action_pop_menu.dart';
import 'package:paracosm/widgets/common/app_action_sheet.dart';
import 'package:paracosm/widgets/common/app_loading.dart';
import 'package:paracosm/widgets/common/app_toast.dart';
import 'package:paracosm/widgets/modals/share_modals.dart';

import 'moment_post_card.dart';

/// 个人主页详情页
/// 保留社区详情页的主体结构，只显示看板下面的内容列表，移除 TabController 和其他 Tab 区域。
class MomentUserProfilePage extends StatefulWidget {
  final String userId;
  final String communityName;
  final String mode;

  const MomentUserProfilePage({
    super.key,
    required this.userId,
    this.communityName = 'Kristen',
    this.mode = 'friend',
  });

  @override
  State<MomentUserProfilePage> createState() => _MomentUserProfilePageState();
}

class _MomentUserProfilePageState extends State<MomentUserProfilePage> {
  static const double _sendMomentSize = 80;
  final List<SocialInvitationModel> _posts = [];
  Offset? _sendMomentOffset;
  bool _sendMomentInitialized = false;
  bool _isLoading = true;
  bool get _isSelf => widget.mode == 'self';
  String get _currentUserId =>
      AccountManager().currentAccount?.userId.toLowerCase() ?? '';

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void didUpdateWidget(covariant MomentUserProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _loadPosts();
    }
  }

  Future<void> _loadPosts() async {
    final userId = widget.userId.trim();
    setState(() {
      _isLoading = true;
      _posts.clear();
    });

    if (userId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final posts = await SocialCircleNoteApi.getSocialCircleUserNoteList(
        userId,
      );
      final hydratedPosts = await _hydratePostInteractionStates(posts);
      if (!mounted || widget.userId.trim() != userId) return;
      setState(() {
        _posts
          ..clear()
          ..addAll(hydratedPosts);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('load moment user posts failed: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
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
      AppToast.show('点赞失败！');
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
      AppToast.show('收藏失败！');
      return;
    }
    if (!mounted) return;

    setState(() {
      post.isCollect = nextIsCollected;
      post.collects = _nextCount(post.collects, nextIsCollected);
    });
  }

  void _openComments(SocialInvitationModel post) {
    context.push(
      '/moment-post-detail',
      extra: {'item': post, 'isFollowing': false, 'isBlock': false},
    );
  }

  void _showShare(SocialInvitationModel post) {
    ShareModals.show(
      context,
      actions: [
        ShareActionData(
          icon: 'assets/images/moments/share-pop.png',
          label: 'Share',
          onTap: () => _sharePost(post),
        ),
        ShareActionData(
          icon: 'assets/images/moments/friends.png',
          label: 'Retweet',
          onTap: () => _forwardPost(post),
        ),
        ShareActionData(
          icon: 'assets/images/moments/link.png',
          label: 'Copy link',
          onTap: AppToast.showCopied,
        ),
      ],
    );
  }

  Future<void> _sharePost(SocialInvitationModel post) async {
    await _sendShareAction(
      action: () => SocialCircleNoteApi.socialCircleNoteShare(
        _currentUserId,
        post.userId,
        post.noteId,
      ),
      successText: '分享成功！',
      failureText: '分享失败！',
      onSuccess: () {
        setState(() {
          post.shares += 1;
        });
      },
    );
  }

  Future<void> _forwardPost(SocialInvitationModel post) async {
    await _sendShareAction(
      action: () => SocialCircleNoteApi.socialCircleNoteForward(
        _currentUserId,
        post.userId,
        post.noteId,
      ),
      successText: '转发成功！',
      failureText: '转发失败！',
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
      AppToast.show('用户未登录！');
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
      navBackgroundColor: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/moments/moment-bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 140),
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 140,
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
    return Container(
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
          Builder(
            builder: (context) {
              final moreButtonKey = GlobalKey();

              return GestureDetector(
                key: moreButtonKey,
                onTap: () {
                  AppActionPopMenu.show(
                    context,
                    buttonKey: moreButtonKey,
                    width: 152,
                    rightOffset: 5,
                    items: [
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
                    ],
                  );
                },
                child: Image.asset(
                  'assets/images/moments/black-more.png',
                  width: 32,
                  height: 32,
                ),
              );
            },
          ),
        ],
      ),
    );
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
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 85),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.grey900,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      child: Text(
                        l10n.translate('moments_follow'),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 社区标题和地址
  Widget _buildProfileAvatar({required bool showPhotoIcon}) {
    final avatar = SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Image.asset(
              'assets/images/chat/avatar.png',
              fit: BoxFit.cover,
            ),
          ),
          if (showPhotoIcon)
            Positioned(
              right: -8,
              bottom: -8,
              child: Image.asset(
                'assets/images/community/photo.png',
                width: 24,
                height: 24,
              ),
            ),
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
        AppActionSheetItem(label: '从默认头像选择', onTap: () {}),
        AppActionSheetItem(label: '从手机相册选择', onTap: () {}),
      ],
      cancelText: '取消',
    );
  }

  Widget _buildCommunityTitleAndAddress() {
    if (_isSelf) {
      return _buildSelfCommunityTitleAndAddress();
    }

    return _buildFriendCommunityTitleAndAddress();
  }

  Widget _buildSelfCommunityTitleAndAddress() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.communityName,
              style: AppTextStyles.h1.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                context.push(
                  '/user-profile/${Uri.encodeComponent(widget.communityName)}?mode=self',
                );
              },
              child: Image.asset(
                'assets/images/moments/edit.png',
                width: 16,
                height: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.grey200, width: 1),
            borderRadius: BorderRadius.circular(61),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/moments/copy.png',
                width: 12,
                height: 12,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.communityMockAddressDetail,
                style: AppTextStyles.body.copyWith(
                  fontSize: 10,
                  color: AppColors.grey900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFriendCommunityTitleAndAddress() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.communityName,
              style: AppTextStyles.h1.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.grey200, width: 1),
                borderRadius: BorderRadius.circular(61),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/common/copy-black.png',
                    width: 12,
                    height: 12,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    l10n.communityMockAddressDetail,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 10,
                      color: AppColors.grey900,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
          _buildFollowStatColumn('10', l10n.translate('moments_following')),
          const SizedBox(width: 24),
          _buildFollowStatColumn('16,987', l10n.translate('moments_followers')),
        ],
      );
    }

    return Row(
      children: [
        Text(
          '10',
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
        const SizedBox(width: 12),
        Text(
          '16,987',
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
    );
  }

  Widget _buildFollowStatColumn(String value, String label) {
    return Column(
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
    );
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
  Widget _buildPostItem(SocialInvitationModel post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/chat/avatar.png',
                width: 36,
                height: 36,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kristen',
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

  /// 帖子互动区
  Widget _buildPostInteraction(SocialInvitationModel post) {
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
      onComment: () => _openComments(post),
      onShare: () => _showShare(post),
      onForward: () => _forwardPost(post),
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
          '-There is no content-',
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
        const SizedBox(width: 24),
        _ActionIconTextButton(
          icon: 'assets/images/moments/share-pop.png',
          text: '$forwardCount',
          onTap: onForward,
        ),
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
