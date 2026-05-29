import 'dart:async';
import 'dart:ui';

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
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';
import 'package:rongcloud_call_wrapper_plugin/wrapper/rongcloud_call_module.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

class ChatGroupVoicePage extends StatefulWidget {
  final String name;
  final String targetId;
  final String status;

  const ChatGroupVoicePage({
    super.key,
    required this.name,
    this.targetId = '',
    this.status = 'dialing',
  });

  @override
  State<ChatGroupVoicePage> createState() => _ChatGroupVoicePageState();
}

class _ChatGroupVoicePageState extends State<ChatGroupVoicePage> {
  late String _status;
  late bool _micEnabled;
  late bool _speakerEnabled;
  late RongCallState _callState;
  StreamSubscription<RongCallState>? _callSub;
  Timer? _callTimer;
  int? _callStartedAtMs;
  int _callElapsedMs = 0;
  bool _isClosing = false;
  bool _summarySent = false;

  String get name =>
      _callState.displayName.isNotEmpty ? _callState.displayName : widget.name;
  String get status => _status;
  bool get _isIncoming => _status == 'incoming';
  bool get _isInCall => _status == 'in_call';
  bool get _hasActiveCall => _callState.isActive;
  String get _callDurationText => formatDurationFromMs(_callElapsedMs);
  String _incomingDisplayName = '';
  final Set<String> _joinedParticipantUserIds = {};
  List<UserDisplayModel> _inCallParticipants = [];

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
    _speakerEnabled = true;
    _callState = RongCallManager().state;
    _syncCallState(_callState);
    _callSub = RongCallManager().stateStream.listen(_syncCallState);
    if (!_hasActiveCall && _isInCall) {
      _startStaticCallTimer();
    }
    _getGroupMembers();
  }

  Future<void> _getGroupMembers() async {
    final sessionUsers = _callState.session?.users ?? [];
    final activeUserIds = sessionUsers
        .where(_isActiveRemoteParticipant)
        .map((user) => user.userId)
        .toSet();
    if (_isInCall) {
      _joinedParticipantUserIds.addAll(activeUserIds);
    }
    final users = _isInCall
        ? sessionUsers
              .where(
                (user) => _shouldShowParticipantInStrip(user, activeUserIds),
              )
              .toList()
        : sessionUsers;
    List<UserDisplayModel> models = [];
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
        _incomingDisplayName = inviter?.name ?? '';
      }
    }
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
    _GroupVoiceMiniOverlayController.show(
      context: context,
      name: name,
      targetId: widget.targetId,
      status: status,
      connectedTimeMs: _hasActiveCall
          ? _callState.connectedTimeMs
          : (_callStartedAtMs ?? 0),
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
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h1.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                _isInCall
                    ? Text(
                        '(${_inCallParticipants.length + 1})',
                        style: AppTextStyles.h1.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      )
                    : SizedBox(),
              ],
            ),
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
    bool showMore = _inCallParticipants.length > 6;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: visibleParticipants.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 18,
          crossAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        itemBuilder: (context, index) {
          return _buildParticipantCell(
            visibleParticipants[index],
            showMore ? index == visibleParticipants.length - 1 : false,
            _inCallParticipants.length - 6,
          );
        },
      ),
    );
  }

  Widget _buildParticipantCell(
    UserDisplayModel participant,
    bool isOverflow,
    int hiddenCount,
  ) {
    return SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildParticipantAvatar(participant, isOverflow, hiddenCount),
          const SizedBox(height: 12),
          Text(
            _participantName(participant.name),
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

  String _participantName(String name) {
    if (name == '_me') {
      return AppLocalizations.currentText('moments_me');
    }
    if (name == '_others') {
      return AppLocalizations.currentText('chat_filter_others');
    }
    return name;
  }

  Widget _buildParticipantAvatar(
    UserDisplayModel participant,
    bool isOverflow,
    int hiddenCount,
  ) {
    final callUser = _callUserProfile(participant.userId);
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: SizedBox(
              width: 60,
              height: 60,
              child: isOverflow
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                          child: UserAvatarWidget(
                            userId: participant.userId,
                            avatarUrl: participant.avatar,
                            size: 60,
                          ),
                        ),
                        Container(color: Colors.black.withValues(alpha: 0.32)),
                        Center(
                          child: Text(
                            '+$hiddenCount',
                            style: AppTextStyles.h1.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    )
                  : UserAvatarWidget(
                      userId: participant.userId,
                      avatarUrl: participant.avatar,
                      size: 60,
                    ),
            ),
          ),
          if (!isOverflow)
            Positioned(
              right: -2,
              bottom: -2,
              child: Image.asset(
                callUser?.enableMicrophone ?? false
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

    return Text(
      _callDurationText,
      textAlign: TextAlign.center,
      style: baseStyle,
    );
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
        AppLocalizations.currentText('call_invite_voice'),
        textAlign: TextAlign.center,
        style: baseStyle,
      );
    }
    if (_isInCall) {
      return Text(
        _callDurationText,
        textAlign: TextAlign.center,
        style: baseStyle,
      );
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: AppLocalizations.currentText('call_waiting_group_join', {
              'name': _localUserName,
            }),
            style: baseStyle,
          ),
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
              micEnabled: _micEnabled,
              speakerEnabled: _speakerEnabled,
              onMicTap: _toggleMicrophone,
              onSpeakerTap: _toggleSpeaker,
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
              onAnswer: _answerVoiceSession,
              onHangup: () => _closeVoiceSession(context),
            )
          : _VoiceControlButtons(
              isInCall: _isInCall,
              micEnabled: _micEnabled,
              speakerEnabled: _speakerEnabled,
              onMicTap: _toggleMicrophone,
              onSpeakerTap: _toggleSpeaker,
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

  Future<void> _closeVoiceSession(BuildContext context) async {
    if (_isClosing) return;
    _isClosing = true;
    _GroupVoiceMiniOverlayController.dismiss();
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
      isVideo: false,
      durationMs: _callElapsedMs,
    );
  }

  Future<void> _answerVoiceSession() async {
    if (RongCallManager().state.isActive) {
      await RongCallManager().accept();
      return;
    }
    setState(() {
      _status = 'in_call';
    });
    _startStaticCallTimer();
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

  Future<void> _toggleSpeaker() async {
    if (RongCallManager().state.isActive) {
      await RongCallManager().toggleSpeaker();
      return;
    }
    setState(() {
      _speakerEnabled = !_speakerEnabled;
    });
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
      _GroupVoiceMiniOverlayController.dismiss();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      return;
    }

    setState(() {
      _callState = state;
      _status = _statusFromCallState(state.status);
      _micEnabled = state.micEnabled;
      _speakerEnabled = state.speakerEnabled;
    });
    _syncCallTimer(state);
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

  void _startStaticCallTimer({int? connectedTimeMs}) {
    _stopCallTimer();
    _callStartedAtMs = connectedTimeMs ?? DateTime.now().millisecondsSinceEpoch;
    _updateStaticCallElapsed();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateStaticCallElapsed();
    });
  }

  void _updateStaticCallElapsed() {
    final startedAt = _callStartedAtMs;
    final elapsed = startedAt == null
        ? 0
        : DateTime.now().millisecondsSinceEpoch - startedAt;
    if (!mounted) return;
    setState(() {
      _callElapsedMs = elapsed < 0 ? 0 : elapsed;
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

class _GroupVoiceMiniOverlayController {
  static OverlayEntry? _entry;
  static String? _name;
  static String _targetId = '';
  static String _status = 'dialing';
  static int _connectedTimeMs = 0;

  static void show({
    required BuildContext context,
    required String name,
    String targetId = '',
    required String status,
    required int connectedTimeMs,
  }) {
    dismiss();
    final overlay = Overlay.of(context, rootOverlay: true);

    _name = name;
    _targetId = targetId;
    _status = status;
    _connectedTimeMs = connectedTimeMs;
    _entry = OverlayEntry(
      builder: (overlayContext) => _GroupVoiceMiniBubble(
        name: _name ?? name,
        status: _status,
        connectedTimeMs: _connectedTimeMs,
        onTap: () {
          final encodedName = Uri.encodeComponent(_name ?? name);
          final rootContext = AppRouter.rootNavigatorKey.currentContext;
          if (rootContext == null) {
            return;
          }
          dismiss();
          final encodedTargetId = Uri.encodeQueryComponent(_targetId);
          rootContext.push(
            '/chat-group-voice/$encodedName?status=$_status&targetId=$encodedTargetId',
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

class _GroupVoiceMiniBubble extends StatefulWidget {
  final String name;
  final String status;
  final int connectedTimeMs;
  final VoidCallback onTap;

  const _GroupVoiceMiniBubble({
    required this.name,
    required this.status,
    required this.connectedTimeMs,
    required this.onTap,
  });

  @override
  State<_GroupVoiceMiniBubble> createState() => _GroupVoiceMiniBubbleState();
}

class _GroupVoiceMiniBubbleState extends State<_GroupVoiceMiniBubble> {
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
    if (!_callState.isActive && widget.status == 'in_call') {
      _updateStaticCallElapsed();
      _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateStaticCallElapsed();
      });
    }
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
    if (_callState.status == RongCallStatus.inCall ||
        widget.status == 'in_call') {
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
        _GroupVoiceMiniOverlayController.dismiss();
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
    _updateCallElapsedFromState();
    _callTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCallElapsedFromState();
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

  void _updateStaticCallElapsed() {
    final connectedTime = widget.connectedTimeMs;
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
