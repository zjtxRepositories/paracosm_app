import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/widgets/common/app_action_pop_menu.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';

class MomentPostDetailPage extends StatelessWidget {
  const MomentPostDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final moreButtonKey = GlobalKey();

    return AppPage(
      title: 'Post body',
      backgroundColor: Colors.white,
      navBackgroundColor: Colors.white,
      showNavBorder: true,
      headerActions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Builder(
            builder: (context) {
              return GestureDetector(
                key: moreButtonKey,
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  AppActionPopMenu.show(
                    context,
                    buttonKey: moreButtonKey,
                    width: 152,
                    rightOffset: 5,
                    items: [
                      AppActionPopMenuItem(
                        icon: 'assets/images/moments/share-pop.png',
                        label: 'Share',
                        onTap: () {},
                      ),
                      AppActionPopMenuItem(
                        icon: 'assets/images/moments/block.png',
                        label: 'Block this user',
                        onTap: () {},
                      ),
                      AppActionPopMenuItem(
                        icon: 'assets/images/moments/report.png',
                        label: 'Report',
                        onTap: () {},
                        showDivider: false,
                      ),
                    ],
                  );
                },
                child: Image.asset(
                  'assets/images/moments/more-btn.png',
                  width: 32,
                  height: 32,
                ),
              );
            },
          ),
        ),
      ],
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              physics: const BouncingScrollPhysics(),
              children: const [
                _MomentDetailHeader(
                  name: 'Warren',
                  time: '1 day ago',
                  subtitle:
                      'What kind of photos can a novice take after learning by himself for half a What kind of photos can a novice take after learning by himself for half',
                  avatar: 'assets/images/chat/avatar.png',
                  imagePaths: [
                    'assets/images/moments/moment1.png',
                    'assets/images/moments/moment1.png',
                    'assets/images/moments/moment1.png',
                    'assets/images/moments/moment1.png',
                    'assets/images/moments/moment1.png',
                    'assets/images/moments/moment1.png',
                  ],
                ),
                SizedBox(height: 16),
                Divider(color: AppColors.grey100, thickness: 1),
                _MomentCommentsSection(),
              ],
            ),
          ),
          const _CommentComposerBar(),
        ],
      ),
    );
  }
}

class _MomentDetailHeader extends StatelessWidget {
  final String name;
  final String time;
  final String subtitle;
  final String avatar;
  final List<String> imagePaths;

  const _MomentDetailHeader({
    required this.name,
    required this.time,
    required this.subtitle,
    required this.avatar,
    required this.imagePaths,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    context.push('/moment-user-profile');
                  },
                  child: _AvatarBadge(avatar: avatar),
                ),
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
            const _FollowButton(),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: AppTextStyles.body.copyWith(
            color: const Color(0xFF404040),
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        _DetailMediaGrid(imagePaths: imagePaths),
      ],
    );
  }
}

class _DetailMediaGrid extends StatelessWidget {
  final List<String> imagePaths;

  const _DetailMediaGrid({required this.imagePaths});

  @override
  Widget build(BuildContext context) {
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
        final itemSize =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

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
                    Image.asset(path, fit: BoxFit.cover),
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
}
class _MomentCommentsSection extends StatelessWidget {
  const _MomentCommentsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _CommentHeader(count: 12),
        SizedBox(height: 24),
        _CommentThread(
          parent: _MomentCommentItem(
            name: 'Warren',
            time: '19:00',
            content: 'One of the hottest spots in Myengdong right now!',
          ),
          replies: [
            _MomentCommentItem(
              name: 'Robert Fox (Me)',
              time: 'yesterday',
               content: 'reply text',
              leftInset: 38,
              showConnector: true,
            ),
            _MomentCommentItem(
              name: '测试',
              time: '17:00',
               content: '测试回复',
              leftInset: 38,
              showConnector: true,
            ),
          ],
          expandLabel: 'Expand 647 replies',
        ),
        SizedBox(height: 20),
        _CommentThread(
          parent: _MomentCommentItem(
            name: 'Warren',
            time: '19:00',
            content: '111',
          ),
          replies: [],
          expandLabel: '',
        ),
        SizedBox(height: 20),
        _CommentThread(
          parent: _MomentCommentItem(
            name: 'Warren',
            time: '19:00',
            content: '22222',
          ),
          replies: [],
          expandLabel: '',
        ),
      ],
    );
  }
}

class _CommentThread extends StatelessWidget {
  final _MomentCommentItem parent;
  final List<_MomentCommentItem> replies;
  final String expandLabel;

  const _CommentThread({
    required this.parent,
    required this.replies,
    required this.expandLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        parent,
        if (replies.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (int i = 0; i < replies.length; i++) ...[
            replies[i],
            if (i != replies.length - 1) const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 80),
            child: Text(
              expandLabel,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CommentHeader extends StatelessWidget {
  final int count;

  const _CommentHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset('assets/images/moments/comment.png', width: 20, height: 20),
        const SizedBox(width: 4),
        Text(
          'Comments',
          style: AppTextStyles.body.copyWith(
            color: AppColors.grey900,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: AppTextStyles.body.copyWith(
            color: AppColors.grey400,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MomentCommentItem extends StatelessWidget {
  final String name;
  final String time;
  final String content;
  final double leftInset;
  final bool showConnector;

  const _MomentCommentItem({
    required this.name,
    required this.time,
    required this.content,
    this.leftInset = 0,
    this.showConnector = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: leftInset),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showConnector) ...[
            Container(width: 2, height: 36, color: AppColors.grey100),
            const SizedBox(width: 10),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              'assets/images/chat/avatar.png',
              width: 24,
              height: 24,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.grey400,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.grey900,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.grey400,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentComposerBar extends StatelessWidget {
  const _CommentComposerBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.grey100, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.topBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const TextField(
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: 'Please Enter...',
                  hintStyle: TextStyle(
                    color: AppColors.grey400,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const _DetailActionIconTextButton(
            icon: 'assets/images/moments/like-active.png',
            text: '6',
          ),
          const SizedBox(width: 12),
          const _DetailActionIconTextButton(
            icon: 'assets/images/moments/collect-active.png',
            text: '6',
          ),
          const SizedBox(width: 12),
          const _DetailActionIconTextButton(
            icon: 'assets/images/moments/share.png',
            text: '1',
          ),
        ],
      ),
    );
  }
}

class _DetailActionIconTextButton extends StatelessWidget {
  final String icon;
  final String text;

  const _DetailActionIconTextButton({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(icon, width: 24, height: 24),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.grey900,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
  const _FollowButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.grey200, width: 1.5),
      ),
      child: Text(
        'Following',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.grey900,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
