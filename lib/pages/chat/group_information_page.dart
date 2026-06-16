import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/core/network/api/upload_file_api.dart';
import 'package:paracosm/modules/im/group_info_update_builder.dart';
import 'package:paracosm/modules/im/group_permission_policy.dart';
import 'package:paracosm/modules/im/manager/im_engine_manager.dart';
import 'package:paracosm/pages/chat/chat_session_args.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/util/media_handle_util.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/chat/group_avatar_widget.dart';
import 'package:paracosm/widgets/common/app_button.dart';
import 'package:paracosm/widgets/common/app_loading.dart';
import 'package:paracosm/widgets/common/image_picker_sheet.dart';
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
  late TextEditingController _introductionController;
  late TextEditingController _noticeController;

  late GroupModel _group;
  String _groupName = '';
  String? _pickedAvatarPath;
  late bool _isJoined;
  late List<RCIMIWGroupMemberInfo> _qrMembers;

  GroupPermissionPolicy get _permission =>
      GroupPermissionPolicy(groupInfo: _group.info, isJoined: _isJoined);

  bool get _canEditGroupInfo => _permission.canEditGroupInfo;

  @override
  void initState() {
    super.initState();

    _group = widget.group;
    _isJoined = widget.isJoined;
    _qrMembers = widget.qrMembers;

    _nameController = TextEditingController(text: widget.group.displayName);

    _introductionController = TextEditingController(
      text: widget.group.info.introduction,
    );
    _noticeController = TextEditingController(text: widget.group.info.notice);

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
    if (_canEditGroupInfo) {
      _nameController.text = _group.displayName ?? '';
      _introductionController.text = _group.info.introduction ?? '';
      _noticeController.text = _group.info.notice ?? '';
    } else if (!_isJoined) {
      _groupName = _group.displayName ?? _group.info.groupName ?? '';
      if (_groupName.isEmpty || _groupName == '[默认]') {
        _groupName = '-';
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
    _introductionController.dispose();
    _noticeController.dispose();
    super.dispose();
  }

  Future<void> _pickGroupAvatar() async {
    if (!_canEditGroupInfo) return;
    final path = await ImagePickerSheet.show(context);
    if (path == null || path.isEmpty || !mounted) return;
    setState(() {
      _pickedAvatarPath = path;
    });
  }

  Future<void> updateGroupInfo() async {
    if (!_canEditGroupInfo) {
      AppToast.show(AppLocalizations.currentText('chat_group_no_permission'));
      return;
    }
    final updateFailedText = AppLocalizations.of(context)!.commonUpdateFailed;
    final updateSuccessText = AppLocalizations.of(context)!.commonUpdateSuccess;
    final uploadFailedText = AppLocalizations.of(context)!.commonUploadFailed;
    final groupName = _nameController.text.trim();
    if (groupName.isEmpty) {
      AppToast.show(AppLocalizations.of(context)!.chatGroupInfoNameRequired);
      return;
    }

    FocusScope.of(context).unfocus();

    AppLoading.show();

    try {
      final currentGroupInfo = _group.info;
      var portraitUri = currentGroupInfo.portraitUri;
      final pickedAvatarPath = _pickedAvatarPath;
      if (pickedAvatarPath != null && pickedAvatarPath.isNotEmpty) {
        final compressed = await MediaHandleUtil.compressedImageQuality(
          pickedAvatarPath,
        );
        final url = await UploadFileApi.uploadFileByPath(compressed);
        if (url == null || url.isEmpty) {
          AppToast.show(uploadFailedText);
          return;
        }
        portraitUri = url;
      }

      final groupInfo = GroupInfoUpdateBuilder.build(
        groupId: currentGroupInfo.groupId ?? '',
        groupName: groupName,
        portraitUri: portraitUri,
        introduction: _introductionController.text.trim(),
        notice: _noticeController.text.trim(),
        extProfile: currentGroupInfo.extProfile,
      );

      final isOk = await ImGroupManager().updateGroupInfo(groupInfo);

      if (!mounted) return;

      if (!isOk) {
        AppToast.show(updateFailedText);
        return;
      }

      GroupInfoUpdateBuilder.applyToLocal(
        target: currentGroupInfo,
        update: groupInfo,
      );
      _group = GroupModel(info: currentGroupInfo);
      _pickedAvatarPath = null;

      AppToast.show(updateSuccessText);
      context.pop();
    } finally {
      AppLoading.dismiss();
    }
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
                          child: Center(child: _buildGroupAvatar()),
                        ),

                        Transform.translate(
                          offset: const Offset(0, -40),
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context)!.chatGroupInfoAvatar,
                              style: AppTextStyles.caption.copyWith(
                                color: _canEditGroupInfo
                                    ? AppColors.grey600
                                    : AppColors.grey400,
                              ),
                            ),
                          ),
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
                        _canEditGroupInfo
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

                        // Group introduction
                        Text(
                          AppLocalizations.of(context)!.chatGroupInfoIntro,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.grey600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _canEditGroupInfo
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
                                      controller: _introductionController,
                                      maxLines: 5,
                                      maxLength: 80,
                                      decoration: InputDecoration(
                                        hintText: AppLocalizations.of(
                                          context,
                                        )!.chatGroupInfoIntroHint,
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
                                      '${_introductionController.text.length}/80',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.grey400,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Text(
                                _emptyText(_group.info.introduction),
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.grey900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                        const SizedBox(height: 24),

                        // Group notice
                        Text(
                          AppLocalizations.of(context)!.chatGroupInfoNotice,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.grey600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _canEditGroupInfo
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
                                      controller: _noticeController,
                                      maxLines: 5,
                                      maxLength: 200,
                                      decoration: InputDecoration(
                                        hintText: AppLocalizations.of(
                                          context,
                                        )!.chatGroupInfoNoticeHint,
                                        hintStyle: AppTextStyles.body.copyWith(
                                          color: AppColors.grey400,
                                        ),
                                        border: InputBorder.none,
                                        counterText: '',
                                      ),
                                      onChanged: (val) => setState(() {}),
                                      style: AppTextStyles.body.copyWith(
                                        color: AppColors.grey900,
                                      ),
                                    ),
                                    Text(
                                      '${_noticeController.text.length}/200',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.grey400,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Text(
                                _emptyText(_group.info.notice),
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.grey900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                        const SizedBox(height: 32),

                        // Save Button
                        _isJoined
                            ? _canEditGroupInfo
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
    final pickedAvatarPath = _pickedAvatarPath;
    final avatar = pickedAvatarPath == null || pickedAvatarPath.isEmpty
        ? GroupAvatarWidget(
            groupId: _group.info.groupId ?? '',
            size: 80,
            portraitUri: _group.info.portraitUri,
            initialMembers: _qrMembers,
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(pickedAvatarPath),
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => GroupAvatarWidget(
                groupId: _group.info.groupId ?? '',
                size: 80,
                portraitUri: _group.info.portraitUri,
                initialMembers: _qrMembers,
              ),
            ),
          );

    return GestureDetector(
      onTap: _canEditGroupInfo ? _pickGroupAvatar : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          if (_canEditGroupInfo)
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _emptyText(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? '-' : text;
  }
}
