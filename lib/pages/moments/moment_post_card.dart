import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:paracosm/core/network/models/social_Invitation_model.dart';
import 'package:paracosm/core/util/string_util.dart';
import '../../core/network/models/social_media_model.dart';
import '../../widgets/common/app_action_pop_menu.dart';

class MomentPostCard extends StatelessWidget {
  final SocialInvitationModel model;
  final bool isFollowing;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onCollect;
  final VoidCallback? onShare;
  final VoidCallback? onFollow;

  const MomentPostCard({
    super.key,
    required this.model,
    required this.isFollowing,
    this.onTap,
    this.onLike,
    this.onCollect,
    this.onShare,
    this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              model: model,
              isFollowing: isFollowing,
              onFollow: onFollow,
              onShare: onShare,
            ),

            const SizedBox(height: 16),
            /// 内容
            Text(
              model.content,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF404040),
              ),
            ),

            const SizedBox(height: 8),

            /// 图片
            _ImageGrid(medias: model.media),

            const SizedBox(height: 12),

            /// 操作栏
            _PostActionBar(
              model: model,
              onLike: onLike,
              onCollect: onCollect,
              onShare: onShare,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final SocialInvitationModel model;
  final bool isFollowing;
  final VoidCallback? onFollow;
  final VoidCallback? onShare;

  const _Header({
    required this.model,
    required this.isFollowing,
    this.onFollow,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _Avatar(url: model.userInfoModel?.avatar ?? ''),
            const SizedBox(width: 8),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.userInfoModel?.nickname ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatTime(model.timestamp),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),

        Row(
          children: [
            GestureDetector(
              onTap: onFollow,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isFollowing ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(28),
                  border: isFollowing
                      ? Border.all(color: Colors.grey.shade300)
                      : null,
                ),
                child: Text(
                  isFollowing ? 'Following' : 'Follow',
                  style: TextStyle(
                    fontSize: 12,
                    color: isFollowing ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
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
                          onTap: onShare ?? (){},
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
    );
  }


  String _formatTime(int time) {
    return formatTimeAgo(time);
  }

}

class _ImageGrid extends StatelessWidget {
  final List<SocialMediaModel> medias;
  final double spacing;

  const _ImageGrid({
    required this.medias,
    this.spacing = 4,
  });

  @override
  Widget build(BuildContext context) {
    if (medias.isEmpty) return const SizedBox.shrink();

    final count = medias.length;
    final hasMore = count > 9;
    final visibleCount = hasMore ? 9 : count;
    final hiddenCount = count - 9;

    final columns = count == 1
        ? 1
        : (count <= 4 ? 2 : 3);

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemSize =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(visibleCount, (index) {
            final image = medias[index];
            final isLast = index == visibleCount - 1;
            final showOverlay = hasMore && isLast;

            return SizedBox(
              width: itemSize,
              height: itemSize,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      image.url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFF2F2F2),
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),

                    if (showOverlay)
                      Container(
                        color: Colors.black.withOpacity(0.5),
                        alignment: Alignment.center,
                        child: Text(
                          '+$hiddenCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
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

class _PostActionBar extends StatelessWidget {
  final SocialInvitationModel model;
  final VoidCallback? onLike;
  final VoidCallback? onCollect;
  final VoidCallback? onShare;

  const _PostActionBar({
    required this.model,
    this.onLike,
    this.onCollect,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Item(
          icon: 'assets/images/moments/like.png',
          text: '${model.likes}',
          onTap: onLike,
        ),
        const SizedBox(width: 24),

        _Item(
          icon: 'assets/images/moments/collect.png',
          text: '${model.collects}',
          onTap: onCollect,
        ),
        const SizedBox(width: 24),

        _Item(
          icon: 'assets/images/moments/comment.png',
          text: '${model.reviewInfo.length}',
        ),

        const Spacer(),

        _Item(
          icon: 'assets/images/moments/share.png',
          text: '0',
          onTap: onShare,
        ),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  final String icon;
  final String text;
  final VoidCallback? onTap;

  const _Item({
    required this.icon,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: [
            Image.asset(icon, width: 16, height: 16),
            const SizedBox(width: 4),
            Text(text, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final double size;
  final double radius;

  const _Avatar({
    this.url,
    this.size = 36,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: _buildImage(),
    );
  }

  Widget _buildImage() {
    if (url == null || url!.isEmpty) {
      return _placeholder();
    }

    return Image.network(
      url!,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      color: const Color(0xFFF2F2F2),
      child: Icon(
        Icons.person,
        size: size * 0.5,
        color: const Color(0xFFCCCCCC),
      ),
    );
  }
}