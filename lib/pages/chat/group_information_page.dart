import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/modules/im/manager/im_engine_manager.dart';
import 'package:paracosm/pages/chat/chat_session_args.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/chat/group_avatar_widget.dart';
import 'package:paracosm/widgets/common/app_button.dart';
import 'package:paracosm/widgets/common/app_loading.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../core/models/custom_message_model.dart';
import '../../core/models/group_model.dart';
import '../../modules/im/listener/group_state_center.dart';
import '../../modules/im/manager/im_group_manager.dart';
import '../../modules/im/message/base/im_message.dart';
import '../../modules/im/message/send/im_sender.dart';
import '../../widgets/common/app_toast.dart';

/// 群组信息页面
class GroupInformationPage extends StatefulWidget {
  final GroupModel group;
  final bool isJoined;
  final List<RCIMIWGroupMemberInfo> qrMembers;

  const GroupInformationPage({
    super.key,
    required this.group,
    this.isJoined = true,
    this.qrMembers = const [],
  });

  @override
  State<GroupInformationPage> createState() => _GroupInformationPageState();
}

class _GroupInformationPageState extends State<GroupInformationPage> {
  late TextEditingController _nameController;
  late TextEditingController _noteController;

  late GroupModel _group;
  String _groupName = '';
  late bool _isJoined;
  late List<RCIMIWGroupMemberInfo> _qrMembers;

  /// 是否群管理员/群主
  bool get _isManager =>
      _isJoined &&
      (_group.info.role == RCIMIWGroupMemberRole.manager ||
          _group.info.role == RCIMIWGroupMemberRole.owner);

  @override
  void initState() {
    super.initState();

    _group = widget.group;
    _isJoined = widget.isJoined;
    _qrMembers = widget.qrMembers;

    _nameController = TextEditingController(text: widget.group.displayName);

    _noteController = TextEditingController(text: widget.group.info.notice);

    getGroup();
  }

  Future<void> getGroup() async {
    final groupId = widget.group.info.groupId ?? '';

    final group = await GroupStateCenter().getGroup(
      groupId,
      forceRefresh: true,
    );
    if (_isJoined) {
      await GroupStateCenter().getGroupMembers(groupId, forceRefresh: true);
    }

    if (group != null) {
      _group = GroupModel(info: group);
    }
    if (_isManager) {
      _nameController.text = _group.displayName ?? '';

      _noteController.text = _group.info.notice ?? '';
    } else if (!_isJoined) {
      _groupName = _group.displayName ?? _group.info.groupName ?? '';
      if (_groupName.isEmpty || _groupName == '[默认]') {
        _groupName = _qrMemberNames();
      }
    } else {
      _groupName = await _group.name;
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> joinGroup() async {
    final groupId = _group.info.groupId ?? '';
    if (groupId.isEmpty) return;
    final joinFailedText = AppLocalizations.of(context)!.scanGroupJoinFailed;

    AppLoading.show();
    final isOk = await ImGroupManager().joinGroup(groupId);
    AppLoading.dismiss();

    if (!mounted) return;

    if (!isOk) {
      AppToast.show(joinFailedText);
      return;
    }
    final message = CustomMessage(
      targetId: groupId,
      customMessageType: CustomMessageType.groupJoined,
      conversationType: RCIMIWConversationType.group,
      userIds: [IMEngineManager().currentUserId!],
    );
    await ImSender.instance.send(message: message);

    _isJoined = true;
    await getGroup();

    if (!mounted) return;
    context.pushReplacement(
      '/chat-detail/${Uri.encodeComponent(_groupName)}',
      extra: ChatSessionArgs(
        targetId: groupId,
        conversationType: RCIMIWConversationType.group,
        name: _groupName,
        isGroup: true,
        avatar: _group.info.portraitUri,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> updateGroupInfo() async {
    if (!_isManager) return;
    final updateFailedText = AppLocalizations.of(context)!.commonUpdateFailed;
    final updateSuccessText = AppLocalizations.of(context)!.commonUpdateSuccess;

    FocusScope.of(context).unfocus();

    AppLoading.show();

    final groupInfo = _group.info;

    if (_nameController.text.trim().isNotEmpty) {
      groupInfo.groupName = _nameController.text.trim();
    }

    if (_noteController.text.trim().isNotEmpty) {
      groupInfo.notice = _noteController.text.trim();
    }

    final isOk = await ImGroupManager().updateGroupInfo(groupInfo);

    AppLoading.dismiss();

    if (!mounted) return;

    if (!isOk) {
      AppToast.show(updateFailedText);
      return;
    }

    AppToast.show(updateSuccessText);

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. 全屏背景图 (完全对齐 wallet_setup_page.dart L30-35)
        Positioned.fill(
          child: Image.asset(
            'assets/images/chat/group-bg.png',
            fit: BoxFit.cover,
          ),
        ),

        // 2. 页面内容 (完全对齐 wallet_setup_page.dart L38-42 结构)
        Positioned.fill(
          child: Column(
            children: [
              // 自定义导航栏
              SafeArea(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Image.asset(
                          'assets/images/common/back-icon.png',
                          width: 32,
                          height: 32,
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context)!.chatGroupInfoTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // 占位保持居中
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 180),

              // 白色圆角内容区
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                    ),
                    clipBehavior: Clip.none, // 允许头像超出容器
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 群头像预览 (叠加在内容区上方)
                        Transform.translate(
                          offset: const Offset(0, -60),
                          child: _buildGroupAvatar(),
                        ),

                        // Group name
                        Text(
                          AppLocalizations.of(context)!.chatGroupInfoName,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.grey600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _isManager
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 15,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.grey100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    hintText:
                                        '${AppLocalizations.of(context)!.profileTransferPleaseEnter}${AppLocalizations.of(context)!.chatGroupInfoName}',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFFBDBDBD),
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.grey900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            : Text(
                                _groupName,
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.grey900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                        const SizedBox(height: 24),

                        // Group note
                        Text(
                          AppLocalizations.of(context)!.chatGroupInfoNote,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.grey600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _isManager
                            ? Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.grey200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    TextField(
                                      controller: _noteController,
                                      maxLines: 5,
                                      maxLength: 80,
                                      decoration: InputDecoration(
                                        hintText: AppLocalizations.of(
                                          context,
                                        )!.chatGroupInfoHint,
                                        hintStyle: AppTextStyles.body.copyWith(
                                          color: AppColors.grey400,
                                        ),
                                        border: InputBorder.none,
                                        counterText: '',
                                      ),
                                      onChanged: (val) =>
                                          setState(() {}), // 刷新字数统计
                                      style: AppTextStyles.body.copyWith(
                                        color: AppColors.grey900,
                                      ),
                                    ),
                                    Text(
                                      '${_noteController.text.length}/80',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.grey400,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Text(
                                _group.info.notice ?? '-',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.grey900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                        const SizedBox(height: 32),

                        // Save Button
                        _isJoined
                            ? _isManager
                                  ? AppButton(
                                      text: AppLocalizations.of(
                                        context,
                                      )!.commonSave,
                                      onPressed: updateGroupInfo,
                                    )
                                  : SizedBox()
                            : AppButton(
                                text: AppLocalizations.of(
                                  context,
                                )!.communityDetailBtnJoin,
                                onPressed: joinGroup,
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupAvatar() {
    return GroupAvatarWidget(
      groupId: _group.info.groupId ?? '',
      size: 80,
      portraitUri: _group.info.portraitUri,
      initialMembers: _qrMembers,
    );
  }

  String _qrMemberNames() {
    final names = _qrMembers
        .map((member) {
          final nickname = (member.nickname ?? '').replaceAll(' ', '');
          if (nickname.isNotEmpty) return nickname;
          return member.name ?? '';
        })
        .where((name) => name.isNotEmpty)
        .toList();
    return names.join('、');
  }
}
