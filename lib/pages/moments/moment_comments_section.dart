import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';

import '../../core/models/social_review_model.dart';
import '../../core/network/api/social_circle_note_api.dart';
import '../../theme/app_colors.dart';
import '../../util/string_util.dart';
import '../../widgets/base/app_localizations.dart';
import '../../widgets/common/app_loading.dart';
import '../../widgets/common/app_toast.dart';

class MomentCommentsSection extends StatefulWidget {
  final String noteId;
  final List<SocialReviewModel> reviews;
  final Function(String, String, String)? onReply;

  const MomentCommentsSection({
    required this.noteId,
    required this.reviews,
    this.onReply,
    super.key,
  });

  @override
  State<MomentCommentsSection> createState() => _MomentCommentsSectionState();
}

class _MomentCommentsSectionState extends State<MomentCommentsSection> {
  /// 已展开的评论 id
  final Set<String> _expanded = {};

  /// 评论点赞
  Future<void> toggleReviewLike(SocialReviewModel item) async {
    final nextIsLike = !item.isLike;
    AppLoading.show();
    final result = await SocialCircleNoteApi.socialCircleNoteReviewLikeToggle(
      widget.noteId,
      item.reviewId,
      nextIsLike,
    );
    AppLoading.dismiss();
    if (!result) {
      AppToast.show(AppLocalizations.currentText('moments_like_failed'));
      return;
    }
    item.isLike = nextIsLike;
    item.likes = nextIsLike
        ? item.likes + 1
        : (item.likes > 0 ? item.likes - 1 : 0);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CommentHeader(count: widget.reviews.length),
        const SizedBox(height: 20),

        if (widget.reviews.isEmpty)
          Text(
            AppLocalizations.of(context)!.translate('moments_no_comments_yet'),
            style: const TextStyle(color: AppColors.grey400),
          )
        else
          for (final c in widget.reviews) _buildThread(c),
      ],
    );
  }

  Widget _buildThread(SocialReviewModel c) {
    final id = c.reviewId;
    final replies = _flattenReplies(c);

    final isExpanded = _expanded.contains(id);

    /// ✅ 只显示前2条 or 全部
    final visibleReplies = isExpanded ? replies : replies.take(2).toList();

    /// ✅ 是否显示展开按钮
    final showExpand = replies.length > 2 && !isExpanded;

    return _CommentThread(
      parent: _MomentCommentItem(
        userId: c.userId,
        imUserId: c.userFullInfo?.userId ?? '',
        name: c.userFullInfo?.name ?? '',
        avatar: c.userFullInfo?.avatar ?? '',
        time: formatIMTime(c.timestamp),
        content: c.content,
        isLiked: c.isLike,
        likeCount: c.likes,
        onTap: () => widget.onReply?.call(
          c.reviewId,
          c.walletAddress,
          c.userFullInfo?.name ?? '',
        ),
        onLike: () => toggleReviewLike(c),
      ),

      replies: visibleReplies.map((r) {
        return _MomentCommentItem(
          userId: r.userId,
          imUserId: r.userFullInfo?.userId ?? '',
          name: _replyTitle(r),
          avatar: r.userFullInfo?.avatar ?? '',
          time: formatIMTime(r.timestamp),
          content: r.content,
          isLiked: r.isLike,
          likeCount: r.likes,
          leftInset: 38,
          showConnector: true,
          onTap: () => widget.onReply?.call(
            c.reviewId,
            r.walletAddress,
            r.userFullInfo?.name ?? '',
          ),
          onLike: () => toggleReviewLike(r),
        );
      }).toList(),

      expandLabel: showExpand
          ? AppLocalizations.of(context)!.translate('moments_expand_replies', {
              'count': replies.length - 2,
            })
          : '',

      onExpand: showExpand
          ? () {
              setState(() {
                _expanded.add(id);
              });
            }
          : null,
    );
  }

  List<SocialReviewModel> _flattenReplies(SocialReviewModel root) {
    final replies = <SocialReviewModel>[];

    void collect(List<SocialReviewModel>? items) {
      if (items == null) return;

      for (final item in items) {
        replies.add(item);
        collect(item.subReviews);
      }
    }

    collect(root.subReviews);
    return replies;
  }

  String _replyTitle(SocialReviewModel review) {
    final userName = review.userFullInfo?.name ?? '';
    final toUserName = review.toUserFullInfo?.name ?? '';

    if (userName.isEmpty && toUserName.isEmpty) return '';
    if (toUserName.isEmpty) return userName;
    if (userName.isEmpty) return '回复 $toUserName';
    return '$userName 回复 $toUserName';
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
          AppLocalizations.of(context)!.translate('moments_comments'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CommentThread extends StatelessWidget {
  final _MomentCommentItem parent;
  final List<_MomentCommentItem> replies;
  final String expandLabel;
  final VoidCallback? onExpand;

  const _CommentThread({
    required this.parent,
    required this.replies,
    required this.expandLabel,
    this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          parent,

          if (replies.isNotEmpty) ...[
            const SizedBox(height: 12),

            ...replies,

            if (expandLabel.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 80),
                child: GestureDetector(
                  onTap: onExpand,
                  child: Text(
                    expandLabel,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _MomentCommentItem extends StatelessWidget {
  final String userId;
  final String imUserId;
  final String name;
  final String avatar;
  final String time;
  final String content;
  final bool isLiked;
  final int likeCount;
  final double leftInset;
  final bool showConnector;
  final VoidCallback? onTap;
  final VoidCallback? onLike;

  const _MomentCommentItem({
    required this.userId,
    required this.imUserId,
    required this.name,
    required this.avatar,
    required this.time,
    required this.content,
    required this.isLiked,
    required this.likeCount,
    this.leftInset = 0,
    this.showConnector = false,
    this.onTap,
    this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: leftInset),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showConnector) ...[
              Container(width: 2, height: 36, color: AppColors.grey100),
              const SizedBox(width: 10),
            ],
            imUserId.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      context.push(
                        '/moment-user-profile',
                        extra: {'userId': userId},
                      );
                    },
                    child: UserAvatarWidget(
                      userId: imUserId,
                      avatarUrl: avatar,
                      size: 24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )
                : const SizedBox(),

            const SizedBox(width: 8),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.grey400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.grey400,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _CommentLikeButton(
                        icon: isLiked
                            ? 'assets/images/moments/like-active.png'
                            : 'assets/images/moments/like.png',
                        text: '$likeCount',
                        active: isLiked,
                        onTap: onLike,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentLikeButton extends StatelessWidget {
  final String icon;
  final String text;
  final bool active;
  final VoidCallback? onTap;

  const _CommentLikeButton({
    required this.icon,
    required this.text,
    required this.active,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(icon, width: 12, height: 12),
            const SizedBox(width: 3),
            Text(
              text,
              style: TextStyle(
                fontSize: 10,
                color: active ? AppColors.primaryDark : AppColors.grey400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
