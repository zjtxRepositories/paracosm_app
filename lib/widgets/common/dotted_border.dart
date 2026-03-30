import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';

/// 一个简单的虚线边框装饰器组件
/// 用于为子组件添加圆角虚线边框。
class DottedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashWidth;
  final double dashSpace;
  final EdgeInsets padding;

  const DottedBorder({
    super.key,
    required this.child,
    this.color = AppColors.grey300,
    this.strokeWidth = 1.0,
    this.radius = 12.0,
    this.dashWidth = 4.0,
    this.dashSpace = 4.0,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedBorderPainter(
        color: color,
        strokeWidth: strokeWidth,
        radius: radius,
        dashWidth: dashWidth,
        dashSpace: dashSpace,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashWidth;
  final double dashSpace;

  _DottedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    ));

    final dashPath = Path();
    var distance = 0.0;
    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DottedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace;
  }
}
