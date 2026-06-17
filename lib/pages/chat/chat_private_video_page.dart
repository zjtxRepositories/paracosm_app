import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/modules/call/rong_call_manager.dart';
import 'package:paracosm/modules/call/rong_call_types.dart';
import 'package:paracosm/router/app_router.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/util/string_util.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';

import '../../widgets/chat/waiting_dots.dart';

/// 单人视频通话静态页。
///
/// 这页只做 UI 状态展示，不接真实通话逻辑。
/// - dialing: 拨打中
/// - incoming: 来电中
/// - in_call: 通话中
class ChatPrivateVideoPage extends StatefulWidget {
  final String name;
  final Object? status;
  final bool cameraEnabled;
  final bool initialRemoteOnBackdrop;

  const ChatPrivateVideoPage({
    super.key,
    required this.name,
    this.status = ChatCallStatus.dialing,
    this.cameraEnabled = true,
    this.initialRemoteOnBackdrop = false,
  });

  @override
  State<ChatPrivateVideoPage> createState() => _ChatPrivateVideoPageState();
}

class _ChatPrivateVideoPageState extends State<ChatPrivateVideoPage> {
  late ChatCallStatus _status;
  late bool _micEnabled;
  late bool _cameraEnabled;
  late RongCallState _callState;
  StreamSubscription<RongCallState>? _callSub;
  Timer? _callTimer;
  int _callElapsedMs = 0;
  bool _isClosing = false;
  bool _isMinimized = false;
  String? _miniOverlayName;
  ChatCallStatus _miniOverlayStatus = ChatCallStatus.dialing;
  bool _miniOverlayCameraEnabled = true;
  late bool _isRemoteOnBackdrop;
  RCCallView? _backdropVideoView;
  RCCallView? _previewVideoView;
  bool? _backdropVideoRemote;
  bool? _previewVideoRemote;
  bool _isPreparingVideoViews = false;
  bool _videoRetryBlocked = false;
  Timer? _videoRetryTimer;
  String? _boundLayoutKey;
  int _videoLayoutVersion = 0;
  String get name =>
      _callState.displayName.isNotEmpty ? _callState.displayName : widget.name;
  bool get _isIncoming => _status == ChatCallStatus.incoming;
  bool get _isInCall => _status == ChatCallStatus.inCall;

  @override
  void initState() {
    super.initState();
    _status = _normalizeInitialStatus(widget.status);
    _micEnabled = true;
    _cameraEnabled = widget.cameraEnabled;
    _isRemoteOnBackdrop = widget.initialRemoteOnBackdrop;
    _callState = RongCallManager().state;
    _syncCallState(_callState);
    _callSub = RongCallManager().stateStream.listen(_syncCallState);
    unawaited(_prepareAndBindVideoSlots());
  }

  ChatCallStatus _normalizeInitialStatus(Object? status) {
    if (status is ChatCallStatus) {
      return status;
    }
    if (status is String) {
      return ChatCallStatus.fromRoute(status);
    }
    return ChatCallStatus.dialing;
  }

  @override
  void dispose() {
    _stopCallTimer();
    _videoRetryTimer?.cancel();
    _callSub?.cancel();
    _backdropVideoView = null;
    _previewVideoView = null;
    _backdropVideoRemote = null;
    _previewVideoRemote = null;
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
          if (_isIncoming) _buildIncomingTitle(),
          if (_isInCall) _buildCallTimer(),
          if (!_isInCall)
            Align(
              alignment: const Alignment(0, -0.70),
              child: _buildCenterContent(),
            ),
          Align(
            alignment: const Alignment(0, 0.50),
            child: _isIncoming
                ? _buildIncomingTopControls()
                : _buildCameraAction(),
          ),
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

  /// 整体背景，拨打中优先使用本地预备采集画面。
  Widget _buildBackground() {
    return _buildCameraOffBackground();
  }

  /// 关闭摄像头时，切到更接近语音通话的暗色背景。
  Widget _buildCameraOffBackground() {
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

  /// 背景里的氛围光圈，和语音页保持同一类静态视觉写法。
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

  Widget _buildVideoLayer() {
    return Stack(
      children: [
        if (_backdropVideoView != null)
          Positioned.fill(child: _backdropVideoView!),
        if (_backdropVideoView != null) _buildVideoGradientOverlay(),
        if (_isInCall) _buildPreviewBackground(),
        if (_isInCall && _previewVideoView != null)
          _buildPreviewVideo(_previewVideoView!),
        if (_isInCall) _buildPreviewTapFrame(),
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
                Colors.black.withValues(alpha: 0.32),
                Colors.black.withValues(alpha: 0.18),
                Colors.black.withValues(alpha: 0.34),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Rect _previewRect(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + 84;
    final size = MediaQuery.of(context).size;
    return Rect.fromLTWH(size.width - 112, topPadding, 92, 160);
  }

  Widget _buildPreviewBackground() {
    final rect = _previewRect(context);

    return Positioned.fromRect(
      rect: rect,
      child: Stack(
        children: [
          UserAvatarWidget(
            userId: _callState.targetId,
            avatarUrl: _callState.avatar,
            borderRadius: BorderRadius.circular(8),
            width: rect.width,
            height: rect.height,
          ),

          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(8),
            ),
          ),

          const Center(child: WaitingDots()),
        ],
      ),
    );
  }

  Widget _buildPreviewVideo(Widget videoView) {
    final rect = _previewRect(context);
    return Positioned.fromRect(
      rect: rect,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: IgnorePointer(child: videoView),
      ),
    );
  }

  Widget _buildPreviewTapFrame() {
    final rect = _previewRect(context);
    return Positioned.fromRect(
      rect: rect,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleVideoLayout,
        child: Container(
          decoration: BoxDecoration(
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
        ),
      ),
    );
  }

  /// 左上角缩小按钮。
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
    if (!_minimizeCallToOverlay()) {
      return true;
    }
    return true;
  }

  void _minimizeCall(BuildContext context) {
    _minimizeCallToOverlay();
    if (context.canPop()) {
      context.pop();
    }
  }

  bool _minimizeCallToOverlay() {
    if (!RongCallManager().state.isActive) {
      _VideoMiniOverlayController.dismiss();
      return false;
    }
    _isMinimized = true;
    _miniOverlayName = name;
    _miniOverlayStatus = _status;
    _miniOverlayCameraEnabled = _cameraEnabled;
    _VideoMiniOverlayController.remoteOnBackdrop = _isRemoteOnBackdrop;
    return true;
  }

  void _showMiniOverlayAfterDispose() {
    final overlayName = _miniOverlayName ?? name;
    final overlayStatus = _miniOverlayStatus;
    final overlayCameraEnabled = _miniOverlayCameraEnabled;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!RongCallManager().state.isActive) return;
      final rootContext = AppRouter.rootNavigatorKey.currentContext;
      if (rootContext == null) return;
      _VideoMiniOverlayController.show(
        context: rootContext,
        name: overlayName,
        status: overlayStatus,
        cameraEnabled: overlayCameraEnabled,
        remoteOnBackdrop: _VideoMiniOverlayController.remoteOnBackdrop,
      );
    });
  }

  String get _callDurationText => formatDurationFromMs(_callElapsedMs);

  /// 拨打中 / 来电中的中心内容。
  Widget _buildCenterContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCameraAvatar(),
        const SizedBox(height: 44),
        Text(
          name,
          style: AppTextStyles.h1.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _buildSubtitle(),
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.grey300,
          ),
        ),
      ],
    );
  }

  /// 视频打开时的独立头像，不显示环形光效。
  Widget _buildCameraAvatar() {
    return UserAvatarWidget(
      userId: _callState.targetId,
      avatarUrl: _callState.avatar,
      size: 64,
    );
  }

  /// 来电态上方的三按钮区，和截图保持一致。
  Widget _buildIncomingTopControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => RongCallManager().toggleMicrophone(),
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
            onTap: () => RongCallManager().toggleCamera(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  _cameraEnabled
                      ? 'assets/images/chat/call/camera-off.png'
                      : 'assets/images/chat/call/camera-on.png',
                  width: 24,
                  height: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.currentText(
                    _cameraEnabled
                        ? 'call_turn_off_camera'
                        : 'call_open_camera',
                  ),
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.grey200,
                  ),
                ),
              ],
            ),
          ),
          Image.asset(
            'assets/images/chat/call/camera.png',
            width: 28,
            height: 28,
          ),
        ],
      ),
    );
  }

  /// 来电态底部接听区，单独显示拒接、点阵和接听按钮。
  Widget _buildIncomingBottomControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
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
            onTap: () => RongCallManager().accept(),
          ),
        ],
      ),
    );
  }

  /// 来电态顶部文案，和截图里的标题区保持一致。
  Widget _buildIncomingTitle() {
    final topPadding = MediaQuery.of(context).padding.top + 18;

    return Positioned(
      top: topPadding,
      left: 0,
      right: 0,
      child: Center(
        child: Text(
          AppLocalizations.currentText('call_notifications'),
          style: AppTextStyles.h1.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// 摄像头切换区域，拨打中 / 来电中显示。
  Widget _buildCameraAction() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => RongCallManager().toggleCamera(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            _cameraEnabled
                ? 'assets/images/chat/call/camera-off.png'
                : 'assets/images/chat/call/camera-on.png',
            width: 28,
            height: 28,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.currentText(
              _cameraEnabled ? 'call_turn_off_camera' : 'call_open_camera',
            ),
            style: AppTextStyles.body.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.90),
            ),
          ),
        ],
      ),
    );
  }

  /// 通用图片按钮。
  Widget _buildImageActionButton({
    required String assetPath,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Image.asset(assetPath, width: size, height: size),
    );
  }

  /// 来电态中间的点阵分隔。
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
              color: AppColors.grey400,
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }

  /// 通话中的时间。
  Widget _buildCallTimer() {
    final topPadding = MediaQuery.of(context).padding.top + 14;

    return Positioned(
      top: topPadding,
      left: 0,
      right: 0,
      child: Center(
        child: Text(
          _callDurationText,
          style: AppTextStyles.h1.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _toggleVideoLayout() {
    if (!_isInCall || !_callState.remoteCameraEnabled) return;
    setState(() {
      _isRemoteOnBackdrop = !_isRemoteOnBackdrop;
      _clearVideoViewsForRebuild();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_prepareAndBindVideoSlots());
    });
  }

  /// 底部控制区：麦克风、挂断、摄像头。
  Widget _buildBottomControls(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 48, right: 48, bottom: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => RongCallManager().toggleMicrophone(),
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
            onTap: () => RongCallManager().switchCamera(),
            child: Image.asset(
              'assets/images/chat/call/camera.png',
              width: 28,
              height: 28,
            ),
          ),
        ],
      ),
    );
  }

  String _buildSubtitle() {
    if (_isIncoming) {
      return AppLocalizations.currentText('call_invite_video');
    }
    if (_isInCall) {
      return _callDurationText;
    }
    return AppLocalizations.currentText('call_waiting_accept');
  }

  /// 挂断时同时关闭通话页和悬浮窗，避免小窗残留。
  Future<void> _closeVideoSession(BuildContext context) async {
    if (_isClosing) return;
    _isClosing = true;
    _isMinimized = false;
    _VideoMiniOverlayController.dismiss();
    if (RongCallManager().state.isActive) {
      await RongCallManager().hangup();
    }
    if (!context.mounted) return;
    Navigator.of(context).maybePop();
  }

  void _syncCallState(RongCallState state) {
    if (!mounted) return;
    if (state.status == RongCallStatus.idle) {
      _closePageForInactiveState();
      return;
    }
    if (state.status == RongCallStatus.ended ||
        state.status == RongCallStatus.error) {
      _closePageForInactiveState();
      return;
    }
    final hadRemoteVideo = _canShowRemoteVideo();
    setState(() {
      _callState = state;
      _status = _statusFromCallState(state.status);
      _micEnabled = state.micEnabled;
      _cameraEnabled = state.cameraEnabled;
      final hasRemoteVideo = _canShowRemoteVideo();
      if (hasRemoteVideo && !hadRemoteVideo) {
        _isRemoteOnBackdrop = false;
        _clearVideoViewsForRebuild();
        _scheduleVideoSlotsRebind();
      }
      if (_isRemoteOnBackdrop && !hasRemoteVideo) {
        _isRemoteOnBackdrop = false;
        _clearVideoViewsForRebuild();
      }
      if (!_canShowLocalVideo()) {
        _clearVideoViewsForParticipant(remote: false);
      }
      if (!_canShowRemoteVideo()) {
        _clearVideoViewsForParticipant(remote: true);
      }
    });
    _syncCallTimer(state);
    unawaited(_prepareAndBindVideoSlots());
  }

  void _scheduleVideoSlotsRebind() {
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        _clearVideoViewsForRebuild();
      });
      unawaited(_prepareAndBindVideoSlots());
    });
  }

  void _closePageForInactiveState() {
    _stopCallTimer();
    if (_isClosing) return;
    _isClosing = true;
    _isMinimized = false;
    _VideoMiniOverlayController.dismiss();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  bool _canShowLocalVideo() {
    return _callState.isVideo &&
        _callState.isActive &&
        _cameraEnabled &&
        !_isIncoming;
  }

  bool _canShowRemoteVideo() {
    return _isInCall &&
        _callState.remoteCameraEnabled &&
        _hasRemoteVideoStream(_callState);
  }

  bool _hasRemoteVideoStream(RongCallState state) {
    final currentUserId = state.session?.mine.userId;
    return state.session?.users.any(
          (user) =>
              user.userId.isNotEmpty &&
              user.userId != currentUserId &&
              (user.mediaId?.isNotEmpty ?? false) &&
              user.enableCamera &&
              user.mediaType == RCCallMediaType.audio_video,
        ) ??
        false;
  }

  Future<void> _prepareAndBindVideoSlots() async {
    if (_isPreparingVideoViews || _videoRetryBlocked) return;
    if (!_callState.isVideo || !_callState.isActive) return;

    final layoutKey = [
      _isRemoteOnBackdrop ? 'remote_backdrop' : 'local_backdrop',
      _canShowLocalVideo() ? 'local_on' : 'local_off',
      _canShowRemoteVideo() ? 'remote_on' : 'remote_off',
    ].join('|');
    if (_boundLayoutKey == layoutKey) return;

    _isPreparingVideoViews = true;
    final version = _videoLayoutVersion;
    final backdropRemote = _isRemoteOnBackdrop;
    final previewRemote = !backdropRemote;
    await _unbindCurrentVideoViews();
    if (!mounted) return;
    if (version != _videoLayoutVersion) {
      _isPreparingVideoViews = false;
      return;
    }
    setState(() {
      _backdropVideoView = null;
      _previewVideoView = null;
      _backdropVideoRemote = null;
      _previewVideoRemote = null;
    });
    await WidgetsBinding.instance.endOfFrame;

    final backdropView = await _createVideoView(remote: backdropRemote);
    final previewView = _isInCall
        ? await _createVideoView(remote: previewRemote)
        : null;
    if (!mounted) return;
    if (version != _videoLayoutVersion) {
      _isPreparingVideoViews = false;
      return;
    }

    setState(() {
      _backdropVideoView = backdropView;
      _previewVideoView = previewView;
      _backdropVideoRemote = backdropView == null ? null : backdropRemote;
      _previewVideoRemote = previewView == null ? null : previewRemote;
    });
    await WidgetsBinding.instance.endOfFrame;

    final backdropBound =
        backdropView == null ||
        await _bindVideoView(backdropView, remote: backdropRemote);
    final previewBound =
        previewView == null ||
        await _bindVideoView(previewView, remote: previewRemote);
    if (!mounted) return;
    if (version != _videoLayoutVersion) {
      _isPreparingVideoViews = false;
      return;
    }

    setState(() {
      if (backdropBound && previewBound) {
        _boundLayoutKey = layoutKey;
      } else {
        _clearVideoViewsForRebuild();
        _blockVideoRetry();
      }
      _isPreparingVideoViews = false;
    });
  }

  Future<RCCallView?> _createVideoView({required bool remote}) {
    if (remote) {
      if (!_canShowRemoteVideo()) return Future.value(null);
      return RongCallManager().createRemoteVideoView();
    }
    if (!_canShowLocalVideo()) return Future.value(null);
    return RongCallManager().createLocalVideoView();
  }

  Future<bool> _bindVideoView(RCCallView view, {required bool remote}) {
    return remote
        ? RongCallManager().bindRemoteVideoView(view)
        : RongCallManager().bindLocalVideoView(view);
  }

  Future<void> _unbindCurrentVideoViews() async {
    final futures = <Future<void>>[];
    if (_backdropVideoRemote != null) {
      futures.add(_unbindVideoView(remote: _backdropVideoRemote!));
    }
    if (_previewVideoRemote != null &&
        _previewVideoRemote != _backdropVideoRemote) {
      futures.add(_unbindVideoView(remote: _previewVideoRemote!));
    }
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  Future<void> _unbindVideoView({required bool remote}) {
    return remote
        ? RongCallManager().unbindRemoteVideoView()
        : RongCallManager().unbindLocalVideoView();
  }

  void _clearVideoViewsForRebuild() {
    _backdropVideoView = null;
    _previewVideoView = null;
    _backdropVideoRemote = null;
    _previewVideoRemote = null;
    _boundLayoutKey = null;
    _videoLayoutVersion++;
  }

  void _clearVideoViewsForParticipant({required bool remote}) {
    var didClear = false;
    if (_backdropVideoRemote == remote) {
      _backdropVideoView = null;
      _backdropVideoRemote = null;
      didClear = true;
    }
    if (_previewVideoRemote == remote) {
      _previewVideoView = null;
      _previewVideoRemote = null;
      didClear = true;
    }
    if (didClear) {
      _boundLayoutKey = null;
      _videoLayoutVersion++;
    }
  }

  void _blockVideoRetry() {
    _videoRetryBlocked = true;
    _videoRetryTimer?.cancel();
    _videoRetryTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      _videoRetryBlocked = false;
      unawaited(_prepareAndBindVideoSlots());
    });
  }

  void _syncCallTimer(RongCallState state) {
    if (state.status != RongCallStatus.inCall) {
      _stopCallTimer();
      return;
    }
    _updateCallElapsed();
    _callTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCallElapsed();
    });
  }

  void _updateCallElapsed() {
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

  ChatCallStatus _statusFromCallState(RongCallStatus status) {
    switch (status) {
      case RongCallStatus.incoming:
        return ChatCallStatus.incoming;
      case RongCallStatus.inCall:
        return ChatCallStatus.inCall;
      case RongCallStatus.connecting:
      case RongCallStatus.dialing:
      case RongCallStatus.idle:
      case RongCallStatus.ended:
      case RongCallStatus.error:
        return ChatCallStatus.dialing;
    }
  }
}

/// 视频通话缩小后的悬浮窗。
class _VideoMiniOverlayController {
  static OverlayEntry? _entry;
  static String? _name;
  static ChatCallStatus _status = ChatCallStatus.dialing;
  static bool _cameraEnabled = true;
  static bool remoteOnBackdrop = false;

  static void show({
    required BuildContext context,
    required String name,
    required ChatCallStatus status,
    required bool cameraEnabled,
    required bool remoteOnBackdrop,
  }) {
    dismiss();
    final overlay = Overlay.of(context, rootOverlay: true);

    _name = name;
    _status = status;
    _cameraEnabled = cameraEnabled;
    _VideoMiniOverlayController.remoteOnBackdrop = remoteOnBackdrop;
    _entry = OverlayEntry(
      builder: (overlayContext) => _VideoMiniBubble(
        initialRemoteOnBackdrop: remoteOnBackdrop,
        onTap: () {
          final encodedName = Uri.encodeComponent(_name ?? name);
          final rootContext = AppRouter.rootNavigatorKey.currentContext;
          if (rootContext == null) {
            return;
          }
          dismiss();
          RongCallManager().clearVideoViews();
          final layout = _VideoMiniOverlayController.remoteOnBackdrop
              ? 'remote'
              : 'local';
          rootContext.push(
            '/chat-private-video/$encodedName?status=${_status.routeValue}&camera=${_cameraEnabled ? 'on' : 'off'}&backdrop=$layout',
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

/// 视频通话的小窗，使用截图里的矩形预览样式。
class _VideoMiniBubble extends StatefulWidget {
  final VoidCallback onTap;
  final bool initialRemoteOnBackdrop;

  const _VideoMiniBubble({
    required this.onTap,
    required this.initialRemoteOnBackdrop,
  });

  @override
  State<_VideoMiniBubble> createState() => _VideoMiniBubbleState();
}

class _VideoMiniBubbleState extends State<_VideoMiniBubble> {
  static const double _bubbleWidth = 92;
  static const double _bubbleHeight = 160;
  static const double _previewWidth = 32;
  static const double _previewHeight = 56;

  Offset? _position;
  bool _isDragging = false;
  late RongCallState _callState;
  late bool _isRemoteOnBackdrop;
  StreamSubscription<RongCallState>? _callSub;
  RCCallView? _localVideoView;
  RCCallView? _remoteVideoView;
  bool _isPreparingLocalView = false;
  bool _isPreparingRemoteView = false;
  bool _localVideoBound = false;
  bool _remoteVideoBound = false;
  bool _localVideoRetryBlocked = false;
  bool _remoteVideoRetryBlocked = false;
  Timer? _localVideoRetryTimer;
  Timer? _remoteVideoRetryTimer;

  @override
  void initState() {
    super.initState();
    _isRemoteOnBackdrop = widget.initialRemoteOnBackdrop;
    _callState = RongCallManager().state;
    _syncCallState(_callState);
    _callSub = RongCallManager().stateStream.listen(_syncCallState);
    unawaited(_prepareVideoViewsIfNeeded());
  }

  @override
  void dispose() {
    _localVideoRetryTimer?.cancel();
    _remoteVideoRetryTimer?.cancel();
    _callSub?.cancel();
    super.dispose();
  }

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
    final backdropView = _backdropVideoView();
    final previewView = _previewVideoView();

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
            fit: StackFit.expand,
            children: [
              backdropView != null
                  ? IgnorePointer(child: backdropView)
                  : const DecoratedBox(
                      decoration: BoxDecoration(color: Colors.black),
                    ),
              if (_callState.status == RongCallStatus.inCall)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: _previewWidth,
                    height: _previewHeight,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.55),
                        width: 0.5,
                      ),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: previewView != null
                        ? IgnorePointer(child: previewView)
                        : const SizedBox.expand(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _syncCallState(RongCallState state) {
    if (state.status == RongCallStatus.idle ||
        state.status == RongCallStatus.ended ||
        state.status == RongCallStatus.error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _VideoMiniOverlayController.dismiss();
      });
      return;
    }
    if (!mounted) return;
    final hadRemoteVideo = _shouldShowRemoteVideo(_callState);
    setState(() {
      _callState = state;
      final hasRemoteVideo = _shouldShowRemoteVideo(state);
      if (hasRemoteVideo && !hadRemoteVideo) {
        _isRemoteOnBackdrop = false;
        _VideoMiniOverlayController.remoteOnBackdrop = false;
      }
      if (_isRemoteOnBackdrop && !hasRemoteVideo) {
        _isRemoteOnBackdrop = false;
        _VideoMiniOverlayController.remoteOnBackdrop = false;
      }
      if (!_shouldShowLocalVideo(state)) {
        _localVideoView = null;
        _localVideoBound = false;
      }
      if (!_shouldShowRemoteVideo(state)) {
        _remoteVideoView = null;
        _remoteVideoBound = false;
      }
    });
    unawaited(_prepareVideoViewsIfNeeded());
  }

  Widget? _backdropVideoView() {
    return _isRemoteOnBackdrop ? _remoteVideoView : _localVideoView;
  }

  Widget? _previewVideoView() {
    return _isRemoteOnBackdrop ? _localVideoView : _remoteVideoView;
  }

  bool _shouldShowLocalVideo(RongCallState state) {
    return state.isVideo && state.isActive && state.cameraEnabled;
  }

  bool _shouldShowRemoteVideo(RongCallState state) {
    return state.isVideo &&
        state.status == RongCallStatus.inCall &&
        state.remoteCameraEnabled &&
        _hasRemoteVideoStream(state);
  }

  bool _hasRemoteVideoStream(RongCallState state) {
    final currentUserId = state.session?.mine.userId;
    return state.session?.users.any(
          (user) =>
              user.userId.isNotEmpty &&
              user.userId != currentUserId &&
              (user.mediaId?.isNotEmpty ?? false) &&
              user.enableCamera &&
              user.mediaType == RCCallMediaType.audio_video,
        ) ??
        false;
  }

  Future<void> _prepareVideoViewsIfNeeded() async {
    await _prepareLocalVideoViewIfNeeded();
    await _prepareRemoteVideoViewIfNeeded();
  }

  Future<void> _prepareLocalVideoViewIfNeeded() async {
    if (_localVideoBound) return;
    if (_isPreparingLocalView || _localVideoView != null) return;
    if (_localVideoRetryBlocked) return;
    if (!_shouldShowLocalVideo(_callState)) return;

    _isPreparingLocalView = true;
    final view = await RongCallManager().createLocalVideoView();
    if (!mounted) return;
    setState(() {
      _localVideoView = view;
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
      _isPreparingLocalView = false;
    });
  }

  Future<void> _prepareRemoteVideoViewIfNeeded() async {
    if (_remoteVideoBound) return;
    if (_isPreparingRemoteView || _remoteVideoView != null) {
      return;
    }
    if (_remoteVideoRetryBlocked) return;
    if (!_shouldShowRemoteVideo(_callState)) return;

    _isPreparingRemoteView = true;
    final view = await RongCallManager().createRemoteVideoView();
    if (!mounted) return;
    setState(() {
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
      _isPreparingRemoteView = false;
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
}
