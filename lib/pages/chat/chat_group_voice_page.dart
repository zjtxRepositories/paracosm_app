import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/router/app_router.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';

class ChatGroupVoicePage extends StatefulWidget {
  final String name;
  final String status;

  const ChatGroupVoicePage({
    super.key,
    required this.name,
    this.status = 'dialing',
  });

  @override
  State<ChatGroupVoicePage> createState() => _ChatGroupVoicePageState();
}

class _ChatGroupVoicePageState extends State<ChatGroupVoicePage> {
  static const String _incomingDisplayName = 'Kristen';
  static const String _localUserName = 'Wei Wei';
  static const List<_VoiceParticipant> _inCallParticipants = [
    _VoiceParticipant(
      name: 'ME',
      micEnabled: true,
      avatarColor: Color(0xFFB58C84),
    ),
    _VoiceParticipant(
      name: 'Wilson',
      micEnabled: false,
      avatarColor: Color(0xFFB7DD46),
    ),
    _VoiceParticipant(
      name: 'Kristen',
      micEnabled: false,
      avatarColor: Color(0xFFF1B4B0),
    ),
    _VoiceParticipant(
      name: 'Robert',
      micEnabled: false,
      avatarColor: Color(0xFF8DE4C1),
    ),
    _VoiceParticipant(
      name: 'Howard',
      micEnabled: false,
      avatarColor: Color(0xFF92D1FF),
    ),
    _VoiceParticipant(
      name: 'Others',
      micEnabled: false,
      avatarColor: Color(0xFF6A655F),
      isOverflow: true,
      hiddenCount: 1,
    ),
    _VoiceParticipant(
      name: 'Olivia',
      micEnabled: true,
      avatarColor: Color(0xFFCBB4FF),
    ),
  ];

  late String _status;

  String get name => widget.name;
  String get status => _status;
  bool get _isIncoming => _status == 'incoming';
  bool get _isInCall => _status == 'in_call';

  @override
  void initState() {
    super.initState();
    _status = widget.status;
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
          Align(
            alignment: const Alignment(0, -0.5),
            child: _buildCenterContent(),
          ),
          Align(
            alignment: const Alignment(0, 0.8),
            child: _buildBottomControls(context),
          ),
        ],
      ),
    );
  }

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
        onTap: () {
          _GroupVoiceMiniOverlayController.show(
            context: context,
            name: name,
            status: status,
          );
          Navigator.of(context).maybePop();
        },
        child: Image.asset(
          'assets/images/chat/call/voice-small.png',
          width: 32,
          height: 32,
        ),
      ),
    );
  }

  Widget _buildCenterContent() {
    if (_isInCall) {
      return _buildInCallParticipants();
    }

    final displayName = _isIncoming ? _incomingDisplayName : name;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildGroupAvatarRing(),
        const SizedBox(height: 56),
        Text(
          '$displayName''(20)',
          style: AppTextStyles.h1.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        _buildSubtitleWidget(),
      ],
    );
  }

  Widget _buildInCallParticipants() {
    final visibleParticipants = _inCallParticipants
        .take(6)
        .toList(growable: false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 58),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildParticipantRow(
                visibleParticipants.take(3).toList(growable: false),
              ),
              const SizedBox(height: 28),
              _buildParticipantRow(
                visibleParticipants.skip(3).take(3).toList(growable: false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantRow(List<_VoiceParticipant> participants) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < participants.length; i++) ...[
          _buildParticipantCell(participants[i]),
        ],
      ],
    );
  }

  Widget _buildParticipantCell(_VoiceParticipant participant) {
    return SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildParticipantAvatar(participant),
          const SizedBox(height: 12),
          Text(
            participant.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantAvatar(_VoiceParticipant participant) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: Container(
              width: 60,
              height: 60,
              color: participant.avatarColor,
              child: participant.isOverflow
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                          child: Image.asset(
                            'assets/images/chat/avatar.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                        Container(color: Colors.black.withValues(alpha: 0.32)),
                        Center(
                          child: Text(
                            '+${participant.hiddenCount}',
                            style: AppTextStyles.h1.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Image.asset(
                      'assets/images/chat/avatar.png',
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          if (!participant.isOverflow)
            Positioned(
              right: -2,
              bottom: -2,
              child: Image.asset(
                participant.micEnabled
                    ? 'assets/images/chat/call/mic-active.png'
                    : 'assets/images/chat/call/mic-close.png',
                width: 18,
                height: 18,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInCallDurationWidget() {
    final baseStyle = AppTextStyles.body.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.grey300,
    );

    return Text('00:08:32', textAlign: TextAlign.center, style: baseStyle);
  }

  Widget _buildGroupAvatarRing() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const designSize = 284.0;
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : designSize;
        final scale = availableWidth < designSize
            ? availableWidth / designSize
            : 1.0;
        final outerSize = designSize * scale;
        final middleSize = 212.0 * scale;
        final innerSize = 136.0 * scale;

        return SizedBox(
          width: outerSize,
          height: outerSize,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: outerSize,
                height: outerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF9AB000).withValues(alpha: 0.08),
                ),
              ),
              Container(
                width: middleSize,
                height: middleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF90A000).withValues(alpha: 0.18),
                ),
              ),
              Container(
                width: innerSize,
                height: innerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFBDD100).withValues(alpha: 0.20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9AB000).withValues(alpha: 0.28),
                      blurRadius: 18 * scale,
                      spreadRadius: 2 * scale,
                    ),
                  ],
                ),
              ),
              ..._buildOrbitAvatars(scale),
              ..._buildFloatingDots(scale),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildOrbitAvatars(double scale) {
    return [
      // 左上大头像
      Positioned(
        left: 42.0 * scale,
        top: 8.0 * scale,
        child: _buildOrbitAvatar(
          size: 58.0 * scale,
          innerSize: 44.0 * scale,
          borderPadding: 4.0 * scale,
          ringColor: const Color(0xFFFFFFFF),
          fillColor: const Color(0xFF96D831),
        ),
      ),

      // 右上大头像
      Positioned(
        right: 24.0 * scale,
        top: 16.0 * scale,
        child: _buildOrbitAvatar(
          size: 60.0 * scale,
          innerSize: 46.0 * scale,
          borderPadding: 4.0 * scale,
          ringColor: const Color(0xFFFFFFFF),
          fillColor: const Color(0xFFF2B0AD),
        ),
      ),

      // 中上小头像
      Positioned(
        left: 118.0 * scale,
        top: 54.0 * scale,
        child: _buildOrbitAvatar(
          size: 42.0 * scale,
          innerSize: 30.0 * scale,
          borderPadding: 3.0 * scale,
          ringColor: const Color(0xFFFFFFFF),
          fillColor: const Color(0xFFD8CCFF),
        ),
      ),

      // 左侧头像
      Positioned(
        left: 2.0 * scale,
        top: 104.0 * scale,
        child: _buildOrbitAvatar(
          size: 46.0 * scale,
          innerSize: 34.0 * scale,
          borderPadding: 3.0 * scale,
          ringColor: const Color(0xFFFFFFFF),
          fillColor: const Color(0xFF6EC5F7),
        ),
      ),

      // 左中很小头像
      Positioned(
        left: 78.0 * scale,
        top: 138.0 * scale,
        child: _buildOrbitAvatar(
          size: 28.0 * scale,
          innerSize: 20.0 * scale,
          borderPadding: 2.5 * scale,
          ringColor: const Color(0xFFFFFFFF),
          fillColor: const Color(0xFFF0C6C0),
        ),
      ),

      // 中右主头像（最大）
      Positioned(
        left: 146.0 * scale,
        top: 142.0 * scale,
        child: _buildOrbitAvatar(
          size: 62.0 * scale,
          innerSize: 48.0 * scale,
          borderPadding: 4.0 * scale,
          ringColor: const Color(0xFFFFFFFF),
          fillColor: const Color(0xFF7AE7C6),
        ),
      ),

      // 右侧小头像
      Positioned(
        right: 20.0 * scale,
        top: 136.0 * scale,
        child: _buildOrbitAvatar(
          size: 32.0 * scale,
          innerSize: 22.0 * scale,
          borderPadding: 2.5 * scale,
          ringColor: const Color(0xFFFFFFFF),
          fillColor: const Color(0xFF8FE3D0),
        ),
      ),

      // 左下头像
      Positioned(
        left: 52.0 * scale,
        bottom: 6.0 * scale,
        child: _buildOrbitAvatar(
          size: 42.0 * scale,
          innerSize: 30.0 * scale,
          borderPadding: 3.0 * scale,
          ringColor: const Color(0xFFFFFFFF),
          fillColor: const Color(0xFFDFF55C),
        ),
      ),

      // 下方偏右头像
      Positioned(
        left: 156.0 * scale,
        bottom: 0.0 * scale,
        child: _buildOrbitAvatar(
          size: 46.0 * scale,
          innerSize: 34.0 * scale,
          borderPadding: 3.0 * scale,
          ringColor: const Color(0xFFFFFFFF),
          fillColor: const Color(0xFF73C2F7),
        ),
      ),
    ];
  }

  List<Widget> _buildFloatingDots(double scale) {
    final dotSpecs = <_FloatingDotSpec>[
      // 左上橙色大点
      _FloatingDotSpec(
        size: 22.0 * scale,
        left: 42.0 * scale,
        top: 70.0 * scale,
        color: const Color(0xFFFF8B3D),
      ),

      // 顶部黄绿色点
      _FloatingDotSpec(
        size: 18.0 * scale,
        left: 142.0 * scale,
        top: -5.0 * scale,
        color: const Color(0xFFB3CE0B),
      ),

      // 右上偏中的紫点
      _FloatingDotSpec(
        size: 10.0 * scale,
        right: 48.0 * scale,
        top: 84.0 * scale,
        color: const Color(0xFF7D6CF7),
      ),

      // 左下蓝点
      _FloatingDotSpec(
        size: 10.0 * scale,
        left: 20.0 * scale,
        bottom: 56.0 * scale,
        color: const Color(0xFF57B6FF),
      ),

      // 下方中间粉点
      _FloatingDotSpec(
        size: 9.0 * scale,
        left: 118.0 * scale,
        bottom: 32.0 * scale,
        color: const Color(0xFFFF5F7E),
      ),

      // 右下黄色大点
      _FloatingDotSpec(
        size: 22.0 * scale,
        right: 22.0 * scale,
        bottom: 46.0 * scale,
        color: const Color(0xFFF2B400),
      ),
    ];

    return dotSpecs
        .map(
          (spec) => Positioned(
            left: spec.left,
            top: spec.top,
            right: spec.right,
            bottom: spec.bottom,
            child: _buildAccentDot(size: spec.size, color: spec.color),
          ),
        )
        .toList();
  }

  Widget _buildOrbitAvatar({
    required double size,
    required double innerSize,
    required double borderPadding,
    required Color ringColor,
    required Color fillColor,
  }) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(borderPadding),
      decoration: BoxDecoration(
        color: ringColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Container(
        width: innerSize,
        height: innerSize,
        decoration: BoxDecoration(shape: BoxShape.circle, color: fillColor),
        child: ClipOval(
          child: Image.asset(
            'assets/images/chat/avatar.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildAccentDot({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildSubtitleWidget() {
    final baseStyle = AppTextStyles.body.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.grey300,
    );

    if (_isIncoming) {
      return Text(
        'Invite you to voice call',
        textAlign: TextAlign.center,
        style: baseStyle,
      );
    }
    if (_isInCall) {
      return Text('00:08:32', textAlign: TextAlign.center, style: baseStyle);
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'Waiting for ', style: baseStyle),
          TextSpan(
            text: _localUserName,
            style: baseStyle.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(text: ' and others to join...', style: baseStyle),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 24;

    if (_isInCall) {
      return Padding(
        padding: EdgeInsets.only(left: 48, right: 48, bottom: bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInCallDurationWidget(),
            const SizedBox(height: 108),
            _VoiceControlButtons(
              isInCall: _isInCall,
              onHangup: () => _closeVoiceSession(context),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(left: 48, right: 48, bottom: bottomPadding),
      child: _isIncoming
          ? _buildIncomingControls(
              onAnswer: () => _enterInCall(context),
              onHangup: () => _closeVoiceSession(context),
            )
          : _VoiceControlButtons(
              isInCall: _isInCall,
              onHangup: () => _closeVoiceSession(context),
            ),
    );
  }

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

  void _closeVoiceSession(BuildContext context) {
    _GroupVoiceMiniOverlayController.dismiss();
    Navigator.of(context).maybePop();
  }

  void _enterInCall(BuildContext context) {
    setState(() {
      _status = 'in_call';
    });
  }
}

class _VoiceControlButtons extends StatefulWidget {
  final bool isInCall;
  final VoidCallback onHangup;

  const _VoiceControlButtons({required this.isInCall, required this.onHangup});

  @override
  State<_VoiceControlButtons> createState() => _VoiceControlButtonsState();
}

class _VoiceControlButtonsState extends State<_VoiceControlButtons> {
  late bool _micEnabled;
  late bool _soundEnabled;

  @override
  void initState() {
    super.initState();
    // 进入通话中时，默认麦克风和扬声器都处于开启状态。
    _micEnabled = true;
    _soundEnabled = true;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
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
          onTap: widget.onHangup,
          child: Image.asset(
            'assets/images/chat/call/voice-cancel.png',
            width: 72,
            height: 72,
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _soundEnabled = !_soundEnabled;
            });
          },
          child: Image.asset(
            _soundEnabled
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

class _GroupVoiceMiniOverlayController {
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
      builder: (overlayContext) => _GroupVoiceMiniBubble(
        name: _name ?? name,
        status: _status,
        onTap: () {
          final encodedName = Uri.encodeComponent(_name ?? name);
          final rootContext = AppRouter.rootNavigatorKey.currentContext;
          if (rootContext == null) {
            return;
          }
          dismiss();
          rootContext.push('/chat-group-voice/$encodedName?status=$_status');
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

class _GroupVoiceMiniBubble extends StatefulWidget {
  final String name;
  final String status;
  final VoidCallback onTap;

  const _GroupVoiceMiniBubble({
    required this.name,
    required this.status,
    required this.onTap,
  });

  @override
  State<_GroupVoiceMiniBubble> createState() => _GroupVoiceMiniBubbleState();
}

class _GroupVoiceMiniBubbleState extends State<_GroupVoiceMiniBubble> {
  static const double _bubbleWidth = 64;
  static const double _bubbleHeight = 64;

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
                _buildSubtitle(widget.status),
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

  String _buildSubtitle(String value) {
    if (value == 'incoming') {
      return 'Invite you to voice call';
    }
    if (value == 'in_call') {
      return '00:08:32';
    }
    return 'Waiting...';
  }
}

class _FloatingDotSpec {
  final double size;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final Color color;

  const _FloatingDotSpec({
    required this.size,
    this.left,
    this.top,
    this.right,
    this.bottom,
    required this.color,
  });
}

class _VoiceParticipant {
  final String name;
  final bool micEnabled;
  final Color avatarColor;
  final bool isOverflow;
  final int hiddenCount;

  const _VoiceParticipant({
    required this.name,
    required this.micEnabled,
    required this.avatarColor,
    this.isOverflow = false,
    this.hiddenCount = 0,
  });
}
