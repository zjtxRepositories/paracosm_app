import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';

/// 聊天列表项组件 (支持单聊和群聊)
class ChatListItem extends StatefulWidget {
  final String title;
  final String subtitle;
  final String time;
  final int unreadCount;
  final List<String>? avatars; // 如果是群聊，传入多个头像 URL
  final bool isMuted;
  final VoidCallback? onTap;

  const ChatListItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
    this.unreadCount = 0,
    this.avatars,
    this.isMuted = false,
    this.onTap,
  });

  @override
  State<ChatListItem> createState() => _ChatListItemState();
}

class _ChatListItemState extends State<ChatListItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  double _dragExtent = 0;
  final double _actionWidth = 144.0; // 展开后的总位移距离
  bool _isPinned = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-144.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
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
        // 背景层：操作按钮
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final value = _controller.value;
              return Stack(
                children: [
                  // 置顶按钮 (现在在右侧，被覆盖在下层)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Transform.translate(
                      offset: Offset((1 - value) * 88, 0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isPinned = !_isPinned;
                          });
                          _close();
                        },
                        child: Container(
                          width: 88,
                          decoration: BoxDecoration(
                            color: AppColors.topBg, // 浅灰色背景
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Image.asset(
                              _isPinned ? 'assets/images/chat/top-off.png' : 'assets/images/chat/top.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 删除按钮 (现在在左侧，覆盖在置顶按钮上)
                  Positioned(
                    right: 70, // 与置顶按钮产生重叠
                    top: 0,
                    bottom: 0,
                    child: Transform.translate(
                      offset: Offset((1 - value) * 144, 0),
                      child: GestureDetector(
                        onTap: () {
                          _close();
                          // TODO: 删除逻辑预留
                        },
                        child: Container(
                          width: 88,
                          decoration: BoxDecoration(
                            color: AppColors.deleteBg, // 浅红色背景
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
        // 前景层：内容主体
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
                  // 头像部分
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildAvatar(),
                  ),
                  const SizedBox(width: 12),
                  // 内容部分
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    widget.title,
                                    style: AppTextStyles.h2.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (widget.isMuted) ...[
                                    const SizedBox(width: 4),
                                    Image.asset('assets/images/chat/notifications-off.png', width: 14, height: 14),
                                  ],
                                ],
                              ),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  constraints: const BoxConstraints(minWidth: 18),
                                  child: Text(
                                    widget.unreadCount > 99 ? '99+' : widget.unreadCount.toString(),
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
    final avatars = widget.avatars;
    if (avatars == null || avatars.isEmpty) {
      // 默认头像
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.person, color: AppColors.grey400),
      );
    }

    if (avatars!.length == 1) {
      // 单个头像
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: AssetImage(avatars![0]),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // 群聊头像 (2x2 网格)
    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
        ),
        itemCount: avatars!.length > 4 ? 4 : avatars!.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Image.asset(
              avatars![index],
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}
