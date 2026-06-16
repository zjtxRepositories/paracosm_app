import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/core/models/user_display_model.dart';
import 'package:paracosm/modules/call/rong_call_manager.dart';
import 'package:paracosm/modules/im/listener/user_display_state_center.dart';
import 'package:paracosm/router/app_router.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/util/string_util.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/chat/group_avatar_widget.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';
import 'package:rongcloud_call_wrapper_plugin/rongcloud_call_wrapper_plugin.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

class ChatGroupVideoPage extends StatefulWidget {
  final String name;
  final String targetId;
  final String status;
  final bool cameraEnabled;

  const ChatGroupVideoPage({
    super.key,
    required this.name,
    this.targetId = '',
    this.status = 'dialing',
    this.cameraEnabled = true,
  });

  @override
  State<ChatGroupVideoPage> createState() => _ChatGroupVideoPageState();
}

class _ChatGroupVideoPageState extends State<ChatGroupVideoPage> {
  late String _status;
  late bool _micEnabled;
  late bool _cameraEnabled;
  late RongCallState _callState;
  StreamSubscription<RongCallState>? _callSub;
  Timer? _callTimer;
  int _callElapsedMs = 0;
  bool _isClosing = false;
  bool _isMinimized = false;
  bool _summarySent = false;
  String? _miniOverlayName;
  String _miniOverlayStatus = 'dialing';
  bool _miniOverlayCameraEnabled = true;
  RCCallView? _localVideoView;
  RCCallView? _remoteVideoView;
  final Map<String, RCCallView> _participantVideoViews = {};
  final Set<String> _participantVideoBound = {};
  final Set<String> _preparingParticipantVideos = {};
  final Set<String> _participantVideoRetryBlocked = {};
  final Map<String, Timer> _participantVideoRetryTimers = {};
  bool _localVideoBound = false;
  bool _remoteVideoBound = false;
  bool _localVideoInPreviewSlot = false;
  bool _isPreparingLocalVideo = false;
  bool _isPreparingRemoteVideo = false;
  bool _localVideoRetryBlocked = false;
  bool _remoteVideoRetryBlocked = false;
  Timer? _localVideoRetryTimer;
  Timer? _remoteVideoRetryTimer;
  String _incomingDisplayName = '';
  final Set<String> _joinedParticipantUserIds = {};
  List<UserDisplayModel> _inCallParticipants = [];

  String get name =>
      _callState.displayName.isNotEmpty ? _callState.displayName : widget.name;
  bool get _isIncoming => _status == 'incoming';
  bool get _isInCall => _status == 'in_call';
  bool get _hasActiveCall => _callState.isActive;
  String get _callDurationText => formatDurationFromMs(_callElapsedMs);
  String get _localUserName {
    final user = _inCallParticipants.firstOrNull;
    if (user == null) return '';
    return user.name;
  }

  @override
  void initState() {
    super.initState();
    _status = widget.status;
    _micEnabled = true;
    _cameraEnabled = widget.cameraEnabled && !_isIncoming;
    _callState = RongCallManager().state;
    _syncCallState(_callState);
    _callSub = RongCallManager().stateStream.listen(_syncCallState);
    if (!_hasActiveCall && _isInCall) {
      _startStaticCallTimer();
    }
    _getGroupMembers();
    unawaited(_prepareVideoViewsIfNeeded());
  }

  Future<void> _getGroupMembers() async {
    final sessionUsers = _callUsersWithInvitedPlaceholders();
    final activeUserIds = sessionUsers
        .where(_isActiveRemoteParticipant)
        .map((user) => user.userId)
        .toSet();
    if (_isInCall) {
      _joinedParticipantUserIds.addAll(activeUserIds);
    }
    final users = _sortCallUsersByJoinState(
      _isInCall
          ? sessionUsers
                .where(
                  (user) => _shouldShowParticipantInStrip(user, activeUserIds),
                )
                .toList()
          : sessionUsers,
      activeUserIds,
    );
    final models = <UserDisplayModel>[];
    for (final user in users) {
      final model = await UserDisplayStateCenter().getUser(user.userId);
      if (model == null) continue;
      models.add(model);
    }
    if (!mounted) return;
    setState(() {
      _inCallParticipants = models;
    });
    if (_isIncoming) {
      final userId = _callState.session?.inviter?.userId;
      if (userId != null) {
        final inviter = await UserDisplayStateCenter().getUser(userId);
        if (!mounted) return;
        setState(() {
          _incomingDisplayName = inviter?.name ?? '';
        });
      }
    }
  }

  List<RCCallUserProfile> _callUsersWithInvitedPlaceholders() {
    final users = [...?_callState.session?.users];
    final existingUserIds = users.map((user) => user.userId).toSet();
    final currentUserId = _callState.session?.mine.userId;
    for (final userId in _callState.invitedUserIds) {
      if (userId.isEmpty ||
          userId == currentUserId ||
          existingUserIds.contains(userId)) {
        continue;
      }
      users.add(
        RCCallUserProfile.fromJson({
          'userType': 0,
          'mediaType': _callState.mediaType.index,
          'userId': userId,
          'mediaId': '',
          'enableCamera': false,
          'enableMicrophone': false,
        }),
      );
    }
    return users;
  }

  bool _isActiveRemoteParticipant(RCCallUserProfile user) {
    return user.userId.isNotEmpty &&
        user.userId != _callState.session?.mine.userId &&
        (user.mediaId?.isNotEmpty ?? false);
  }

  bool _shouldShowParticipantInStrip(
    RCCallUserProfile user,
    Set<String> activeUserIds,
  ) {
    if (user.userId.isEmpty || user.userId == _callState.session?.mine.userId) {
      return false;
    }
    if (activeUserIds.contains(user.userId)) return true;
    return !_joinedParticipantUserIds.contains(user.userId);
  }

  RCCallUserProfile? _callUserProfile(String userId) {
    final users = _callState.session?.users ?? [];
    for (final user in users) {
      if (user.userId == userId) {
        return user;
      }
    }
    return null;
  }

  List<RCCallUserProfile> _sortCallUsersByJoinState(
    List<RCCallUserProfile> users,
    Set<String> activeUserIds,
  ) {
    final indexedUsers = users.asMap().entries.toList();
    indexedUsers.sort((a, b) {
      final aJoined = activeUserIds.contains(a.value.userId);
      final bJoined = activeUserIds.contains(b.value.userId);
      if (aJoined != bJoined) return aJoined ? -1 : 1;
      return a.key.compareTo(b.key);
    });
    return indexedUsers.map((entry) => entry.value).toList();
  }

  @override
  void dispose() {
    _stopCallTimer();
    _localVideoRetryTimer?.cancel();
    _remoteVideoRetryTimer?.cancel();
    for (final timer in _participantVideoRetryTimers.values) {
      timer.cancel();
    }
    _callSub?.cancel();
    _localVideoView = null;
    _remoteVideoView = null;
    for (final userId in _participantVideoViews.keys) {
      unawaited(RongCallManager().unbindParticipantVideoView(userId));
    }
    _participantVideoViews.clear();
    RongCallManager().clearVideoViews();
    if (_isMinimized) {
      _showMiniOverlayAfterDispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      showNav: false,
      isAddBottomMargin: false,
      backgroundColor: Colors.black,
      backTheme: Brightness.dark,
      onBeforeBack: _minimizeCallBeforeBack,
      child: Stack(
        children: [
          _buildBackground(),
          _buildVideoLayer(),
          _buildCloseButton(context),
          if (_isIncoming) _buildIncomingCenterContent(),
          if (!_isIncoming) _buildSessionHeader(),
          if (!_isIncoming) _buildParticipantStrip(),
          Align(
            alignment: const Alignment(0, 0.80),
            child: _isIncoming
                ? _buildIncomingBottomControls(context)
                : _buildBottomControls(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    if (!_cameraEnabled || _isIncoming) {
      return _buildDarkBackground();
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/chat/call/video-bg.png',
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.26),
                  Colors.black.withValues(alpha: 0.16),
                  Colors.black.withValues(alpha: 0.34),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoLayer() {
    final featuredVideo = _featuredVideoView();
    final previewVideo = _previewVideoView();

    return Stack(
      children: [
        if (featuredVideo != null)
          Positioned.fill(child: IgnorePointer(child: featuredVideo)),
        if (featuredVideo != null) _buildVideoGradientOverlay(),
        if (_isInCall && previewVideo != null) _buildLocalPreview(previewVideo),
      ],
    );
  }

  Widget _buildVideoGradientOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.26),
                Colors.black.withValues(alpha: 0.12),
                Colors.black.withValues(alpha: 0.38),
              ],
              stops: const [0.0, 0.52, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocalPreview(Widget videoView) {
    final topPadding = MediaQuery.of(context).padding.top + 84;

    return Positioned(
      right: 20,
      top: topPadding,
      child: Container(
        width: 92,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.grey600, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: videoView,
      ),
    );
  }

  Widget _buildDarkBackground() {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF121212),
                  Color(0xFF0B0B0B),
                  Color(0xFF060606),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          top: -80,
          right: -90,
          child: _buildGlowCircle(
            size: 240,
            colors: [
              const Color(0xFF7F4A2A).withValues(alpha: 0.32),
              const Color(0xFF1A0F0A).withValues(alpha: 0.0),
            ],
          ),
        ),
        Positioned(
          left: -120,
          top: 140,
          child: _buildGlowCircle(
            size: 280,
            colors: [
              const Color(0xFF365F7E).withValues(alpha: 0.18),
              const Color(0xFF050505).withValues(alpha: 0.0),
            ],
          ),
        ),
        Positioned(
          left: -60,
          bottom: 120,
          child: _buildGlowCircle(
            size: 180,
            colors: [
              const Color(0xFF7B1F24).withValues(alpha: 0.18),
              const Color(0xFF050505).withValues(alpha: 0.0),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlowCircle({required double size, required List<Color> colors}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + 12;

    return Positioned(
      left: 20,
      top: topPadding,
      child: GestureDetector(
        onTap: () => _minimizeCall(context),
        child: Image.asset(
          'assets/images/chat/call/video-small.png',
          width: 32,
          height: 32,
        ),
      ),
    );
  }

  Future<bool> _minimizeCallBeforeBack() async {
    _minimizeCallToOverlay();
    return true;
  }

  void _minimizeCall(BuildContext context) {
    _minimizeCallToOverlay();
    if (context.canPop()) {
      context.pop();
    }
  }

  void _minimizeCallToOverlay() {
    _isMinimized = true;
    _miniOverlayName = name;
    _miniOverlayStatus = _status;
    _miniOverlayCameraEnabled = _cameraEnabled;
  }

  void _showMiniOverlayAfterDispose() {
    final overlayName = _miniOverlayName ?? name;
    final overlayStatus = _miniOverlayStatus;
    final overlayCameraEnabled = _miniOverlayCameraEnabled;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_hasActiveCall && !RongCallManager().state.isActive) return;
      final rootContext = AppRouter.rootNavigatorKey.currentContext;
      if (rootContext == null) return;
      _GroupVideoMiniOverlayController.show(
        context: rootContext,
        name: overlayName,
        targetId: widget.targetId,
        status: overlayStatus,
        cameraEnabled: overlayCameraEnabled,
      );
    });
  }

  Widget _buildIncomingCenterContent() {
    final participantCount = _inCallParticipants.length;
    final title = participantCount > 0 ? '$name($participantCount)' : name;

    return Align(
      alignment: const Alignment(0, -0.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildGroupAvatarGrid(),
          const SizedBox(height: 32),
          // Text(
          //   title,
          //   style: AppTextStyles.h1.copyWith(
          //     fontSize: 16,
          //     fontWeight: FontWeight.w600,
          //     color: Colors.white,
          //   ),
          // ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h1.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    '(${_inCallParticipants.length + 1})',
                    style: AppTextStyles.h1.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildIncomingSubtitle(),
        ],
      ),
    );
  }

  Widget _buildGroupAvatarGrid() {
    return GroupAvatarWidget(
      groupId: widget.targetId,
      portraitUri: _callState.avatar,
      size: 64,
    );
  }

  Widget _buildIncomingSubtitle() {
    final baseStyle = AppTextStyles.body.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.grey300,
    );

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$_incomingDisplayName ',
            style: baseStyle.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: AppLocalizations.currentText('call_invite_group_session'),
            style: baseStyle,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSessionHeader() {
    final topPadding = MediaQuery.of(context).padding.top + 14;
    final titleText = _isInCall
        ? _callDurationText
        : AppLocalizations.currentText('call_waiting_group_join', {
            'name': _localUserName,
          });
    final titleStyle = _isInCall
        ? AppTextStyles.h1.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          )
        : AppTextStyles.body.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.grey300,
          );

    return Positioned(
      top: topPadding + 5,
      left: 0,
      right: 0,
      child: Center(
        child: SizedBox(
          width: 180,
          child: Text(
            titleText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: titleStyle,
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantStrip() {
    if (_isIncoming) {
      return const SizedBox.shrink();
    }
    if (_inCallParticipants.isEmpty) {
      return const SizedBox.shrink();
    }

    final media = MediaQuery.of(context);
    final stripWidth = media.size.width - 20;

    return Align(
      alignment: const Alignment(0, 0.4),
      child: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: SizedBox(
          width: stripWidth,
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _inCallParticipants.length,
            itemBuilder: (context, index) {
              final participant = _inCallParticipants[index];
              final callUser = _callUserProfile(participant.userId);
              return _GroupParticipantTile(
                key: ValueKey(participant.userId),
                participant: participant,
                isInCall: _isInCall,
                videoView: _participantVideoViews[participant.userId],
                micEnabled: callUser?.enableMicrophone ?? false,
              );
            },
            separatorBuilder: (context, index) => const SizedBox(width: 8),
          ),
        ),
      ),
    );
  }

  Widget _buildIncomingBottomControls(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 24;

    return Padding(
      padding: EdgeInsets.only(left: 48, right: 48, bottom: bottomPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildImageActionButton(
            assetPath: 'assets/images/chat/call/voice-cancel.png',
            size: 72,
            onTap: () => _closeVideoSession(context),
          ),
          _buildIncomingDots(),
          _buildImageActionButton(
            assetPath: 'assets/images/chat/call/voice-answer.png',
            size: 72,
            onTap: _answerVideoSession,
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(8, (index) {
        return Padding(
          padding: EdgeInsets.only(right: index == 7 ? 0 : 12),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.grey700,
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 24;

    return Padding(
      padding: EdgeInsets.only(left: 48, right: 48, bottom: bottomPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _toggleMicrophone,
            child: Image.asset(
              _micEnabled
                  ? 'assets/images/chat/call/mic-on.png'
                  : 'assets/images/chat/call/mic-off.png',
              width: 28,
              height: 28,
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _closeVideoSession(context),
            child: Image.asset(
              'assets/images/chat/call/voice-cancel.png',
              width: 72,
              height: 72,
            ),
          ),
          GestureDetector(
            onTap: _isInCall
                ? () => RongCallManager().switchCamera()
                : _toggleCamera,
            child: Image.asset(
              _cameraEnabled
                  ? 'assets/images/chat/call/camera.png'
                  : 'assets/images/chat/call/camera-off.png',
              width: 28,
              height: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageActionButton({
    required String assetPath,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset(assetPath, width: size, height: size),
    );
  }

  Future<void> _closeVideoSession(BuildContext context) async {
    if (_isClosing) return;
    _isClosing = true;
    _isMinimized = false;
    _GroupVideoMiniOverlayController.dismiss();
    if (RongCallManager().state.isActive) {
      await RongCallManager().hangup();
    } else {
      await _sendGroupCallSummaryIfNeeded();
    }
    if (!context.mounted) return;
    Navigator.of(context).maybePop();
  }

  Future<void> _sendGroupCallSummaryIfNeeded() async {
    if (_summarySent || widget.targetId.isEmpty) return;
    _summarySent = true;
    await RongCallManager().sendCallSummaryMessage(
      conversationType: RCIMIWConversationType.group,
      targetId: widget.targetId,
      isVideo: true,
      durationMs: _callElapsedMs,
    );
  }

  Future<void> _answerVideoSession() async {
    if (RongCallManager().state.isActive) {
      await RongCallManager().accept();
      return;
    }
    setState(() {
      _status = 'in_call';
      _cameraEnabled = true;
    });
    _startStaticCallTimer();
    unawaited(_prepareVideoViewsIfNeeded());
  }

  Future<void> _toggleMicrophone() async {
    if (RongCallManager().state.isActive) {
      await RongCallManager().toggleMicrophone();
      return;
    }
    setState(() {
      _micEnabled = !_micEnabled;
    });
  }

  Future<void> _toggleCamera() async {
    if (RongCallManager().state.isActive) {
      await RongCallManager().toggleCamera();
      return;
    }
    setState(() {
      _cameraEnabled = !_cameraEnabled;
      if (!_cameraEnabled) {
        _localVideoView = null;
        _localVideoBound = false;
        _localVideoInPreviewSlot = false;
      }
    });
  }

  void _syncCallState(RongCallState state) {
    if (!mounted) return;
    if (state.status == RongCallStatus.idle) {
      return;
    }
    if (state.status == RongCallStatus.ended ||
        state.status == RongCallStatus.error) {
      _stopCallTimer();
      if (_isClosing) return;
      _isClosing = true;
      _isMinimized = false;
      _GroupVideoMiniOverlayController.dismiss();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      return;
    }

    setState(() {
      _callState = state;
      _status = _statusFromCallState(state.status);
      _micEnabled = state.micEnabled;
      _cameraEnabled = state.cameraEnabled;
      if (!_shouldShowLocalVideo(state)) {
        _localVideoView = null;
        _localVideoBound = false;
        _localVideoInPreviewSlot = false;
      }
      if (!_shouldShowRemoteVideo(state)) {
        _remoteVideoView = null;
        _remoteVideoBound = false;
        if (_localVideoView != null && _localVideoInPreviewSlot) {
          _localVideoView = null;
          _localVideoBound = false;
          _localVideoInPreviewSlot = false;
          _scheduleLocalVideoPrepare();
        }
      }
    });
    _syncCallTimer(state);
    unawaited(_getGroupMembers());
    unawaited(_prepareVideoViewsIfNeeded());
  }

  Widget? _featuredVideoView() {
    if (_isInCall && _remoteVideoView != null) {
      return _remoteVideoView;
    }
    return _localVideoView;
  }

  Widget? _previewVideoView() {
    if (_isInCall && _remoteVideoView != null) {
      return _localVideoView;
    }
    return null;
  }

  bool _shouldShowLocalVideo(RongCallState state) {
    return state.isVideo &&
        state.isActive &&
        state.cameraEnabled &&
        !_isIncoming;
  }

  bool _shouldShowRemoteVideo(RongCallState state) {
    return state.isVideo &&
        !state.isGroupCall &&
        state.status == RongCallStatus.inCall &&
        state.remoteCameraEnabled;
  }

  Future<void> _prepareVideoViewsIfNeeded() async {
    await _prepareLocalVideoViewIfNeeded();
    await _prepareRemoteVideoViewIfNeeded();
    await _prepareParticipantVideoViewsIfNeeded();
  }

  Future<void> _prepareLocalVideoViewIfNeeded() async {
    if (_localVideoBound) return;
    if (_isPreparingLocalVideo || _localVideoView != null) return;
    if (_localVideoRetryBlocked) return;
    if (!_shouldShowLocalVideo(_callState)) return;

    _isPreparingLocalVideo = true;
    final view = await RongCallManager().createLocalVideoView();
    if (!mounted) return;
    setState(() {
      _localVideoView = view;
      if (view != null) {
        _localVideoInPreviewSlot = _shouldUseLocalPreviewSlot();
      }
    });
    await WidgetsBinding.instance.endOfFrame;
    final isBound = view != null
        ? await RongCallManager().bindLocalVideoView(view)
        : false;
    if (!mounted) return;
    setState(() {
      _localVideoBound = isBound;
      if (!isBound) {
        _localVideoView = null;
        _blockLocalVideoRetry();
      }
      _isPreparingLocalVideo = false;
    });
  }

  Future<void> _prepareRemoteVideoViewIfNeeded() async {
    if (_remoteVideoBound) return;
    if (_isPreparingRemoteVideo || _remoteVideoView != null) return;
    if (_remoteVideoRetryBlocked) return;
    if (!_shouldShowRemoteVideo(_callState)) return;

    _isPreparingRemoteVideo = true;
    final view = await RongCallManager().createRemoteVideoView();
    if (!mounted) return;
    setState(() {
      if (view != null &&
          _localVideoView != null &&
          !_localVideoInPreviewSlot) {
        _localVideoView = null;
        _localVideoBound = false;
      }
      _remoteVideoView = view;
    });
    await WidgetsBinding.instance.endOfFrame;
    final isBound = view != null
        ? await RongCallManager().bindRemoteVideoView(view)
        : false;
    if (!mounted) return;
    setState(() {
      _remoteVideoBound = isBound;
      if (!isBound) {
        _remoteVideoView = null;
        _blockRemoteVideoRetry();
      }
      _isPreparingRemoteVideo = false;
    });
    _scheduleLocalVideoPrepare();
  }

  bool _shouldUseLocalPreviewSlot() {
    return _isInCall && _remoteVideoView != null;
  }

  void _scheduleLocalVideoPrepare() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_prepareLocalVideoViewIfNeeded());
    });
  }

  void _blockLocalVideoRetry() {
    _localVideoRetryBlocked = true;
    _localVideoRetryTimer?.cancel();
    _localVideoRetryTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      _localVideoRetryBlocked = false;
      unawaited(_prepareLocalVideoViewIfNeeded());
    });
  }

  void _blockRemoteVideoRetry() {
    _remoteVideoRetryBlocked = true;
    _remoteVideoRetryTimer?.cancel();
    _remoteVideoRetryTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      _remoteVideoRetryBlocked = false;
      unawaited(_prepareRemoteVideoViewIfNeeded());
    });
  }

  Future<void> _prepareParticipantVideoViewsIfNeeded() async {
    if (!_callState.isGroupCall || !_callState.isVideo || !_isInCall) {
      _clearParticipantVideoViews();
      return;
    }

    final targetUserIds =
        _callState.session?.users
            .where(_shouldShowParticipantVideo)
            .map((user) => user.userId)
            .toSet() ??
        <String>{};

    final staleUserIds = _participantVideoViews.keys
        .where((userId) => !targetUserIds.contains(userId))
        .toList(growable: false);
    if (staleUserIds.isNotEmpty && mounted) {
      setState(() {
        for (final userId in staleUserIds) {
          _participantVideoViews.remove(userId);
          _participantVideoBound.remove(userId);
        }
      });
      for (final userId in staleUserIds) {
        _cancelParticipantVideoRetry(userId);
        unawaited(RongCallManager().unbindParticipantVideoView(userId));
      }
    }

    for (final userId in targetUserIds) {
      await _prepareParticipantVideoViewIfNeeded(userId);
    }
  }

  bool _shouldShowParticipantVideo(RCCallUserProfile user) {
    return user.userId.isNotEmpty &&
        !_isLocalCallUser(user) &&
        (user.mediaId?.isNotEmpty ?? false) &&
        user.enableCamera &&
        user.mediaType == RCCallMediaType.audio_video;
  }

  bool _isLocalCallUser(RCCallUserProfile user) {
    return user.userId == _callState.session?.mine.userId;
  }

  Future<void> _prepareParticipantVideoViewIfNeeded(String userId) async {
    if (!_shouldShowParticipantVideoById(userId)) return;
    if (_participantVideoBound.contains(userId)) return;
    if (_participantVideoViews.containsKey(userId)) return;
    if (_preparingParticipantVideos.contains(userId)) return;
    if (_participantVideoRetryBlocked.contains(userId)) return;

    _preparingParticipantVideos.add(userId);
    final view = await RongCallManager().createParticipantVideoView();
    if (!mounted) return;
    if (view == null) {
      _preparingParticipantVideos.remove(userId);
      _blockParticipantVideoRetry(userId);
      return;
    }

    setState(() {
      _participantVideoViews[userId] = view;
    });
    await WidgetsBinding.instance.endOfFrame;
    final isBound = await RongCallManager().bindParticipantVideoView(
      userId,
      view,
    );
    if (!mounted) return;
    setState(() {
      if (isBound) {
        _participantVideoBound.add(userId);
      } else {
        _participantVideoViews.remove(userId);
        _participantVideoBound.remove(userId);
        _blockParticipantVideoRetry(userId);
      }
      _preparingParticipantVideos.remove(userId);
    });
  }

  void _clearParticipantVideoViews() {
    if (_participantVideoViews.isEmpty) {
      for (final timer in _participantVideoRetryTimers.values) {
        timer.cancel();
      }
      _participantVideoRetryTimers.clear();
      _participantVideoRetryBlocked.clear();
      _preparingParticipantVideos.clear();
      return;
    }
    final userIds = _participantVideoViews.keys.toList(growable: false);
    setState(() {
      _participantVideoViews.clear();
      _participantVideoBound.clear();
      _preparingParticipantVideos.clear();
    });
    for (final userId in userIds) {
      _cancelParticipantVideoRetry(userId);
      unawaited(RongCallManager().unbindParticipantVideoView(userId));
    }
  }

  bool _shouldShowParticipantVideoById(String userId) {
    final user = _callUserProfile(userId);
    if (user == null) return false;
    return _callState.isGroupCall &&
        _callState.isVideo &&
        _isInCall &&
        _shouldShowParticipantVideo(user);
  }

  void _blockParticipantVideoRetry(String userId) {
    _participantVideoRetryBlocked.add(userId);
    _participantVideoRetryTimers[userId]?.cancel();
    _participantVideoRetryTimers[userId] = Timer(
      const Duration(seconds: 1),
      () {
        if (!mounted) return;
        _participantVideoRetryBlocked.remove(userId);
        unawaited(_prepareParticipantVideoViewIfNeeded(userId));
      },
    );
  }

  void _cancelParticipantVideoRetry(String userId) {
    _participantVideoRetryTimers.remove(userId)?.cancel();
    _participantVideoRetryBlocked.remove(userId);
  }

  void _syncCallTimer(RongCallState state) {
    if (state.status != RongCallStatus.inCall) {
      _stopCallTimer();
      return;
    }
    _updateCallElapsedFromState();
    _callTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCallElapsedFromState();
    });
  }

  void _startStaticCallTimer() {
    _stopCallTimer();
    _callElapsedMs = 0;
    final startedAt = DateTime.now().millisecondsSinceEpoch;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final elapsed = DateTime.now().millisecondsSinceEpoch - startedAt;
      setState(() {
        _callElapsedMs = elapsed < 0 ? 0 : elapsed;
      });
    });
  }

  void _updateCallElapsedFromState() {
    final connectedTime = _callState.connectedTimeMs;
    final elapsed = connectedTime <= 0
        ? 0
        : DateTime.now().millisecondsSinceEpoch - connectedTime;
    if (!mounted) return;
    setState(() {
      _callElapsedMs = elapsed < 0 ? 0 : elapsed;
    });
  }

  void _stopCallTimer() {
    _callTimer?.cancel();
    _callTimer = null;
  }

  String _statusFromCallState(RongCallStatus status) {
    switch (status) {
      case RongCallStatus.incoming:
        return 'incoming';
      case RongCallStatus.inCall:
        return 'in_call';
      case RongCallStatus.connecting:
      case RongCallStatus.dialing:
      case RongCallStatus.idle:
      case RongCallStatus.ended:
      case RongCallStatus.error:
        return 'dialing';
    }
  }
}

class _GroupParticipantTile extends StatefulWidget {
  final UserDisplayModel participant;
  final bool isInCall;
  final bool micEnabled;
  final Widget? videoView;

  const _GroupParticipantTile({
    super.key,
    required this.participant,
    required this.isInCall,
    required this.micEnabled,
    this.videoView,
  });

  @override
  State<_GroupParticipantTile> createState() => _GroupParticipantTileState();
}

class _GroupParticipantTileState extends State<_GroupParticipantTile> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                UserAvatarWidget(
                  userId: widget.participant.userId,
                  avatarUrl: widget.participant.avatar,
                  width: 90,
                  height: 90,
                  borderRadius: BorderRadius.circular(12),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.40),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: _ParticipantWaitingDots()),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox.expand(child: widget.videoView ?? SizedBox()),
          ),
          if (widget.isInCall)
            Positioned(
              left: 6,
              top: 6,
              child: Image.asset(
                widget.micEnabled
                    ? 'assets/images/chat/call/mic-active.png'
                    : 'assets/images/chat/call/mic-close.png',
                width: 16,
                height: 16,
              ),
            ),
          Positioned(
            left: 6,
            right: 6,
            bottom: 4,
            child: Text(
              _participantName(widget.participant.name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _participantName(String name) {
    if (name == '_me') {
      return AppLocalizations.currentText('moments_me');
    }
    if (name == '_others') {
      return AppLocalizations.currentText('chat_filter_others');
    }
    return name;
  }
}

class _ParticipantWaitingDots extends StatefulWidget {
  const _ParticipantWaitingDots();

  @override
  State<_ParticipantWaitingDots> createState() =>
      _ParticipantWaitingDotsState();
}

class _ParticipantWaitingDotsState extends State<_ParticipantWaitingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ParticipantDot(progress: _dotProgress(0)),
            const SizedBox(width: 8),
            _ParticipantDot(progress: _dotProgress(1)),
            const SizedBox(width: 8),
            _ParticipantDot(progress: _dotProgress(2)),
          ],
        );
      },
    );
  }

  double _dotProgress(int index) {
    final value = (_controller.value - index * 0.22) % 1.0;
    if (value < 0.5) return value * 2;
    return (1 - value) * 2;
  }
}

class _ParticipantDot extends StatelessWidget {
  final double progress;

  const _ParticipantDot({required this.progress});

  @override
  Widget build(BuildContext context) {
    final opacity = 0.35 + progress * 0.65;
    final scale = 0.78 + progress * 0.28;

    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.grey200,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _GroupVideoMiniOverlayController {
  static OverlayEntry? _entry;
  static String? _name;
  static String _targetId = '';
  static String _status = 'dialing';
  static bool _cameraEnabled = true;

  static void show({
    required BuildContext context,
    required String name,
    String targetId = '',
    required String status,
    required bool cameraEnabled,
  }) {
    dismiss();
    final overlay = Overlay.of(context, rootOverlay: true);

    _name = name;
    _targetId = targetId;
    _status = status;
    _cameraEnabled = cameraEnabled;
    _entry = OverlayEntry(
      builder: (overlayContext) => _GroupVideoMiniBubble(
        onTap: () {
          final encodedName = Uri.encodeComponent(_name ?? name);
          final rootContext = AppRouter.rootNavigatorKey.currentContext;
          if (rootContext == null) {
            return;
          }
          dismiss();
          RongCallManager().clearVideoViews();
          final encodedTargetId = Uri.encodeQueryComponent(_targetId);
          rootContext.push(
            '/chat-group-video/$encodedName?status=$_status&camera=${_cameraEnabled ? 'on' : 'off'}&targetId=$encodedTargetId',
          );
        },
      ),
    );
    overlay.insert(_entry!);
  }

  static void dismiss() {
    _entry?.remove();
    _entry = null;
  }
}

class _GroupVideoMiniBubble extends StatefulWidget {
  final VoidCallback onTap;

  const _GroupVideoMiniBubble({required this.onTap});

  @override
  State<_GroupVideoMiniBubble> createState() => _GroupVideoMiniBubbleState();
}

class _GroupVideoMiniBubbleState extends State<_GroupVideoMiniBubble> {
  static const double _bubbleWidth = 92;
  static const double _bubbleHeight = 160;

  Offset? _position;
  bool _isDragging = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensurePositionInitialized();
  }

  void _ensurePositionInitialized() {
    final media = MediaQuery.of(context);
    final initialPosition = Offset(
      media.size.width - _bubbleWidth - 20,
      media.padding.top + 88,
    );
    if (_position == null) {
      _position = initialPosition;
      return;
    }
    _position = _clampToBounds(_position!, media);
  }

  Offset _clampToBounds(Offset value, MediaQueryData media) {
    final minX = 8.0;
    final maxX = media.size.width - _bubbleWidth - 8.0;
    final minY = media.padding.top + 8.0;
    final maxY = media.size.height - media.padding.bottom - _bubbleHeight - 8.0;
    return Offset(value.dx.clamp(minX, maxX), value.dy.clamp(minY, maxY));
  }

  Offset _rightDockedPosition(MediaQueryData media) {
    final maxX = media.size.width - _bubbleWidth - 8.0;
    return _clampToBounds(Offset(maxX, _position?.dy ?? 0), media);
  }

  void _handlePanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final media = MediaQuery.of(context);
    setState(() {
      _position = _clampToBounds(
        (_position ?? Offset.zero) + details.delta,
        media,
      );
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    final media = MediaQuery.of(context);
    setState(() {
      _isDragging = false;
      _position = _rightDockedPosition(media);
    });
  }

  void _handlePanCancel() {
    final media = MediaQuery.of(context);
    setState(() {
      _isDragging = false;
      _position = _rightDockedPosition(media);
    });
  }

  @override
  Widget build(BuildContext context) {
    final position = _position ?? Offset.zero;

    return AnimatedPositioned(
      duration: _isDragging ? Duration.zero : const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        onPanCancel: _handlePanCancel,
        child: Container(
          width: _bubbleWidth,
          height: _bubbleHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF737373), width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/chat/call/video-bg.png',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.18),
                        Colors.black.withValues(alpha: 0.38),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
