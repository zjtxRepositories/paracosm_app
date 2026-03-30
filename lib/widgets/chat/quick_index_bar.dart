import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';

/// 通用的快捷导航索引栏组件
class QuickIndexBar extends StatefulWidget {
  final List<String> letters;
  final Function(String) onLetterSelected;

  const QuickIndexBar({
    super.key,
    required this.letters,
    required this.onLetterSelected,
  });

  @override
  State<QuickIndexBar> createState() => _QuickIndexBarState();
}

class _QuickIndexBarState extends State<QuickIndexBar> {
  String? _selectedLetter;
  double _overlayY = 0;

  void _handleTap(Offset localPosition) {
    // 字母高度 18，顶部 padding 20
    final relativeY = localPosition.dy - 20.0;
    final index = (relativeY / 18.0).floor();

    if (index >= 0 && index < widget.letters.length) {
      final letter = widget.letters[index];
      
      // 直接使用 localPosition 计算气泡位置，气泡高度 30，中心对齐
      // 字母的中心 Y 坐标即 localPosition.dy (大致)
      // 为了更精准，我们基于 index 计算
      final double letterCenterY = 20.0 + (index * 18.0) + 9.0;
      
      if (_selectedLetter != letter) {
        setState(() {
          _selectedLetter = letter;
          _overlayY = letterCenterY - 15.0; // 15 是气泡高度 30 的一半
        });
        widget.onLetterSelected(letter);
      } else {
        setState(() {
          _overlayY = letterCenterY - 15.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 索引字母列表
        GestureDetector(
          onVerticalDragUpdate: (details) => _handleTap(details.localPosition),
          onVerticalDragDown: (details) => _handleTap(details.localPosition),
          onVerticalDragEnd: (_) => setState(() => _selectedLetter = null),
          onVerticalDragCancel: () => setState(() => _selectedLetter = null),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 32,
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: widget.letters.map((letter) {
                final isSelected = _selectedLetter == letter;
                return Container(
                  height: 18,
                  width: 18,
                  decoration: isSelected
                      ? const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        )
                      : null,
                  alignment: Alignment.center,
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? AppColors.grey900 : AppColors.grey400,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // 气泡提示
        if (_selectedLetter != null)
          Positioned(
            right: 40,
            top: _overlayY,
            child: _IndexOverlay(letter: _selectedLetter!),
          ),
      ],
    );
  }
}

class _IndexOverlay extends StatelessWidget {
  final String letter;

  const _IndexOverlay({required this.letter});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 30,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(36, 30),
            painter: _IndexOverlayPainter(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Text(
              letter,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IndexOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF171717)
      ..style = PaintingStyle.fill;

    final path = Path();
    final double radius = size.height / 2;
    final double centerX = radius;
    final double centerY = radius;

    path.addOval(Rect.fromCircle(center: Offset(centerX, centerY), radius: radius));
    
    final double arrowTipX = size.width;
    final double arrowTipY = centerY;
    final double arrowBaseX = centerX + radius - 2;
    const double arrowHalfWidth = 6;

    path.moveTo(arrowBaseX, centerY - arrowHalfWidth);
    path.quadraticBezierTo(
      arrowBaseX + 4, centerY - arrowHalfWidth + 2, 
      arrowTipX, arrowTipY
    );
    path.quadraticBezierTo(
      arrowBaseX + 4, centerY + arrowHalfWidth - 2, 
      arrowBaseX, arrowHalfWidth + centerY
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
