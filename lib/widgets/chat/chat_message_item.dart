import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/chat/chat_bubble_painters.dart';

class ChatMessageItem extends StatelessWidget {
  const ChatMessageItem({
    super.key,
    required this.isMe,
    required this.child,
    required this.onLongPressStart,
    this.isUnread = false,
    this.showBubble = true,
    this.isFlashing = false,
    this.readReceiptText,
  });

  final bool isMe;
  final Widget child;
  final bool isUnread;
  final bool showBubble;
  final bool isFlashing;
  final String? readReceiptText;
  final GestureLongPressStartCallback onLongPressStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe) const _ChatMessageAvatar(),
          if (!isMe) const SizedBox(width: 12),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onLongPressStart: onLongPressStart,
                        child: showBubble
                            ? _FlashingChatBubble(
                                isMe: isMe,
                                isFlashing: isFlashing,
                                child: child,
                              )
                            : child,
                      ),
                    ),
                    if (isUnread) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                if (isMe && readReceiptText != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    readReceiptText!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.grey400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlashingChatBubble extends StatelessWidget {
  const _FlashingChatBubble({
    required this.isMe,
    required this.isFlashing,
    required this.child,
  });

  final bool isMe;
  final bool isFlashing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final baseColor = isMe ? const Color(0xFFF1FADC) : Colors.white;
    final flashColor = isMe ? const Color(0xFFE4FF8A) : const Color(0xFFEDEDED);

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(
        begin: baseColor,
        end: isFlashing ? flashColor : baseColor,
      ),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, color, child) {
        return CustomPaint(
          painter: ChatBubblePainter(color: color ?? baseColor, isMe: isMe),
          child: Padding(padding: const EdgeInsets.all(10), child: child),
        );
      },
      child: child,
    );
  }
}

class _ChatMessageAvatar extends StatelessWidget {
  const _ChatMessageAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        image: const DecorationImage(
          image: AssetImage('assets/images/chat/avatar.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
