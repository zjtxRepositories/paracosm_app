import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rongcloud_call_wrapper_plugin/rongcloud_call_wrapper_plugin.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../router/app_router.dart';
import '../../widgets/base/app_localizations.dart';
import '../../widgets/common/app_toast.dart';
import '../im/manager/im_send_manager.dart';
import '../im/manager/im_engine_manager.dart';
import '../im/manager/im_user_manager.dart';
import 'rong_call_summary_parser.dart';

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
    this.avatar = '',
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
  final String avatar;
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
  bool _nativeCallSummaryDisabled = false;
  Future<void>? _videoViewsFuture;
  bool _localVideoViewBound = false;
  bool _remoteVideoViewBound = false;
  final Set<String> _sentSummaryKeys = <String>{};

  Stream<RongCallState> get stateStream => _stateController.stream;
  RongCallState get state => _state;

  Future<void> init() async {
    if (_engine != null || _isInitializing) return;
    _isInitializing = true;
    try {
      _engine = await RCCallEngine.create();
      _bindListeners();
      await _disableNativeCallSummary();
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
      AppToast.showInfo(AppLocalizations.currentText('call_im_not_connected'));
      return false;
    }
    if (_state.isActive) {
      AppToast.showInfo(AppLocalizations.currentText('call_in_progress'));
      return false;
    }
    if (!await _ensurePermissions(mediaType)) {
      AppToast.showInfo(
        AppLocalizations.currentText('call_permission_required'),
      );
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
        AppToast.showInfo(AppLocalizations.currentText('call_start_failed'));
        return false;
      }
      await _disableNativeCallSummary();
      _setState(_state.copyWith(session: session));
      return true;
    } catch (_) {
      _setState(_state.copyWith(status: RongCallStatus.error));
      AppToast.showInfo(AppLocalizations.currentText('call_start_failed'));
      return false;
    }
  }

  Future<bool> accept() async {
    await init();
    await _disableNativeCallSummary();
    if (!await _ensurePermissions(_state.mediaType)) {
      AppToast.showInfo(
        AppLocalizations.currentText('call_answer_permission_required'),
      );
      return false;
    }
    _setState(_state.copyWith(status: RongCallStatus.connecting));
    final code = await _engine?.accept() ?? -1;
    if (code != 0) {
      AppToast.showInfo(
        AppLocalizations.currentText('call_answer_failed_code', {'code': code}),
      );
      return false;
    }
    return true;
  }

  Future<void> hangup() async {
    if (_engine == null) {
      _setState(const RongCallState.idle());
      return;
    }
    await _disableNativeCallSummary();
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
      if (!next) {
        clearLocalVideoView();
      }
    }
  }

  Future<void> switchCamera() async {
    if (!_state.cameraEnabled) return;
    await _engine?.switchCamera();
  }

  Future<RCCallView?> createLocalVideoView() async {
    final engine = _engine;
    final currentUserId = IMEngineManager().currentUserId;
    if (engine == null ||
        currentUserId == null ||
        currentUserId.isEmpty ||
        !_state.isVideo ||
        !_state.isActive ||
        !_state.cameraEnabled) {
      return null;
    }

    try {
      final view = await RCCallView.create(fit: BoxFit.cover, mirror: true);
      if (!_state.isVideo || !_state.isActive || !_state.cameraEnabled) {
        return null;
      }
      return view;
    } catch (e) {
      debugPrint('create local video view failed: $e');
      return null;
    }
  }

  Future<bool> bindLocalVideoView(RCCallView view) async {
    final engine = _engine;
    final currentUserId = IMEngineManager().currentUserId;
    if (engine == null ||
        currentUserId == null ||
        currentUserId.isEmpty ||
        !_state.isVideo ||
        !_state.isActive ||
        !_state.cameraEnabled) {
      return false;
    }

    try {
      final code = await engine.setVideoView(currentUserId, view);
      if (code != 0) {
        debugPrint('bind local video view failed: $code');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('bind local video view failed: $e');
      return false;
    }
  }

  Future<void> unbindLocalVideoView() async {
    final engine = _engine;
    final currentUserId = IMEngineManager().currentUserId;
    if (engine == null || currentUserId == null || currentUserId.isEmpty) {
      return;
    }
    try {
      await engine.setVideoView(currentUserId, null);
    } catch (e) {
      debugPrint('unbind local video view failed: $e');
    }
  }

  Future<RCCallView?> createRemoteVideoView() async {
    final engine = _engine;
    final targetId = _state.targetId;
    if (engine == null ||
        targetId.isEmpty ||
        !_state.isVideo ||
        !_state.isActive) {
      return null;
    }

    try {
      final view = await RCCallView.create(fit: BoxFit.cover);
      if (!_state.isVideo || !_state.isActive || _state.targetId != targetId) {
        return null;
      }
      return view;
    } catch (e) {
      debugPrint('create remote video view failed: $e');
      return null;
    }
  }

  Future<bool> bindRemoteVideoView(RCCallView view) async {
    final engine = _engine;
    final targetId = _state.targetId;
    if (engine == null ||
        targetId.isEmpty ||
        !_state.isVideo ||
        _state.status != RongCallStatus.inCall ||
        !_state.remoteCameraEnabled) {
      return false;
    }

    try {
      final code = await engine.setVideoView(targetId, view);
      if (code != 0) {
        debugPrint('bind remote video view failed: $code');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('bind remote video view failed: $e');
      return false;
    }
  }

  Future<void> unbindRemoteVideoView() async {
    final engine = _engine;
    final targetId = _state.targetId;
    if (engine == null || targetId.isEmpty) return;
    try {
      await engine.setVideoView(targetId, null);
    } catch (e) {
      debugPrint('unbind remote video view failed: $e');
    }
  }

  Future<void> prepareVideoViews() {
    if (!_state.isVideo) return Future.value();
    if (!_state.isActive) return Future.value();
    if (!_state.cameraEnabled && _state.status == RongCallStatus.inCall) {
      return Future.value();
    }
    final engine = _engine;
    final currentUserId = IMEngineManager().currentUserId;
    final targetId = _state.targetId;
    if (engine == null || currentUserId == null || targetId.isEmpty) {
      return Future.value();
    }
    if (_state.localVideoView != null &&
        _state.remoteVideoView != null &&
        _localVideoViewBound &&
        _remoteVideoViewBound) {
      return Future.value();
    }

    return _videoViewsFuture ??= _prepareVideoViews(
      engine: engine,
      currentUserId: currentUserId,
      targetId: targetId,
    );
  }

  Future<void> _prepareVideoViews({
    required RCCallEngine engine,
    required String currentUserId,
    required String targetId,
  }) async {
    try {
      final views = await Future.wait<RCCallView>([
        _state.localVideoView != null
            ? Future.value(_state.localVideoView!)
            : RCCallView.create(fit: BoxFit.cover, mirror: true),
        _state.remoteVideoView != null
            ? Future.value(_state.remoteVideoView!)
            : RCCallView.create(fit: BoxFit.cover),
      ]);
      final localView = views[0];
      final remoteView = views[1];

      if (!_state.isVideo || !_state.isActive || _state.targetId != targetId) {
        return;
      }

      final viewsChanged =
          !identical(localView, _state.localVideoView) ||
          !identical(remoteView, _state.remoteVideoView);
      if (viewsChanged) {
        _localVideoViewBound = false;
        _remoteVideoViewBound = false;
        _setState(
          _state.copyWith(
            localVideoView: localView,
            remoteVideoView: remoteView,
          ),
        );
      }

      if (viewsChanged ||
          !_localVideoViewBound ||
          (_state.status == RongCallStatus.inCall && !_remoteVideoViewBound)) {
        await WidgetsBinding.instance.endOfFrame;
        if (!_state.isVideo ||
            !_state.isActive ||
            _state.targetId != targetId) {
          return;
        }
      }

      final localCode = await engine.setVideoView(currentUserId, localView);
      _localVideoViewBound = localCode == 0;
      if (localCode != 0) {
        debugPrint('bind local video view failed: $localCode');
      }

      if (!_state.isVideo || !_state.isActive || _state.targetId != targetId) {
        return;
      }
      if (_state.status != RongCallStatus.inCall) {
        _remoteVideoViewBound = false;
        return;
      }

      final remoteCode = await engine.setVideoView(targetId, remoteView);
      _remoteVideoViewBound = remoteCode == 0;
      if (remoteCode != 0) {
        debugPrint('bind remote video view failed: $remoteCode');
      }
    } catch (e) {
      debugPrint('prepare video views failed: $e');
    } finally {
      _videoViewsFuture = null;
    }
  }

  void clearVideoViews() {
    if (_state.localVideoView == null && _state.remoteVideoView == null) return;
    _localVideoViewBound = false;
    _remoteVideoViewBound = false;
    _setState(
      RongCallState(
        status: _state.status,
        targetId: _state.targetId,
        displayName: _state.displayName,
        mediaType: _state.mediaType,
        isOutgoing: _state.isOutgoing,
        micEnabled: _state.micEnabled,
        speakerEnabled: _state.speakerEnabled,
        cameraEnabled: _state.cameraEnabled,
        remoteMicEnabled: _state.remoteMicEnabled,
        remoteCameraEnabled: _state.remoteCameraEnabled,
        disconnectReason: _state.disconnectReason,
        errorCode: _state.errorCode,
        session: _state.session,
        connectedTimeMs: _state.connectedTimeMs,
      ),
    );
  }

  void clearLocalVideoView() {
    if (_state.localVideoView == null) return;
    _localVideoViewBound = false;
    _setState(
      RongCallState(
        status: _state.status,
        targetId: _state.targetId,
        displayName: _state.displayName,
        mediaType: _state.mediaType,
        isOutgoing: _state.isOutgoing,
        micEnabled: _state.micEnabled,
        speakerEnabled: _state.speakerEnabled,
        cameraEnabled: _state.cameraEnabled,
        remoteMicEnabled: _state.remoteMicEnabled,
        remoteCameraEnabled: _state.remoteCameraEnabled,
        disconnectReason: _state.disconnectReason,
        errorCode: _state.errorCode,
        session: _state.session,
        remoteVideoView: _state.remoteVideoView,
        connectedTimeMs: _state.connectedTimeMs,
      ),
    );
  }

  void markIdle() {
    _setState(const RongCallState.idle());
  }

  void _bindListeners() {
    final engine = _engine;
    if (engine == null) return;

    engine.onReceiveCall = (session) {
      _disableNativeCallSummary();
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
      await _disableNativeCallSummary();
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
      unawaited(_applyConnectedMediaSettings(engine, _state));
    };

    engine.onDisconnect = (reason) {
      final endedState = _state.copyWith(
        status: RongCallStatus.ended,
        disconnectReason: reason,
      );
      _setState(endedState);
      unawaited(_sendCallSummaryFallback(endedState, reason));
      AppToast.showInfo(_disconnectText(reason));
    };

    engine.onCallError = (errorCode) {
      _setState(
        _state.copyWith(status: RongCallStatus.error, errorCode: errorCode),
      );
      AppToast.showInfo(
        AppLocalizations.currentText('call_error_code', {'code': errorCode}),
      );
    };

    engine.onEnableCamera = (_, enabled) {
      _setState(_state.copyWith(cameraEnabled: enabled));
    };

    engine.onRemoteUserDidChangeMicrophoneState = (_, enabled) {
      _setState(_state.copyWith(remoteMicEnabled: enabled));
    };

    engine.onRemoteUserDidChangeCameraState = (_, enabled) {
      _remoteVideoViewBound = false;
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

  Future<void> _disableNativeCallSummary() async {
    if (_nativeCallSummaryDisabled) return;
    try {
      final code = await _engineChannel.invokeMethod<int>('setEngineConfig', {
        'enableCallSummary': false,
      });
      if (code == 0) {
        _nativeCallSummaryDisabled = true;
      } else {
        debugPrint('disable native call summary failed: $code');
      }
    } catch (e) {
      debugPrint('disable native call summary failed: $e');
    }
  }

  int _connectedTimeFromSession(RCCallSession? session) {
    final connectedTime = session?.connectedTime ?? 0;
    if (connectedTime > 0) return connectedTime;
    return DateTime.now().millisecondsSinceEpoch;
  }

  Future<void> _applyConnectedMediaSettings(
    RCCallEngine engine,
    RongCallState state,
  ) async {
    try {
      final futures = <Future<int>>[
        engine.enableSpeaker(state.speakerEnabled),
        engine.enableMicrophone(state.micEnabled),
      ];
      if (state.isVideo) {
        futures.add(
          engine.enableCamera(state.cameraEnabled, RCCallCamera.front),
        );
      }
      await Future.wait<int>(futures);
    } catch (e) {
      debugPrint('apply connected media settings failed: $e');
    }
  }

  Future<void> _sendCallSummaryFallback(
    RongCallState state,
    RCCallDisconnectReason reason,
  ) async {
    if (!_shouldSendCallSummaryFallback(state)) return;

    final engine = IMEngineManager().engine;
    final targetId = state.targetId;
    if (engine == null || targetId.isEmpty) return;

    final key = _callSummaryKey(state, reason);
    if (!_sentSummaryKeys.add(key)) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final duration = _callDurationMs(state, now);
    final fields = <String, dynamic>{
      'duration': duration,
      'mediaType': state.isVideo ? 2 : 1,
      'hangupReason': _summaryReasonCode(reason),
      'reason': _summaryReasonCode(reason),
      'reasonName': reason.name,
      'callId': state.session?.callId,
      'sessionId': state.session?.sessionId,
      'startTime': state.session?.startTime,
      'connectedTime': state.connectedTimeMs,
      'endTime': now,
      'isOutgoing': state.isOutgoing,
    }..removeWhere((_, value) => value == null);

    try {
      final message = await engine.createNativeCustomMessage(
        RCIMIWConversationType.private,
        targetId,
        null,
        RongCallSummaryParser.objectName,
        fields,
      );
      if (message == null) {
        debugPrint('create call summary fallback message failed: null');
        return;
      }
      message.senderUserId = IMEngineManager().currentUserId;
      message.sentTime = now;
      final sent = await ImSendManager.instance.sendMessage(message);
      if (kDebugMode) {
        debugPrint(
          'send call summary fallback message: targetId=$targetId, '
          'reason=${reason.name}, duration=$duration, sent=$sent',
        );
      }
      if (!sent) {
        debugPrint('send call summary fallback message failed');
      }
    } catch (e) {
      debugPrint('send call summary fallback message failed: $e');
    }
  }

  bool _shouldSendCallSummaryFallback(RongCallState state) {
    if (state.targetId.isEmpty) return false;
    return _isCurrentUserCallInitiator(state);
  }

  bool _isCurrentUserCallInitiator(RongCallState state) {
    final currentUserId = IMEngineManager().currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) return false;

    final callerUserId = _callInitiatorUserId(state);
    if (callerUserId != null) return callerUserId == currentUserId;

    return state.isOutgoing;
  }

  String? _callInitiatorUserId(RongCallState state) {
    final callerUserId = state.session?.caller?.userId;
    if (callerUserId != null && callerUserId.isNotEmpty) {
      return callerUserId;
    }

    if (state.isOutgoing) return IMEngineManager().currentUserId;
    return null;
  }

  int _callDurationMs(RongCallState state, int now) {
    final connectedTime = state.connectedTimeMs > 0
        ? state.connectedTimeMs
        : state.session?.connectedTime ?? 0;
    if (connectedTime <= 0) return 0;
    final duration = now - connectedTime;
    return duration > 0 ? duration : 0;
  }

  int _summaryReasonCode(RCCallDisconnectReason reason) {
    switch (reason) {
      case RCCallDisconnectReason.cancel:
      case RCCallDisconnectReason.remote_cancel:
        return 1;
      case RCCallDisconnectReason.reject:
      case RCCallDisconnectReason.remote_reject:
        return 2;
      case RCCallDisconnectReason.busy_line:
      case RCCallDisconnectReason.remote_busy_line:
        return 4;
      case RCCallDisconnectReason.no_response:
      case RCCallDisconnectReason.remote_no_response:
        return 5;
      case RCCallDisconnectReason.network_error:
      case RCCallDisconnectReason.remote_network_error:
        return 7;
      default:
        return 0;
    }
  }

  String _callSummaryKey(RongCallState state, RCCallDisconnectReason reason) {
    final session = state.session;
    final callId = session?.callId;
    if (callId != null && callId.isNotEmpty) return callId;
    final sessionId = session?.sessionId;
    if (sessionId != null && sessionId.isNotEmpty) return sessionId;
    return [
      state.targetId,
      session?.startTime ?? state.connectedTimeMs,
      state.isOutgoing,
      reason.name,
    ].join(':');
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
        return AppLocalizations.currentText('call_ended');
      case RCCallDisconnectReason.remote_no_response:
      case RCCallDisconnectReason.no_response:
        return AppLocalizations.currentText('call_peer_no_answer');
      case RCCallDisconnectReason.remote_reject:
      case RCCallDisconnectReason.reject:
        return AppLocalizations.currentText('call_rejected');
      default:
        return AppLocalizations.currentText('call_disconnected');
    }
  }

  void _setState(RongCallState state) {
    _state = state;
    _stateController.add(_state);
  }
}
