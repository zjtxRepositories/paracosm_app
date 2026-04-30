import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';

class VoiceRecordManager {
  static final VoiceRecordManager _instance =
  VoiceRecordManager._internal();

  factory VoiceRecordManager() => _instance;

  VoiceRecordManager._internal();

  final FlutterSoundRecorder _recorder =
  FlutterSoundRecorder();

  StreamSubscription? _recorderSubscription;

  DateTime? _startTime;

  bool _isRecording = false;
  bool _isCancelling = false;

  /// 回调
  Function(String path, int duration)? onSend;
  Function(double volume)? onVolume;
  VoidCallback? onStart;
  VoidCallback? onCancel;
  VoidCallback? onTooShort;
  bool _inited = false;
  double _volume = 0.0;

  /// =========================
  /// 初始化
  /// =========================
  Future<void> _ensureInit() async {
    if (_inited) return;

    await _recorder.openRecorder();

    await _recorder.setSubscriptionDuration(
      const Duration(milliseconds: 80),
    );

    _inited = true;
  }

  /// =========================
  /// 开始录音
  /// =========================
  Future<void> startRecord() async {
    try {
      await _ensureInit();

      final path =
          '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.aac';

      _startTime = DateTime.now();
      _isCancelling = false;

      await _recorder.startRecorder(
        toFile: path,
        codec: Codec.aacADTS,
      );

      _isRecording = true;

      /// 🎯 监听音量
      _recorderSubscription =
          _recorder.onProgress!.listen((event) {
            final raw = event.decibels ?? 0.0;

            // 🔥 微信级压缩
            double v = (raw / 3.0).clamp(0.0, 1.0);

            // 平滑
            _volume = _volume * 0.7 + v * 0.3;

            if (_volume < 0.05) _volume = 0.05;

            onVolume?.call(_volume);
          });

      onStart?.call();

      debugPrint("🎤 开始录音");
    } catch (e) {
      debugPrint("录音失败: $e");
    }
  }

  /// =========================
  /// 停止录音
  /// =========================
  Future<void> stopRecord() async {
    try {
      if (!_isRecording) return;

      final path = await _recorder.stopRecorder();

      await _recorderSubscription?.cancel();

      _isRecording = false;

      if (_isCancelling || path == null) return;

      final duration =
          DateTime.now().difference(_startTime!).inMilliseconds;

      if (duration < 1) {
        debugPrint("⚠️ 录音太短");
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
        onTooShort?.call();
        return;
      }

      onSend?.call(path, duration);

      debugPrint("✅ 录音完成");
    } catch (e) {
      debugPrint("停止失败: $e");
    }
  }

  /// =========================
  /// 取消录音
  /// =========================
  Future<void> cancelRecord() async {
    try {
      if (!_isRecording) return;

      _isCancelling = true;

      await _recorder.stopRecorder();
      await _recorderSubscription?.cancel();

      _isRecording = false;

      onCancel?.call();

      debugPrint("🚫 取消录音");
    } catch (e) {
      debugPrint("取消失败: $e");
    }
  }

  /// =========================
  void updateCancelling(bool cancel) {
    _isCancelling = cancel;
  }

  bool get isCancelling => _isCancelling;

  /// =========================
  void dispose() {
    _recorder.closeRecorder();
  }

  double normalizeDb(double db) {
    const minDb = -100.0; // 最小噪音
    const maxDb = 0.0;

    double normalized = (db - minDb) / (maxDb - minDb);

    return normalized.clamp(0.0, 1.0);
  }
}