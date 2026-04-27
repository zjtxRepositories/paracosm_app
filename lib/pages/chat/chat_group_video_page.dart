import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/router/app_router.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';

class ChatGroupVideoPage extends StatefulWidget {
  final String name;
  final String status;
  final bool cameraEnabled;

  const ChatGroupVideoPage({
    super.key,
    required this.name,
    this.status = 'dialing',
    this.cameraEnabled = true,
  });

  @override
  State<ChatGroupVideoPage> createState() => _ChatGroupVideoPageState();
}

class _ChatGroupVideoPageState extends State<ChatGroupVideoPage> {
  static const String _incomingDisplayName = 'Kristen';
  static const String _localUserName = 'Wei Wei';

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
    _cameraEnabled = widget.cameraEnabled && !_isIncoming;
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
        onTap: () {
          _GroupVideoMiniOverlayController.show(
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

  Widget _buildIncomingCenterContent() {
    return Align(
      alignment: const Alignment(0, -0.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildGroupAvatarGrid(),
          const SizedBox(height: 32),
          Text(
            '$name(20)',
            style: AppTextStyles.h1.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          _buildIncomingSubtitle(),
        ],
      ),
    );
  }

  Widget _buildGroupAvatarGrid() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Image.asset(
                'assets/images/chat/avatar.png',
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
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
            text: 'Invite you to a multiplayer session...',
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
        ? '00:08:32'
        : 'Waiting for $_localUserName and others to join...';
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
          width: 116,
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

    final participants = <_ParticipantCard>[
      _ParticipantCard(name: 'Padraic'),
      _ParticipantCard(name: 'Wilson'),
      _ParticipantCard(name: 'Kristen'),
      _ParticipantCard(name: 'Howard'),
      _ParticipantCard(name: 'Howard'),
      _ParticipantCard(name: 'Howard'),
    ];

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
            itemCount: participants.length,
            itemBuilder: (context, index) {
              final participant = participants[index];
              return _GroupParticipantTile(
                key: ValueKey(participant.name),
                participant: participant,
                isInCall: _isInCall,
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
            onTap: () {
              setState(() {
                _status = 'in_call';
                _cameraEnabled = true;
              });
            },
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
            onTap: () {},
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

  void _closeVideoSession(BuildContext context) {
    _GroupVideoMiniOverlayController.dismiss();
    Navigator.of(context).maybePop();
  }
}

class _ParticipantCard {
  final String name;

  const _ParticipantCard({required this.name});
}

class _GroupParticipantTile extends StatefulWidget {
  final _ParticipantCard participant;
  final bool isInCall;

  const _GroupParticipantTile({
    super.key,
    required this.participant,
    required this.isInCall,
  });

  @override
  State<_GroupParticipantTile> createState() => _GroupParticipantTileState();
}

class _GroupParticipantTileState extends State<_GroupParticipantTile> {
  static const Color _avatarBaseColor = Color(0xFFB6B0FF);
  late bool _micEnabled;

  @override
  void initState() {
    super.initState();
    _micEnabled = true;
  }

  void _toggleMic() {
    setState(() {
      _micEnabled = !_micEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: _avatarBaseColor,
                  child: Image.asset(
                    'assets/images/chat/avatar.png',
                    fit: BoxFit.cover,
                  ),
                ),
                if (!widget.isInCall)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.40),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ParticipantDot(),
                          SizedBox(width: 8),
                          _ParticipantDot(),
                          SizedBox(width: 8),
                          _ParticipantDot(),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (widget.isInCall)
            Positioned(
              left: 6,
              top: 6,
              child: GestureDetector(
                onTap: _toggleMic,
                child: Image.asset(
                  _micEnabled
                      ? 'assets/images/chat/call/mic-active.png'
                      : 'assets/images/chat/call/mic-close.png',
                  width: 16,
                  height: 16,
                ),
              ),
            ),
          Positioned(
            left: 6,
            right: 6,
            bottom: 4,
            child: Text(
              widget.participant.name,
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
}

class _ParticipantDot extends StatelessWidget {
  const _ParticipantDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.grey200,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _GroupVideoMiniOverlayController {
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
      builder: (overlayContext) => _GroupVideoMiniBubble(
        onTap: () {
          final encodedName = Uri.encodeComponent(_name ?? name);
          final rootContext = AppRouter.rootNavigatorKey.currentContext;
          if (rootContext == null) {
            return;
          }
          dismiss();
          rootContext.push(
            '/chat-group-video/$encodedName?status=$_status&camera=${_cameraEnabled ? 'on' : 'off'}',
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
