import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:k_chart_plus/k_chart_plus.dart';
import 'package:paracosm/core/network/models/social_Invitation_model.dart';
import 'package:paracosm/widgets/common/app_action_pop_menu.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import '../../util/string_util.dart';
import 'comment_composer_bar.dart';
import 'home/moments_controller.dart';
import 'moment_comments_section.dart';
import 'moment_post_card.dart';

class MomentPostDetailPage extends StatefulWidget {
  final SocialInvitationModel item;
  final bool isFollowing;
  final bool isBlock;

  const MomentPostDetailPage({
    super.key,
    required this.item,
    required this.isFollowing,
    required this.isBlock,
  });

  @override
  State<MomentPostDetailPage> createState() => _MomentPostDetailPageState();
}

class _MomentPostDetailPageState extends State<MomentPostDetailPage> {
  late SocialInvitationModel model;
  late bool isFollowing;
  late bool isBlock;
  final MomentsController controller = MomentsController();
  final GlobalKey<CommentComposerBarState> inputKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    model = widget.item;
    isFollowing = widget.isFollowing;
    isBlock = widget.isBlock;
  }

  @override
  Widget build(BuildContext context) {
    final moreButtonKey = GlobalKey();

    return AppPage(
      title: 'Post',
      backgroundColor: Colors.white,
      navBackgroundColor: Colors.white,
      showNavBorder: true,
      headerActions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: GestureDetector(
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
                    onTap: () => controller.toggleShare(model,context),
                  ),
                  AppActionPopMenuItem(
                    icon: 'assets/images/moments/block.png',
                    label: 'Block this user',
                    onTap: () => controller.toggleBlock(model),
                  ),
                  AppActionPopMenuItem(
                    icon: 'assets/images/moments/report.png',
                    label: isBlock ? 'Unblock this use' : 'Block this user',
                    onTap: () => controller.toggleReport(model,context),
                    showDivider: false,
                  ),
                ],
              );
            },
            child: Image.asset(
              'assets/images/moments/more.png',
              width: 32,
              height: 32,
            ),
          ),
        ),
      ],
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              physics: const BouncingScrollPhysics(),
              children: [
                _MomentDetailHeader(
                  model: model,
                  isFollowing: isFollowing,
                  onFollow: ()=> controller.toggleFollow(model),
                ),

                const SizedBox(height: 12),

                Text(
                  model.content,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF404040),
                  ),
                ),

                const SizedBox(height: 16),
                ImageGrid(
                  medias: model.media,
                  onTap:(index) => controller.toggleMedia(model.media, index,context),
                ),

                const SizedBox(height: 16),
                const Divider(color: AppColors.grey100),
                const SizedBox(height: 16),

                MomentCommentsSection(
                  noteId: model.noteId,
                  reviews: model.reviewInfo,
                  onReply: (reviewId, toUserId, userName){
                    inputKey.currentState?.setReply(
                      rootId: reviewId,
                      toUserId: toUserId,
                      userName: userName,
                    );
                  },
                ),
              ],
            ),
          ),
          CommentComposerBar(
            key: inputKey,
            model: model,
            onLike: () => controller.toggleLike(model),
            onCollect: () => controller.toggleCollect(model),
            onShare: () => controller.toggleShare(model, context),
            onSend: (text, rootReviewId, toUserId) async {
              final newModel = await controller.sendComment(model, text, rootReviewId, model.noteId, toUserId ?? model.userId);
              setState(() {
                model = newModel;
              });
            },
          ),
        ],
      ),
    );
  }
}

class _MomentDetailHeader extends StatelessWidget {
  final SocialInvitationModel model;
  final bool isFollowing;
  final VoidCallback? onFollow;

  const _MomentDetailHeader({
    required this.model,
    required this.isFollowing,
    this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                context.push('/moment-user-profile');
              },
              child:Avatar(url: model.userInfoModel?.avatar ?? ''),

            ),
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
                  formatTimeAgo(model.timestamp),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.grey400,
                  ),
                ),
              ],
            ),
          ],
        ),

        FollowButton(isFollowing: isFollowing,onTap: onFollow),
      ],
    );
  }
}
