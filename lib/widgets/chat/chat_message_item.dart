import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/widgets/chat/chat_bubble_painters.dart';

class ChatMessageItem extends StatelessWidget {
  const ChatMessageItem({
    super.key,
    required this.isMe,
    required this.child,
    required this.onLongPressStart,
    this.isUnread = false,
    this.showBubble = true,
  });

  final bool isMe;
  final Widget child;
  final bool isUnread;
  final bool showBubble;
  final GestureLongPressStartCallback onLongPressStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) const _ChatMessageAvatar(),
          if (!isMe) const SizedBox(width: 12),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: GestureDetector(
                    onLongPressStart: onLongPressStart,
                    child: showBubble
                        ? CustomPaint(
                            painter: ChatBubblePainter(
                              color: isMe
                                  ? const Color(0xFFF1FADC)
                                  : Colors.white,
                              isMe: isMe,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: child,
                            ),
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
          ),
        ],
      ),
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
