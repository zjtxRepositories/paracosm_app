import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/router/app_router.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';

/// 单人视频通话静态页。
///
/// 这页只做 UI 状态展示，不接真实通话逻辑。
/// - dialing: 拨打中
/// - incoming: 来电中
/// - in_call: 通话中
class ChatPrivateVideoPage extends StatefulWidget {
  final String name;
  final String status;
  final bool cameraEnabled;

  const ChatPrivateVideoPage({
    super.key,
    required this.name,
    this.status = 'dialing',
    this.cameraEnabled = true,
  });

  @override
  State<ChatPrivateVideoPage> createState() => _ChatPrivateVideoPageState();
}

class _ChatPrivateVideoPageState extends State<ChatPrivateVideoPage> {
  late String _status;
  late bool _micEnabled;
  late bool _cameraEnabled;

  String get name => widget.name;
  bool get _isIncoming => _status == 'incoming';
  bool get _isInCall => _status == 'in_call';

  @override
  void initState() {
    super.initState();
    _status = widget.status;
    _micEnabled = true;
    _cameraEnabled = widget.cameraEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      showNav: false,
      isAddBottomMargin: false,
      backgroundColor: Colors.black,
      backTheme: Brightness.dark,
      child: Stack(
        children: [
          _buildBackground(),
          _buildCloseButton(context),
          if (_isIncoming) _buildIncomingTitle(),
          if (_cameraEnabled && _isInCall) _buildCallTimer(),
          if (_cameraEnabled && _isInCall) _buildLocalPreview(),
          if (!(_cameraEnabled && _isInCall))
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

  /// 整体背景，直接使用视频背景图作为主视觉。
  Widget _buildBackground() {
    if (!_cameraEnabled) {
      return _buildCameraOffBackground();
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
                  Colors.black.withValues(alpha: 0.32),
                  Colors.black.withValues(alpha: 0.18),
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
  Widget _buildGlowCircle({
    required double size,
    required List<Color> colors,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
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
        onTap: () {
          _VideoMiniOverlayController.show(
            context: context,
            name: name,
            status: _status,
            cameraEnabled: _cameraEnabled,
          );
          Navigator.of(context).maybePop();
        },
        child: Image.asset(
          'assets/images/chat/call/video-small.png',
          width: 32,
          height: 32,
        ),
      ),
    );
  }

  /// 拨打中 / 来电中的中心内容。
  Widget _buildCenterContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _cameraEnabled ? _buildCameraAvatar() : _buildAvatarRing(),
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
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF61D3B0),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/chat/avatar.png',
          fit: BoxFit.cover,
        ),
      ),
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
            onTap: () {
              setState(() {
                _micEnabled = !_micEnabled;
              });
            },
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
            onTap: () {
              setState(() {
                _cameraEnabled = !_cameraEnabled;
              });
            },
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
                  _cameraEnabled ? 'Turn Off Camera' : 'Open The Camera',
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
            onTap: () {
              setState(() {
                _status = 'in_call';
              });
            },
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
          'Notifications',
          style: AppTextStyles.h1.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// 中间头像环，拨打态和来电态共用。
  Widget _buildAvatarRing() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 190,
          height: 190,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF9AB000).withValues(alpha: 0.10),
          ),
        ),
        Container(
          width: 158,
          height: 158,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF90A000).withValues(alpha: 0.18),
          ),
        ),
        Container(
          width: 132,
          height: 132,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFBDD100).withValues(alpha: 0.24),
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
          width: 104,
          height: 104,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF61D3B0),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/chat/avatar.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  /// 摄像头切换区域，拨打中 / 来电中显示。
  Widget _buildCameraAction() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _cameraEnabled = !_cameraEnabled;
        });
      },
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
            _cameraEnabled ? 'Turn Off Camera' : 'Open The Camera',
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
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
      ),
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
          '00:08:32',
          style: AppTextStyles.h1.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// 通话中的右上角小窗预览。
  Widget _buildLocalPreview() {
    final topPadding = MediaQuery.of(context).padding.top + 84;

    return Positioned(
      right: 20,
      top: topPadding,
      child: Container(
        width: 92,
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.grey600,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Image.asset(
          'assets/images/chat/call/video-bg.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// 底部控制区：麦克风、挂断、摄像头。
  Widget _buildBottomControls(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 24;

    return Padding(
      padding: EdgeInsets.only(
        left: 48,
        right: 48,
        bottom: bottomPadding,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _micEnabled = !_micEnabled;
              });
            },
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
      return 'Invite you to video call';
    }
    if (_isInCall) {
      return '00:08:32';
    }
    return 'Waiting for the invitation to be accepted...';
  }

  /// 挂断时同时关闭通话页和悬浮窗，避免小窗残留。
  void _closeVideoSession(BuildContext context) {
    _VideoMiniOverlayController.dismiss();
    Navigator.of(context).maybePop();
  }
}

/// 视频通话缩小后的悬浮窗。
class _VideoMiniOverlayController {
  static OverlayEntry? _entry;
  static String? _name;
  static String _status = 'dialing';
  static bool _cameraEnabled = true;

  static void show({
    required BuildContext context,
    required String name,
    required String status,
    required bool cameraEnabled,
  }) {
    dismiss();
    final overlay = Overlay.of(context, rootOverlay: true);

    _name = name;
    _status = status;
    _cameraEnabled = cameraEnabled;
    _entry = OverlayEntry(
      builder: (overlayContext) => _VideoMiniBubble(
        onTap: () {
          final encodedName = Uri.encodeComponent(_name ?? name);
          final rootContext = AppRouter.rootNavigatorKey.currentContext;
          if (rootContext == null) {
            return;
          }
          dismiss();
          rootContext.push(
            '/chat-private-video/$encodedName?status=$_status&camera=${_cameraEnabled ? 'on' : 'off'}',
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

  const _VideoMiniBubble({
    required this.onTap,
  });

  @override
  State<_VideoMiniBubble> createState() => _VideoMiniBubbleState();
}

class _VideoMiniBubbleState extends State<_VideoMiniBubble> {
  static const double _bubbleWidth = 92;
  static const double _bubbleHeight = 160;

  Offset? _position;

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
    return Offset(
      value.dx.clamp(minX, maxX),
      value.dy.clamp(minY, maxY),
    );
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

  @override
  Widget build(BuildContext context) {
    final position = _position ?? Offset.zero;

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onPanUpdate: _handlePanUpdate,
        child: Container(
          width: _bubbleWidth,
          height: _bubbleHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF737373),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Image.asset(
            'assets/images/chat/call/video-bg.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
