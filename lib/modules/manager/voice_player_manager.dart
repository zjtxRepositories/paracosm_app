import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

enum VoicePlayState {
  idle,
  loading,
  playing,
  paused,
  stopped,
}

class VoicePlayerManager {
  static final VoicePlayerManager _instance =
  VoicePlayerManager._internal();

  factory VoicePlayerManager() => _instance;

  VoicePlayerManager._internal();

  /// 当前播放ID（用于列表高亮）
  String? _currentId;
  String get currentId => _currentId ?? '';
  /// 状态
  VoicePlayState _state = VoicePlayState.idle;

  /// 进度
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  final _stateController = StreamController<VoicePlayState>.broadcast();
  final _progressController = StreamController<Duration>.broadcast();
  final _currentIdController = StreamController<String?>.broadcast();

  Stream<VoicePlayState> get stateStream => _stateController.stream;
  Stream<Duration> get progressStream => _progressController.stream;
  Stream<String?> get currentIdStream => _currentIdController.stream;
  final player = AudioPlayer();

  /// =========================
  /// 播放
  /// =========================
  Future<void> play({
    required String id,
    required String path,
  }) async {
    // 如果点击同一个 => 暂停/继续
    if (_currentId == id && _state == VoicePlayState.playing) {
      pause();
      return;
    }

    // 切换新的播放源
    _currentId = id;
    _currentIdController.add(_currentId!);

    _setState(VoicePlayState.loading);

    try {
      await player.play(AssetSource(path));

      _setState(VoicePlayState.playing);

      // mock progress（实际要用播放器监听）
      _startMockProgress();
    } catch (e) {
      _setState(VoicePlayState.stopped);
    }
  }

  /// =========================
  /// 暂停
  /// =========================
  Future<void> pause() async {
    if (_state == VoicePlayState.playing) {
      await player.pause();
      _setState(VoicePlayState.paused);
    }
  }

  /// =========================
  /// 停止
  /// =========================
  Future<void> stop() async {
    await player.stop();
    _setState(VoicePlayState.stopped);
    _currentId = null;
    _currentIdController.add(null);
    _position = Duration.zero;
    _progressController.add(_position);
  }

  /// =========================
  /// 状态更新
  /// =========================
  void _setState(VoicePlayState state) {
    _state = state;
    _stateController.add(state);
  }

  /// =========================
  /// mock 进度（后面换真实监听）
  /// =========================
  Timer? _timer;

  void _startMockProgress() {
    _timer?.cancel();
    _position = Duration.zero;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _position += const Duration(seconds: 1);
      _progressController.add(_position);
    });
  }

  /// =========================
  /// dispose
  /// =========================
  void dispose() {
    _timer?.cancel();
    _stateController.close();
    _progressController.close();
    _currentIdController.close();
  }
}