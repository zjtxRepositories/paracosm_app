import 'package:flutter/material.dart';

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ChatBubblePainter extends CustomPainter {
  final Color color;
  final bool isMe;

  ChatBubblePainter({required this.color, required this.isMe});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    const radius = 16.0;
    const tailWidth = 8.0;

    if (isMe) {
      path.addRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(0, 0, size.width, size.height),
          topLeft: const Radius.circular(radius),
          topRight: const Radius.circular(radius),
          bottomLeft: const Radius.circular(radius),
          bottomRight: const Radius.circular(0),
        ),
      );

      path.moveTo(size.width, size.height - 12);
      path.lineTo(size.width + tailWidth, size.height);
      path.lineTo(size.width - 12, size.height);
    } else {
      path.addRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(0, 0, size.width, size.height),
          topLeft: const Radius.circular(0),
          topRight: const Radius.circular(radius),
          bottomLeft: const Radius.circular(radius),
          bottomRight: const Radius.circular(radius),
        ),
      );

      path.moveTo(0, 12);
      path.lineTo(-tailWidth, 0);
      path.lineTo(12, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ChatBubblePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isMe != isMe;
}
