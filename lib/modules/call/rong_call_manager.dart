import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rongcloud_call_wrapper_plugin/rongcloud_call_wrapper_plugin.dart';

import '../../router/app_router.dart';
import '../../widgets/common/app_toast.dart';
import '../im/manager/im_engine_manager.dart';
import '../im/manager/im_user_manager.dart';

enum RongCallStatus {
  idle,
  dialing,
  incoming,
  connecting,
  inCall,
  ended,
  error,
}

class RongCallState {
  const RongCallState({
    required this.status,
    this.targetId = '',
    this.displayName = '',
    this.mediaType = RCCallMediaType.audio,
    this.isOutgoing = false,
    this.micEnabled = true,
    this.speakerEnabled = true,
    this.cameraEnabled = true,
    this.remoteMicEnabled = true,
    this.remoteCameraEnabled = true,
    this.disconnectReason,
    this.errorCode,
    this.session,
    this.localVideoView,
    this.remoteVideoView,
    this.connectedTimeMs = 0,
  });

  const RongCallState.idle() : this(status: RongCallStatus.idle);

  final RongCallStatus status;
  final String targetId;
  final String displayName;
  final RCCallMediaType mediaType;
  final bool isOutgoing;
  final bool micEnabled;
  final bool speakerEnabled;
  final bool cameraEnabled;
  final bool remoteMicEnabled;
  final bool remoteCameraEnabled;
  final RCCallDisconnectReason? disconnectReason;
  final int? errorCode;
  final RCCallSession? session;
  final RCCallView? localVideoView;
  final RCCallView? remoteVideoView;
  final int connectedTimeMs;

  bool get isVideo => mediaType == RCCallMediaType.audio_video;
  bool get isActive =>
      status == RongCallStatus.dialing ||
      status == RongCallStatus.incoming ||
      status == RongCallStatus.connecting ||
      status == RongCallStatus.inCall;

  RongCallState copyWith({
    RongCallStatus? status,
    String? targetId,
    String? displayName,
    RCCallMediaType? mediaType,
    bool? isOutgoing,
    bool? micEnabled,
    bool? speakerEnabled,
    bool? cameraEnabled,
    bool? remoteMicEnabled,
    bool? remoteCameraEnabled,
    RCCallDisconnectReason? disconnectReason,
    int? errorCode,
    RCCallSession? session,
    RCCallView? localVideoView,
    RCCallView? remoteVideoView,
    int? connectedTimeMs,
  }) {
    return RongCallState(
      status: status ?? this.status,
      targetId: targetId ?? this.targetId,
      displayName: displayName ?? this.displayName,
      mediaType: mediaType ?? this.mediaType,
      isOutgoing: isOutgoing ?? this.isOutgoing,
      micEnabled: micEnabled ?? this.micEnabled,
      speakerEnabled: speakerEnabled ?? this.speakerEnabled,
      cameraEnabled: cameraEnabled ?? this.cameraEnabled,
      remoteMicEnabled: remoteMicEnabled ?? this.remoteMicEnabled,
      remoteCameraEnabled: remoteCameraEnabled ?? this.remoteCameraEnabled,
      disconnectReason: disconnectReason ?? this.disconnectReason,
      errorCode: errorCode ?? this.errorCode,
      session: session ?? this.session,
      localVideoView: localVideoView ?? this.localVideoView,
      remoteVideoView: remoteVideoView ?? this.remoteVideoView,
      connectedTimeMs: connectedTimeMs ?? this.connectedTimeMs,
    );
  }
}

class RongCallManager {
  RongCallManager._();
  static final RongCallManager _instance = RongCallManager._();
  factory RongCallManager() => _instance;

  static const MethodChannel _engineChannel = MethodChannel(
    'cn.rongcloud.call.flutter/engine',
  );

  final StreamController<RongCallState> _stateController =
      StreamController<RongCallState>.broadcast();

  RCCallEngine? _engine;
  RongCallState _state = const RongCallState.idle();
  bool _isInitializing = false;

  Stream<RongCallState> get stateStream => _stateController.stream;
  RongCallState get state => _state;

  Future<void> init() async {
    if (_engine != null || _isInitializing) return;
    _isInitializing = true;
    try {
      _engine = await RCCallEngine.create();
      _bindListeners();
      await _enableCallSummary();
      await _engine?.setVideoConfig(
        RCCallVideoConfig.create(
          profile: RCCallVideoProfile.profile_480_640_high,
        ),
      );
    } finally {
      _isInitializing = false;
    }
  }

  Future<bool> startPrivateCall({
    required String targetId,
    required String displayName,
    required RCCallMediaType mediaType,
  }) async {
    await init();
    if (!IMEngineManager().connection.isConnected) {
      AppToast.showInfo('IM 未连接，请稍后再试');
      return false;
    }
    if (_state.isActive) {
      AppToast.showInfo('当前已有通话');
      return false;
    }
    if (!await _ensurePermissions(mediaType)) {
      AppToast.showInfo('请开启相机/麦克风权限后再试');
      return false;
    }

    _setState(
      RongCallState(
        status: RongCallStatus.dialing,
        targetId: targetId,
        displayName: displayName,
        mediaType: mediaType,
        isOutgoing: true,
        speakerEnabled: mediaType == RCCallMediaType.audio_video,
        cameraEnabled: mediaType == RCCallMediaType.audio_video,
      ),
    );

    try {
      final session = await _engine?.startCall(
        targetId,
        mediaType,
        displayName,
      );
      if (session == null) {
        _setState(_state.copyWith(status: RongCallStatus.error));
        AppToast.showInfo('发起通话失败');
        return false;
      }
      _setState(_state.copyWith(session: session));
      return true;
    } catch (_) {
      _setState(_state.copyWith(status: RongCallStatus.error));
      AppToast.showInfo('发起通话失败');
      return false;
    }
  }

  Future<bool> accept() async {
    await init();
    if (!await _ensurePermissions(_state.mediaType)) {
      AppToast.showInfo('请开启相机/麦克风权限后再接听');
      return false;
    }
    _setState(_state.copyWith(status: RongCallStatus.connecting));
    final code = await _engine?.accept() ?? -1;
    if (code != 0) {
      AppToast.showInfo('接听失败：$code');
      return false;
    }
    return true;
  }

  Future<void> hangup() async {
    if (_engine == null) {
      _setState(const RongCallState.idle());
      return;
    }
    await _engine?.hangup();
    _setState(_state.copyWith(status: RongCallStatus.ended));
  }

  Future<void> toggleMicrophone() async {
    final next = !_state.micEnabled;
    if (_state.status == RongCallStatus.incoming) {
      _setState(_state.copyWith(micEnabled: next));
      return;
    }
    final code = await _engine?.enableMicrophone(next) ?? -1;
    if (code == 0) {
      _setState(_state.copyWith(micEnabled: next));
    }
  }

  Future<void> toggleSpeaker() async {
    final next = !_state.speakerEnabled;
    final code = await _engine?.enableSpeaker(next) ?? -1;
    if (code == 0) {
      _setState(_state.copyWith(speakerEnabled: next));
    }
  }

  Future<void> toggleCamera() async {
    final next = !_state.cameraEnabled;
    if (_state.status == RongCallStatus.incoming) {
      _setState(_state.copyWith(cameraEnabled: next));
      return;
    }
    final code = await _engine?.enableCamera(next, RCCallCamera.front) ?? -1;
    if (code == 0) {
      _setState(_state.copyWith(cameraEnabled: next));
      if (next) {
        await prepareVideoViews();
      }
    }
  }

  Future<void> switchCamera() async {
    if (!_state.cameraEnabled) return;
    await _engine?.switchCamera();
  }

  Future<void> prepareVideoViews() async {
    if (!_state.isVideo) return;
    if (_state.status != RongCallStatus.inCall) return;
    final engine = _engine;
    final currentUserId = IMEngineManager().currentUserId;
    final targetId = _state.targetId;
    if (engine == null || currentUserId == null || targetId.isEmpty) return;

    final localView =
        _state.localVideoView ?? await RCCallView.create(fit: BoxFit.cover);
    final remoteView =
        _state.remoteVideoView ?? await RCCallView.create(fit: BoxFit.cover);
    await engine.setVideoView(currentUserId, localView);
    await engine.setVideoView(targetId, remoteView);
    if (identical(localView, _state.localVideoView) &&
        identical(remoteView, _state.remoteVideoView)) {
      return;
    }
    _setState(
      _state.copyWith(localVideoView: localView, remoteVideoView: remoteView),
    );
  }

  void markIdle() {
    _setState(const RongCallState.idle());
  }

  void _bindListeners() {
    final engine = _engine;
    if (engine == null) return;

    engine.onReceiveCall = (session) {
      final targetId = session.caller?.userId ?? session.targetId;
      final displayName = targetId;
      _setState(
        RongCallState(
          status: RongCallStatus.incoming,
          targetId: targetId,
          displayName: displayName,
          mediaType: session.mediaType,
          isOutgoing: false,
          session: session,
          cameraEnabled: session.mediaType == RCCallMediaType.audio_video,
          speakerEnabled: session.mediaType == RCCallMediaType.audio_video,
        ),
      );
      _openIncomingCallPage(displayName, session.mediaType);
      _resolveIncomingDisplayName(targetId);
    };

    engine.onCallDidMake = () {
      _setState(_state.copyWith(status: RongCallStatus.dialing));
    };

    engine.onRemoteUserDidRing = (_) {
      _setState(_state.copyWith(status: RongCallStatus.dialing));
    };

    engine.onConnect = () async {
      final session = await engine.getCurrentCallSession();
      final connectedTime = _connectedTimeFromSession(
        session ?? _state.session,
      );
      _setState(
        _state.copyWith(
          status: RongCallStatus.inCall,
          session: session,
          connectedTimeMs: connectedTime,
        ),
      );
      await engine.enableSpeaker(_state.speakerEnabled);
      await engine.enableMicrophone(_state.micEnabled);
      if (_state.isVideo) {
        await engine.enableCamera(_state.cameraEnabled, RCCallCamera.front);
        await prepareVideoViews();
      }
    };

    engine.onDisconnect = (reason) {
      _setState(
        _state.copyWith(status: RongCallStatus.ended, disconnectReason: reason),
      );
      AppToast.showInfo(_disconnectText(reason));
    };

    engine.onCallError = (errorCode) {
      _setState(
        _state.copyWith(status: RongCallStatus.error, errorCode: errorCode),
      );
      AppToast.showInfo('通话异常：$errorCode');
    };

    engine.onEnableCamera = (_, enabled) {
      _setState(_state.copyWith(cameraEnabled: enabled));
    };

    engine.onRemoteUserDidChangeMicrophoneState = (_, enabled) {
      _setState(_state.copyWith(remoteMicEnabled: enabled));
    };

    engine.onRemoteUserDidChangeCameraState = (_, enabled) {
      _setState(_state.copyWith(remoteCameraEnabled: enabled));
    };
  }

  Future<bool> _ensurePermissions(RCCallMediaType mediaType) async {
    final microphone = await Permission.microphone.request();
    if (!microphone.isGranted) return false;
    if (mediaType == RCCallMediaType.audio_video) {
      final camera = await Permission.camera.request();
      if (!camera.isGranted) return false;
    }
    return true;
  }

  Future<void> _enableCallSummary() async {
    try {
      await _engineChannel.invokeMethod<int>('setEngineConfig', {
        'enableCallSummary': true,
      });
    } catch (e) {
      debugPrint('enable call summary failed: $e');
    }
  }

  int _connectedTimeFromSession(RCCallSession? session) {
    final connectedTime = session?.connectedTime ?? 0;
    if (connectedTime > 0) return connectedTime;
    return DateTime.now().millisecondsSinceEpoch;
  }

  Future<void> _resolveIncomingDisplayName(String targetId) async {
    if (targetId.isEmpty) return;
    try {
      final users = await ImUserManager().getUserProfiles([targetId]);
      if (users == null || users.isEmpty) return;
      final profile = users.first;
      final displayName = (profile.name ?? '').trim();
      if (displayName.isEmpty) return;
      if (_state.targetId != targetId || !_state.isActive) return;
      _setState(_state.copyWith(displayName: displayName));
    } catch (e) {
      debugPrint('resolve call user failed: $e');
    }
  }

  void _openIncomingCallPage(String displayName, RCCallMediaType mediaType) {
    final rootContext = AppRouter.rootNavigatorKey.currentContext;
    if (rootContext == null) return;
    final encodedName = Uri.encodeComponent(displayName);
    final path = mediaType == RCCallMediaType.audio_video
        ? '/chat-private-video/$encodedName?status=incoming'
        : '/chat-private-voice/$encodedName?status=incoming';
    rootContext.push(path);
  }

  String _disconnectText(RCCallDisconnectReason reason) {
    switch (reason) {
      case RCCallDisconnectReason.hangup:
      case RCCallDisconnectReason.remote_hangup:
        return '通话已结束';
      case RCCallDisconnectReason.remote_no_response:
      case RCCallDisconnectReason.no_response:
        return '对方无应答';
      case RCCallDisconnectReason.remote_reject:
      case RCCallDisconnectReason.reject:
        return '通话已拒绝';
      default:
        return '通话已断开';
    }
  }

  void _setState(RongCallState state) {
    _state = state;
    _stateController.add(_state);
  }
}
