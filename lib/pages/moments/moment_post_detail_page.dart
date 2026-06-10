import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/modules/im/listener/user_display_state_center.dart';
import 'package:paracosm/widgets/common/app_action_pop_menu.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import '../../core/models/moment_post_model.dart';
import '../../core/models/social_review_model.dart';
import '../../util/string_util.dart';
import '../../widgets/base/app_localizations.dart';
import '../../widgets/chat/user_avatar_widget.dart';
import 'comment_composer_bar.dart';
import 'home/moments_controller.dart';
import 'moment_comments_section.dart';
import 'moment_post_card.dart';

class MomentPostDetailPage extends StatefulWidget {
  final MomentPostModel item;
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
  late MomentPostModel model;
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
    resolveReviewInfo();
  }

  Future<void> resolveReviewInfo() async {
    // 并发处理所有 reviewInfo
    await Future.wait(model.item.reviewInfo.map(_resolveSingleReviewInfo));
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _resolveSingleReviewInfo(SocialReviewModel info) async {
    final subReviews = info.subReviews ?? const <SocialReviewModel>[];
    await Future.wait([
      Future.wait([
        UserDisplayStateCenter().getUser(info.userId),
        UserDisplayStateCenter().getUser(info.toUserId),
      ]).then((displayResults) {
        info.userFullInfo = displayResults[0];
        info.toUserFullInfo = displayResults[1];
      }),
      ...subReviews.map(_resolveSingleReviewInfo),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final moreButtonKey = GlobalKey();
    final l10n = AppLocalizations.of(context)!;
    return AppPage(
      title: l10n.translate('moments_post_body_title'),
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
                    label: l10n.translate('moments_share'),
                    onTap: () => controller.toggleShare(model.item, context),
                  ),
                  AppActionPopMenuItem(
                    icon: 'assets/images/moments/block.png',
                    label: isBlock
                        ? l10n.translate('moments_unblock_this_user')
                        : l10n.translate('moments_block_this_user'),
                    onTap: () => controller.toggleBlock(model.item),
                  ),
                  AppActionPopMenuItem(
                    icon: 'assets/images/moments/report.png',
                    label: l10n.translate('moments_report'),
                    onTap: () => controller.toggleReport(model.item, context),
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
                  onFollow: () => controller.toggleFollow(model.item),
                ),

                const SizedBox(height: 12),

                Text(
                  model.item.content,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF404040),
                  ),
                ),

                const SizedBox(height: 16),
                ImageGrid(
                  medias: model.item.media,
                  onTap: (index) =>
                      controller.toggleMedia(model.item.media, index, context),
                ),

                const SizedBox(height: 16),
                const Divider(color: AppColors.grey100),
                const SizedBox(height: 16),

                MomentCommentsSection(
                  noteId: model.item.noteId,
                  reviews: model.item.reviewInfo,
                  onReply: (reviewId, toUserId, userName) {
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
            model: model.item,
            onLike: () async {
              await controller.toggleLike(model.item);
              if (!mounted) return;
              setState(() {});
            },
            onCollect: () async {
              await controller.toggleCollect(model.item);
              if (!mounted) return;
              setState(() {});
            },
            onShare: () => controller.toggleShare(model.item, context),
            onSend: (text, rootReviewId, toUserId) async {
              final newModel = await controller.sendComment(
                model.item,
                text,
                rootReviewId,
                model.item.noteId,
                toUserId ?? model.item.walletAddress,
              );
              setState(() {
                model.item = newModel;
                resolveReviewInfo();
              });
            },
          ),
        ],
      ),
    );
  }
}

class _MomentDetailHeader extends StatelessWidget {
  final MomentPostModel model;
  final bool isFollowing;
  final VoidCallback? onFollow;

  const _MomentDetailHeader({
    required this.model,
    required this.isFollowing,
    this.onFollow,
  });

  String get _avatarUrl {
    return model.user?.avatar ?? '';
  }

  String get _displayName {
    return model.user?.name ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                context.push(
                  '/moment-user-profile',
                  extra: {
                    'userId': model.item.userId,
                    'imUserId': model.user?.userId,
                  },
                );
              },
              child: UserAvatarWidget(
                userId: model.user?.userId,
                avatarUrl: _avatarUrl,
                size: 36,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  formatIMTime(model.item.timestamp),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.grey400,
                  ),
                ),
              ],
            ),
          ],
        ),

        FollowButton(isFollowing: isFollowing, onTap: onFollow),
      ],
    );
  }
}
