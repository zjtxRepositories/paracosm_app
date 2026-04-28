import 'package:flutter/material.dart';

import '../../core/models/social_Invitation_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class CommentComposerBar extends StatefulWidget {
  final SocialInvitationModel model;

  final VoidCallback? onLike;
  final VoidCallback? onCollect;
  final VoidCallback? onShare;

  /// text, rootId, toUserId
  final Function(String, String, String?)? onSend;

  const CommentComposerBar({
    required this.model,
    this.onLike,
    this.onCollect,
    this.onShare,
    this.onSend,
    super.key,
  });

  @override
  State<CommentComposerBar> createState() => CommentComposerBarState();
}

class CommentComposerBarState extends State<CommentComposerBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  /// 回复相关状态
  String rootReviewId = '';
  String? toUserId;
  String hint = 'Please Enter...';

  /// =========================
  /// 外部调用：设置回复对象 + 弹起键盘
  /// =========================
  void setReply({
    required String rootId,
    required String toUserId,
    required String userName,
  }) {
    setState(() {
      rootReviewId = rootId;
      this.toUserId = toUserId;
      hint = 'Reply @$userName';
    });

    /// 弹起键盘
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  /// =========================
  /// 发送
  /// =========================
  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onSend?.call(text, rootReviewId, toUserId);

    _controller.clear();

    /// 重置状态
    setState(() {
      rootReviewId = '';
      toUserId = '';
      hint = 'Please Enter...';
    });
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTextChanged);
    _focusNode.addListener(_handleFocusChanged);
  }

  void _handleTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (_hasText == hasText) return;
    setState(() {
      _hasText = hasText;
    });
  }

  void _handleFocusChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _focusNode.removeListener(_handleFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final showSendButton = _focusNode.hasFocus || _hasText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.grey100)),
      ),
      child: Row(
        children: [
          /// 输入框
          Expanded(
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.topBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: 1,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  textAlignVertical: TextAlignVertical.center,
                  strutStyle: const StrutStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    forceStrutHeight: true,
                  ),
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.grey900,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 20 / 14,
                  ),
                  onSubmitted: (_) => _handleSend(),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: AppTextStyles.body.copyWith(
                      color: AppColors.grey400,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 20 / 14,
                    ),
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          if (showSendButton)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _hasText ? _handleSend : null,
              child: Opacity(
                opacity: _hasText ? 1 : 0.35,
                child: Image.asset(
                  'assets/images/chat/send.png',
                  width: 27,
                  height: 27,
                ),
              ),
            )
          else ...[
            /// 点赞
            GestureDetector(
              onTap: widget.onLike,
              child: _DetailActionIconTextButton(
                icon: model.isLike
                    ? 'assets/images/moments/like-active.png'
                    : 'assets/images/moments/like.png',
                text: '${model.likes}',
              ),
            ),

            const SizedBox(width: 12),

            /// 收藏
            GestureDetector(
              onTap: widget.onCollect,
              child: _DetailActionIconTextButton(
                icon: model.isCollect
                    ? 'assets/images/moments/collect-active.png'
                    : 'assets/images/moments/collect.png',
                text: '${model.collects}',
              ),
            ),

            const SizedBox(width: 12),

            /// 分享
            GestureDetector(
              onTap: widget.onShare,
              child: _DetailActionIconTextButton(
                icon: 'assets/images/moments/share.png',
                text: '${model.shares}',
              ),
            ),
          ],
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
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
