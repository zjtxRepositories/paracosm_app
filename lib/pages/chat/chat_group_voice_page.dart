import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/core/models/user_display_model.dart';
import 'package:paracosm/modules/call/rong_group_call_status_message.dart';
import 'package:paracosm/modules/call/rong_call_manager.dart';
import 'package:paracosm/modules/im/listener/group_state_center.dart';
import 'package:paracosm/modules/im/manager/im_engine_manager.dart';
import 'package:paracosm/modules/im/listener/user_display_state_center.dart';
import 'package:paracosm/router/app_router.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/util/string_util.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/chat/select_members_modal.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';
import 'package:paracosm/widgets/common/app_toast.dart';
import 'package:rongcloud_call_wrapper_plugin/wrapper/rongcloud_call_module.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../core/models/group_member_model.dart';

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
  static const Duration _participantAnswerTimeout = Duration(seconds: 60);

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
  bool _isJoiningGroupCall = false;

  String get name =>
      _callState.displayName.isNotEmpty ? _callState.displayName : widget.name;
  String get status => _status;
  bool get _isIncoming => _status == 'incoming';
  bool get _isInCall => _status == 'in_call';
  bool get _isJoin => _status == 'join';
  bool get _hasActiveCall => _callState.isActive;
  bool get _isUninvitedJoinPreview {
    if (!_isJoin) return false;
    final currentUserId = IMEngineManager().currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) return false;
    final status = RongGroupCallStatusCenter().statusFor(_groupId);
    if (status == null || !status.isActive) return false;
    return !status.activeUserIds.contains(currentUserId) &&
        !status.invitedUserIds.contains(currentUserId);
  }

  bool get _canInviteMembers => !_isIncoming && !_isUninvitedJoinPreview;
  int get _uninvitedPreviewMemberCount {
    final count = RongGroupCallStatusCenter()
        .statusFor(_groupId)
        ?.activeUserIds
        .toSet()
        .length;
    return count == null || count <= 0 ? 1 : count;
  }

  String get _callDurationText => formatDurationFromMs(_callElapsedMs);
  String _incomingDisplayName = '';
  final Set<String> _joinedParticipantUserIds = {};
  final Set<String> _activeRemoteParticipantUserIds = {};
  final Set<String> _timedOutParticipantUserIds = {};
  final Map<String, Timer> _participantAnswerTimers = {};
  List<GroupMemberModel> _inCallParticipants = [];

  String get _localUserName {
    if (_inCallParticipants.length > 1) {
      final user = _inCallParticipants[1];
      return user.name;
    }
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
    _activeRemoteParticipantUserIds.addAll(_activeRemoteUserIds(_callState));
    _syncCallState(_callState);
    _callSub = RongCallManager().stateStream.listen(_syncCallState);
    if (!_hasActiveCall && _isInCall) {
      _startStaticCallTimer();
    }
    _getGroupMembers();
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
    _syncParticipantAnswerTimers(sessionUsers, activeUserIds);
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
    List<GroupMemberModel> models = [];
    final members = await GroupStateCenter().getGroupMembers(
      _callState.targetId,
    );
    for (final user in users) {
      final member = members.firstWhere((item) => item.userId == user.userId);
      models.add(GroupMemberModel(item: member));
    }
    final mine = _isUninvitedJoinPreview
        ? null
        : await _localParticipantModel();
    if (mine != null) {
      models = [
        mine,
        ...models.where((model) => model.item.userId != mine.item.userId),
      ];
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

  Future<GroupMemberModel?> _localParticipantModel() async {
    final currentUserId = IMEngineManager().currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) return null;
    final currentUser = UserDisplayStateCenter().getDisplayModel(currentUserId);
    return GroupMemberModel(
      item: RCIMIWGroupMemberInfo.fromJson({
        'userId': currentUserId,
        'nickname': currentUser.name,
        'portraitUri': currentUser.avatar,
      }),
    );
  }

  List<RCCallUserProfile> _callUsersWithInvitedPlaceholders() {
    final users = [...?_callState.session?.users];
    final existingUserIds = users.map((user) => user.userId).toSet();
    final currentUserId =
        _callState.session?.mine.userId ?? IMEngineManager().currentUserId;
    final status = RongGroupCallStatusCenter().statusFor(_groupId);
    if (_isUninvitedJoinPreview) {
      final initiatorUserId = status?.initiatorUserId ?? '';
      if (initiatorUserId.isEmpty) return const [];
      final existingInitiator = users
          .where((user) => user.userId == initiatorUserId)
          .toList(growable: false);
      if (existingInitiator.isNotEmpty) return existingInitiator;
      return [
        RCCallUserProfile.fromJson({
          'userType': 0,
          'mediaType': (status?.mediaType ?? _callState.mediaType).index,
          'userId': initiatorUserId,
          'mediaId': status?.activeUserIds.contains(initiatorUserId) == true
              ? initiatorUserId
              : '',
          'enableCamera': false,
          'enableMicrophone': false,
        }),
      ];
    }

    final statusActiveUserIds = _isJoin
        ? (status?.activeUserIds ?? const <String>[])
        : const <String>[];
    final statusInvitedUserIds = _isJoin
        ? (status?.invitedUserIds ?? const <String>[])
        : const <String>[];

    for (final userId in [
      ...statusActiveUserIds,
      ..._callState.invitedUserIds,
      ...statusInvitedUserIds,
    ]) {
      if (userId.isEmpty ||
          userId == currentUserId ||
          existingUserIds.contains(userId)) {
        continue;
      }
      existingUserIds.add(userId);
      users.add(
        RCCallUserProfile.fromJson({
          'userType': 0,
          'mediaType': _callState.mediaType.index,
          'userId': userId,
          'mediaId': statusActiveUserIds.contains(userId) ? userId : '',
          'enableCamera': false,
          'enableMicrophone': false,
        }),
      );
    }
    return users;
  }

  bool _isActiveRemoteParticipant(RCCallUserProfile user) {
    final localUserId =
        _callState.session?.mine.userId ?? IMEngineManager().currentUserId;
    return user.userId.isNotEmpty &&
        user.userId != localUserId &&
        (user.mediaId?.isNotEmpty ?? false);
  }

  Set<String> _activeRemoteUserIds(RongCallState state) {
    final localUserId =
        state.session?.mine.userId ?? IMEngineManager().currentUserId;
    return (state.session?.users ?? const <RCCallUserProfile>[])
        .where(
          (user) =>
              user.userId.isNotEmpty &&
              user.userId != localUserId &&
              (user.mediaId?.isNotEmpty ?? false),
        )
        .map((user) => user.userId)
        .toSet();
  }

  void _syncParticipantChangeToasts(RongCallState state) {
    final nextActiveUserIds = _activeRemoteUserIds(state);
    final shouldNotify =
        _status == 'in_call' && state.status == RongCallStatus.inCall;
    if (shouldNotify) {
      final joinedUserIds = nextActiveUserIds
          .where((userId) => !_activeRemoteParticipantUserIds.contains(userId))
          .toList(growable: false);
      final leftUserIds = _activeRemoteParticipantUserIds
          .where((userId) => !nextActiveUserIds.contains(userId))
          .toList(growable: false);
      for (final userId in joinedUserIds) {
        unawaited(_showParticipantChangeToast(userId, joined: true));
      }
      for (final userId in leftUserIds) {
        unawaited(_showParticipantChangeToast(userId, joined: false));
      }
    }
    _activeRemoteParticipantUserIds
      ..clear()
      ..addAll(nextActiveUserIds);
  }

  Future<void> _showParticipantChangeToast(
    String userId, {
    required bool joined,
  }) async {
    final user = await UserDisplayStateCenter().getUser(userId);
    if (!mounted) return;
    final name = user?.name.trim().isNotEmpty == true ? user!.name : userId;
    AppToast.show(
      AppLocalizations.currentText(
        joined ? 'call_group_voice_joined' : 'call_group_voice_left',
        {'name': name},
      ),
    );
  }

  bool _shouldShowParticipantInStrip(
    RCCallUserProfile user,
    Set<String> activeUserIds,
  ) {
    if (user.userId.isEmpty || user.userId == _callState.session?.mine.userId) {
      return false;
    }
    if (activeUserIds.contains(user.userId)) return true;
    if (_timedOutParticipantUserIds.contains(user.userId)) return false;
    return !_joinedParticipantUserIds.contains(user.userId);
  }

  void _syncParticipantAnswerTimers(
    List<RCCallUserProfile> users,
    Set<String> activeUserIds,
  ) {
    if (_isIncoming) return;

    final waitingUserIds = <String>{};
    for (final user in users) {
      if (user.userId.isEmpty ||
          user.userId == _callState.session?.mine.userId) {
        continue;
      }
      if (activeUserIds.contains(user.userId)) {
        _timedOutParticipantUserIds.remove(user.userId);
        _participantAnswerTimers.remove(user.userId)?.cancel();
        continue;
      }
      if (_timedOutParticipantUserIds.contains(user.userId)) continue;
      waitingUserIds.add(user.userId);
      _participantAnswerTimers[user.userId] ??= Timer(
        _participantAnswerTimeout,
        () => _timeoutParticipant(user.userId),
      );
    }

    final staleUserIds = _participantAnswerTimers.keys
        .where((userId) => !waitingUserIds.contains(userId))
        .toList();
    for (final userId in staleUserIds) {
      _participantAnswerTimers.remove(userId)?.cancel();
    }
  }

  void _timeoutParticipant(String userId) {
    _participantAnswerTimers.remove(userId);
    if (!mounted) return;
    setState(() {
      _timedOutParticipantUserIds.add(userId);
    });
    unawaited(_getGroupMembers());
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

  String get _groupId =>
      widget.targetId.isNotEmpty ? widget.targetId : _callState.targetId;

  @override
  void dispose() {
    _stopCallTimer();
    for (final timer in _participantAnswerTimers.values) {
      timer.cancel();
    }
    _participantAnswerTimers.clear();
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
          // if (_canInviteMembers) _buildAddMemberButton(context),
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
    if (_isUninvitedJoinPreview) {
      return Positioned(
        left: 20,
        top: topPadding,
        child: GestureDetector(
          onTap: () {
            if (context.canPop()) context.pop();
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
        ),
      );
    }

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

  Widget _buildAddMemberButton(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + 12;
    return Positioned(
      right: 20,
      top: topPadding,
      child: GestureDetector(
        onTap: _showAddMemberSheet,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: const Icon(
            Icons.person_add_alt_1_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Future<void> _showAddMemberSheet() async {
    if (!_canInviteMembers) return;
    if (_isJoin && !RongCallManager().state.isActive) {
      await _joinVoiceSession();
      if (!mounted || _isJoin) return;
    }

    final candidates = await _availableInviteMembers();
    if (!mounted) return;
    if (candidates.isEmpty) {
      AppToast.show(AppLocalizations.currentText('chat_invite_failed'));
      return;
    }

    final selected = await SelectMembersModal.show(
      context,
      friends: candidates,
      confirmText: AppLocalizations.of(context)!.commonDone,
      showSelectedCount: true,
    );
    if (selected == null || selected.isEmpty) return;

    final success = await RongCallManager().inviteGroupCallMembers(selected);
    if (!success || !mounted) return;
    await _getGroupMembers();
  }

  Future<List<RCIMIWFriendInfo>> _availableInviteMembers() async {
    final groupId = _groupId;
    final currentUserId = IMEngineManager().currentUserId;
    final status = RongGroupCallStatusCenter().statusFor(groupId);
    final sessionUsers =
        _callState.session?.users ?? const <RCCallUserProfile>[];
    final joinedUserIds = {
      currentUserId,
      ...?status?.activeUserIds,
      ...sessionUsers
          .where(_isActiveRemoteParticipant)
          .map((user) => user.userId),
    };
    final waitingUserIds = {
      ...sessionUsers
          .where(
            (user) =>
                user.userId.isNotEmpty &&
                user.userId != currentUserId &&
                !joinedUserIds.contains(user.userId) &&
                !_joinedParticipantUserIds.contains(user.userId) &&
                !_timedOutParticipantUserIds.contains(user.userId),
          )
          .map((user) => user.userId),
    };
    final members = await GroupStateCenter().getGroupMembers(groupId);

    return members
        .where((member) {
          final userId = member.userId ?? '';
          return userId.isNotEmpty &&
              !joinedUserIds.contains(userId) &&
              !waitingUserIds.contains(userId);
        })
        .map(
          (member) => RCIMIWFriendInfo.create(
            userId: member.userId,
            name: member.nickname?.isNotEmpty == true
                ? member.nickname
                : member.name,
            portrait: member.portraitUri,
          ),
        )
        .toList();
  }

  Future<bool> _minimizeCallBeforeBack() async {
    if (_isUninvitedJoinPreview) return true;
    _showMiniOverlay(context);
    return true;
  }

  void _minimizeCall(BuildContext context) {
    if (_isUninvitedJoinPreview) {
      if (context.canPop()) context.pop();
      return;
    }
    _showMiniOverlay(context);
    if (context.canPop()) {
      context.pop();
    }
  }

  void _showMiniOverlay(BuildContext context) {
    _GroupVoiceMiniOverlayController.show(
      context: context,
      name: name,
      targetId: _groupId,
      status: status,
      connectedTimeMs: _hasActiveCall
          ? _callState.connectedTimeMs
          : (_callStartedAtMs ?? 0),
    );
  }

  Widget _buildCenterContent() {
    print(
      '_buildCenterContent '
      'status=$_status '
      'isIncoming=$_isIncoming '
      'isInCall=$_isInCall '
      'isJoin=$_isJoin '
      'count=${_inCallParticipants.length}',
    );
    if (_isUninvitedJoinPreview) {
      return _buildUninvitedJoinPreviewMembers();
    }
    if (_isInCall || _isJoin) {
      return _buildInCallParticipants();
    }
    if (!_isIncoming && _inCallParticipants.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInCallParticipants(),
          const SizedBox(height: 18),
          _buildSubtitleWidget(),
        ],
      );
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

  Widget _buildUninvitedJoinPreviewMembers() {
    final participant = _inCallParticipants.firstOrNull;
    if (participant == null) return const SizedBox.shrink();

    return Transform.translate(
      offset: const Offset(0, -28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '通话成员($_uninvitedPreviewMemberCount人)',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          _buildParticipantCell(participant, false, 0),
        ],
      ),
    );
  }

  Widget _buildInCallParticipants() {
    final visibleParticipants = _inCallParticipants
        .take(6)
        .toList(growable: false);
    bool showMore = _inCallParticipants.length > 6;

    if (_isUninvitedJoinPreview && visibleParticipants.length == 1) {
      return Center(
        child: _buildParticipantCell(visibleParticipants.first, false, 0),
      );
    }

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
          final isOverflow =
              showMore && index == visibleParticipants.length - 1;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isOverflow ? _showParticipantsSheet : null,
            child: _buildParticipantCell(
              visibleParticipants[index],
              isOverflow,
              _inCallParticipants.length - 6,
            ),
          );
        },
      ),
    );
  }

  Widget _buildParticipantCell(
    GroupMemberModel participant,
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
    GroupMemberModel participant,
    bool isOverflow,
    int hiddenCount,
  ) {
    final userId = participant.item.userId ?? '';
    final callUser = _callUserProfile(userId);
    final isLocalUser = userId == IMEngineManager().currentUserId;
    final isConnected =
        isLocalUser ||
        (callUser != null && _isActiveRemoteParticipant(callUser));
    final micState = _participantMicState(
      userId: userId,
      callUser: callUser,
      isLocalUser: isLocalUser,
      isConnected: isConnected,
    );
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
                            userId: userId,
                            avatarUrl: participant.item.portraitUri,
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
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        UserAvatarWidget(
                          userId: userId,
                          avatarUrl: participant.item.portraitUri,
                          size: 60,
                        ),
                        if (!isConnected)
                          Container(
                            color: Colors.black.withValues(alpha: 0.48),
                          ),
                      ],
                    ),
            ),
          ),
          if (!isOverflow && micState.shouldShow)
            Positioned(
              right: -2,
              bottom: -2,
              child: Image.asset(
                micState.isSpeaking
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

  _ParticipantMicState _participantMicState({
    required String userId,
    required RCCallUserProfile? callUser,
    required bool isLocalUser,
    required bool isConnected,
  }) {
    if (!isConnected) return const _ParticipantMicState.hidden();

    final isMuted = isLocalUser
        ? !_micEnabled
        : !(callUser?.enableMicrophone ?? false);
    final isSpeaking = !isMuted && _callState.speakingUserIds.contains(userId);

    return _ParticipantMicState(
      isMuted: isMuted,
      isSpeaking: isSpeaking,
      shouldShow: isMuted || isSpeaking,
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
      final groupName = name.trim();
      return Text(
        groupName.isEmpty
            ? AppLocalizations.currentText('call_invite_group_voice')
            : AppLocalizations.currentText('call_invite_named_group_voice', {
                'name': _compactIncomingGroupName(groupName),
              }),
        textAlign: TextAlign.center,
        style: baseStyle.copyWith(color: AppColors.grey300),
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

  String _compactIncomingGroupName(String value) {
    const maxLength = 10;
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength)}...';
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
          : _isJoin
          ? _buildJoinControls(onJoin: _joinVoiceSession)
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

  Widget _buildJoinControls({required VoidCallback onJoin}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onJoin,
      child: Container(
        width: double.infinity,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFBDD100),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          AppLocalizations.currentText('call_join_now'),
          style: AppTextStyles.body.copyWith(
            color: AppColors.grey900,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
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
    print('_answerVoiceSession-----');
    final callState = RongCallManager().state;
    if (callState.isActive && callState.session != null) {
      print('_answerVoiceSession-----1');

      await RongCallManager().accept();
      return;
    }
    if (_isIncoming || _isJoin) {
      print('_answerVoiceSession-----2');

      await _joinVoiceSession();
      return;
    }
    print('_answerVoiceSession-----3');

    setState(() {
      _status = 'in_call';
    });
    _startStaticCallTimer();
  }

  Future<void> _joinVoiceSession() async {
    if (_isJoiningGroupCall) return;
    final status = RongGroupCallStatusCenter().statusFor(_groupId);
    if (status == null || !status.isActive) {
      AppToast.show(AppLocalizations.currentText('call_ended'));
      if (mounted) Navigator.of(context).maybePop();
      return;
    }
    setState(() {
      _isJoiningGroupCall = true;
    });
    final requested = await RongCallManager().requestJoinActiveGroupCall(
      status,
    );
    print('_answerVoiceSession-----3--$requested');

    if (!mounted) return;
    if (!requested) {
      setState(() {
        _isJoiningGroupCall = false;
      });
      return;
    }
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
    if (_isJoin && !state.isActive) {
      return;
    }
    if (state.status == RongCallStatus.idle) {
      _stopCallTimer();
      _activeRemoteParticipantUserIds.clear();
      return;
    }
    if (state.status == RongCallStatus.ended ||
        state.status == RongCallStatus.error) {
      _stopCallTimer();
      _activeRemoteParticipantUserIds.clear();
      if (_isClosing) return;
      _isClosing = true;
      _GroupVoiceMiniOverlayController.dismiss();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      return;
    }

    _syncParticipantChangeToasts(state);
    if (_isJoin &&
        _isJoiningGroupCall &&
        state.status != RongCallStatus.inCall) {
      setState(() {
        _callState = state;
        _micEnabled = state.micEnabled;
        _speakerEnabled = state.speakerEnabled;
      });
      return;
    }
    setState(() {
      _callState = state;
      _status = _statusFromCallState(state.status);
      if (state.status == RongCallStatus.inCall) {
        _isJoiningGroupCall = false;
      }
      _micEnabled = state.micEnabled;
      _speakerEnabled = state.speakerEnabled;
    });
    _syncCallTimer(state);
    unawaited(_getGroupMembers());
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

  void _showParticipantsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '通话成员(${_inCallParticipants.length})',
                style: AppTextStyles.h2.copyWith(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _inCallParticipants.length,
                  itemBuilder: (context, index) {
                    final item = _inCallParticipants[index];

                    return ListTile(
                      leading: UserAvatarWidget(
                        userId: item.item.userId,
                        avatarUrl: item.item.portraitUri,
                        size: 40,
                      ),
                      title: Text(
                        _participantName(item.name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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

class _ParticipantMicState {
  const _ParticipantMicState({
    required this.isMuted,
    required this.isSpeaking,
    required this.shouldShow,
  });

  const _ParticipantMicState.hidden()
    : isMuted = false,
      isSpeaking = false,
      shouldShow = false;

  final bool isMuted;
  final bool isSpeaking;
  final bool shouldShow;
}
