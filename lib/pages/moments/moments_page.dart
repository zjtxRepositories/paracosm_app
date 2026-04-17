import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/common/app_action_pop_menu.dart';
import 'package:paracosm/widgets/common/app_modal.dart';
import 'package:paracosm/widgets/common/app_toast.dart';
import 'package:paracosm/widgets/base/app_page.dart';

class MomentsPage extends StatelessWidget {
  const MomentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      showNav: false,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildHeader(context),
            const SizedBox(height: 12),
            _buildStories(),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                children: [
                  _MomentPostCard(
                    name: 'Cody',
                    time: '45秒前',
                    subtitle: 'Let\'s learn English together',
                    avatar: 'assets/images/chat/avatar.png',
                    imagePaths: ['assets/images/moments/moment1.png'],
                    followState: _FollowButtonState.following,
                    initialLiked: true,
                    likeCount: 6,
                    commentCount: 1,
                    shareCount: 1,
                    onTap: () => context.push('/moment-post-detail'),
                    shareOnTap: () => context.push('/new-post?retweet=1'),
                  ),
                  const SizedBox(height: 12),
                  _MomentPostCard(
                    name: 'Devon Lane',
                    time: '45分钟前',
                    subtitle: 'Two photos should switch to a 2-column layout',
                    avatar: 'assets/images/chat/avatar.png',
                    imagePaths: [
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                    ],
                    followState: _FollowButtonState.follow,
                    initialCollected: true,
                    collectCount: 1,
                    commentCount: 1,
                    shareCount: 1,
                  ),
                  SizedBox(height: 12),
                  _MomentPostCard(
                    name: 'Kristen',
                    time: '1小时前',
                    subtitle: 'Three photos should keep a 3-column layout',
                    avatar: 'assets/images/chat/avatar.png',
                    imagePaths: [
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                    ],
                    followState: _FollowButtonState.following,
                  ),
                  SizedBox(height: 12),
                  _MomentPostCard(
                    name: 'Robert',
                    time: '2小时前',
                    subtitle: 'Four photos should switch to a 2-column layout',
                    avatar: 'assets/images/chat/avatar.png',
                    imagePaths: [
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                    ],
                    followState: _FollowButtonState.follow,
                  ),
                  SizedBox(height: 12),
                  _MomentPostCard(
                    name: 'Howard',
                    time: '3小时前',
                    subtitle: 'Five photos should fall back to 3 columns',
                    avatar: 'assets/images/chat/avatar.png',
                    imagePaths: [
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                    ],
                    followState: _FollowButtonState.follow,
                  ),
                  SizedBox(height: 12),
                  _MomentPostCard(
                    name: 'Monica',
                    time: '4小时前',
                    subtitle: 'Six photos should fill two rows of three',
                    avatar: 'assets/images/chat/avatar.png',
                    imagePaths: [
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                    ],
                    followState: _FollowButtonState.follow,
                  ),
                  SizedBox(height: 12),
                  _MomentPostCard(
                    name: 'Nolan',
                    time: '5小时前',
                    subtitle: 'Seven photos should still use 3 columns',
                    avatar: 'assets/images/chat/avatar.png',
                    imagePaths: [
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                    ],
                    followState: _FollowButtonState.follow,
                  ),
                  SizedBox(height: 12),
                  _MomentPostCard(
                    name: 'Olivia',
                    time: '6小时前',
                    subtitle: 'Eight photos are useful for checking the last row',
                    avatar: 'assets/images/chat/avatar.png',
                    imagePaths: [
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                    ],
                    followState: _FollowButtonState.following,
                  ),
                  SizedBox(height: 12),
                  _MomentPostCard(
                    name: 'Parker',
                    time: '7小时前',
                    subtitle: 'Nine photos should make a full 3x3 grid',
                    avatar: 'assets/images/chat/avatar.png',
                    imagePaths: [
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                    ],
                    followState: _FollowButtonState.follow,
                  ),
                  SizedBox(height: 12),
                  _MomentPostCard(
                    name: '李经理',
                    time: '7小时前',
                    subtitle: 'Nine photos should make a full 3x3 grid',
                    avatar: 'assets/images/chat/avatar.png',
                    imagePaths: [
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                      'assets/images/moments/moment1.png',
                    ],
                    followState: _FollowButtonState.follow,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Moment',
            style: AppTextStyles.h1.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.grey900,
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              context.push('/message-center');
            },
            child: Image.asset(
              'assets/images/moments/has-msg.png',
              width: 32,
              height: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStories() {
    final stories = <_StoryData>[
      const _StoryData(
        label: '',
        avatar: 'assets/images/moments/add-moment.png',
        insideColor: AppColors.grey200,
        outsideColor: Colors.transparent,
        showPlusIcon: true,
      ),
      const _StoryData(
        label: 'ME',
        avatar: 'assets/images/chat/avatar.png',
        insideColor: Color(0xFF5A45FE),
        outsideColor: Color(0xFFDEDAFF),
        showAddBadge: true,
      ),

      const _StoryData(
        label: 'Wilson',
        avatar: 'assets/images/chat/avatar.png',
        insideColor: AppColors.primary,
        outsideColor: Color(0xFFF6FECC),
      ),
      const _StoryData(
        label: 'Kristen',
        avatar: 'assets/images/chat/avatar.png',
        insideColor: AppColors.primary,
        outsideColor: Color(0xFFF6FECC),
      ),
      const _StoryData(
        label: 'Robert',
        avatar: 'assets/images/chat/avatar.png',
        insideColor: AppColors.primary,
        outsideColor: Color(0xFFF6FECC),
      ),
      const _StoryData(
        label: 'Howard',
        avatar: 'assets/images/chat/avatar.png',
        insideColor: AppColors.primary,
        outsideColor: Color(0xFFF6FECC),
      ),
      const _StoryData(
        label: 'Monica',
        avatar: 'assets/images/chat/avatar.png',
        insideColor: AppColors.primary,
        outsideColor: Color(0xFFF6FECC),
      ),
    ];

    return SizedBox(
      height: 78,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) => _StoryAvatar(story: stories[index]),
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemCount: stories.length,
      ),
    );
  }
}

class _StoryData {
  final String label;
  final String avatar;
  final Color insideColor;
  final Color outsideColor;
  final bool showAddBadge;
  final bool showPlusIcon;

  const _StoryData({
    required this.label,
    required this.avatar,
    required this.insideColor,
    required this.outsideColor,
    this.showAddBadge = false,
    this.showPlusIcon = false,
  });
}

class _StoryAvatar extends StatelessWidget {
  final _StoryData story;

  const _StoryAvatar({required this.story});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: story.outsideColor, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: story.insideColor, width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: ClipOval(
                        child: Image.asset(story.avatar, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
                if (story.showPlusIcon)
                  const Center(
                    child: Icon(Icons.add, size: 18, color: AppColors.grey600),
                  ),
                if (story.showAddBadge)
                  Positioned(
                    right: -1,
                    bottom: -5,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        context.push('/new-post');
                      },
                      child: Image.asset(
                        'assets/images/moments/add.png',
                        width: 18,
                        height: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 54,
          child: Text(
            story.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.grey900,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _MomentPostCard extends StatelessWidget {
  final String name;
  final String time;
  final String subtitle;
  final String avatar;
  final List<String> imagePaths;
  final _FollowButtonState followState;
  final bool initialLiked;
  final bool initialCollected;
  final int likeCount;
  final int collectCount;
  final int commentCount;
  final int shareCount;
  final VoidCallback? onTap;
  final VoidCallback? shareOnTap;

  const _MomentPostCard({
    required this.name,
    required this.time,
    required this.subtitle,
    required this.avatar,
    required this.imagePaths,
    required this.followState,
    this.initialLiked = false,
    this.initialCollected = false,
    this.likeCount = 1,
    this.collectCount = 1,
    this.commentCount = 1,
    this.shareCount = 1,
    this.onTap,
    this.shareOnTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _AvatarBadge(avatar: avatar),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTextStyles.h2.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey900,
                        ),
                      ),
                      Text(
                        time,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.grey400,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _FollowButton(state: followState),
                  const SizedBox(width: 8),
                  Builder(
                    builder: (context) {
                      final moreButtonKey = GlobalKey();

                      return GestureDetector(
                        key: moreButtonKey,
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          AppActionPopMenu.show(
                            context,
                            buttonKey: moreButtonKey,
                            width: 152,
                            rightOffset: 15,
                            items: [
                              AppActionPopMenuItem(
                                icon: 'assets/images/moments/share-pop.png',
                                label: 'Share',
                                onTap: () => _showShareModal(context),
                              ),
                              AppActionPopMenuItem(
                                icon: 'assets/images/moments/block.png',
                                label: 'Block this user',
                                onTap: () {},
                              ),
                              AppActionPopMenuItem(
                                icon: 'assets/images/moments/report.png',
                                label: 'Report',
                                onTap: () => context.push('/moment-report'),
                                showDivider: false,
                              ),
                            ],
                          );
                        },
                        child: Image.asset(
                          'assets/images/moments/more.png',
                          width: 24,
                          height: 24,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: AppTextStyles.body.copyWith(
              color: const Color(0xFF404040),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          _buildMedia(),
          const SizedBox(height: 12),
          _PostActionBar(
            initialLiked: initialLiked,
            initialCollected: initialCollected,
            likeCount: likeCount,
            collectCount: collectCount,
            commentCount: commentCount,
            shareCount: shareCount,
            shareOnTap: shareOnTap,
          ),
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }

  Widget _buildMedia() {
    // 按张数自适应列数：
    // 1 张显示为 1 列大图，2/4 张显示为 2 列，其他情况默认 3 列。
    // 超过 9 张时只展示前 9 张，并在第 9 张上加蒙层显示剩余数量。
    // 这样可以保持图片宽高一致，并且在不同屏幕宽度下自动铺满可用区域。
    const double spacing = 4;

    if (imagePaths.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final imageCount = imagePaths.length;
        final visibleCount = imageCount > 9 ? 9 : imageCount;
        final hiddenCount = imageCount - visibleCount;
        var columns = 3;
        if (imageCount == 1) {
          columns = 1;
        } else if (imageCount == 2 || imageCount == 4) {
          columns = 2;
        }
        final itemSize = (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(visibleCount, (index) {
            final path = imagePaths[index];
            final showMoreOverlay = hiddenCount > 0 && index == 8;

            return SizedBox(
              width: itemSize,
              height: itemSize,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      path,
                      fit: BoxFit.cover,
                    ),
                    if (showMoreOverlay)
                      Container(
                        color: Colors.black.withValues(alpha: 0.5),
                        alignment: Alignment.center,
                        child: Text(
                          '+$hiddenCount',
                          style: AppTextStyles.h1.copyWith(
                            color: AppColors.grey100,
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  void _showShareModal(BuildContext context) {
    AppModal.show(
      context,
      title: 'Share',
      confirmText: null,
      onConfirm: () {},
      child: const _ShareModalContent(),
    );
  }
}

enum _FollowButtonState {
  follow,
  following,
}

class _PostActionBar extends StatefulWidget {
  final bool initialLiked;
  final bool initialCollected;
  final int likeCount;
  final int collectCount;
  final int commentCount;
  final int shareCount;
  final VoidCallback? shareOnTap;

  const _PostActionBar({
    required this.initialLiked,
    required this.initialCollected,
    required this.likeCount,
    required this.collectCount,
    required this.commentCount,
    required this.shareCount,
    this.shareOnTap,
  });

  @override
  State<_PostActionBar> createState() => _PostActionBarState();
}

class _PostActionBarState extends State<_PostActionBar> {
  late bool _isLiked;
  late bool _isCollected;
  late int _likeCount;
  late int _collectCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initialLiked;
    _isCollected = widget.initialCollected;
    _likeCount = widget.likeCount;
    _collectCount = widget.collectCount;
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount = _isLiked ? _likeCount + 1 : (_likeCount > 0 ? _likeCount - 1 : 0);
    });
  }

  void _toggleCollect() {
    setState(() {
      _isCollected = !_isCollected;
      _collectCount = _isCollected ? _collectCount + 1 : (_collectCount > 0 ? _collectCount - 1 : 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionIconTextButton(
          icon: _isLiked ? 'assets/images/moments/like-active.png' : 'assets/images/moments/like.png',
          text: '$_likeCount',
          active: _isLiked,
          onTap: _toggleLike,
        ),
        const SizedBox(width: 24),
        _ActionIconTextButton(
          icon: _isCollected ? 'assets/images/moments/collect-active.png' : 'assets/images/moments/collect.png',
          text: '$_collectCount',
          active: _isCollected,
          onTap: _toggleCollect,
        ),
        const SizedBox(width: 24),
        _ActionIconTextButton(
          icon: 'assets/images/moments/comment.png',
          text: '${widget.commentCount}',
        ),
        const Spacer(),
        _ActionIconTextButton(
          icon: 'assets/images/moments/share.png',
          text: '${widget.shareCount}',
          onTap: widget.shareOnTap,
        ),
      ],
    );
  }
}

class _ActionIconTextButton extends StatelessWidget {
  final String icon;
  final String text;
  final bool active;
  final VoidCallback? onTap;

  const _ActionIconTextButton({
    required this.icon,
    required this.text,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          icon,
          width: 16,
          height: 16,
        ),
        const SizedBox(width:4),
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

    if (onTap == null) {
      return content;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}

class _ShareModalContent extends StatelessWidget {
  const _ShareModalContent();

  @override
  Widget build(BuildContext context) {
    const shareContacts = <_ShareContactData>[
      _ShareContactData(name: 'Kristen', avatar: 'assets/images/chat/avatar.png'),
      _ShareContactData(name: 'Kristen', avatar: 'assets/images/chat/avatar.png'),
      _ShareContactData(name: 'Kristen', avatar: 'assets/images/chat/avatar.png'),
      _ShareContactData(name: 'Kristen', avatar: 'assets/images/chat/avatar.png'),
      _ShareContactData(name: 'Kristen', avatar: 'assets/images/chat/avatar.png'),
    ];

    final shareActions = <_ShareActionData>[
      const _ShareActionData(icon: 'assets/images/moments/friends.png', label: 'Friends'),
      const _ShareActionData(icon: 'assets/images/moments/save.png', label: 'Save'),
      _ShareActionData(
        icon: 'assets/images/moments/link.png',
        label: 'Copy link',
        onTap: () {
          AppToast.showCopied();
        },
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final contact in shareContacts) ...[
                _ShareContactItem(contact: contact),
                const SizedBox(width: 24),
              ],
            ],
          ),
        ),
        const SizedBox(height:16),
        Container(
          height: 1,
          color: AppColors.grey100,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (final action in shareActions) ...[
              _ShareActionItem(action: action),
              if (action != shareActions.last) const SizedBox(width: 24),
            ],
          ],
        ),
      ],
    );
  }
}

class _ShareContactData {
  final String name;
  final String avatar;

  const _ShareContactData({
    required this.name,
    required this.avatar,
  });
}

class _ShareActionData {
  final String icon;
  final String label;
  final VoidCallback? onTap;

  const _ShareActionData({
    required this.icon,
    required this.label,
    this.onTap,
  });
}

class _ShareContactItem extends StatelessWidget {
  final _ShareContactData contact;

  const _ShareContactItem({required this.contact});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.asset(
              contact.avatar,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            contact.name,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              color: AppColors.grey900,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareActionItem extends StatelessWidget {
  final _ShareActionData action;

  const _ShareActionItem({required this.action});

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Image.asset(
            action.icon,
            width: 20,
            height: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          action.label,
          style: AppTextStyles.body.copyWith(
            color: AppColors.grey800,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    if (action.onTap == null) {
      return content;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: action.onTap,
      child: content,
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  final String avatar;

  const _AvatarBadge({required this.avatar});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(avatar, fit: BoxFit.cover),
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  final _FollowButtonState state;

  const _FollowButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final isFollowing = state == _FollowButtonState.following;
    final buttonText = isFollowing ? 'Following' : 'Follow';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: isFollowing ? Colors.white : AppColors.grey900,
        borderRadius: BorderRadius.circular(28),
        border: isFollowing
            ? Border.all(
                color: AppColors.grey200,
                width: 1.5,
              )
            : null,
      ),
      child: Text(
        buttonText,
        style: AppTextStyles.caption.copyWith(
          color: isFollowing ? AppColors.grey900 : Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
