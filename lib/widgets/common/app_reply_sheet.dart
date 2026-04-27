import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';

/// 通用回复弹框。
///
/// 适合用于动态详情、社区详情等场景：
/// - 上半部分放帖子预览或评论列表
/// - 下半部分放输入栏
/// - 默认使用 common 目录中的 dictation / emoji 图标
class AppReplySheet extends StatefulWidget {
  final Widget? child;
  final String hintText;
  final String? initialText;
  final Widget? titleWidget;
  final String? title;
  final bool showDragHandle;
  final bool showVoiceButton;
  final bool showEmojiButton;
  final bool showBottomAccessoryBar;
  final bool readOnly;
  final VoidCallback? onVoiceTap;
  final VoidCallback? onEmojiTap;
  final VoidCallback? onBottomVoiceTap;
  final VoidCallback? onBottomEmojiTap;
  final Future<void> Function(String text)? onSend;
  final String sendIconAsset;
  final String voiceIconAsset;
  final String emojiIconAsset;
  final String bottomVoiceIconAsset;
  final String bottomEmojiIconAsset;
  final bool useRootNavigator;

  const AppReplySheet({
    super.key,
    this.child,
    this.hintText = '',
    this.initialText,
    this.titleWidget,
    this.title,
    this.showDragHandle = false,
    this.showVoiceButton = true,
    this.showEmojiButton = true,
    this.showBottomAccessoryBar = false,
    this.readOnly = false,
    this.onVoiceTap,
    this.onEmojiTap,
    this.onBottomVoiceTap,
    this.onBottomEmojiTap,
    this.onSend,
    this.sendIconAsset = 'assets/images/chat/send.png',
    this.voiceIconAsset = 'assets/images/common/dictation.png',
    this.emojiIconAsset = 'assets/images/chat/emoj.png',
    this.bottomVoiceIconAsset = 'assets/images/common/dictation.png',
    this.bottomEmojiIconAsset = 'assets/images/common/emoji.png',
    this.useRootNavigator = true,
  });

  /// 显示通用回复弹框。
  static Future<T?> show<T>(
    BuildContext context, {
    Widget? child,
    String hintText = '',
    String? initialText,
    Widget? titleWidget,
    String? title,
    bool showDragHandle = false,
    bool showVoiceButton = true,
    bool showEmojiButton = true,
    bool showBottomAccessoryBar = false,
    bool readOnly = false,
    VoidCallback? onVoiceTap,
    VoidCallback? onEmojiTap,
    VoidCallback? onBottomVoiceTap,
    VoidCallback? onBottomEmojiTap,
    Future<void> Function(String text)? onSend,
    String sendIconAsset = 'assets/images/chat/send.png',
    String voiceIconAsset = 'assets/images/common/dictation.png',
    String emojiIconAsset = 'assets/images/chat/emoj.png',
    String bottomVoiceIconAsset = 'assets/images/common/dictation.png',
    String bottomEmojiIconAsset = 'assets/images/common/emoji.png',
    bool useRootNavigator = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AppReplySheet(
        hintText: hintText,
        initialText: initialText,
        titleWidget: titleWidget,
        title: title,
        showDragHandle: showDragHandle,
        showVoiceButton: showVoiceButton,
        showEmojiButton: showEmojiButton,
        showBottomAccessoryBar: showBottomAccessoryBar,
        readOnly: readOnly,
        onVoiceTap: onVoiceTap,
        onEmojiTap: onEmojiTap,
        onBottomVoiceTap: onBottomVoiceTap,
        onBottomEmojiTap: onBottomEmojiTap,
        onSend: onSend,
        sendIconAsset: sendIconAsset,
        voiceIconAsset: voiceIconAsset,
        emojiIconAsset: emojiIconAsset,
        bottomVoiceIconAsset: bottomVoiceIconAsset,
        bottomEmojiIconAsset: bottomEmojiIconAsset,
        useRootNavigator: useRootNavigator,
        child: child,
      ),
    );
  }

  @override
  State<AppReplySheet> createState() => _AppReplySheetState();
}

class _AppReplySheetState extends State<AppReplySheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isInputEmpty = true;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
    _focusNode = FocusNode();
    _isInputEmpty = _controller.text.trim().isEmpty;
    _controller.addListener(_handleTextChanged);
    _focusNode.addListener(_handleFocusChanged);

    // 弹出后自动聚焦，方便直接输入，符合回复弹框的交互预期。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !widget.readOnly) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _focusNode.removeListener(_handleFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    final nextIsEmpty = _controller.text.trim().isEmpty;
    if (nextIsEmpty == _isInputEmpty) {
      return;
    }

    setState(() {
      _isInputEmpty = nextIsEmpty;
    });
  }

  void _handleFocusChanged() {
    if (!mounted) {
      return;
    }

    final nextHasFocus = _focusNode.hasFocus;
    if (nextHasFocus == _hasFocus) {
      return;
    }

    setState(() {
      _hasFocus = nextHasFocus;
    });
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    final onSend = widget.onSend;
    if (onSend != null) {
      await onSend(text);
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final hasBody = widget.child != null;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.86;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: hasBody ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.showDragHandle) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.grey200,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (widget.title != null || widget.titleWidget != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: widget.titleWidget ??
                              Text(
                                widget.title!,
                                style: AppTextStyles.h2.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.grey900,
                                ),
                              ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          behavior: HitTestBehavior.opaque,
                          child: const Icon(
                            Icons.close,
                            size: 24,
                            color: AppColors.grey900,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.title != null || widget.titleWidget != null) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1, thickness: 1, color: AppColors.grey100),
                ],
                if (hasBody)
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: widget.child!,
                    ),
                  ),
                _buildComposer(safeBottom),
                if (widget.showBottomAccessoryBar) _buildBottomAccessoryBar(safeBottom),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComposer(double safeBottom) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + safeBottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.grey100, width: 1)),
      ),
      child: Row(
        children: [
          if (widget.showVoiceButton) ...[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onVoiceTap,
              child: Image.asset(
                widget.voiceIconAsset,
                width: 27,
                height: 27,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _hasFocus ? AppColors.grey900 : AppColors.grey200,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                readOnly: widget.readOnly,
                showCursor: !widget.readOnly,
                maxLines: 1,
                strutStyle: const StrutStyle(
                  fontSize: 14,
                  height: 1.0,
                  forceStrutHeight: true,
                ),
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: AppTextStyles.body.copyWith(
                    color: AppColors.grey400,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: AppTextStyles.body.copyWith(
                  color: AppColors.grey900,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (widget.showEmojiButton)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onEmojiTap,
              child: Image.asset(
                widget.emojiIconAsset,
                width: 27,
                height: 27,
              ),
            )
          else
            const SizedBox(width: 27, height: 27),
          const SizedBox(width: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _isInputEmpty ? null : _handleSend,
            child: Image.asset(
              widget.sendIconAsset,
              width: 27,
              height: 27,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAccessoryBar(double safeBottom) {
    return Container(
      padding: EdgeInsets.fromLTRB(31, 10, 31, 10 + safeBottom),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onBottomEmojiTap ?? widget.onEmojiTap,
            child: Image.asset(
              widget.bottomEmojiIconAsset,
              width: 27,
              height: 27,
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onBottomVoiceTap ?? widget.onVoiceTap,
            child: Image.asset(
              widget.bottomVoiceIconAsset,
              width: 27,
              height: 27,
            ),
          ),
        ],
      ),
    );
  }
}
