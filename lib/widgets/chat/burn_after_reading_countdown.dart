import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:paracosm/modules/im/manager/im_message_manager.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/util/string_util.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

class BurnAfterReadingCountdown extends StatefulWidget {
  const BurnAfterReadingCountdown({super.key, required this.message});

  final RCIMIWMessage message;

  @override
  State<BurnAfterReadingCountdown> createState() =>
      _BurnAfterReadingCountdownState();
}

class _BurnAfterReadingCountdownState extends State<BurnAfterReadingCountdown>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hourglassController;
  Timer? _timer;
  int? _expireTime;
  int _remainingSeconds = 0;

  bool get _isCountingDown => _expireTime != null;

  @override
  void initState() {
    super.initState();
    _hourglassController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _remainingSeconds = widget.message.destructDuration ?? 0;
    _refreshRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _refreshRemaining();
    });
  }

  @override
  void didUpdateWidget(covariant BurnAfterReadingCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message) {
      _expireTime = null;
      _hourglassController.stop();
      _hourglassController.value = 0;
      _remainingSeconds = widget.message.destructDuration ?? 0;
      _refreshRemaining();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hourglassController.dispose();
    super.dispose();
  }

  Future<void> _refreshRemaining() async {
    final duration = widget.message.destructDuration ?? 0;
    if (duration <= 0) {
      return;
    }

    final expireTime =
        _expireTime ??
        await ImMessageManager().getBurnAfterReadingExpireTime(widget.message);
    if (!mounted) {
      return;
    }

    final nextRemaining = expireTime == null
        ? duration
        : ((expireTime - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();

    setState(() {
      _expireTime = expireTime;
      _remainingSeconds = nextRemaining.clamp(0, duration);
    });

    if (expireTime != null && !_hourglassController.isAnimating) {
      _hourglassController.repeat();
    } else if (expireTime == null && _hourglassController.isAnimating) {
      _hourglassController.stop();
      _hourglassController.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if ((widget.message.destructDuration ?? 0) <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _isCountingDown
              ? AnimatedBuilder(
                  animation: _hourglassController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(14, 14),
                      painter: _HourglassPainter(
                        progress: _hourglassController.value,
                        color: AppColors.grey500,
                      ),
                    );
                  },
                )
              : CustomPaint(
                  size: const Size(14, 14),
                  painter: const _HourglassPainter(
                    progress: 0,
                    color: AppColors.grey500,
                  ),
                ),
          const SizedBox(width: 6),
          Text(
            formatDurationFromSeconds(_remainingSeconds),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.grey600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _HourglassPainter extends CustomPainter {
  const _HourglassPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rotation = progress < 0.85
        ? 0.0
        : ((progress - 0.85) / 0.15) * math.pi;
    final sandProgress = (progress / 0.85).clamp(0.0, 1.0);
    final center = Offset(size.width / 2, size.height / 2);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    final topLeft = Offset(size.width * 0.25, size.height * 0.12);
    final topRight = Offset(size.width * 0.75, size.height * 0.12);
    final bottomLeft = Offset(size.width * 0.25, size.height * 0.88);
    final bottomRight = Offset(size.width * 0.75, size.height * 0.88);
    final throat = Offset(size.width * 0.5, size.height * 0.5);

    final frame = Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..lineTo(throat.dx, throat.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..lineTo(throat.dx, throat.dy)
      ..close();
    canvas.drawPath(frame, stroke);

    final topSandHeight =
        size.height * (0.33 - 0.25 * sandProgress).clamp(0.04, 0.33);
    final bottomSandHeight = size.height * (0.06 + 0.25 * sandProgress);

    final topSand = Path()
      ..moveTo(size.width * 0.32, size.height * 0.18)
      ..lineTo(size.width * 0.68, size.height * 0.18)
      ..lineTo(size.width * 0.5, topSandHeight)
      ..close();
    canvas.drawPath(topSand, fill);

    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.43),
      Offset(size.width * 0.5, size.height * 0.66),
      stroke,
    );

    final bottomSand = Path()
      ..moveTo(size.width * 0.32, size.height * 0.84)
      ..lineTo(size.width * 0.68, size.height * 0.84)
      ..lineTo(size.width * 0.5, size.height * 0.84 - bottomSandHeight)
      ..close();
    canvas.drawPath(bottomSand, fill);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HourglassPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
