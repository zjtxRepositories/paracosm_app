import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum VoicePlayState { idle, loading, playing, paused, stopped, completed }

class VoicePlayerManager {
  static const double _defaultVolume = 1.0;

  static final AudioContext _speakerContext = AudioContextConfig(
    route: AudioContextConfigRoute.speaker,
    focus: AudioContextConfigFocus.gain,
  ).build();

  /// =========================
  /// 单例
  /// =========================
  static final VoicePlayerManager _instance = VoicePlayerManager._internal();

  factory VoicePlayerManager() => _instance;

  VoicePlayerManager._internal() {
    _initListener();
  }

  /// =========================
  /// 播放器
  /// =========================
  final AudioPlayer _player = AudioPlayer();

  /// 当前播放ID（用于UI高亮）
  String? _currentId;

  String get currentId => _currentId ?? '';

  /// 当前状态
  VoicePlayState _state = VoicePlayState.idle;

  /// 进度
  Duration _position = Duration.zero;

  /// 队列（自动播放下一条）
  final List<_VoiceTask> _queue = [];

  /// =========================
  /// Stream
  /// =========================
  final _stateController = StreamController<VoicePlayState>.broadcast();
  final _progressController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _currentIdController = StreamController<String?>.broadcast();

  Stream<VoicePlayState> get stateStream => _stateController.stream;

  Stream<Duration> get progressStream => _progressController.stream;

  Stream<Duration> get durationStream => _durationController.stream;

  Stream<String?> get currentIdStream => _currentIdController.stream;

  /// =========================
  /// 初始化监听
  /// =========================
  void _initListener() {
    unawaited(_applyDefaultAudioOutput());

    /// 播放进度
    _player.onPositionChanged.listen((pos) {
      _position = pos;
      _progressController.add(pos);
    });

    /// 总时长
    _player.onDurationChanged.listen((dur) {
      _durationController.add(dur);
    });

    /// 播放完成
    _player.onPlayerComplete.listen((event) {
      _onComplete();
    });

    /// 兜底（某些机型）
    _player.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        _onComplete();
      }
    });
  }

  /// =========================
  /// 播放入口（核心）
  /// =========================
  Future<void> play({required String id, String path = '', String? url}) async {
    /// 同一个 => 切换暂停/继续
    if (_currentId == id) {
      if (_state == VoicePlayState.playing) {
        pause();
        return;
      } else if (_state == VoicePlayState.paused) {
        resume();
        return;
      }
    }

    /// =========================
    /// 判断本地文件是否可用
    /// =========================
    bool isAsset = false;
    var source = path.trim();
    if (path.isNotEmpty) {
      try {
        final file = File(path);

        if (await file.exists()) {
          final length = await file.length();

          /// 防止空文件（很关键）
          if (length > 0) {
            isAsset = true;
          }
        }
      } catch (e) {
        debugPrint("本地文件检测失败: $e");
      }
    }
    if (!isAsset) {
      source = url?.trim() ?? source;
    }
    if (source.isEmpty) return;

    /// 播放新音频（自动停止旧的）
    await _startNew(_VoiceTask(id: id, path: source, isAsset: isAsset));
  }

  /// =========================
  /// 开始新播放
  /// =========================
  Future<void> _startNew(_VoiceTask task) async {
    await _player.stop();
    await _applyDefaultAudioOutput();

    _currentId = task.id;
    _currentIdController.add(_currentId);

    _position = Duration.zero;
    _progressController.add(_position);

    _setState(VoicePlayState.loading);
    try {
      if (task.isAsset) {
        await _player.play(DeviceFileSource(task.path));
      } else {
        await _player.play(UrlSource(task.path));
      }

      _setState(VoicePlayState.playing);
    } catch (e) {
      _setState(VoicePlayState.stopped);
    }
  }

  /// =========================
  /// 暂停
  /// =========================
  Future<void> pause() async {
    if (_state == VoicePlayState.playing) {
      await _player.pause();
      _setState(VoicePlayState.paused);
    }
  }

  /// =========================
  /// 继续
  /// =========================
  Future<void> resume() async {
    if (_state == VoicePlayState.paused) {
      await _player.resume();
      _setState(VoicePlayState.playing);
    }
  }

  /// =========================
  /// 停止
  /// =========================
  Future<void> stop() async {
    await _player.stop();
    _reset();
  }

  /// =========================
  /// 播放完成
  /// =========================
  void _onComplete() {
    _setState(VoicePlayState.completed);

    /// 自动播放下一条（IM关键能力）
    if (_queue.isNotEmpty) {
      final next = _queue.removeAt(0);
      _startNew(next);
      return;
    }

    _reset();
  }

  /// =========================
  /// 重置状态
  /// =========================
  void _reset() {
    _currentId = null;
    _currentIdController.add(null);

    _position = Duration.zero;
    _progressController.add(_position);

    _setState(VoicePlayState.stopped);
  }

  /// =========================
  /// 设置状态
  /// =========================
  void _setState(VoicePlayState state) {
    _state = state;
    _stateController.add(state);
  }

  Future<void> _applyDefaultAudioOutput() async {
    await _player.setAudioContext(_speakerContext);
    await _player.setVolume(_defaultVolume);
  }

  /// =========================
  /// 释放
  /// =========================
  void dispose() {
    _player.dispose();
    _stateController.close();
    _progressController.close();
    _durationController.close();
    _currentIdController.close();
  }
}

/// =========================
/// 播放任务
/// =========================
class _VoiceTask {
  final String id;
  final String path;
  final bool isAsset;

  _VoiceTask({required this.id, required this.path, required this.isAsset});
}
