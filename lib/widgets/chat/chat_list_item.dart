import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';

import 'group_avatar_widget.dart';

/// 聊天列表项组件 (支持单聊和群聊)
class ChatListItem extends StatefulWidget {
  final String title;
  final String subtitle;
  final String time;
  final int unreadCount;
  final bool isMuted;
  final bool isPinned;
  final bool isGroup;
  final String? avatar;
  final String? targetId;
  final VoidCallback? onTap;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onPinTap;
  final VoidCallback? onDeleteTap;

  const ChatListItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isGroup,
    required this.isPinned,
    this.unreadCount = 0,
    this.isMuted = false,
    this.avatar,
    this.targetId,
    this.onTap,
    this.onAvatarTap,
    this.onPinTap,
    this.onDeleteTap,
  });

  @override
  State<ChatListItem> createState() => _ChatListItemState();
}

class _ChatListItemState extends State<ChatListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragExtent = 0;
  final double _actionWidth = 144.0;
  bool _isPinned = false;

  @override
  void initState() {
    super.initState();
    _isPinned = widget.isPinned;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void didUpdateWidget(covariant ChatListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPinned != widget.isPinned) {
      _isPinned = widget.isPinned;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.primaryDelta!;
      if (_dragExtent > 0) _dragExtent = 0;
      if (_dragExtent < -_actionWidth) _dragExtent = -_actionWidth;
      _controller.value = -_dragExtent / _actionWidth;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragExtent < -_actionWidth / 2 || details.primaryVelocity! < -300) {
      _open();
    } else {
      _close();
    }
  }

  void _open() {
    _controller.forward();
    setState(() {
      _dragExtent = -_actionWidth;
    });
  }

  void _close() {
    _controller.reverse();
    setState(() {
      _dragExtent = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final value = _controller.value;
              return Stack(
                children: [
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Transform.translate(
                      offset: Offset((1 - value) * 88, 0),
                      child: GestureDetector(
                        onTap: () {
                          widget.onPinTap?.call();
                          _close();
                        },
                        child: Container(
                          width: 88,
                          decoration: BoxDecoration(
                            color: AppColors.topBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Image.asset(
                              _isPinned
                                  ? 'assets/images/chat/top-off.png'
                                  : 'assets/images/chat/top.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 70,
                    top: 0,
                    bottom: 0,
                    child: Transform.translate(
                      offset: Offset((1 - value) * 144, 0),
                      child: GestureDetector(
                        onTap: () {
                          widget.onDeleteTap?.call();
                          _close();
                        },
                        child: Container(
                          width: 88,
                          decoration: BoxDecoration(
                            color: AppColors.deleteBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/images/chat/delete.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_controller.value * -_actionWidth, 0),
              child: child,
            );
          },
          child: GestureDetector(
            onTap: widget.onTap,
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.only(left: 20, top: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: widget.onAvatarTap,
                      behavior: HitTestBehavior.opaque,
                      child: _buildAvatar(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(right: 20, bottom: 16),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.grey100,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.title,
                                        style: AppTextStyles.h2.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (widget.isPinned) ...[
                                      const SizedBox(width: 4),
                                      Image.asset(
                                        'assets/images/chat/top.png',
                                        width: 14,
                                        height: 14,
                                      ),
                                    ],
                                    if (widget.isMuted) ...[
                                      const SizedBox(width: 4),
                                      Image.asset(
                                        'assets/images/chat/notifications-off.png',
                                        width: 14,
                                        height: 14,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.time,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.grey400,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.subtitle,
                                  style: AppTextStyles.caption.copyWith(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.unreadCount > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                  ),
                                  child: Text(
                                    widget.unreadCount > 99
                                        ? '99+'
                                        : widget.unreadCount.toString(),
                                    style: AppTextStyles.overline.copyWith(
                                      color: AppColors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    if (widget.isGroup) {
      return GroupAvatarWidget(
        groupId: widget.targetId ?? '',
        portraitUri: widget.avatar,
        size: 44,
      );
    }

    return UserAvatarWidget(
      userId: widget.targetId,
      avatarUrl: widget.avatar,
      size: 44,
      borderRadius: BorderRadius.circular(10),
    );
  }
}
