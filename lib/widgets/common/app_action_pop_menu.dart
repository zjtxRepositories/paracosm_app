import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';

/// 菜单项配置模型
class AppActionPopMenuItem {
  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool showDivider;

  const AppActionPopMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showDivider = true,
  });
}

/// 右上角“+”按钮点击后的通用弹窗菜单
class AppActionPopMenu extends StatelessWidget {
  final List<AppActionPopMenuItem> items;
  final double width;

  const AppActionPopMenu({
    super.key,
    required this.items,
    this.width = 148,
  });

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
            width: width,
            decoration: BoxDecoration(
              color: AppColors.grey900, // 黑色背景
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isLast = index == items.length - 1;
                
                return _buildMenuItem(
                  icon: item.icon,
                  label: item.label,
                  onTap: item.onTap,
                  showDivider: item.showDivider && !isLast,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建菜单项内容
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
        padding: const EdgeInsets.only(left: 12, right: 8),
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

  /// 显示菜单的静态封装方法
  static void show(
    BuildContext context, {
    required GlobalKey buttonKey,
    required List<AppActionPopMenuItem> items,
    double width = 148,
    double rightOffset = 12,
  }) {
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
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          return Stack(
            children: [
              Positioned(
                top: offset.dy + renderBox.size.height +10,
                right: rightOffset,
                child: FadeTransition(
                  opacity: animation,
                  child: AppActionPopMenu(
                    items: items.map((item) => AppActionPopMenuItem(
                      icon: item.icon,
                      label: item.label,
                      onTap: () {
                        // 1. 立即关闭弹窗（使用弹窗自己的 context）
                        Navigator.of(dialogContext).pop();
                        // 2. 执行原有的业务逻辑
                        item.onTap();
                      },
                      showDivider: item.showDivider,
                    )).toList(),
                    width: width,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('Error showing action pop menu: $e');
    }
  }
}

/// 顶部小三角形绘制器
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
