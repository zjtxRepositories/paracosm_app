import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/chat/select_members_modal.dart';

/// 聊天页右上角“+”按钮点击后的弹窗菜单
class ChatActionPopMenu extends StatelessWidget {
  const ChatActionPopMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 顶部的小三角
          Padding(
            padding: const EdgeInsets.only(right: 25),
            child: CustomPaint(
              size: const Size(12, 6),
              painter: _TrianglePainter(),
            ),
          ),
          // 菜单主体
          Container(
            width: 148,
            decoration: BoxDecoration(
              color: AppColors.grey900, // 黑色背景
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                // BoxShadow(
                //   color: AppColors.grey900.withAlpha(0.5),
                //   blurRadius: 10,
                //   offset: const Offset(0, 4),
                // ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMenuItem(
                  icon: 'assets/images/chat/add-friend.png',
                  label: 'Add Friend',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: 跳转添加朋友
                  },
                  showDivider: true,
                ),
                _buildMenuItem(
                  icon: 'assets/images/chat/create-group.png',
                  label: 'Create Group',
                  onTap: () {
                    Navigator.pop(context);
                    SelectMembersModal.show(context);
                  },
                  showDivider: true,
                ),
                _buildMenuItem(
                  icon: 'assets/images/chat/scanner.png',
                  label: 'Scan',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: 跳转扫一扫
                  },
                  showDivider: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required String icon,
    required String label,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.only(left: 12,right: 8),
        child: Row(
          children: [
            Image.asset(icon, width: 20, height: 20),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 17),
                decoration: BoxDecoration(
                  border: showDivider
                      ? Border(
                          bottom: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                            width: 0.5,
                          ),
                        )
                      : null,
                ),
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示菜单的静态方法
  static void show(BuildContext context, GlobalKey? buttonKey) {
    if (buttonKey == null) return;
    
    try {
      final currentContext = buttonKey.currentContext;
      if (currentContext == null) return;
      
      final renderBox = currentContext.findRenderObject() as RenderBox?;
      if (renderBox == null) return;
      
      final offset = renderBox.localToGlobal(Offset.zero);
      
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: '',
        barrierColor: Colors.transparent,
        pageBuilder: (context, animation, secondaryAnimation) {
          return Stack(
            children: [
              Positioned(
                top: offset.dy + renderBox.size.height - 4,
                right: 12,
                child: FadeTransition(
                  opacity: animation,
                  child: const ChatActionPopMenu(),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('Error showing chat action pop menu: $e');
    }
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF171717)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
