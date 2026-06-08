import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/modules/call/rong_call_manager.dart';
import 'package:paracosm/router/app_router.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/util/string_util.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';

/// 私聊语音通话静态页
///
/// 这份页面不接真实通话逻辑，只按照设计稿展示三个静态状态：
/// - dialing：拨打中
/// - incoming：来电中
/// - in_call：通话中
class ChatPrivateVoicePage extends StatefulWidget {
  final String name;
  final String status;

  const ChatPrivateVoicePage({
    super.key,
    required this.name,
    this.status = 'dialing',
  });

  @override
  State<ChatPrivateVoicePage> createState() => _ChatPrivateVoicePageState();
}

class _ChatPrivateVoicePageState extends State<ChatPrivateVoicePage> {
  late String _status;
  late RongCallState _callState;
  StreamSubscription<RongCallState>? _callSub;
  Timer? _callTimer;
  int _callElapsedMs = 0;
  bool _isClosing = false;

  String get name =>
      _callState.displayName.isNotEmpty ? _callState.displayName : widget.name;
  String get status => _status;
  bool get _isIncoming => _status == 'incoming';
  bool get _isInCall => _status == 'in_call';

  @override
  void initState() {
    super.initState();
    _status = widget.status;
    _callState = RongCallManager().state;
    _syncCallState(_callState);
    _callSub = RongCallManager().stateStream.listen(_syncCallState);
  }

  @override
  void dispose() {
    _stopCallTimer();
    _callSub?.cancel();
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
          _buildCloseButton(context),
          Align(
            alignment: const Alignment(0, -0.5),
            child: _buildCenterContent(context),
          ),
          Align(
            alignment: const Alignment(0, 0.8),
            child: _buildBottomControls(context),
          ),
        ],
      ),
    );
  }

  /// 构建整页背景。
  /// 这里只做静态视觉效果，不做动态动画。
  Widget _buildBackground() {
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

  /// 构建背景里的氛围光晕。
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

  /// 左上角关闭按钮。
  Widget _buildCloseButton(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + 12;

    return Positioned(
      left: 20,
      top: topPadding,
      child: GestureDetector(
        onTap: () => _minimizeCall(context),
        child: Image.asset(
          'assets/images/chat/call/voice-small.png',
          width: 32,
          height: 32,
        ),
      ),
    );
  }

  Future<bool> _minimizeCallBeforeBack() async {
    _showMiniOverlay(context);
    return true;
  }

  void _minimizeCall(BuildContext context) {
    _showMiniOverlay(context);
    if (context.canPop()) {
      context.pop();
    }
  }

  void _showMiniOverlay(BuildContext context) {
    _VoiceMiniOverlayController.show(
      context: context,
      name: name,
      status: status,
    );
  }

  /// 中部头像、昵称、状态文案。
  Widget _buildCenterContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAvatarRing(),
        const SizedBox(height: 48),
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

  /// 中间的头像环效果。
  Widget _buildAvatarRing() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 198,
          height: 198,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF9AB000).withValues(alpha: 0.08),
          ),
        ),
        Container(
          width: 164,
          height: 164,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF90A000).withValues(alpha: 0.18),
          ),
        ),
        Container(
          width: 138,
          height: 138,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFBDD100).withValues(alpha: 0.22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9AB000).withValues(alpha: 0.35),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        Container(
          width: 108,
          height: 108,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF61D3B0),
          ),
          child: ClipOval(
            child: UserAvatarWidget(
              userId: _callState.targetId,
              avatarUrl: _callState.avatar,
              size: 108,
            ),
          ),
        ),
      ],
    );
  }

  /// 根据不同状态返回说明文案。
  String _buildSubtitle() {
    if (_isIncoming) {
      return AppLocalizations.currentText('call_invite_voice');
    }
    if (_isInCall) {
      return formatDurationFromMs(_callElapsedMs);
    }
    // 默认状态展示拨打中的提示文案。
    return AppLocalizations.currentText('call_waiting_accept');
  }

  /// 底部控制区。
  Widget _buildBottomControls(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 24;

    return Padding(
      padding: EdgeInsets.only(left: 48, right: 48, bottom: bottomPadding),
      child: _isIncoming
          ? _buildIncomingControls(
              onAnswer: _answerCall,
              onHangup: () => _closeVoiceSession(context),
            )
          : _VoiceControlButtons(
              isInCall: _isInCall,
              micEnabled: _callState.micEnabled,
              speakerEnabled: _callState.speakerEnabled,
              onMicTap: () => RongCallManager().toggleMicrophone(),
              onSpeakerTap: () => RongCallManager().toggleSpeaker(),
              onHangup: () => _closeVoiceSession(context),
            ),
    );
  }

  /// 来电中底部控制。
  Widget _buildIncomingControls({
    required VoidCallback onAnswer,
    required VoidCallback onHangup,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildImageActionButton(
          assetPath: 'assets/images/chat/call/voice-cancel.png',
          size: 72,
          onTap: onHangup,
        ),
        _buildIncomingDots(),
        _buildImageActionButton(
          assetPath: 'assets/images/chat/call/voice-answer.png',
          size: 72,
          onTap: onAnswer,
        ),
      ],
    );
  }

  /// 拨打/通话中的红色挂断按钮。
  /// 底部两侧音频控制按钮，直接使用资源图标。
  /// 通用圆形操作按钮，直接显示图片资源。
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

  /// 来电中间的等待点。
  /// 关闭当前通话页时，同时清理悬浮窗，避免小窗残留在屏幕上。
  Future<void> _closeVoiceSession(BuildContext context) async {
    if (_isClosing) return;
    _isClosing = true;
    _VoiceMiniOverlayController.dismiss();
    if (RongCallManager().state.isActive) {
      await RongCallManager().hangup();
    }
    if (!context.mounted) return;
    Navigator.of(context).maybePop();
  }

  Future<void> _answerCall() async {
    await RongCallManager().accept();
  }

  void _syncCallState(RongCallState state) {
    if (!mounted) return;
    if (state.status == RongCallStatus.idle) {
      _stopCallTimer();
      return;
    }
    if (state.status == RongCallStatus.ended ||
        state.status == RongCallStatus.error) {
      _stopCallTimer();
      if (_isClosing) return;
      _isClosing = true;
      _VoiceMiniOverlayController.dismiss();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      return;
    }
    setState(() {
      _callState = state;
      _status = _statusFromCallState(state.status);
    });
    _syncCallTimer(state);
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
}

/// ??????????
class _VoiceControlButtons extends StatefulWidget {
  final bool isInCall;
  final bool micEnabled;
  final bool speakerEnabled;
  final VoidCallback onMicTap;
  final VoidCallback onSpeakerTap;
  final VoidCallback onHangup;

  const _VoiceControlButtons({
    required this.isInCall,
    required this.micEnabled,
    required this.speakerEnabled,
    required this.onMicTap,
    required this.onSpeakerTap,
    required this.onHangup,
  });

  @override
  State<_VoiceControlButtons> createState() => _VoiceControlButtonsState();
}

class _VoiceControlButtonsState extends State<_VoiceControlButtons> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: widget.onMicTap,
          child: Image.asset(
            widget.micEnabled
                ? 'assets/images/chat/call/mic-on.png'
                : 'assets/images/chat/call/mic-off.png',
            width: 28,
            height: 28,
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onHangup,
          child: Image.asset(
            'assets/images/chat/call/voice-cancel.png',
            width: 72,
            height: 72,
          ),
        ),
        GestureDetector(
          onTap: widget.onSpeakerTap,
          child: Image.asset(
            widget.speakerEnabled
                ? 'assets/images/chat/call/sound-on.png'
                : 'assets/images/chat/call/sound-off.png',
            width: 28,
            height: 28,
          ),
        ),
      ],
    );
  }
}

/// ??????????????
class _VoiceMiniOverlayController {
  static OverlayEntry? _entry;
  static String? _name;
  static String _status = 'dialing';

  static void show({
    required BuildContext context,
    required String name,
    required String status,
  }) {
    dismiss();
    final overlay = Overlay.of(context, rootOverlay: true);

    _name = name;
    _status = status;
    _entry = OverlayEntry(
      builder: (overlayContext) => _VoiceMiniBubble(
        name: _name ?? name,
        status: _status,
        onTap: () {
          final encodedName = Uri.encodeComponent(_name ?? name);
          final rootContext = AppRouter.rootNavigatorKey.currentContext;
          if (rootContext == null) {
            return;
          }
          dismiss();
          rootContext.push('/chat-private-voice/$encodedName?status=$_status');
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

/// 可拖动的通话悬浮窗，方便后续其他页面复用“缩小后悬浮”的交互。
class _VoiceMiniBubble extends StatefulWidget {
  final String name;
  final String status;
  final VoidCallback onTap;

  const _VoiceMiniBubble({
    required this.name,
    required this.status,
    required this.onTap,
  });

  @override
  State<_VoiceMiniBubble> createState() => _VoiceMiniBubbleState();
}

class _VoiceMiniBubbleState extends State<_VoiceMiniBubble> {
  static const double _bubbleWidth = 64;
  static const double _bubbleHeight = 64;

  Offset? _position;
  bool _isDragging = false;
  late RongCallState _callState;
  StreamSubscription<RongCallState>? _callSub;
  Timer? _callTimer;
  int _callElapsedMs = 0;

  @override
  void initState() {
    super.initState();
    _callState = RongCallManager().state;
    _syncCallState(_callState);
    _callSub = RongCallManager().stateStream.listen(_syncCallState);
  }

  @override
  void dispose() {
    _stopCallTimer();
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
      media.padding.top + 92,
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
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/chat/call/call-status.png',
                width: 18,
                height: 18,
              ),
              const SizedBox(height: 4),
              Text(
                _buildSubtitle(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildSubtitle() {
    if (_callState.status == RongCallStatus.inCall) {
      return formatDurationFromMs(_callElapsedMs);
    }
    return AppLocalizations.currentText('call_waiting_short');
  }

  void _syncCallState(RongCallState state) {
    if (!mounted) return;
    if (state.status == RongCallStatus.idle ||
        state.status == RongCallStatus.ended ||
        state.status == RongCallStatus.error) {
      _stopCallTimer();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _VoiceMiniOverlayController.dismiss();
      });
      return;
    }
    setState(() {
      _callState = state;
    });
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
}
