import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';

/// 通用的快捷索引栏组件。
///
/// 说明：
/// - `selectedLetter` 由父组件传入，用于列表滚动时同步高亮。
/// - `showOverlay` 用来控制是否显示黑色字母气泡，避免滚动停止后气泡一直停留。
class QuickIndexBar extends StatefulWidget {
  final List<String> letters;
  final Function(String) onLetterSelected;
  final String? selectedLetter;
  final bool showOverlay;

  const QuickIndexBar({
    super.key,
    required this.letters,
    required this.onLetterSelected,
    this.selectedLetter,
    this.showOverlay = false,
  });

  @override
  State<QuickIndexBar> createState() => _QuickIndexBarState();
}

class _QuickIndexBarState extends State<QuickIndexBar> {
  String? _selectedLetter;
  double _overlayY = 0;

  String? get _activeLetter => _selectedLetter ?? widget.selectedLetter;

  String? get _overlayLetter =>
      _selectedLetter ?? (widget.showOverlay ? widget.selectedLetter : null);

  double _overlayYForLetter(String letter) {
    final index = widget.letters.indexOf(letter);
    if (index < 0) {
      return 0;
    }

    // 顶部 padding 为 20，每个字母高度 18，气泡高度 30，中心对齐到当前字母。
    final double letterCenterY = 20.0 + (index * 18.0) + 9.0;
    return letterCenterY - 15.0;
  }

  void _handleTap(Offset localPosition) {
    final relativeY = localPosition.dy - 20.0;
    final index = (relativeY / 18.0).floor();

    if (index >= 0 && index < widget.letters.length) {
      final letter = widget.letters[index];
      final overlayY = _overlayYForLetter(letter);

      if (_selectedLetter != letter) {
        setState(() {
          _selectedLetter = letter;
          _overlayY = overlayY;
        });
        widget.onLetterSelected(letter);
      } else {
        setState(() {
          _overlayY = overlayY;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final overlayLetter = _overlayLetter;

    return Stack(
      clipBehavior: Clip.none,
      children: [
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
                final isSelected = _activeLetter == letter;
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
        if (overlayLetter != null)
          Positioned(
            right: 40,
            top: _selectedLetter != null ? _overlayY : _overlayYForLetter(overlayLetter),
            child: _IndexOverlay(letter: overlayLetter),
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
      arrowBaseX + 4,
      centerY - arrowHalfWidth + 2,
      arrowTipX,
      arrowTipY,
    );
    path.quadraticBezierTo(
      arrowBaseX + 4,
      centerY + arrowHalfWidth - 2,
      arrowBaseX,
      arrowHalfWidth + centerY,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
