import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/models/social_review_model.dart';
import '../../theme/app_colors.dart';
import '../../util/string_util.dart';

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
  State<MomentCommentsSection> createState() =>
      _MomentCommentsSectionState();
}

class _MomentCommentsSectionState extends State<MomentCommentsSection> {
  /// 已展开的评论 id
  final Set<String> _expanded = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CommentHeader(count: widget.reviews.length),
        const SizedBox(height: 20),

        if (widget.reviews.isEmpty)
          const Text(
            "No comments yet",
            style: TextStyle(color: AppColors.grey400),
          )
        else
          for (final c in widget.reviews)
            _buildThread(c),
      ],
    );
  }

  Widget _buildThread(SocialReviewModel c) {
    final id = c.reviewId;
    final replies = c.subReviews ?? [];

    final isExpanded = _expanded.contains(id);

    /// ✅ 只显示前2条 or 全部
    final visibleReplies =
    isExpanded ? replies : replies.take(2).toList();

    /// ✅ 是否显示展开按钮
    final showExpand = replies.length > 2 && !isExpanded;

    return _CommentThread(
      parent: _MomentCommentItem(
        name: c.userFullInfo?.nickname ?? '',
        time: formatIMTime(c.timestamp),
        content: c.content,
        onTap: ()=> widget.onReply?.call(c.reviewId,c.userId,c.userFullInfo?.nickname ?? ''),
      ),

      replies: visibleReplies.map((r) {
        return _MomentCommentItem(
          name: r.userFullInfo?.nickname ?? '',
          time: formatIMTime(r.timestamp),
          content: r.content,
          leftInset: 38,
          showConnector: true,
          onTap: ()=> widget.onReply?.call(r.reviewId,r.userId,r.userFullInfo?.nickname ?? ''),
        );
      }).toList(),

      expandLabel:
      showExpand ? 'Expand ${replies.length - 2} replies' : '',

      onExpand: showExpand
          ? () {
        setState(() {
          _expanded.add(id);
        });
      }
          : null,
    );
  }
}

class _CommentHeader extends StatelessWidget {
  final int count;

  const _CommentHeader({
    required this.count,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/images/moments/comment.png',
          width: 20,
          height: 20,
        ),
        const SizedBox(width: 4),
        const Text(
          'Comments',
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
  final String name;
  final String time;
  final String content;
  final double leftInset;
  final bool showConnector;
  final VoidCallback? onTap;


  const _MomentCommentItem({
    required this.name,
    required this.time,
    required this.content,
    this.leftInset = 0,
    this.showConnector = false,
    this.onTap,
    super.key,
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
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.grey400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )
    );
  }
}