import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/core/models/conversation_model.dart';
import 'package:paracosm/core/models/custom_message_model.dart';
import 'package:paracosm/core/models/group_model.dart';
import 'package:paracosm/modules/im/listener/im_data_center.dart';
import 'package:paracosm/modules/im/manager/im_burn_after_reading_manager.dart';
import 'package:paracosm/modules/im/manager/im_conversation_manager.dart';
import 'package:paracosm/modules/im/manager/im_group_manager.dart';
import 'package:paracosm/modules/im/manager/im_message_manager.dart';
import 'package:paracosm/modules/im/message/base/im_message.dart';
import 'package:paracosm/modules/im/message/send/im_sender.dart';
import 'package:paracosm/pages/chat/chat_session_args.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/chat/select_members_modal.dart';
import 'package:paracosm/widgets/common/app_loading.dart';
import 'package:paracosm/widgets/common/app_modal.dart';
import 'package:paracosm/widgets/common/app_toast.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

/// 会话详情页面
/// 包含成员列表、聊天配置选项（免打扰、置顶、清除记录等）以及阅后即焚设置
class SessionDetailsPage extends StatefulWidget {
  final String name;
  final String userId;
  final ChatSessionArgs? sessionArgs;
  final String mode;

  const SessionDetailsPage({
    super.key,
    required this.name,
    this.userId = '',
    this.sessionArgs,
    this.mode = 'friend',
  });

  @override
  State<SessionDetailsPage> createState() => _SessionDetailsPageState();
}

class _SessionDetailsPageState extends State<SessionDetailsPage> {
  bool _isDoNotDisturb = false;
  bool _isSettingDoNotDisturb = false;
  bool _isPinned = false;
  bool _isSettingPinned = false;
  bool get _isFriend => widget.mode == 'friend';
  bool get _isPrivateSession =>
      widget.sessionArgs?.conversationType == RCIMIWConversationType.private;

  /// 阅后即焚当前选中的档位值 (0-5)
  double _burnAfterReadingValue =
      0.0; // 0: Close, 1: 10s, 2: 1m, 3: 5m, 4: 10m, 5: 30m
  double _savedBurnAfterReadingValue = 0.0;
  bool _isSavingBurnAfterReading = false;

  @override
  void initState() {
    super.initState();
    _loadDoNotDisturb();
    _loadTopStatus();
    _loadBurnAfterReading();
  }

  Future<void> _loadDoNotDisturb() async {
    final args = widget.sessionArgs;
    if (args == null) return;

    final level = await ImConversationManager()
        .getConversationNotificationLevel(
          type: args.conversationType,
          targetId: args.targetId,
          channelId: args.channelId,
        );
    if (!mounted || level == null) return;

    setState(() {
      _isDoNotDisturb = level == RCIMIWPushNotificationLevel.blocked;
    });
  }

  Future<void> _toggleDoNotDisturb() async {
    final args = widget.sessionArgs;
    if (args == null || _isSettingDoNotDisturb) return;

    final nextValue = !_isDoNotDisturb;
    setState(() {
      _isDoNotDisturb = nextValue;
      _isSettingDoNotDisturb = true;
    });

    final success = await ImConversationManager().setConversationDoNotDisturb(
      type: args.conversationType,
      targetId: args.targetId,
      channelId: args.channelId,
      enabled: nextValue,
    );
    if (!mounted) return;

    setState(() {
      _isSettingDoNotDisturb = false;
      if (!success) {
        _isDoNotDisturb = !nextValue;
      }
    });

    if (!success) {
      AppToast.show('设置失败');
    }
  }

  Future<void> _loadTopStatus() async {
    final args = widget.sessionArgs;
    if (args == null) return;

    final top = await ImConversationManager().getConversationTopStatus(
      type: args.conversationType,
      targetId: args.targetId,
      channelId: args.channelId,
    );
    if (!mounted || top == null) return;

    setState(() {
      _isPinned = top;
    });
  }

  Future<void> _toggleTopStatus() async {
    final args = widget.sessionArgs;
    if (args == null || _isSettingPinned) return;

    final nextValue = !_isPinned;
    setState(() {
      _isPinned = nextValue;
      _isSettingPinned = true;
    });

    final success = await ImConversationManager().setConversationTopStatus(
      type: args.conversationType,
      targetId: args.targetId,
      channelId: args.channelId,
      top: nextValue,
    );
    if (!mounted) return;

    setState(() {
      _isSettingPinned = false;
      if (!success) {
        _isPinned = !nextValue;
      }
    });

    if (!success) {
      AppToast.show('设置失败');
    }
  }

  Future<void> _loadBurnAfterReading() async {
    final args = widget.sessionArgs;
    if (args == null || !_isPrivateSession) return;

    final seconds = await ImBurnAfterReadingManager().getDurationSeconds(
      type: args.conversationType,
      targetId: args.targetId,
      channelId: args.channelId,
    );
    final index = ImBurnAfterReadingManager().indexForDuration(seconds);
    if (!mounted) return;

    setState(() {
      _burnAfterReadingValue = index.toDouble();
      _savedBurnAfterReadingValue = index.toDouble();
    });
  }

  Future<void> _saveBurnAfterReading(double value) async {
    final args = widget.sessionArgs;
    if (args == null || !_isPrivateSession || _isSavingBurnAfterReading) return;

    final index = value.round();
    final seconds = ImBurnAfterReadingManager().durationForIndex(index);

    setState(() {
      _isSavingBurnAfterReading = true;
      _burnAfterReadingValue = index.toDouble();
    });

    final success = await ImBurnAfterReadingManager().setDurationSeconds(
      type: args.conversationType,
      targetId: args.targetId,
      channelId: args.channelId,
      seconds: seconds,
    );
    if (!mounted) return;

    setState(() {
      _isSavingBurnAfterReading = false;
      if (success) {
        _savedBurnAfterReadingValue = index.toDouble();
      } else {
        _burnAfterReadingValue = _savedBurnAfterReadingValue;
      }
    });

    if (!success) {
      AppToast.show('设置失败');
    }
  }

  Future<void> _showChooseMembers() async {
    final args = widget.sessionArgs;
    if (args == null || args.targetId.isEmpty) return;

    final result = await SelectMembersModal.show(
      context,
      friends: ImDataCenter().friends,
      confirmText: AppLocalizations.of(context)!.commonDone,
      defaultSelectedUserIds: [args.targetId],
      minSelectedCount: 3,
    );
    if (result == null || result.isEmpty) return;

    final userIds = [...result, args.targetId];
    await _createGroupAndNavigate(userIds);
  }

  Future<void> _createGroupAndNavigate(List<String> userIds) async {
    AppLoading.show();

    try {
      final groupId = await ImGroupManager().create(
        inviteeUserIds: userIds,
        groupId: generateGroupId(GroupType.normal),
      );

      if (groupId == null) {
        AppToast.show('创建群组失败');
        return;
      }

      final message = CustomMessage(
        targetId: groupId,
        customMessageType: CustomMessageType.groupInvited,
        conversationType: RCIMIWConversationType.group,
        userIds: userIds,
      );
      final isSend = await ImSender.instance.send(message: message);
      if (!isSend) return;

      final conversation = await ImConversationManager().getConversation(
        type: RCIMIWConversationType.group,
        targetId: groupId,
      );
      if (conversation == null) return;

      final model = ConversationModel(info: conversation);
      await ConversationResolver().resolve(model);

      if (!mounted) return;

      final title = model.title ?? '';
      context.pushReplacement(
        '/chat-detail/${Uri.encodeComponent(title)}',
        extra: ChatSessionArgs(
          targetId: groupId,
          conversationType: RCIMIWConversationType.group,
          name: title,
          channelId: conversation.channelId,
          isGroup: true,
          avatar: model.portraitUri,
        ),
      );
    } catch (e) {
      AppToast.show('创建群组失败');
    } finally {
      AppLoading.dismiss();
    }
  }

  Future<void> _clearHistory() async {
    final args = widget.sessionArgs;
    if (args == null) return;

    Navigator.pop(context);

    final isOk = await ImMessageManager().clearMessages(
      type: args.conversationType,
      targetId: args.targetId,
      channelId: args.channelId,
      timestamp: 0,
    );

    if (isOk) {
      AppToast.show('已清空聊天记录');
    } else {
      AppToast.show('清空聊天记录失败');
    }
  }

  /// 显示清空记录确认弹窗
  void _showClearHistoryModal() {
    AppModal.show(
      context,
      title: AppLocalizations.of(context)!.commonRiskTips,
      description: AppLocalizations.of(context)!.chatSettingClearConfirm,
      confirmText: AppLocalizations.of(context)!.commonConfirm,
      cancelText: AppLocalizations.of(context)!.commonCancel,
      confirmWidth: 161,
      cancelWidth: 161,
      cancelBorder: const BorderSide(color: AppColors.grey300),
      icon: Image.asset(
        'assets/images/wallet/bell-icon.png',
        width: 120,
        height: 120,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            color: AppColors.grey100,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.notifications_active_outlined,
            size: 64,
            color: AppColors.warning,
          ),
        ),
      ),
      onConfirm: _clearHistory,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: AppLocalizations.of(context)!.sessionDetailsTitle,
      backgroundColor: Colors.white,
      showNavBorder: true,
      child: ListView(
        children: [
          _buildMemberGrid(),
          _buildOptionItem(
            AppLocalizations.of(context)!.chatSettingSearchHistory,
            onTap: _navigateToHistorySearch,
          ),
          _buildOptionItem(
            AppLocalizations.of(context)!.chatSettingMessageDoNotDisturb,
            isFullBorder: false,
            trailing: GestureDetector(
              onTap: widget.sessionArgs == null ? null : _toggleDoNotDisturb,
              child: Image.asset(
                _isDoNotDisturb
                    ? 'assets/images/common/switch-active.png'
                    : 'assets/images/common/switch-default.png',
                width: 52,
                height: 28,
              ),
            ),
          ),
          if (_isFriend)
            _buildOptionItem(
              AppLocalizations.of(context)!.chatSettingPin,
              isFullBorder: true,
              trailing: GestureDetector(
                onTap: widget.sessionArgs == null ? null : _toggleTopStatus,
                child: Image.asset(
                  _isPinned
                      ? 'assets/images/common/switch-active.png'
                      : 'assets/images/common/switch-default.png',
                  width: 52,
                  height: 28,
                ),
              ),
            ),
          Container(
            height: 10,
            decoration: const BoxDecoration(color: AppColors.grey100),
          ),
          _buildOptionItem(
            AppLocalizations.of(context)!.chatSettingClearHistory,
            isFullBorder: true,
            onTap: _showClearHistoryModal,
          ),
          Container(
            height: 10,
            decoration: const BoxDecoration(color: AppColors.grey100),
          ),
          _buildOptionItem(
            AppLocalizations.of(context)!.sessionDetailsReport,
            isFullBorder: true,
            onTap: () {},
          ),
          if (_isPrivateSession) ...[
            Container(
              height: 10,
              decoration: const BoxDecoration(color: AppColors.grey100),
            ),
            _buildBurnAfterReading(),
          ],
        ],
      ),
    );
  }

  /// 构建成员网格列表
  Widget _buildMemberGrid() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Wrap(
        spacing: 28,
        runSpacing: 12,
        children: [
          _buildMemberItem(widget.name, 'assets/images/chat/avatar.png'),
          _buildAddButton(),
        ],
      ),
    );
  }

  /// 构建单个成员项
  Widget _buildMemberItem(String name, String avatarPath) {
    return GestureDetector(
      onTap: () {
        if (widget.userId.isEmpty) return;
        context.push('/user-profile', extra: widget.userId);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: AssetImage(avatarPath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name.length > 5 ? '${name.substring(0, 4)}..' : name,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.grey900,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToHistorySearch() {
    if (widget.sessionArgs == null) return;
    context.push('/chat-history-search', extra: widget.sessionArgs);
  }

  /// 构建添加成员按钮
  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _showChooseMembers,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/common/add-member.png',
            width: 44,
            height: 44,
            color: AppColors.grey900,
          ),
          const SizedBox(height: 4),
          const Text('', style: TextStyle(fontSize: 14)), // 占位保持对齐
        ],
      ),
    );
  }

  /// 通用选项行构建方法
  Widget _buildOptionItem(
    String title, {
    Widget? trailing,
    VoidCallback? onTap,
    bool isFullBorder = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        color: Colors.white,
        child: Stack(
          children: [
            // 底部边框
            Positioned(
              left: isFullBorder ? 0 : 20,
              right: isFullBorder ? 0 : 20,
              bottom: 0,
              child: Container(height: 0.5, color: AppColors.grey200),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.grey900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    trailing ??
                        Image.asset(
                          'assets/images/common/next.png',
                          width: 20,
                          height: 20,
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建阅后即焚设置区块
  Widget _buildBurnAfterReading() {
    final labels = [
      AppLocalizations.of(context)!.sessionDetailsBurnClose,
      AppLocalizations.of(context)!.sessionDetailsBurn10s,
      AppLocalizations.of(context)!.sessionDetailsBurn1m,
      AppLocalizations.of(context)!.sessionDetailsBurn5m,
      AppLocalizations.of(context)!.sessionDetailsBurn10m,
      AppLocalizations.of(context)!.sessionDetailsBurn30m,
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.sessionDetailsBurnTitle,
            style: AppTextStyles.body.copyWith(
              color: AppColors.grey900,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              // 滑动条 (放在底层)
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.grey200,
                  thumbColor: Colors.white,
                  overlayColor: AppColors.primary.withAlpha(32),
                  thumbShape: const CustomSliderThumbShape(),
                  trackShape: const CustomTrackShape(),
                  tickMarkShape: SliderTickMarkShape.noTickMark,
                ),
                child: Slider(
                  value: _burnAfterReadingValue,
                  min: 0,
                  max: 5,
                  divisions: 5,
                  onChanged: (value) {
                    setState(() {
                      _burnAfterReadingValue = value.roundToDouble();
                    });
                  },
                  onChangeEnd: _saveBurnAfterReading,
                ),
              ),
              // 轨道上的刻度点 (放在顶层以确保可见，同时使用 IgnorePointer 避免干扰 Slider 点击)
              IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(labels.length, (index) {
                      // 当前选中的项留空，由 Slider 的 Thumb 覆盖，以显示 Thumb 的白色中心
                      // 同时保持 index == 0 的项不显示（即“关闭”位置不显示绿色圆点，仅显示滑块）
                      if (index == 0 ||
                          index == _burnAfterReadingValue.toInt()) {
                        return const SizedBox(width: 0);
                      }
                      final isReached = index <= _burnAfterReadingValue.toInt();
                      return SizedBox(
                        width: 0,
                        child: UnconstrainedBox(
                          clipBehavior: Clip.none,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: isReached
                                  ? AppColors.primary
                                  : AppColors.grey200,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: labels.asMap().entries.map((entry) {
                final index = entry.key;
                final label = entry.value;
                final isSelected = index == _burnAfterReadingValue.toInt();
                return SizedBox(
                  width: 0,
                  child: UnconstrainedBox(
                    clipBehavior: Clip.none,
                    child: Text(
                      label,
                      style: AppTextStyles.caption.copyWith(
                        color: isSelected
                            ? AppColors.grey900
                            : AppColors.grey400,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                      softWrap: false,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomSliderThumbShape extends SliderComponentShape {
  const CustomSliderThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(16, 16);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    final paint = Paint()
      ..color = sliderTheme.activeTrackColor ?? AppColors.primary
      ..style = PaintingStyle.fill;

    // 外圈尺寸 16 (半径 8)
    canvas.drawCircle(center, 8, paint);

    // 内圈白色尺寸 10 (半径 5)
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5, whitePaint);
  }
}

class CustomTrackShape extends RoundedRectSliderTrackShape {
  const CustomTrackShape();
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight!;
    final double trackLeft = offset.dx + 12;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width - 24;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}

class DottedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.grey300
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path();
    const radius = 12.0;
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(radius),
      ),
    );

    final dashPath = Path();
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    var distance = 0.0;
    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
