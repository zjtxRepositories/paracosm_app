import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/base/app_page.dart';
import '../moment_post_card.dart';
import 'moments_controller.dart';

class MomentsPage extends StatefulWidget {
  const MomentsPage({super.key});

  @override
  State<MomentsPage> createState() => _MomentsPageState();
}

class _MomentsPageState extends State<MomentsPage> {
  final MomentsController controller = MomentsController();

  @override
  void initState() {
    super.initState();
    controller.init();
    controller.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_onUpdate);
    controller.dispose();
    super.dispose();
  }

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
            _buildStories(),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                itemCount: controller.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = controller.items[index];
                  return MomentPostCard(
                    model: item,
                    isFollowing: controller.followIds.contains(item.userId),
                    isBlock:controller.blockIds.contains(item.userId),
                    onLike: () => controller.toggleLike(item),
                    onCollect: () => controller.toggleCollect(item),
                    onShare: () => controller.toggleShare(item,context),
                    onFollow: () => controller.toggleFollow(item),
                    onBlock: () => controller.toggleBlock(item),
                    onReport: () => controller.toggleReport(item,context),
                    onTap: () => context.push('/moment-post-detail',extra: {
                      'item': item,
                      'isFollowing': controller.followIds.contains(item.userId),
                      'isBlock': controller.blockIds.contains(item.userId),
                    },),
                  );
                },
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

          _MessageButton(
            onTap: () {
              context.push('/message-center');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStories() {
    final stories = controller.stories;
    if (stories.isEmpty) return SizedBox();
    return Column(
      children: [
        SizedBox(
          height: 78,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return GestureDetector(
                child: _StoryAvatar(story: stories[index]),
                onTap: (){
                  if (!stories[index].showAddBadge){
                    context.push('/new-post?retweet=1');
                    return;
                  }
                },
              );
            },
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemCount: stories.length,
          ),
        ),
      ],
    );

  }

}
class _MessageButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MessageButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Image.asset(
        'assets/images/moments/has-msg.png',
        width: 32,
        height: 32,
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  final StoryData story;
  final VoidCallback? onTap;

  const _StoryAvatar({
    required this.story,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: story.outsideColor,
              width: 2,
            ),
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
                      border: Border.all(
                        color: story.insideColor,
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: ClipOval(
                        child: Image.asset(
                          story.avatar,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),

                /// + icon（完全不动）
                if (story.showPlusIcon)
                  const Center(
                    child: Icon(
                      Icons.add,
                      size: 18,
                      color: AppColors.grey600,
                    ),
                  ),

                /// add badge（完全不动）
                if (story.showAddBadge)
                  Positioned(
                    right: -1,
                    bottom: -5,
                    child: Image.asset(
                      'assets/images/moments/add.png',
                      width: 18,
                      height: 18,
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
