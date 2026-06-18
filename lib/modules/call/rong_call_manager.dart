import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/core/models/group_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../router/app_router.dart';
import '../../widgets/base/app_localizations.dart';
import '../../widgets/common/app_toast.dart';
import '../im/listener/group_state_center.dart';
import '../im/manager/im_send_manager.dart';
import '../im/manager/im_engine_manager.dart';
import '../im/manager/im_user_manager.dart';
import 'rong_call_invite_update_message.dart';
import 'rong_call_join_request_message.dart';
import 'rong_group_call_status_message.dart';
import 'rong_call_summary_parser.dart';
import 'rong_call_types.dart';

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
    this.inviter = '',
    this.mediaType = RCCallMediaType.audio,
    this.isGroupCall = false,
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
    this.invitedUserIds = const [],
    this.speakingUserIds = const [],
  });

  const RongCallState.idle() : this(status: RongCallStatus.idle);

  final RongCallStatus status;
  final String targetId;
  final String displayName;
  final String avatar;
  final String inviter;
  final RCCallMediaType mediaType;
  final bool isGroupCall;
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
  final List<String> invitedUserIds;
  final List<String> speakingUserIds;

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
    String? avatar,
    String? inviter,
    RCCallMediaType? mediaType,
    bool? isGroupCall,
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
    List<String>? invitedUserIds,
    List<String>? speakingUserIds,
    bool clearDisconnectReason = false,
    bool clearErrorCode = false,
    bool clearSession = false,
    bool clearLocalVideoView = false,
    bool clearRemoteVideoView = false,
  }) {
    return RongCallState(
      status: status ?? this.status,
      targetId: targetId ?? this.targetId,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      inviter: inviter ?? this.inviter,
      mediaType: mediaType ?? this.mediaType,
      isGroupCall: isGroupCall ?? this.isGroupCall,
      isOutgoing: isOutgoing ?? this.isOutgoing,
      micEnabled: micEnabled ?? this.micEnabled,
      speakerEnabled: speakerEnabled ?? this.speakerEnabled,
      cameraEnabled: cameraEnabled ?? this.cameraEnabled,
      remoteMicEnabled: remoteMicEnabled ?? this.remoteMicEnabled,
      remoteCameraEnabled: remoteCameraEnabled ?? this.remoteCameraEnabled,
      disconnectReason: clearDisconnectReason
          ? null
          : disconnectReason ?? this.disconnectReason,
      errorCode: clearErrorCode ? null : errorCode ?? this.errorCode,
      session: clearSession ? null : session ?? this.session,
      localVideoView: clearLocalVideoView
          ? null
          : localVideoView ?? this.localVideoView,
      remoteVideoView: clearRemoteVideoView
          ? null
          : remoteVideoView ?? this.remoteVideoView,
      connectedTimeMs: connectedTimeMs ?? this.connectedTimeMs,
      invitedUserIds: invitedUserIds ?? this.invitedUserIds,
      speakingUserIds: speakingUserIds ?? this.speakingUserIds,
    );
  }
}

class RongCallManager {
  RongCallManager._();
  static final RongCallManager _instance = RongCallManager._();
  factory RongCallManager() => _instance;

  static const int _speakingVolumeThreshold = 4;
  static const int _speakingHoldMs = 1200;

  final StreamController<RongCallState> _stateController =
      StreamController<RongCallState>.broadcast();

  RCCallEngine? _engine;
  RongCallState _state = const RongCallState.idle();
  StreamSubscription<RongCallInviteUpdate>? _inviteUpdateSub;
  StreamSubscription<RongCallJoinRequest>? _joinRequestSub;
  StreamSubscription<RongCallSummaryEvent>? _summarySub;
  StreamSubscription<RongGroupCallStatus?>? _groupCallStatusSub;
  Timer? _groupCallSessionRefreshTimer;
  Timer? _singleMemberGroupCallTimer;
  Timer? _speakingCleanupTimer;
  bool _isInitializing = false;
  bool _callSummaryMessageRegistered = false;
  bool _callInviteUpdateMessageRegistered = false;
  bool _groupCallStatusMessageRegistered = false;
  bool _isRefreshingGroupCallSession = false;
  Future<void>? _videoViewsFuture;
  bool _localVideoViewBound = false;
  bool _remoteVideoViewBound = false;
  RCCallDisconnectReason? _localDisconnectReasonOverride;
  final Set<String> _sentSummaryKeys = <String>{};
  final Map<String, int> _speakingUntilMsByUserId = {};
  RongGroupCallStatus? _pendingJoinStatus;
  String _lastGroupCallStatusKey = '';

  Stream<RongCallState> get stateStream => _stateController.stream;
  RongCallState get state => _state;

  Future<void> init() async {
    if (_engine != null) {
      _syncEngineCurrentUserId();
      _ensureCallMessageSubscriptions();
      return;
    }
    if (_isInitializing) return;
    _isInitializing = true;
    try {
      _engine = await RCCallEngine.create(
        IMEngineManager().engine,
        currentUserId: IMEngineManager().currentUserId,
      );
      _syncEngineCurrentUserId();
      _bindListeners();
      _ensureCallMessageSubscriptions();
      await _registerCallMessages();
      await _disableNativeCallSummary();
    } finally {
      _isInitializing = false;
    }
  }

  void _syncEngineCurrentUserId() {
    _engine?.updateCurrentUserId(IMEngineManager().currentUserId);
  }

  void _ensureCallMessageSubscriptions() {
    _inviteUpdateSub ??= RongCallInviteUpdateCenter().stream.listen(
      _handleInviteUpdate,
    );
    _joinRequestSub ??= RongCallJoinRequestCenter().stream.listen(
      _handleJoinRequest,
    );
    _summarySub ??= RongCallSummaryCenter().stream.listen(
      _handlePreConnectCallSummary,
    );
    _groupCallStatusSub ??= RongGroupCallStatusCenter().stream.listen(
      _handleGroupCallStatus,
    );
  }

  Future<void> _registerCallMessages() async {
    final engine = IMEngineManager().engine;
    if (engine == null) return;
    await Future.wait([
      _ensureCallSummaryMessageRegistered(engine),
      _ensureCallInviteUpdateMessageRegistered(engine),
      _ensureCallJoinRequestMessageRegistered(engine),
      _ensureGroupCallStatusMessageRegistered(engine),
    ]);
  }

  Future<bool> startPrivateCall({
    required String targetId,
    required String displayName,
    required RCCallMediaType mediaType,
    String avatar = '',
  }) async {
    await init();
    _syncEngineCurrentUserId();
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
        avatar: avatar,
        mediaType: mediaType,
        isGroupCall: false,
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
        await _failActiveCall();
        AppToast.showInfo(AppLocalizations.currentText('call_start_failed'));
        return false;
      }
      await _disableNativeCallSummary();
      _setState(_state.copyWith(session: session));
      final invited = await _sendPrivateCallInvite(targetId);
      if (!invited) {
        await _failActiveCall();
        AppToast.showInfo(AppLocalizations.currentText('call_start_failed'));
        return false;
      }
      final joined =
          await _engine?.joinCurrentRoom(notifyConnected: false) ?? -1;
      if (joined != 0) {
        await _failActiveCall(errorCode: joined);
        AppToast.showInfo(
          AppLocalizations.currentText('call_error_code', {'code': joined}),
        );
        return false;
      }
      return true;
    } catch (_) {
      await _failActiveCall();
      AppToast.showInfo(AppLocalizations.currentText('call_start_failed'));
      return false;
    }
  }

  Future<bool> startGroupCall({
    required String targetId,
    required String displayName,
    required RCCallMediaType mediaType,
    List<String>? inviteeUserIds,
  }) async {
    await init();
    _syncEngineCurrentUserId();
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
    final userIds =
        inviteeUserIds ??
        (await _groupCallMembers(
          targetId,
        )).map((item) => item.userId ?? '').toList();
    if (userIds.isEmpty) {
      AppToast.showInfo(AppLocalizations.currentText('call_start_failed'));
      return false;
    }

    _setState(
      RongCallState(
        status: RongCallStatus.dialing,
        targetId: targetId,
        displayName: displayName,
        mediaType: mediaType,
        isGroupCall: true,
        isOutgoing: true,
        speakerEnabled: mediaType == RCCallMediaType.audio_video,
        cameraEnabled: mediaType == RCCallMediaType.audio_video,
        invitedUserIds: userIds,
      ),
    );

    try {
      final session = await _engine?.startCall(
        targetId,
        mediaType,
        displayName,
        RCCallCallType.group,
        userIds,
      );
      if (session == null) {
        await _failActiveCall();
        AppToast.showInfo(AppLocalizations.currentText('call_start_failed'));
        return false;
      }
      await _disableNativeCallSummary();
      _setState(
        _state.copyWith(
          session: session,
          isGroupCall:
              _state.isGroupCall || session.callType == RCCallCallType.group,
        ),
      );
      final invited = await _sendGroupCallInviteUpdate(userIds);
      if (!invited) {
        await _failActiveCall();
        AppToast.showInfo(AppLocalizations.currentText('call_start_failed'));
        return false;
      }
      final joined = await _engine?.joinCurrentRoom() ?? -1;
      if (joined != 0) {
        await _failActiveCall(errorCode: joined);
        AppToast.showInfo(
          AppLocalizations.currentText('call_error_code', {'code': joined}),
        );
        return false;
      }
      unawaited(_publishGroupCallStatus(_state, force: true));
      return true;
    } catch (_) {
      await _failActiveCall();
      AppToast.showInfo(AppLocalizations.currentText('call_start_failed'));
      return false;
    }
  }

  Future<bool> accept() async {
    await init();
    _syncEngineCurrentUserId();
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
      await _failActiveCall();
      print('call_answer_failed_code------1');
      AppToast.showInfo(
        AppLocalizations.currentText('call_answer_failed_code', {'code': code}),
      );
      return false;
    }
    return true;
  }

  Future<bool> joinActiveGroupCall(RongGroupCallStatus status) async {
    return joinActiveGroupCallDirectly(status);
  }

  Future<bool> joinActiveGroupCallDirectly(RongGroupCallStatus status) async {
    await init();
    _syncEngineCurrentUserId();
    if (!status.isActive || status.targetId.isEmpty || status.callId.isEmpty) {
      AppToast.showInfo(AppLocalizations.currentText('call_start_failed'));
      return false;
    }
    if (!IMEngineManager().connection.isConnected) {
      AppToast.showInfo(AppLocalizations.currentText('call_im_not_connected'));
      return false;
    }
    if (_state.isActive) {
      if (_state.isGroupCall && _state.targetId == status.targetId) {
        return true;
      }
      AppToast.showInfo(AppLocalizations.currentText('call_in_progress'));
      return false;
    }
    if (!await _ensurePermissions(status.mediaType)) {
      AppToast.showInfo(
        AppLocalizations.currentText('call_permission_required'),
      );
      return false;
    }

    final session = _incomingSession(
      callType: RCCallCallType.group,
      mediaType: status.mediaType,
      targetId: status.targetId,
      callId: status.callId,
      inviterUserId: status.initiatorUserId,
      userIds: status.activeUserIds,
    );
    _engine?.setCurrentSession(session);
    _setState(
      RongCallState(
        status: RongCallStatus.connecting,
        targetId: status.targetId,
        displayName: status.displayName,
        inviter: status.initiatorUserId,
        mediaType: status.mediaType,
        isGroupCall: true,
        isOutgoing: false,
        session: session,
        cameraEnabled: status.mediaType == RCCallMediaType.audio_video,
        speakerEnabled: status.mediaType == RCCallMediaType.audio_video,
        invitedUserIds: status.invitedUserIds,
      ),
    );

    final code = await _engine?.accept() ?? -1;
    if (code != 0) {
      try {
        await _engine?.hangup(notifyDisconnect: false);
      } catch (e) {
        debugPrint('hangup failed direct group join failed: $e');
      }
      _clearSpeakingUsers();
      _setState(_state.copyWith(status: RongCallStatus.error, errorCode: code));
      print('call_answer_failed_code------2');
      AppToast.showInfo(
        AppLocalizations.currentText('call_answer_failed_code', {'code': code}),
      );
      return false;
    }
    return true;
  }

  Future<bool> requestJoinActiveGroupCall(RongGroupCallStatus status) async {
    await init();
    if (!status.isActive || status.targetId.isEmpty) return false;
    if (!IMEngineManager().connection.isConnected) {
      AppToast.showInfo(AppLocalizations.currentText('call_im_not_connected'));
      return false;
    }
    if (_state.isActive) {
      if (_state.isGroupCall && _state.targetId == status.targetId) {
        final isSyntheticIncomingInvite =
            _state.status == RongCallStatus.incoming && _state.session == null;
        if (!isSyntheticIncomingInvite) return true;
      } else {
        AppToast.showInfo(AppLocalizations.currentText('call_in_progress'));
        return false;
      }
    }
    if (!await _ensurePermissions(status.mediaType)) {
      AppToast.showInfo(
        AppLocalizations.currentText('call_permission_required'),
      );
      return false;
    }

    final currentUserId = IMEngineManager().currentUserId;
    final notifyUserIds = status.activeUserIds
        .where((userId) => userId.isNotEmpty && userId != currentUserId)
        .toSet()
        .toList();
    if (currentUserId == null ||
        currentUserId.isEmpty ||
        notifyUserIds.isEmpty) {
      AppToast.showInfo(AppLocalizations.currentText('call_start_failed'));
      return false;
    }

    final engine = IMEngineManager().engine;
    if (engine == null) return false;
    if (!await _ensureCallJoinRequestMessageRegistered(engine)) return false;

    try {
      final message = await engine.createNativeCustomMessage(
        RCIMIWConversationType.group,
        status.targetId,
        null,
        RongCallJoinRequestMessage.objectName,
        {
          'targetId': status.targetId,
          'mediaType': status.mediaType.index,
          'displayName': status.displayName,
          'requesterUserId': currentUserId,
          'sentAt': DateTime.now().millisecondsSinceEpoch,
        },
      );
      if (message == null) return false;
      final completer = Completer<bool>();
      final ret = await engine.sendGroupMessageToDesignatedUsers(
        message,
        notifyUserIds,
        callback: RCIMIWSendGroupMessageToDesignatedUsersCallback(
          onMessageSent: (code, _) {
            if (!completer.isCompleted) {
              completer.complete(code == 0);
            }
          },
        ),
      );
      if (ret != 0) return false;
      final sent = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );
      if (sent) {
        _pendingJoinStatus = status;
      }
      return sent;
    } catch (e) {
      debugPrint('send group call join request failed: $e');
      return false;
    }
  }

  Future<List<RCIMIWGroupMemberInfo>> _groupCallMembers(String groupId) async {
    final currentUserId = IMEngineManager().currentUserId;
    final members = await GroupStateCenter().getGroupMembers(groupId);
    return members.where((item) => item.userId != currentUserId).toList();
  }

  Future<bool> inviteGroupCallMembers(List<String> userIds) async {
    await init();
    final session = _state.session;
    final targetId = session?.targetId ?? _state.targetId;
    if (targetId.isEmpty || userIds.isEmpty) return false;
    if (session == null || session.callId.isEmpty) {
      AppToast.showInfo(AppLocalizations.currentText('chat_invite_failed'));
      return false;
    }
    if (!_state.isGroupCall || !_state.isActive) {
      AppToast.showInfo(AppLocalizations.currentText('call_start_failed'));
      return false;
    }

    try {
      final existingUserIds = session.users.map((user) => user.userId).toSet();
      for (final userId in userIds) {
        if (userId.isEmpty || existingUserIds.contains(userId)) continue;
        existingUserIds.add(userId);
        session.users.add(
          RCCallUserProfile(userId: userId, mediaType: _state.mediaType),
        );
      }
      _setState(
        _state.copyWith(
          session: session,
          invitedUserIds: {..._state.invitedUserIds, ...userIds}.toList(),
        ),
      );
      final invited = await _sendGroupCallInviteUpdate(userIds);
      if (!invited) {
        AppToast.showInfo(AppLocalizations.currentText('chat_invite_failed'));
        return false;
      }
      unawaited(_publishGroupCallStatus(_state, force: true));
      return true;
    } catch (_) {
      AppToast.showInfo(AppLocalizations.currentText('chat_invite_failed'));
      return false;
    }
  }

  Future<void> _handleInviteUpdate(RongCallInviteUpdate update) async {
    final currentUserId = IMEngineManager().currentUserId;
    if (update.senderUserId == currentUserId) return;
    if (currentUserId != null &&
        update.invitedUserIds.contains(currentUserId) &&
        !_state.isActive) {
      if (update.isGroupCall) {
        _handleIncomingGroupCallInviteUpdate(update);
      } else {
        _handleIncomingPrivateCallInvite(update);
      }
      return;
    }
    if (!_state.isGroupCall ||
        !_state.isActive ||
        _state.targetId != update.targetId) {
      return;
    }

    _setState(
      _state.copyWith(
        invitedUserIds: {
          ..._state.invitedUserIds,
          ...update.invitedUserIds,
        }.toList(),
      ),
    );
    unawaited(_publishGroupCallStatus(_state, force: true, sendMessage: false));
    await _refreshGroupCallSession();
  }

  void _handleIncomingPrivateCallInvite(RongCallInviteUpdate update) {
    final mediaType = update.mediaTypeIndex == RCCallMediaType.audio_video.index
        ? RCCallMediaType.audio_video
        : RCCallMediaType.audio;
    final callerUserId = update.senderUserId.isNotEmpty
        ? update.senderUserId
        : update.initiatorUserId;
    if (callerUserId.isEmpty) return;

    _setState(
      RongCallState(
        status: RongCallStatus.incoming,
        targetId: callerUserId,
        displayName: callerUserId,
        inviter: callerUserId,
        mediaType: mediaType,
        isGroupCall: false,
        isOutgoing: false,
        session: _incomingSession(
          callType: RCCallCallType.single,
          mediaType: mediaType,
          targetId: callerUserId,
          callId: update.callId,
          inviterUserId: callerUserId,
        ),
        cameraEnabled: mediaType == RCCallMediaType.audio_video,
        speakerEnabled: mediaType == RCCallMediaType.audio_video,
      ),
    );
    final session = _state.session;
    if (session != null) _engine?.setCurrentSession(session);
    _openIncomingCallPage(
      displayName: callerUserId,
      targetId: callerUserId,
      mediaType: mediaType,
      isGroupCall: false,
    );
    unawaited(_resolveIncomingDisplayName(callerUserId));
  }

  void _handleIncomingGroupCallInviteUpdate(RongCallInviteUpdate update) {
    final mediaType = update.mediaTypeIndex == RCCallMediaType.audio_video.index
        ? RCCallMediaType.audio_video
        : RCCallMediaType.audio;
    final activeUserIds = {
      ...update.activeUserIds,
      if (update.senderUserId.isNotEmpty) update.senderUserId,
    }.where((userId) => userId.isNotEmpty).toList();
    final status = RongGroupCallStatus(
      targetId: update.targetId,
      action: RongGroupCallStatusAction.active,
      mediaType: mediaType,
      displayName: update.displayName,
      initiatorUserId: update.initiatorUserId.isNotEmpty
          ? update.initiatorUserId
          : update.senderUserId,
      callId: update.callId,
      activeUserIds: activeUserIds,
      invitedUserIds: update.invitedUserIds,
      sentAt: update.sentAt,
    );
    RongGroupCallStatusCenter().updateLocal(status);
    _setState(
      RongCallState(
        status: RongCallStatus.incoming,
        targetId: update.targetId,
        displayName: update.displayName.isNotEmpty
            ? update.displayName
            : update.targetId,
        inviter: update.senderUserId,
        mediaType: mediaType,
        isGroupCall: true,
        isOutgoing: false,
        session: _incomingSession(
          callType: RCCallCallType.group,
          mediaType: mediaType,
          targetId: update.targetId,
          callId: update.callId,
          inviterUserId: update.senderUserId,
          userIds: {...activeUserIds, ...update.invitedUserIds}.toList(),
        ),
        cameraEnabled: mediaType == RCCallMediaType.audio_video,
        speakerEnabled: mediaType == RCCallMediaType.audio_video,
        invitedUserIds: update.invitedUserIds,
      ),
    );
    final session = _state.session;
    if (session != null) _engine?.setCurrentSession(session);
    _openIncomingCallPage(
      displayName: update.displayName.isNotEmpty
          ? update.displayName
          : update.targetId,
      targetId: update.targetId,
      mediaType: mediaType,
      isGroupCall: true,
    );
    unawaited(_resolveIncomingGroupName(update.targetId));
  }

  RCCallSession _incomingSession({
    required RCCallCallType callType,
    required RCCallMediaType mediaType,
    required String targetId,
    required String callId,
    required String inviterUserId,
    List<String> userIds = const [],
  }) {
    final currentUserId = IMEngineManager().currentUserId ?? '';
    final roomId = callId.isNotEmpty
        ? callId
        : [
            callType.name,
            targetId,
            inviterUserId,
            DateTime.now().millisecondsSinceEpoch,
          ].join(':');
    final mine = RCCallUserProfile(
      userId: currentUserId,
      mediaId: 'local',
      mediaType: mediaType,
    );
    final inviter = RCCallUserProfile(
      userId: inviterUserId,
      mediaId: 'remote',
      mediaType: mediaType,
    );
    return RCCallSession(
      callType: callType,
      mediaType: mediaType,
      callId: roomId,
      targetId: targetId,
      mine: mine,
      inviter: inviter,
      caller: inviter,
      users: {inviterUserId, ...userIds}
          .where((userId) => userId.isNotEmpty && userId != currentUserId)
          .map(
            (userId) => RCCallUserProfile(
              userId: userId,
              mediaId: userId == inviterUserId ? 'remote' : '',
              mediaType: mediaType,
            ),
          )
          .toList(),
    );
  }

  Future<void> _handleJoinRequest(RongCallJoinRequest request) async {
    final currentUserId = IMEngineManager().currentUserId;
    if (currentUserId == null ||
        currentUserId.isEmpty ||
        request.requesterUserId == currentUserId ||
        request.targetId != _state.targetId ||
        !_state.isGroupCall ||
        !_state.isActive ||
        _state.session == null) {
      return;
    }

    final alreadyInCall = {
      currentUserId,
      ..._activeRemoteUserIds(),
    }.contains(request.requesterUserId);
    if (alreadyInCall) return;

    await inviteGroupCallMembers([request.requesterUserId]);
  }

  Future<void> _handlePreConnectCallSummary(RongCallSummaryEvent event) async {
    final currentUserId = IMEngineManager().currentUserId;
    if (event.senderUserId.isNotEmpty && event.senderUserId == currentUserId) {
      return;
    }
    if (!_state.isActive || _state.status == RongCallStatus.inCall) return;
    if (!_isSamePreConnectCallSummary(event)) return;

    final reason = _remoteDisconnectReasonFromSummary(event);
    final endedState = _state.copyWith(
      status: RongCallStatus.ended,
      disconnectReason: reason,
    );
    try {
      await _engine?.hangup(notifyDisconnect: false);
    } catch (e) {
      debugPrint('hangup pre-connect ended call failed: $e');
    }
    _clearSpeakingUsers();
    _localVideoViewBound = false;
    _remoteVideoViewBound = false;
    _setState(endedState);
    unawaited(_publishGroupCallEnded(endedState));
    AppToast.showInfo(_disconnectText(reason));
  }

  Future<void> _handleGroupCallStatus(RongGroupCallStatus? status) async {
    if (status == null ||
        !_state.isGroupCall ||
        !_state.isActive ||
        status.targetId != _state.targetId) {
      return;
    }

    if (!status.isActive) {
      final endedState = _state.copyWith(
        status: RongCallStatus.ended,
        disconnectReason: RCCallDisconnectReason.remote_hangup,
      );
      try {
        await _engine?.hangup(notifyDisconnect: false);
      } catch (e) {
        debugPrint('hangup ended group call failed: $e');
      }
      _clearSpeakingUsers();
      _localVideoViewBound = false;
      _remoteVideoViewBound = false;
      _setState(endedState);
      AppToast.showInfo(AppLocalizations.currentText('call_ended'));
      return;
    }

    final currentUserId = IMEngineManager().currentUserId;
    final visibleUserIds = {
      ...status.activeUserIds,
      ...status.invitedUserIds,
    }.where((userId) => userId.isNotEmpty && userId != currentUserId).toSet();
    final session = _state.session;
    if (session != null) {
      session.users.removeWhere(
        (user) =>
            user.userId.isNotEmpty && !visibleUserIds.contains(user.userId),
      );
      for (final userId in visibleUserIds) {
        final exists = session.users.any((user) => user.userId == userId);
        if (!exists) {
          session.users.add(
            RCCallUserProfile(
              userId: userId,
              mediaType: status.mediaType,
              mediaId: status.activeUserIds.contains(userId) ? userId : '',
              enableMicrophone: status.activeUserIds.contains(userId),
              enableCamera:
                  status.mediaType == RCCallMediaType.audio_video &&
                  status.activeUserIds.contains(userId),
            ),
          );
        }
      }
    }
    _setState(
      _state.copyWith(
        session: session,
        invitedUserIds: status.invitedUserIds,
        remoteCameraEnabled: _hasAnyRemoteCameraEnabled(),
        remoteMicEnabled: _hasAnyRemoteMicrophoneEnabled(),
      ),
    );
  }

  bool _isSamePreConnectCallSummary(RongCallSummaryEvent event) {
    final currentUserId = IMEngineManager().currentUserId ?? '';
    if (event.isGroupCall != _state.isGroupCall) return false;
    final session = _state.session;
    if (event.callId.isNotEmpty && session?.callId.isNotEmpty == true) {
      if (event.callId == session!.callId) return true;
    }
    if (event.sessionId.isNotEmpty && session?.sessionId?.isNotEmpty == true) {
      if (event.sessionId == session!.sessionId) return true;
    }
    if (_state.isGroupCall) {
      return event.targetId == _state.targetId;
    }
    return event.senderUserId == _state.targetId ||
        event.targetId == _state.targetId ||
        event.targetId == currentUserId;
  }

  RCCallDisconnectReason _remoteDisconnectReasonFromSummary(
    RongCallSummaryEvent event,
  ) {
    final reasonName = event.reasonName.toLowerCase();
    final reason = event.reason;
    if (event.connectedTime <= 0 &&
        (reason == 0 || reasonName.contains('hangup'))) {
      return RCCallDisconnectReason.remote_cancel;
    }
    if (reasonName.contains('reject') || reason == 2 || reason == 12) {
      return RCCallDisconnectReason.remote_reject;
    }
    if (reasonName.contains('cancel') || reason == 1 || reason == 11) {
      return RCCallDisconnectReason.remote_cancel;
    }
    if (reasonName.contains('busy') || reason == 4 || reason == 14) {
      return RCCallDisconnectReason.remote_busy_line;
    }
    if (reasonName.contains('no_response') || reason == 5 || reason == 15) {
      return RCCallDisconnectReason.remote_no_response;
    }
    if (reasonName.contains('network') || reason == 7 || reason == 16) {
      return RCCallDisconnectReason.remote_network_error;
    }
    return RCCallDisconnectReason.remote_hangup;
  }

  Future<bool> _sendPrivateCallInvite(String invitedUserId) async {
    final engine = IMEngineManager().engine;
    final currentUserId = IMEngineManager().currentUserId;
    if (engine == null ||
        currentUserId == null ||
        currentUserId.isEmpty ||
        invitedUserId.isEmpty) {
      return false;
    }
    if (!await _ensureCallInviteUpdateMessageRegistered(engine)) return false;

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final message = await engine.createNativeCustomMessage(
        RCIMIWConversationType.private,
        invitedUserId,
        null,
        RongCallInviteUpdateMessage.objectName,
        {
          'targetId': invitedUserId,
          'invitedUserIds': [invitedUserId],
          'mediaType': _state.mediaType.index,
          'displayName': _state.displayName,
          'initiatorUserId': currentUserId,
          'activeUserIds': [currentUserId],
          'isGroupCall': false,
          'action': 'invite',
          'callId': _state.session?.callId,
          'sentAt': now,
        }..removeWhere((_, value) => value == null),
      );
      if (message == null) return false;
      message.senderUserId = currentUserId;
      message.sentTime = now;
      return ImSendManager.instance.sendMessage(
        message,
        pushSavedMessage: false,
      );
    } catch (e) {
      debugPrint('send private call invite failed: $e');
      return false;
    }
  }

  Future<bool> _sendGroupCallInviteUpdate(List<String> invitedUserIds) async {
    final engine = IMEngineManager().engine;
    final targetId = _state.targetId;
    if (engine == null || targetId.isEmpty || invitedUserIds.isEmpty) {
      return false;
    }
    if (!await _ensureCallInviteUpdateMessageRegistered(engine)) return false;

    final notifyUserIds = {
      ..._activeRemoteUserIds(),
      ...invitedUserIds,
    }.where((userId) => userId.isNotEmpty).toList();
    if (notifyUserIds.isEmpty) return false;

    try {
      final status = RongGroupCallStatusCenter().statusFor(targetId);
      final now = DateTime.now().millisecondsSinceEpoch;
      final message = await engine.createNativeCustomMessage(
        RCIMIWConversationType.group,
        targetId,
        null,
        RongCallInviteUpdateMessage.objectName,
        {
          'targetId': targetId,
          'invitedUserIds': invitedUserIds,
          'mediaType': _state.mediaType.index,
          'displayName': _state.displayName,
          'initiatorUserId':
              _callInitiatorUserId(_state) ?? IMEngineManager().currentUserId,
          'activeUserIds':
              status?.activeUserIds ??
              [
                if (IMEngineManager().currentUserId?.isNotEmpty == true)
                  IMEngineManager().currentUserId!,
                ..._activeRemoteUserIds(),
              ],
          'isGroupCall': true,
          'action': 'invite',
          'callId': _state.session?.callId,
          'sentAt': now,
        }..removeWhere((_, value) => value == null),
      );
      if (message == null) return false;
      message.senderUserId = IMEngineManager().currentUserId;
      message.sentTime = now;

      final completer = Completer<bool>();
      final ret = await engine.sendGroupMessageToDesignatedUsers(
        message,
        notifyUserIds,
        callback: RCIMIWSendGroupMessageToDesignatedUsersCallback(
          onMessageSent: (code, _) {
            if (!completer.isCompleted) {
              completer.complete(code == 0);
            }
          },
        ),
      );
      if (ret != 0) return false;
      return completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );
    } catch (e) {
      debugPrint('send group call invite update failed: $e');
      return false;
    }
  }

  List<String> _activeRemoteUserIds() {
    final currentUserId = IMEngineManager().currentUserId;
    final users = _state.session?.users ?? const <RCCallUserProfile>[];
    return users
        .where(
          (user) =>
              user.userId.isNotEmpty &&
              user.userId != currentUserId &&
              (user.mediaId?.isNotEmpty ?? false),
        )
        .map((user) => user.userId)
        .toSet()
        .toList();
  }

  Future<void> hangup() async {
    final endingState = _state;
    if (_engine == null) {
      _clearSpeakingUsers();
      _setState(const RongCallState.idle());
      unawaited(_publishGroupCallLeftOrEnded(endingState));
      return;
    }
    await _disableNativeCallSummary();
    _localDisconnectReasonOverride = _state.status == RongCallStatus.incoming
        ? RCCallDisconnectReason.reject
        : RCCallDisconnectReason.hangup;
    if (_state.isGroupCall && _state.status != RongCallStatus.incoming) {
      unawaited(_publishGroupCallLeftOrEnded(endingState));
    }
    await _engine?.hangup();
    _clearSpeakingUsers();
    _setState(_state.copyWith(status: RongCallStatus.ended));
    if (!_state.isGroupCall) {
      unawaited(_publishGroupCallEnded(endingState));
    }
  }

  Future<void> _failActiveCall({int? errorCode}) async {
    final failedState = _state.copyWith(
      status: RongCallStatus.error,
      errorCode: errorCode,
    );
    try {
      await _engine?.hangup();
    } catch (e) {
      debugPrint('hangup failed call failed: $e');
    }
    _clearSpeakingUsers();
    _localVideoViewBound = false;
    _remoteVideoViewBound = false;
    _setState(failedState);
    unawaited(_publishGroupCallEnded(failedState));
  }

  Future<void> toggleMicrophone() async {
    final next = !_state.micEnabled;
    if (_state.status == RongCallStatus.incoming) {
      _setState(_state.copyWith(micEnabled: next));
      if (!next) _removeSpeakingUser(IMEngineManager().currentUserId);
      return;
    }
    final code = await _engine?.enableMicrophone(next) ?? -1;
    if (code == 0) {
      _setState(_state.copyWith(micEnabled: next));
      if (!next) _removeSpeakingUser(IMEngineManager().currentUserId);
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
    _syncEngineCurrentUserId();

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
    _syncEngineCurrentUserId();

    try {
      final code = await engine.setLocalVideoView(view);
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
    _syncEngineCurrentUserId();
    try {
      await engine.setLocalVideoView(null);
    } catch (e) {
      debugPrint('unbind local video view failed: $e');
    }
  }

  Future<RCCallView?> createRemoteVideoView() async {
    final engine = _engine;
    final remoteUserId = _remoteVideoUserId();
    if (engine == null ||
        remoteUserId.isEmpty ||
        !_state.isVideo ||
        !_state.isActive) {
      return null;
    }

    try {
      final view = await RCCallView.create(fit: BoxFit.cover);
      if (!_state.isVideo ||
          !_state.isActive ||
          _remoteVideoUserId() != remoteUserId) {
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
    final remoteUserId = _remoteVideoUserId();
    if (engine == null ||
        remoteUserId.isEmpty ||
        !_state.isVideo ||
        _state.status != RongCallStatus.inCall ||
        !_state.remoteCameraEnabled) {
      return false;
    }

    try {
      final code = await engine.setVideoView(remoteUserId, view);
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

  Future<RCCallView?> createParticipantVideoView() async {
    final engine = _engine;
    if (engine == null || !_state.isVideo || !_state.isActive) {
      return null;
    }

    try {
      final view = await RCCallView.create(fit: BoxFit.cover);
      if (!_state.isVideo || !_state.isActive) {
        return null;
      }
      return view;
    } catch (e) {
      debugPrint('create participant video view failed: $e');
      return null;
    }
  }

  Future<bool> bindParticipantVideoView(String userId, RCCallView view) async {
    final engine = _engine;
    if (engine == null ||
        userId.isEmpty ||
        !_state.isVideo ||
        _state.status != RongCallStatus.inCall) {
      return false;
    }

    try {
      final code = await engine.setVideoView(userId, view);
      if (code != 0) {
        debugPrint('bind participant video view failed: $code');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('bind participant video view failed: $e');
      return false;
    }
  }

  Future<void> unbindParticipantVideoView(String userId) async {
    final engine = _engine;
    if (engine == null || userId.isEmpty) return;
    try {
      await engine.setVideoView(userId, null);
    } catch (e) {
      debugPrint('unbind participant video view failed: $e');
    }
  }

  Future<void> unbindRemoteVideoView() async {
    final engine = _engine;
    final remoteUserId = _remoteVideoUserId();
    if (engine == null || remoteUserId.isEmpty) return;
    try {
      await engine.setVideoView(remoteUserId, null);
    } catch (e) {
      debugPrint('unbind remote video view failed: $e');
    }
  }

  String _remoteVideoUserId() {
    final users = _state.session?.users ?? const <RCCallUserProfile>[];
    final currentUserId = IMEngineManager().currentUserId;
    for (final user in users) {
      if (user.userId.isEmpty || user.userId == currentUserId) continue;
      if ((user.mediaId?.isNotEmpty ?? false) &&
          user.enableCamera &&
          user.mediaType == RCCallMediaType.audio_video) {
        return user.userId;
      }
    }
    return '';
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
    _syncEngineCurrentUserId();
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

      final localCode = await engine.setLocalVideoView(localView);
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
      _state.copyWith(clearLocalVideoView: true, clearRemoteVideoView: true),
    );
  }

  void clearLocalVideoView() {
    if (_state.localVideoView == null) return;
    _localVideoViewBound = false;
    _setState(_state.copyWith(clearLocalVideoView: true));
  }

  void markIdle() {
    _clearSpeakingUsers();
    _setState(const RongCallState.idle());
  }

  Future<void> sendCallSummaryMessage({
    required RCIMIWConversationType conversationType,
    required String targetId,
    required bool isVideo,
    required int durationMs,
    String? channelId,
    int reason = 0,
    bool isOutgoing = true,
  }) async {
    final engine = IMEngineManager().engine;
    if (engine == null || targetId.isEmpty) return;
    if (!await _ensureCallSummaryMessageRegistered(engine)) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final startedAt = durationMs > 0 ? now - durationMs : now;
    final fields = <String, dynamic>{
      'duration': durationMs > 0 ? durationMs : 0,
      'mediaType': isVideo ? 2 : 1,
      'hangupReason': reason,
      'reason': reason,
      'startTime': startedAt,
      'connectedTime': durationMs > 0 ? startedAt : 0,
      'endTime': now,
      'isOutgoing': isOutgoing,
    };

    final key = [
      conversationType.index,
      targetId,
      isVideo ? 2 : 1,
      startedAt,
      now,
      reason,
    ].join(':');
    if (!_sentSummaryKeys.add(key)) return;

    try {
      final message = await engine.createNativeCustomMessage(
        conversationType,
        targetId,
        channelId,
        RongCallSummaryParser.objectName,
        fields,
      );
      if (message == null) {
        debugPrint('create call summary message failed: null');
        return;
      }
      message.senderUserId = IMEngineManager().currentUserId;
      message.sentTime = now;
      final sent = await ImSendManager.instance.sendMessage(message);
      if (!sent) {
        debugPrint('send call summary message failed');
      }
    } catch (e) {
      debugPrint('send call summary message failed: $e');
    }
  }

  void _bindListeners() {
    final engine = _engine;
    if (engine == null) return;

    engine.onReceiveCall = (session) {
      print('onReceiveCall------');
      _disableNativeCallSummary();
      final isGroupCall = session.callType == RCCallCallType.group;
      final targetId = isGroupCall
          ? session.targetId
          : (session.caller?.userId ?? session.targetId);
      final displayName = targetId;
      final pendingJoinStatus = _pendingJoinStatus;
      final shouldAutoAcceptJoin =
          isGroupCall &&
          pendingJoinStatus != null &&
          pendingJoinStatus.targetId == targetId;
      final isSameIncomingGroupCall =
          isGroupCall &&
          _state.isGroupCall &&
          _state.isActive &&
          _state.targetId == targetId &&
          _state.status == RongCallStatus.incoming;
      print('connect------3');
      _setState(
        RongCallState(
          status: shouldAutoAcceptJoin
              ? RongCallStatus.connecting
              : RongCallStatus.incoming,
          targetId: targetId,
          displayName: pendingJoinStatus?.displayName.isNotEmpty == true
              ? pendingJoinStatus!.displayName
              : displayName,
          inviter: session.inviter?.userId ?? '',
          mediaType: session.mediaType,
          isGroupCall: isGroupCall,
          isOutgoing: false,
          session: session,
          cameraEnabled: session.mediaType == RCCallMediaType.audio_video,
          speakerEnabled: session.mediaType == RCCallMediaType.audio_video,
          invitedUserIds: pendingJoinStatus?.invitedUserIds ?? const [],
        ),
      );
      if (shouldAutoAcceptJoin) {
        _pendingJoinStatus = null;
        unawaited(accept());
        return;
      }
      if (!isSameIncomingGroupCall) {
        _openIncomingCallPage(
          displayName: displayName,
          targetId: targetId,
          mediaType: session.mediaType,
          isGroupCall: isGroupCall,
        );
      }
      if (isGroupCall) {
        _resolveIncomingGroupName(targetId);
      } else {
        _resolveIncomingDisplayName(targetId);
      }
    };

    engine.onCallDidMake = () {
      _setState(_state.copyWith(status: RongCallStatus.dialing));
    };

    engine.onRemoteUserDidRing = (_) {
      _setState(_state.copyWith(status: RongCallStatus.dialing));
    };

    engine.onRemoteUserDidJoin = (user) {
      print('onRemoteUserDidJoin---${user.userId}');
      _upsertSessionUser(user);
      if (!_state.isActive) return;
      final connectedTime = DateTime.now().millisecondsSinceEpoch;
      _setState(
        _state.copyWith(
          status: RongCallStatus.inCall,
          connectedTimeMs: _state.connectedTimeMs > 0
              ? _state.connectedTimeMs
              : connectedTime,
          remoteMicEnabled: user.enableMicrophone,
          remoteCameraEnabled: user.enableCamera,
        ),
      );
      unawaited(
        _publishGroupCallStatus(_state, force: true, sendMessage: false),
      );
    };

    engine.onRemoteUserDidLeave = (userId) {
      print('onRemoteUserDidLeave---${userId}');
      _removeSessionUser(userId);
      _removeSpeakingUser(userId);
      _remoteVideoViewBound = false;
      if (!_state.isGroupCall || !_state.isActive) return;
      _setState(
        _state.copyWith(
          session: _state.session,
          remoteCameraEnabled: _hasAnyRemoteCameraEnabled(),
          remoteMicEnabled: _hasAnyRemoteMicrophoneEnabled(),
        ),
      );
      unawaited(
        _publishGroupCallStatus(_state, force: true, sendMessage: false),
      );
    };

    engine.onRemoteUserDidChangeMediaType = (user, _) {
      print('onRemoteUserDidChangeMediaType-------');
      _upsertSessionUser(user);
      final connectedTime = DateTime.now().millisecondsSinceEpoch;
      _remoteVideoViewBound = false;
      _setState(
        _state.copyWith(
          status: RongCallStatus.inCall,
          connectedTimeMs: _state.connectedTimeMs > 0
              ? _state.connectedTimeMs
              : connectedTime,
          remoteMicEnabled: user.enableMicrophone,
          remoteCameraEnabled: user.enableCamera,
        ),
      );
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
      print('connect------2');

      unawaited(_applyConnectedMediaSettings(engine, _state));
      unawaited(
        _publishGroupCallStatus(_state, force: true, sendMessage: false),
      );
    };

    engine.onDisconnect = (reason) {
      final disconnectReason = _localDisconnectReasonOverride ?? reason;
      _localDisconnectReasonOverride = null;
      final endedState = _state.copyWith(
        status: RongCallStatus.ended,
        disconnectReason: disconnectReason,
      );
      _setState(endedState);
      if (endedState.isGroupCall) {
        unawaited(_publishGroupCallLeftOrEnded(endedState));
      } else {
        unawaited(_publishGroupCallEnded(endedState));
      }
      unawaited(_sendCallSummaryFallback(endedState, disconnectReason));
      AppToast.showInfo(_disconnectText(disconnectReason));
    };

    engine.onCallError = (errorCode) {
      unawaited(_failActiveCall(errorCode: errorCode));
      AppToast.showInfo(
        AppLocalizations.currentText('call_error_code', {'code': errorCode}),
      );
    };

    engine.onEnableCamera = (_, enabled) {
      _setState(_state.copyWith(cameraEnabled: enabled));
    };

    engine.onRemoteUserDidChangeMicrophoneState = (user, enabled) {
      _upsertSessionUser(user);
      _setState(_state.copyWith(remoteMicEnabled: enabled));
      if (!enabled) _removeSpeakingUser(user.userId);
    };

    engine.onRemoteUserDidChangeCameraState = (user, enabled) {
      _upsertSessionUser(user);
      _remoteVideoViewBound = false;
      _setState(_state.copyWith(remoteCameraEnabled: enabled));
    };

    engine.onAudioVolume = (user, volume) {
      _handleAudioVolume(user, volume);
    };
  }

  void _handleAudioVolume(RCCallUserProfile user, int volume) {
    if (!_state.isGroupCall ||
        _state.status != RongCallStatus.inCall ||
        user.userId.isEmpty ||
        !user.enableMicrophone) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    if (volume < _speakingVolumeThreshold) {
      _syncSpeakingUsers(now);
      return;
    }

    _speakingUntilMsByUserId[user.userId] = now + _speakingHoldMs;
    _syncSpeakingUsers(now);
    _speakingCleanupTimer ??= Timer.periodic(
      const Duration(milliseconds: 300),
      (_) => _syncSpeakingUsers(DateTime.now().millisecondsSinceEpoch),
    );
  }

  void _syncSpeakingUsers(int now) {
    _speakingUntilMsByUserId.removeWhere((_, untilMs) => untilMs <= now);
    final nextUserIds = _speakingUntilMsByUserId.keys.toList(growable: false);
    if (_sameStringSet(nextUserIds, _state.speakingUserIds)) {
      if (nextUserIds.isEmpty) {
        _speakingCleanupTimer?.cancel();
        _speakingCleanupTimer = null;
      }
      return;
    }
    _setState(_state.copyWith(speakingUserIds: nextUserIds));
    if (nextUserIds.isEmpty) {
      _speakingCleanupTimer?.cancel();
      _speakingCleanupTimer = null;
    }
  }

  bool _sameStringSet(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final values = a.toSet();
    return b.every(values.contains);
  }

  void _clearSpeakingUsers() {
    _speakingCleanupTimer?.cancel();
    _speakingCleanupTimer = null;
    _speakingUntilMsByUserId.clear();
    if (_state.speakingUserIds.isNotEmpty) {
      _setState(_state.copyWith(speakingUserIds: const []));
    }
  }

  void _removeSpeakingUser(String? userId) {
    if (userId == null || userId.isEmpty) return;
    _speakingUntilMsByUserId.remove(userId);
    if (!_state.speakingUserIds.contains(userId)) return;
    _setState(
      _state.copyWith(
        speakingUserIds: _state.speakingUserIds
            .where((item) => item != userId)
            .toList(growable: false),
      ),
    );
  }

  void _upsertSessionUser(RCCallUserProfile user) {
    final session = _state.session;
    if (session == null || user.userId.isEmpty) return;
    final index = session.users.indexWhere(
      (item) => item.userId == user.userId,
    );
    if (index >= 0) {
      session.users[index] = user;
    } else {
      session.users.add(user);
    }
  }

  void _removeSessionUser(String userId) {
    final session = _state.session;
    if (session == null || userId.isEmpty) return;
    session.users.removeWhere((user) => user.userId == userId);
  }

  bool _hasAnyRemoteCameraEnabled() {
    final currentUserId = IMEngineManager().currentUserId;
    return _state.session?.users.any(
          (user) =>
              user.userId.isNotEmpty &&
              user.userId != currentUserId &&
              user.enableCamera &&
              user.mediaType == RCCallMediaType.audio_video &&
              (user.mediaId?.isNotEmpty ?? false),
        ) ??
        false;
  }

  bool _hasAnyRemoteMicrophoneEnabled() {
    final currentUserId = IMEngineManager().currentUserId;
    return _state.session?.users.any(
          (user) =>
              user.userId.isNotEmpty &&
              user.userId != currentUserId &&
              user.enableMicrophone &&
              (user.mediaId?.isNotEmpty ?? false),
        ) ??
        false;
  }

  void _syncGroupCallSessionRefresh(RongCallState state) {
    if (state.isGroupCall && state.status == RongCallStatus.inCall) {
      _groupCallSessionRefreshTimer ??= Timer.periodic(
        const Duration(seconds: 1),
        (_) => unawaited(_refreshGroupCallSession()),
      );
      return;
    }
    _groupCallSessionRefreshTimer?.cancel();
    _groupCallSessionRefreshTimer = null;
    _cancelSingleMemberGroupCallTimer();
  }

  Future<void> _refreshGroupCallSession() async {
    if (_isRefreshingGroupCallSession) return;
    final engine = _engine;
    if (engine == null ||
        !_state.isGroupCall ||
        _state.status != RongCallStatus.inCall) {
      _syncGroupCallSessionRefresh(_state);
      return;
    }

    _isRefreshingGroupCallSession = true;
    try {
      final session = await engine.getCurrentCallSession();
      if (session == null) return;
      if (!_state.isGroupCall || _state.status != RongCallStatus.inCall) {
        return;
      }

      final activeRemoteUsers = session.users.where(_isActiveRemoteCallUser);
      if (activeRemoteUsers.isEmpty) {
        _startSingleMemberGroupCallTimer();
      } else {
        _cancelSingleMemberGroupCallTimer();
      }

      _setState(_state.copyWith(session: session));
      unawaited(_publishGroupCallStatus(_state, sendMessage: false));
    } catch (e) {
      debugPrint('refresh group call session failed: $e');
    } finally {
      _isRefreshingGroupCallSession = false;
    }
  }

  void _startSingleMemberGroupCallTimer() {
    if (_singleMemberGroupCallTimer != null) return;
    _singleMemberGroupCallTimer = Timer(const Duration(seconds: 60), () {
      unawaited(_hangupIfGroupCallStillSingleMember());
    });
  }

  void _cancelSingleMemberGroupCallTimer() {
    _singleMemberGroupCallTimer?.cancel();
    _singleMemberGroupCallTimer = null;
  }

  Future<void> _hangupIfGroupCallStillSingleMember() async {
    _singleMemberGroupCallTimer = null;
    final engine = _engine;
    if (engine == null ||
        !_state.isGroupCall ||
        _state.status != RongCallStatus.inCall) {
      return;
    }

    try {
      final session = await engine.getCurrentCallSession();
      if (session == null ||
          !_state.isGroupCall ||
          _state.status != RongCallStatus.inCall) {
        return;
      }

      _setState(_state.copyWith(session: session));
      final activeRemoteUsers = session.users.where(_isActiveRemoteCallUser);
      if (activeRemoteUsers.isEmpty) {
        await hangup();
      }
    } catch (e) {
      debugPrint('single member group call hangup check failed: $e');
    }
  }

  bool _isActiveRemoteCallUser(RCCallUserProfile user) {
    final currentUserId = IMEngineManager().currentUserId;
    return user.userId.isNotEmpty &&
        user.userId != currentUserId &&
        (user.mediaId?.isNotEmpty ?? false);
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
    return;
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
    if (!await _ensureCallSummaryMessageRegistered(engine)) return;

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
      final conversationType = state.isGroupCall
          ? RCIMIWConversationType.group
          : RCIMIWConversationType.private;
      final message = await engine.createNativeCustomMessage(
        conversationType,
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
    if (!state.isGroupCall) return true;
    return _isCurrentUserCallInitiator(state);
  }

  Future<bool> _ensureCallSummaryMessageRegistered(RCIMIWEngine engine) async {
    if (_callSummaryMessageRegistered) return true;
    try {
      final code = await engine.registerNativeCustomMessage(
        RongCallSummaryParser.objectName,
        RCIMIWNativeCustomMessagePersistentFlag.persisted,
      );
      if (code == 0) {
        _callSummaryMessageRegistered = true;
        return true;
      }
      debugPrint('register call summary message failed before send: $code');
      return false;
    } catch (e) {
      debugPrint('register call summary message failed before send: $e');
      return false;
    }
  }

  Future<bool> _ensureCallInviteUpdateMessageRegistered(
    RCIMIWEngine engine,
  ) async {
    if (_callInviteUpdateMessageRegistered) return true;
    try {
      final code = await engine.registerNativeCustomMessage(
        RongCallInviteUpdateMessage.objectName,
        RCIMIWNativeCustomMessagePersistentFlag.status,
      );
      if (code == 0) {
        _callInviteUpdateMessageRegistered = true;
        return true;
      }
      debugPrint('register call invite update message failed: $code');
      return false;
    } catch (e) {
      debugPrint('register call invite update message failed: $e');
      return false;
    }
  }

  Future<bool> _ensureCallJoinRequestMessageRegistered(
    RCIMIWEngine engine,
  ) async {
    try {
      final code = await engine.registerNativeCustomMessage(
        RongCallJoinRequestMessage.objectName,
        RCIMIWNativeCustomMessagePersistentFlag.status,
      );
      if (code == 0) {
        return true;
      }
      debugPrint('register call join request message failed: $code');
      return false;
    } catch (e) {
      debugPrint('register call join request message failed: $e');
      return false;
    }
  }

  Future<bool> _ensureGroupCallStatusMessageRegistered(
    RCIMIWEngine engine,
  ) async {
    if (_groupCallStatusMessageRegistered) return true;
    try {
      final code = await engine.registerNativeCustomMessage(
        RongGroupCallStatusMessage.objectName,
        RCIMIWNativeCustomMessagePersistentFlag.status,
      );
      if (code == 0) {
        _groupCallStatusMessageRegistered = true;
        return true;
      }
      debugPrint('register group call status message failed: $code');
      return false;
    } catch (e) {
      debugPrint('register group call status message failed: $e');
      return false;
    }
  }

  Future<void> _publishGroupCallStatus(
    RongCallState state, {
    bool force = false,
    bool sendMessage = true,
    Iterable<String> extraActiveUserIds = const [],
  }) async {
    if (!state.isGroupCall || !state.isActive || state.targetId.isEmpty) return;
    final engine = IMEngineManager().engine;
    if (engine == null) return;
    if (!await _ensureGroupCallStatusMessageRegistered(engine)) return;

    final currentUserId = IMEngineManager().currentUserId;
    final activeUserIds = {
      if (currentUserId != null && currentUserId.isNotEmpty) currentUserId,
      ...extraActiveUserIds.where((userId) => userId.isNotEmpty),
      ..._activeRemoteUserIds(),
    }.toList();
    final sortedActive = [...activeUserIds]..sort();
    final sortedInvited = state.invitedUserIds.toSet().toList()..sort();
    final statusKey = [
      state.targetId,
      state.session?.callId ?? '',
      state.mediaType.index,
      sortedActive.join(','),
      sortedInvited.join(','),
    ].join(':');
    if (!force && statusKey == _lastGroupCallStatusKey) return;
    _lastGroupCallStatusKey = statusKey;

    final status = RongGroupCallStatus(
      targetId: state.targetId,
      action: RongGroupCallStatusAction.active,
      mediaType: state.mediaType,
      displayName: state.displayName,
      initiatorUserId: _callInitiatorUserId(state) ?? currentUserId ?? '',
      callId: state.session?.callId ?? '',
      activeUserIds: activeUserIds,
      invitedUserIds: state.invitedUserIds,
      sentAt: DateTime.now().millisecondsSinceEpoch,
    );
    RongGroupCallStatusCenter().updateLocal(status);
    if (!sendMessage) return;
    await _sendGroupCallStatusMessage(engine, status);
  }

  Future<void> _publishGroupCallEnded(RongCallState state) async {
    if (!state.isGroupCall || state.targetId.isEmpty) return;
    final engine = IMEngineManager().engine;
    if (engine == null) return;
    if (!await _ensureGroupCallStatusMessageRegistered(engine)) return;
    _lastGroupCallStatusKey = '';

    final status = RongGroupCallStatus(
      targetId: state.targetId,
      action: RongGroupCallStatusAction.ended,
      mediaType: state.mediaType,
      displayName: state.displayName,
      initiatorUserId:
          _callInitiatorUserId(state) ?? IMEngineManager().currentUserId ?? '',
      callId: state.session?.callId ?? '',
      activeUserIds: const [],
      invitedUserIds: state.invitedUserIds,
      sentAt: DateTime.now().millisecondsSinceEpoch,
    );
    RongGroupCallStatusCenter().updateLocal(status);
    await _sendGroupCallStatusMessage(engine, status);
  }

  Future<void> _publishGroupCallLeftOrEnded(RongCallState state) async {
    if (!state.isGroupCall || state.targetId.isEmpty) return;

    final currentUserId = IMEngineManager().currentUserId;
    final remainingActiveUserIds = _activeRemoteUserIds()
        .where((userId) => userId.isNotEmpty && userId != currentUserId)
        .toSet()
        .toList();
    if (remainingActiveUserIds.isEmpty) {
      await _publishGroupCallEnded(state);
      return;
    }

    final remainingInvitedUserIds = state.invitedUserIds
        .where((userId) => userId.isNotEmpty && userId != currentUserId)
        .toSet()
        .toList();
    RongGroupCallStatusCenter().updateLocal(
      RongGroupCallStatus(
        targetId: state.targetId,
        action: RongGroupCallStatusAction.active,
        mediaType: state.mediaType,
        displayName: state.displayName,
        initiatorUserId:
            _callInitiatorUserId(state) ??
            IMEngineManager().currentUserId ??
            '',
        callId: state.session?.callId ?? '',
        activeUserIds: remainingActiveUserIds,
        invitedUserIds: remainingInvitedUserIds,
        sentAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> _sendGroupCallStatusMessage(
    RCIMIWEngine engine,
    RongGroupCallStatus status,
  ) async {
    try {
      final message = await engine.createNativeCustomMessage(
        RCIMIWConversationType.group,
        status.targetId,
        null,
        RongGroupCallStatusMessage.objectName,
        {
          'targetId': status.targetId,
          'action': status.action == RongGroupCallStatusAction.ended
              ? 'ended'
              : 'active',
          'mediaType': status.mediaType.index,
          'displayName': status.displayName,
          'initiatorUserId': status.initiatorUserId,
          'callId': status.callId,
          'activeUserIds': status.activeUserIds,
          'invitedUserIds': status.invitedUserIds,
          'sentAt': status.sentAt,
        },
      );
      if (message == null) return;
      await ImSendManager.instance.sendMessage(
        message,
        pushSavedMessage: false,
      );
    } catch (e) {
      debugPrint('send group call status failed: $e');
    }
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
      final avatar = (profile.portraitUri ?? '').trim();
      if (displayName.isEmpty && avatar.isEmpty) return;
      if (_state.targetId != targetId || !_state.isActive) return;
      _setState(
        _state.copyWith(
          displayName: displayName.isEmpty ? null : displayName,
          avatar: avatar.isEmpty ? null : avatar,
        ),
      );
    } catch (e) {
      debugPrint('resolve call user failed: $e');
    }
  }

  Future<void> _resolveIncomingGroupName(String targetId) async {
    if (targetId.isEmpty) return;
    try {
      final group = await GroupStateCenter().getGroup(targetId);
      if (group == null) return;
      final model = GroupModel(info: group);
      final displayName = await model.name;
      if (displayName.isEmpty) return;
      if (_state.targetId != targetId || !_state.isActive) return;
      _setState(_state.copyWith(displayName: displayName));
    } catch (e) {
      debugPrint('resolve call group failed: $e');
    }
  }

  void _openIncomingCallPage({
    required String displayName,
    required String targetId,
    required RCCallMediaType mediaType,
    required bool isGroupCall,
  }) {
    final rootContext = AppRouter.rootNavigatorKey.currentContext;
    if (rootContext == null) return;
    final encodedName = Uri.encodeComponent(displayName);
    final encodedTargetId = Uri.encodeQueryComponent(targetId);
    final path = isGroupCall
        ? (mediaType == RCCallMediaType.audio_video
              ? '/chat-group-video/$encodedName?status=incoming&targetId=$encodedTargetId'
              : '/chat-group-voice/$encodedName?status=incoming&targetId=$encodedTargetId')
        : (mediaType == RCCallMediaType.audio_video
              ? '/chat-private-video/$encodedName?status=incoming'
              : '/chat-private-voice/$encodedName?status=incoming');
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
    if (state.status != RongCallStatus.inCall &&
        state.speakingUserIds.isNotEmpty) {
      _clearSpeakingUsers();
      state = state.copyWith(speakingUserIds: const []);
    }
    _state = state;
    _syncGroupCallSessionRefresh(_state);
    _stateController.add(_state);
  }
}
