import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VoiceRecordOverlay {
  static OverlayEntry? _entry;

  /// 状态（外部驱动）
  static bool _isUp = false;
  static bool _isTooShort = false;
  static double _volume = 0.1;
  static String _text = "";

  /// =========================
  /// 显示
  /// =========================
  static void show(
      BuildContext context, {
        required bool isUp,
        required double volume,
        required String text,
      }) {
    _isUp = isUp;
    _volume = volume;
    _text = text;
    _isTooShort = false;

    if (_entry != null) return;

    _entry = OverlayEntry(
      builder: (_) => _build(),
    );

    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  /// =========================
  /// 更新
  /// =========================
  static void update({
    bool? isUp,
    double? volume,
    String? text,
    bool? isTooShort,
  }) {
    if (_entry == null) return;

    if (isUp != null) _isUp = isUp;
    if (volume != null) _volume = volume;
    if (text != null) _text = text;
    if (isTooShort != null) _isTooShort = isTooShort;

    _entry?.markNeedsBuild();
  }

  /// =========================
  /// 隐藏
  /// =========================
  static void hide() {
    _entry?.remove();
    _entry = null;
  }

  /// =========================
  /// UI（核心）
  /// =========================
  static Widget _build() {
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Opacity(
            opacity: 0.8,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 20.w,
                vertical: 12.h, // 👈 减小padding（关键）
              ),
              width: 140.w,
              height: 154.h,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween, // 👈 核心修复
                children: [
                  /// 顶部区域固定高度（防止撑开）
                  SizedBox(
                    width: 100.w,
                    height: 99.h,
                    child: _isUp || _isTooShort
                        ? Image.asset(
                      _isUp ? "assets/images/chat/voice_cancel.png" : "assets/images/chat/short_speech.png",
                      fit: BoxFit.contain,
                    )
                        : Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      crossAxisAlignment:
                      CrossAxisAlignment.end,
                      children: [
                        Image.asset(
                          "assets/images/chat/microphone-w.png",
                          width: 50.w,
                          height: 64.h,
                        ),
                        SizedBox(width: 5.w),

                        /// 🔊 音量动画
                        ClipRect(
                          child: Align(
                            heightFactor:
                            _volume.clamp(0.0, 1.0),
                            alignment:
                            Alignment.bottomCenter,
                            child: Image.asset(
                              "assets/images/chat/voice_volume_total.png",
                              width: 20.w,
                              height: 36.h,
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// 👇 文案区域固定高度（防止再次溢出）
                  SizedBox(
                    height: 20.h,
                    child: Text(
                      _text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}