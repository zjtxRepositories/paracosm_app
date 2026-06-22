// ignore_for_file: constant_identifier_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import 'package:rongcloud_rtc_wrapper_plugin/rongcloud_rtc_wrapper_plugin.dart';

enum RCCallCallType { single, group }

enum RCCallMediaType { audio, audio_video }

enum RCCallCamera { none, front, back }

enum ChatCallStatus {
  /// 拨打中。
  dialing('dialing'),

  /// 来电中。
  incoming('incoming'),

  /// 通话中。
  inCall('in_call'),

  /// 加入群通话预览。
  join('join');

  const ChatCallStatus(this.routeValue);

  final String routeValue;

  static ChatCallStatus fromRoute(String? value) {
    return ChatCallStatus.values.firstWhere(
      (status) => status.routeValue == value,
      orElse: () => ChatCallStatus.dialing,
    );
  }
}

enum RCCallDisconnectReason {
  hangup,
  remote_hangup,
  cancel,
  remote_cancel,
  reject,
  remote_reject,
  busy_line,
  remote_busy_line,
  no_response,
  remote_no_response,
  network_error,
  remote_network_error,
  unknown,
}

class RCCallUserProfile {
  RCCallUserProfile({
    required this.userId,
    this.mediaId,
    this.mediaType = RCCallMediaType.audio,
    this.enableMicrophone = true,
    this.enableCamera = true,
  });

  factory RCCallUserProfile.fromJson(Map<dynamic, dynamic> json) {
    final mediaTypeIndex = json['mediaType'];
    final mediaType =
        mediaTypeIndex is int &&
            mediaTypeIndex == RCCallMediaType.audio_video.index
        ? RCCallMediaType.audio_video
        : RCCallMediaType.audio;
    return RCCallUserProfile(
      userId: (json['userId'] ?? '').toString(),
      mediaId: json['mediaId']?.toString(),
      mediaType: mediaType,
      enableMicrophone: json['enableMicrophone'] != false,
      enableCamera: json['enableCamera'] != false,
    );
  }

  final String userId;
  final String? mediaId;
  final RCCallMediaType mediaType;
  final bool enableMicrophone;
  final bool enableCamera;
}

class RCCallSession {
  RCCallSession({
    required this.callType,
    required this.mediaType,
    required this.callId,
    required this.targetId,
    required this.mine,
    this.sessionId,
    this.extra,
    int? startTime,
    this.connectedTime = 0,
    this.endTime = 0,
    this.caller,
    this.inviter,
    List<RCCallUserProfile>? users,
  }) : startTime = startTime ?? DateTime.now().millisecondsSinceEpoch,
       users = users ?? <RCCallUserProfile>[];

  final RCCallCallType callType;
  final RCCallMediaType mediaType;
  final String callId;
  final String targetId;
  final String? sessionId;
  final String? extra;
  final int startTime;
  int connectedTime;
  int endTime;
  final RCCallUserProfile? caller;
  final RCCallUserProfile? inviter;
  final RCCallUserProfile mine;
  final List<RCCallUserProfile> users;
}

class RCCallView extends StatelessWidget {
  const RCCallView._({
    required this.fit,
    required this.mirror,
    required RCRTCView this.rtcView,
  });

  static Future<RCCallView> create({
    BoxFit fit = BoxFit.cover,
    bool mirror = false,
  }) async {
    final view = await RCRTCView.create(fit: fit, mirror: mirror);
    return RCCallView._(fit: fit, mirror: mirror, rtcView: view);
  }

  final BoxFit fit;
  final bool mirror;
  final RCRTCView? rtcView;

  @override
  Widget build(BuildContext context) {
    final view = rtcView;
    if (view == null) return const SizedBox.expand();
    return view;
  }
}

class RCCallEngine {
  RCCallEngine._(this._engine, this._currentUserId, this._rtcEngine);

  static const int _joinSameRoomCode = 50002;
  static const int _illegalStateCode = 50007;

  static Future<RCCallEngine> create(
    RCIMIWEngine? engine, {
    String? currentUserId,
  }) async {
    final rtcEngine = await RCRTCEngine.create();
    final callEngine = RCCallEngine._(engine, currentUserId ?? '', rtcEngine);
    callEngine._bindRtcListeners();
    return callEngine;
  }

  final RCIMIWEngine? _engine;
  String _currentUserId;
  RCRTCEngine _rtcEngine;
  RCCallSession? _currentSession;
  Future<int>? _leavingRoomFuture;
  Future<int>? _finishingCallFuture;
  String? _joinedRoomId;
  bool _microphoneEnabled = true;
  bool _speakerEnabled = true;
  bool _cameraEnabled = true;

  Function(RCCallSession session)? onReceiveCall;
  Function()? onCallDidMake;
  Function(String userId)? onRemoteUserDidRing;
  Function(RCCallUserProfile user)? onRemoteUserDidJoin;
  Function(String userId)? onRemoteUserDidLeave;
  Function(RCCallUserProfile user, RCCallMediaType mediaType)?
  onRemoteUserDidChangeMediaType;
  Function()? onConnect;
  Function(RCCallDisconnectReason reason)? onDisconnect;
  Function(int errorCode)? onCallError;
  Function(RCCallCamera camera, bool enabled)? onEnableCamera;
  Function(RCCallUserProfile user, bool enabled)?
  onRemoteUserDidChangeMicrophoneState;
  Function(RCCallUserProfile user, bool enabled)?
  onRemoteUserDidChangeCameraState;
  Function(RCCallUserProfile user, int volume)? onAudioVolume;

  void updateCurrentUserId(String? userId) {
    if (userId == null || userId.isEmpty) return;
    _currentUserId = userId;
  }

  void _bindRtcListeners() {
    unawaited(_rtcEngine.setStatsListener(_RCCallStatsListener(this)));

    _rtcEngine.onUserJoined = (roomId, userId) {
      debugPrint('onUserJoined------------');
      if (_currentSession?.callId != roomId || userId == _currentUserId) {
        return;
      }
      final user = RCCallUserProfile(
        userId: userId,
        mediaId: '',
        mediaType: _currentSession?.mediaType ?? RCCallMediaType.audio,
        enableMicrophone: true,
        enableCamera: false,
      );
      onRemoteUserDidJoin?.call(user);
    };
    _rtcEngine.onRemotePublished = (roomId, userId, mediaType) async {
      if (_currentSession?.callId != roomId || userId == _currentUserId) {
        return;
      }
      await _rtcEngine.subscribe(userId, mediaType, false);
      onRemoteUserDidChangeMediaType?.call(
        RCCallUserProfile(
          userId: userId,
          mediaId: 'remote',
          mediaType: _callMediaType(mediaType),
          enableMicrophone: true,
          enableCamera: mediaType == RCRTCMediaType.audio_video,
        ),
        _callMediaType(mediaType),
      );
    };
    _rtcEngine.onUserLeft = (roomId, userId) {
      debugPrint('onUserLeft------------');
      if (_currentSession?.callId != roomId || userId == _currentUserId) {
        return;
      }
      if (_currentSession?.callType == RCCallCallType.single) {
        unawaited(
          _finishCall(disconnectReason: RCCallDisconnectReason.remote_hangup),
        );
        return;
      }
      onRemoteUserDidLeave?.call(userId);
    };
    _rtcEngine.onUserOffline = (roomId, userId) {
      if (_currentSession?.callId != roomId || userId == _currentUserId) {
        return;
      }
      if (_currentSession?.callType == RCCallCallType.single) {
        unawaited(
          _finishCall(
            disconnectReason: RCCallDisconnectReason.remote_network_error,
          ),
        );
        return;
      }
      onRemoteUserDidLeave?.call(userId);
    };
  }

  Future<void> _recreateRtcEngine() async {
    debugPrint('[RCCall] recreate rtc engine');
    try {
      await _rtcEngine.destroy();
    } catch (error) {
      debugPrint('[RCCall] destroy rtc engine failed: $error');
    }
    _rtcEngine = await RCRTCEngine.create();
    _bindRtcListeners();
  }

  void _handleLocalAudioStats(RCRTCLocalAudioStats stats) {
    final session = _currentSession;
    final mine = session?.mine;
    if (session == null || mine == null || mine.userId.isEmpty) return;

    onAudioVolume?.call(
      RCCallUserProfile(
        userId: mine.userId,
        mediaId: mine.mediaId,
        mediaType: session.mediaType,
        enableMicrophone: _microphoneEnabled,
        enableCamera: _cameraEnabled,
      ),
      stats.volume,
    );
  }

  void _handleRemoteAudioStats(
    String roomId,
    String userId,
    RCRTCRemoteAudioStats stats,
  ) {
    final session = _currentSession;
    if (session == null ||
        session.callId != roomId ||
        userId.isEmpty ||
        userId == _currentUserId) {
      return;
    }

    final user = session.users.firstWhere(
      (item) => item.userId == userId,
      orElse: () => RCCallUserProfile(
        userId: userId,
        mediaType: session.mediaType,
        enableMicrophone: true,
      ),
    );
    onAudioVolume?.call(user, stats.volume);
  }

  Future<RCCallSession?> startCall(
    String targetId,
    RCCallMediaType mediaType, [
    String? extra,
    RCCallCallType callType = RCCallCallType.single,
    List<String>? userIds,
    List<String>? observerUserIds,
  ]) async {
    if (_engine == null) return null;
    final mine = RCCallUserProfile(
      userId: _currentUserId,
      mediaId: 'local',
      mediaType: mediaType,
    );
    _currentSession = RCCallSession(
      callType: callType,
      mediaType: mediaType,
      callId: DateTime.now().microsecondsSinceEpoch.toString(),
      targetId: targetId,
      extra: extra,
      mine: mine,
      caller: mine,
      users: (userIds ?? const <String>[])
          .map(
            (userId) => RCCallUserProfile(
              userId: userId,
              mediaType: mediaType,
              mediaId: '',
            ),
          )
          .toList(),
    );
    onCallDidMake?.call();
    return _currentSession;
  }

  void setCurrentSession(RCCallSession session) {
    _currentSession = session;
  }

  Future<int> accept() async {
    final code = await joinCurrentRoom();
    return code;
  }

  Future<int> joinCurrentRoom({bool notifyConnected = true}) async {
    var code = await _joinCurrentRoomOnce(notifyConnected: notifyConnected);
    if (code == _illegalStateCode) {
      await _recreateRtcEngine();
      code = await _joinCurrentRoomOnce(notifyConnected: notifyConnected);
    }
    return code;
  }

  Future<int> _joinCurrentRoomOnce({required bool notifyConnected}) async {
    final session = _currentSession;
    if (session == null || session.callId.isEmpty) return -1;
    await _waitForPendingLeave();
    final mediaType = _rtcMediaType(session.mediaType);
    debugPrint(
      '[RCCall] joinCurrentRoom start '
      'roomId=${session.callId} targetId=${session.targetId} '
      'callType=${session.callType.name} mediaType=${session.mediaType.name} '
      'currentUserId=$_currentUserId',
    );
    final preconnectCode = await _rtcEngine.preconnectToMediaServer();
    debugPrint(
      '[RCCall] preconnectToMediaServer result: code=$preconnectCode '
      'roomId=${session.callId}',
    );
    if (preconnectCode != 0) {
      debugPrint('rtc preconnect failed: $preconnectCode');
      return preconnectCode;
    }

    final roomJoinedCode = Completer<int>();
    final previousOnRoomJoined = _rtcEngine.onRoomJoined;
    _rtcEngine.onRoomJoined = (code, message) {
      if (!roomJoinedCode.isCompleted) {
        roomJoinedCode.complete(code);
      }
      debugPrint(
        '[RCCall] onRoomJoined: code=$code message=$message '
        'roomId=${session.callId}',
      );
      if (code != 0) {
        debugPrint('rtc room joined failed: code=$code message=$message');
      }
    };

    final joinRet = await _rtcEngine.joinRoom(
      session.callId,
      RCRTCRoomSetup.create(
        mediaType: mediaType,
        role: RCRTCRole.meeting_member,
      ),
    );
    debugPrint(
      '[RCCall] joinRoom return: code=$joinRet roomId=${session.callId}',
    );
    if (joinRet != 0) {
      _rtcEngine.onRoomJoined = previousOnRoomJoined;
      if (joinRet == _joinSameRoomCode && _joinedRoomId == session.callId) {
        return _completeAlreadyJoinedRoom(session, notifyConnected);
      }
      debugPrint(
        'rtc join room failed: code=$joinRet roomId=${session.callId}',
      );
      return joinRet;
    }

    final joinCode = await roomJoinedCode.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => -2,
    );
    debugPrint(
      '[RCCall] onRoomJoined final code=$joinCode roomId=${session.callId}',
    );
    _rtcEngine.onRoomJoined = previousOnRoomJoined;
    if (joinCode != 0) {
      if (joinCode == _joinSameRoomCode && _joinedRoomId == session.callId) {
        return _completeAlreadyJoinedRoom(session, notifyConnected);
      }
      return joinCode;
    }

    await _rtcEngine.enableSpeaker(_speakerEnabled);
    await _rtcEngine.enableMicrophone(_microphoneEnabled);
    if (session.mediaType == RCCallMediaType.audio_video) {
      await _rtcEngine.enableCamera(_cameraEnabled, RCRTCCamera.front);
    }
    final publishCode = await _rtcEngine.publish(mediaType);
    debugPrint(
      '[RCCall] publish return: code=$publishCode roomId=${session.callId} '
      'mediaType=$mediaType',
    );
    if (publishCode != 0) {
      debugPrint(
        'rtc publish failed: code=$publishCode roomId=${session.callId}',
      );
      return publishCode;
    }

    for (final user in session.users) {
      if (user.userId.isNotEmpty && user.userId != _currentUserId) {
        await _rtcEngine.subscribe(user.userId, mediaType, false);
      }
    }

    session.connectedTime = DateTime.now().millisecondsSinceEpoch;
    _joinedRoomId = session.callId;
    if (notifyConnected) {
      onConnect?.call();
    }
    return 0;
  }

  Future<void> _waitForPendingLeave() async {
    final leaving = _leavingRoomFuture;
    if (leaving == null) return;
    await leaving.timeout(const Duration(seconds: 2), onTimeout: () => -2);
  }

  Future<int> _completeAlreadyJoinedRoom(
    RCCallSession session,
    bool notifyConnected,
  ) async {
    session.connectedTime = session.connectedTime == 0
        ? DateTime.now().millisecondsSinceEpoch
        : session.connectedTime;
    if (notifyConnected) {
      onConnect?.call();
    }
    return 0;
  }

  Future<int> hangup({bool notifyDisconnect = true}) async {
    return _finishCall(
      disconnectReason: notifyDisconnect ? RCCallDisconnectReason.hangup : null,
    );
  }

  Future<int> _finishCall({required RCCallDisconnectReason? disconnectReason}) {
    final finishing = _finishingCallFuture;
    if (finishing != null) return finishing;

    _finishingCallFuture = (() async {
      _currentSession?.endTime = DateTime.now().millisecondsSinceEpoch;
      final code = await _leaveRoom();
      if (disconnectReason != null) {
        onDisconnect?.call(disconnectReason);
      }
      _currentSession = null;
      return code;
    })();

    _finishingCallFuture = _finishingCallFuture!.whenComplete(() {
      _finishingCallFuture = null;
    });
    return _finishingCallFuture!;
  }

  Future<int> _leaveRoom() {
    final leaving = _leavingRoomFuture;
    if (leaving != null) return leaving;

    final completer = Completer<int>();
    final previousOnRoomLeft = _rtcEngine.onRoomLeft;
    _rtcEngine.onRoomLeft = (code, message) {
      if (!completer.isCompleted) {
        completer.complete(code);
      }
      if (code != 0) {
        debugPrint('rtc room left failed: code=$code message=$message');
      }
      previousOnRoomLeft?.call(code, message);
    };

    _leavingRoomFuture = (() async {
      final leaveRet = await _rtcEngine.leaveRoom();
      if (leaveRet != 0) {
        if (!completer.isCompleted) {
          completer.complete(leaveRet);
        }
      }
      final code = await completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => leaveRet,
      );
      _rtcEngine.onRoomLeft = previousOnRoomLeft;
      _joinedRoomId = null;
      _leavingRoomFuture = null;
      return code;
    })();

    return _leavingRoomFuture!;
  }

  Future<int> enableMicrophone(bool enabled) async {
    _microphoneEnabled = enabled;
    return _rtcEngine.enableMicrophone(enabled);
  }

  Future<int> enableSpeaker(bool enabled) async {
    _speakerEnabled = enabled;
    return _rtcEngine.enableSpeaker(enabled);
  }

  Future<int> enableCamera(bool enabled, [RCCallCamera? camera]) async {
    _cameraEnabled = enabled;
    onEnableCamera?.call(camera ?? RCCallCamera.front, enabled);
    return _rtcEngine.enableCamera(enabled, _rtcCamera(camera));
  }

  Future<int> switchCamera() => _rtcEngine.switchCamera();

  Future<int> setVideoView(String userId, RCCallView? view) async {
    final rtcView = view?.rtcView;
    if (userId == _currentUserId) {
      return setLocalVideoView(view);
    }
    if (rtcView == null) return _rtcEngine.removeRemoteView(userId);
    return _rtcEngine.setRemoteView(userId, rtcView);
  }

  Future<int> setLocalVideoView(RCCallView? view) async {
    final rtcView = view?.rtcView;
    if (rtcView == null) return _rtcEngine.removeLocalView();
    return _rtcEngine.setLocalView(rtcView);
  }

  Future<RCCallSession?> getCurrentCallSession() async => _currentSession;

  bool get microphoneEnabled => _microphoneEnabled;
  bool get speakerEnabled => _speakerEnabled;
  bool get cameraEnabled => _cameraEnabled;

  RCRTCMediaType _rtcMediaType(RCCallMediaType mediaType) {
    return mediaType == RCCallMediaType.audio_video
        ? RCRTCMediaType.audio_video
        : RCRTCMediaType.audio;
  }

  RCCallMediaType _callMediaType(RCRTCMediaType mediaType) {
    return mediaType == RCRTCMediaType.audio_video
        ? RCCallMediaType.audio_video
        : RCCallMediaType.audio;
  }

  RCRTCCamera _rtcCamera(RCCallCamera? camera) {
    return switch (camera) {
      RCCallCamera.back => RCRTCCamera.back,
      RCCallCamera.none => RCRTCCamera.none,
      _ => RCRTCCamera.front,
    };
  }
}

class _RCCallStatsListener extends RCRTCStatsListener {
  _RCCallStatsListener(this.engine);

  final RCCallEngine engine;

  @override
  void onLocalAudioStats(RCRTCLocalAudioStats stats) {
    engine._handleLocalAudioStats(stats);
  }

  @override
  void onRemoteAudioStats(
    String roomId,
    String userId,
    RCRTCRemoteAudioStats stats,
  ) {
    engine._handleRemoteAudioStats(roomId, userId, stats);
  }
}
