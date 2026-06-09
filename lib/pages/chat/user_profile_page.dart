import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/core/models/user_display_model.dart';
import 'package:paracosm/core/network/api/get_uer_info_api.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/call/rong_call_manager.dart';
import 'package:paracosm/modules/im/listener/user_display_state_center.dart';
import 'package:paracosm/modules/im/manager/im_friend_manager.dart';
import 'package:paracosm/modules/im/result/im_error_mapper.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';
import 'package:paracosm/widgets/common/app_button.dart';
import 'package:paracosm/widgets/common/app_loading.dart';

import 'package:paracosm/widgets/common/app_modal.dart';
import 'package:paracosm/widgets/common/app_toast.dart';
import 'package:rongcloud_call_wrapper_plugin/wrapper/rongcloud_call_constants.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../core/network/api/upload_file_api.dart';
import '../../modules/im/listener/im_data_center.dart';
import '../../modules/im/manager/im_engine_manager.dart';
import '../../util/media_handle_util.dart';
import '../../modules/im/manager/im_user_manager.dart';
import '../../widgets/common/app_confirm_dialog.dart';
import '../../widgets/common/image_picker_sheet.dart';
import 'chat_session_args.dart';

/// 用户资料页面
class UserProfilePage extends StatefulWidget {
  final String userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  UserDisplayModel? _user;

  bool _isSelf = false;
  bool _isFriend = false;

  StreamSubscription? _profileSub;

  /// 防止并发请求乱序
  int _fetchVersion = 0;
  String? _userId;

  @override
  void initState() {
    super.initState();

    _init();

    _profileSub = ImDataCenter().profileStream.listen((userIds) {
      if (userIds.contains(widget.userId)) {
        fetchData();
      }
    });
  }

  Future<void> _init() async {
    await fetchData(forceRefresh: true);
    if (_isSelf) {
      _userId = AccountManager().currentAccount?.userId;
      return;
    }
    final user = await GetUerInfoApi.search(widget.userId);
    _userId = user?.userId;
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }

  Future<void> fetchData({bool forceRefresh = false}) async {
    final version = ++_fetchVersion;

    _isSelf = IMEngineManager().currentUserId == widget.userId;

    final user = await UserDisplayStateCenter().getUser(
      widget.userId,
      forceRefresh: forceRefresh,
    );

    if (!mounted) return;

    /// 已有更新请求
    if (version != _fetchVersion) return;

    if (user == null) return;

    setState(() {
      _user = user;
      _isFriend = user.isFriend;
    });
  }

  Future<void> toggleChat() async {
    if (_user == null) return;
    if (!_isFriend) {
      AppToast.show(AppLocalizations.of(context)!.chatAddFriendRequired);
      return;
    }
    context.push(
      '/chat-detail/${Uri.encodeComponent(_user!.name)}',
      extra: ChatSessionArgs(
        targetId: _user!.userId,
        conversationType: RCIMIWConversationType.private,
        name: _user!.name,
        isGroup: false,
        avatar: _user!.avatar,
      ),
    );
  }

  Future<void> toggleMoment() async {
    final userId = _user?.userId.trim() ?? '';
    if (userId.isEmpty) {
      AppToast.show(AppLocalizations.of(context)!.chatUserLoading);
      return;
    }
    context.push(
      '/moment-user-profile?mode=${_isSelf ? 'self' : 'friend'}',
      extra: {'userId': _userId, 'imUserId': userId},
    );
  }

  Future<void> toggleCall({required bool isVideo}) async {
    final user = _user;
    if (user == null) {
      AppToast.show(AppLocalizations.of(context)!.chatUserLoading);
      return;
    }
    if (!_isFriend) {
      AppToast.show(AppLocalizations.of(context)!.chatAddFriendRequired);
      return;
    }
    if (_isSelf) {
      AppToast.show(AppLocalizations.of(context)!.chatCannotCallSelf);
      return;
    }

    final media = isVideo ? 'video' : 'voice';
    final encodedName = Uri.encodeComponent(user.name);
    final started = await RongCallManager().startPrivateCall(
      targetId: user.userId,
      displayName: user.name,
      avatar: user.avatar,
      mediaType: isVideo ? RCCallMediaType.audio_video : RCCallMediaType.audio,
    );
    if (!started || !mounted) {
      return;
    }

    context.push('/chat-private-$media/$encodedName');
  }

  /// 显示添加好友弹窗
  void _showAddFriendModal() {
    if (_user == null) return;
    String initialText = AppLocalizations.of(context)!
        .chatProfileAddFriendPlaceholder
        .replaceAll("XXX", AccountManager().currentAccount?.name ?? '');
    TextEditingController controller = TextEditingController(text: initialText);
    AppModal.show(
      context,
      title: AppLocalizations.of(context)!.chatProfileAddFriend,
      confirmText: AppLocalizations.of(context)!.commonConfirm,
      onConfirm: () async {
        AppLoading.show();
        final result = await ImFriendManager().addFriend(
          userId: _user!.userId,
          extra: controller.text,
        );
        AppLoading.dismiss();
        if (!result.success) {
          AppToast.show(result.message);
          return;
        }
        AppToast.show(_addFriendSuccessMessage(result.data ?? 0));
        if (!mounted) return;
        context.pop();
      },
      child: _AddFriendInputWrapper(
        initialText: initialText,
        controller: controller,
      ),
    );
  }

  String _addFriendSuccessMessage(int processCode) {
    if (processCode == 0) {
      return AppLocalizations.of(context)!.chatFriendApplySendSuccess;
    }

    return ImErrorMapper.message(processCode);
  }

  /// 显示设置备注弹窗
  void _showSetNoteNameModal() {
    if (_user == null) return;
    TextEditingController controller = TextEditingController(text: _user!.name);
    AppModal.show(
      context,
      title: AppLocalizations.of(context)!.chatProfileSetNote,
      confirmText: AppLocalizations.of(context)!.chatProfileSave,
      onConfirm: () async {
        AppLoading.show();
        _user!.friend?.remark = controller.text;
        final result = await ImFriendManager().setFriendInfo(
          userId: _user!.userId,
          remark: controller.text,
        );
        AppLoading.dismiss();
        if (!result) {
          AppToast.show(AppLocalizations.of(context)!.chatSetNoteFailed);
          return;
        }
        if (!mounted) return;
        context.pop();
        setState(() {});
      },
      child: _SetNoteNameInputWrapper(controller: controller),
    );
  }

  /// 删除好友确认弹窗
  void _showDeleteFriend() {
    AppConfirmDialog.show(
      context,
      description: AppLocalizations.of(context)!.chatDeleteFriendConfirm,
      onConfirm: () async {
        context.pop();
        AppLoading.show();
        final result = await ImFriendManager().deleteFriends([widget.userId]);
        AppLoading.dismiss();
        if (!result.success) {
          AppToast.show(result.message);
          return;
        }
        if (!mounted) return;
        context.pop();
      },
    );
  }

  /// 加入黑名单确认弹窗
  void _showAddBlack() {
    AppConfirmDialog.show(
      context,
      description: AppLocalizations.of(context)!.chatBlacklistConfirm,
      onConfirm: () async {
        context.pop();
        AppLoading.show();
        final result = await ImFriendManager().addToBlacklist(widget.userId);
        AppLoading.dismiss();
        if (!result.success) {
          AppToast.show(result.message);
          return;
        }
        if (!mounted) return;
        context.pop();
      },
    );
  }

  /// 修改名称
  void _showSetNameModal() {
    final profile = _user?.profile;
    if (profile == null) return;
    TextEditingController controller = TextEditingController(
      text: profile.name,
    );
    AppModal.show(
      context,
      title: AppLocalizations.of(context)!.chatModifyName,
      confirmText: AppLocalizations.of(context)!.chatProfileSave,
      onConfirm: () async {
        AppLoading.show();
        profile.name = controller.text;
        final result = await ImUserManager().updateMyUserProfile(
          userProfile: profile,
        );
        AppLoading.dismiss();
        if (!result) {
          AppToast.show(AppLocalizations.of(context)!.chatModifyNameFailed);
          return;
        }
        if (!mounted) return;
        setState(() {});
        context.pop();
        AccountManager().updateAccountUserInfo(
          profile.name ?? '',
          profile.portraitUri ?? '',
        );
      },
      child: _SetNoteNameInputWrapper(controller: controller),
    );
  }

  /// 设置头像
  Future<void> _showPickAvatarAction() async {
    final path = await ImagePickerSheet.show(context);
    if (path == null) return;

    await _handleImage(path);
  }

  Future<void> _handleImage(String path) async {
    final profile = _user?.profile;
    if (profile == null) return;
    try {
      AppLoading.show();

      final compressed = await MediaHandleUtil.compressedImageQuality(path);

      final url = await UploadFileApi.uploadFileByPath(compressed);

      if (url == null || url.isEmpty) {
        AppToast.show(AppLocalizations.of(context)!.commonUploadFailed);
        return;
      }

      profile.portraitUri = url;

      final result = await ImUserManager().updateMyUserProfile(
        userProfile: profile,
      );

      if (!result) {
        AppToast.show(AppLocalizations.of(context)!.chatAvatarModifyFailed);
        return;
      }
      setState(() {});
      AccountManager().updateAccountUserInfo(
        profile.name ?? '',
        profile.portraitUri ?? '',
      );
    } finally {
      AppLoading.dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: '',
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildAvatarSection(),
                  const SizedBox(height: 12),
                  _buildNameSection(),
                  const SizedBox(height: 2),
                  _buildAddressSection(),
                  const SizedBox(height: 24),
                  _buildActionRow(),
                  const SizedBox(height: 40),
                  _isFriend ? _buildOptionList() : SizedBox(),
                ],
              ),
            ),
          ),
          _buildAddFriendButton(),
        ],
      ),
    );
  }

  /// 构建头像部分
  Widget _buildAvatarSection() {
    return Center(
      child: UserAvatarWidget(
        userId: _user?.userId,
        avatarUrl: _user?.avatar,
        size: 80,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  /// 构建用户名称
  Widget _buildNameSection() {
    return Text(
      _user?.name ?? '',
      style: AppTextStyles.h1.copyWith(fontSize: 20, color: AppColors.grey900),
    );
  }

  /// 构建地址展示与复制部分
  Widget _buildAddressSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () async {
            final text = _user?.userId ?? '';
            await Clipboard.setData(ClipboardData(text: text));
            if (!mounted) return;
            AppToast.show(AppLocalizations.of(context)!.commonCopied);
          },
          child: Image.asset(
            'assets/images/common/copy-grey.png',
            width: 16,
            height: 16,
          ),
        ),
        const SizedBox(width: 2),
        SizedBox(
          width: 128,
          child: Text(
            _user?.userId ?? '',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.grey400,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 构建快捷操作按钮行
  Widget _buildActionRow() {
    final items = _isFriend
        ? [
            _buildActionItem(
              AppLocalizations.of(context)!.chatProfileMessage,
              'assets/images/common/msg.png',
              toggleChat,
            ),
            _buildActionItem(
              AppLocalizations.of(context)!.chatProfileCall,
              'assets/images/common/call.png',
              () => toggleCall(isVideo: false),
            ),
            _buildActionItem(
              AppLocalizations.of(context)!.chatProfileVideo,
              'assets/images/common/video-dark.png',
              () => toggleCall(isVideo: true),
            ),
            _buildActionItem(
              AppLocalizations.of(context)!.chatProfileMoment,
              'assets/images/common/moment.png',
              toggleMoment,
            ),
          ]
        : [
            !_isSelf
                ? _buildActionItem(
                    AppLocalizations.of(context)!.chatProfileMessage,
                    'assets/images/common/msg.png',
                    toggleChat,
                  )
                : _buildActionItem(
                    AppLocalizations.of(context)!.chatAvatar,
                    'assets/images/common/camera.png',
                    _showPickAvatarAction,
                  ),

            _buildActionItem(
              AppLocalizations.of(context)!.chatProfileMoment,
              'assets/images/common/moment.png',
              toggleMoment,
            ),
          ];
    if (items.length == 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [items[0], const SizedBox(width: 60), items[1]],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items,
      ),
    );
  }

  /// 构建选项列表（设置备注、加入黑名单）
  Widget _buildOptionList() {
    return Column(
      children: [
        _buildOptionItem(
          title: AppLocalizations.of(context)!.chatProfileSetNote,
          iconPath: 'assets/images/common/set.png',
          onTap: _showSetNoteNameModal,
        ),
        _buildOptionItem(
          title: AppLocalizations.of(context)!.chatProfileAddBlacklist,
          iconPath: 'assets/images/common/slash.png',
          isFullBorder: true,
          onTap: _showAddBlack,
        ),
      ],
    );
  }

  /// 构建添加好友按钮
  Widget _buildAddFriendButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: _isFriend
          ? AppButton(
              text: AppLocalizations.of(context)!.chatProfileDelete,
              textColor: AppColors.error,
              border: BorderSide(color: AppColors.error),
              backgroundColor: Colors.white,
              onPressed: _showDeleteFriend,
            )
          : AppButton(
              text: _isSelf
                  ? 'Modify nickname'
                  : AppLocalizations.of(context)!.chatProfileAddFriend,
              textColor: Colors.white,
              backgroundColor: AppColors.grey900,
              onPressed: _isSelf ? _showSetNameModal : _showAddFriendModal,
            ),
    );
  }

  /// 构建单个快捷操作项
  Widget _buildActionItem(
    String label,
    String iconPath,
    GestureTapCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Image.asset(iconPath, width: 48, height: 48),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.grey900,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单个选项行
  Widget _buildOptionItem({
    required String title,
    required String iconPath,
    required VoidCallback onTap,
    bool isFullBorder = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        color: Colors.white,
        child: Stack(
          children: [
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
                    Image.asset(iconPath, width: 16, height: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.grey900,
                          fontSize: 14,
                        ),
                      ),
                    ),
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
}

/// 添加好友申请输入框包装组件，管理自身状态
class _AddFriendInputWrapper extends StatefulWidget {
  final String initialText;
  final TextEditingController controller;

  const _AddFriendInputWrapper({
    required this.initialText,
    required this.controller,
  });

  @override
  State<_AddFriendInputWrapper> createState() => _AddFriendInputWrapperState();
}

class _AddFriendInputWrapperState extends State<_AddFriendInputWrapper> {
  late TextEditingController controller;
  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
    focusNode = FocusNode();
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AddFriendInput(controller: controller, focusNode: focusNode);
  }
}

/// 设置备注名称输入框包装组件，管理自身状态
class _SetNoteNameInputWrapper extends StatefulWidget {
  final TextEditingController controller;

  const _SetNoteNameInputWrapper({required this.controller});

  @override
  State<_SetNoteNameInputWrapper> createState() =>
      _SetNoteNameInputWrapperState();
}

class _SetNoteNameInputWrapperState extends State<_SetNoteNameInputWrapper> {
  late TextEditingController controller;
  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
    focusNode = FocusNode();
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SetNoteNameInput(controller: controller, focusNode: focusNode);
  }
}

/// 添加好友申请输入框组件
class _AddFriendInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const _AddFriendInput({required this.controller, required this.focusNode});

  @override
  State<_AddFriendInput> createState() => _AddFriendInputState();
}

class _AddFriendInputState extends State<_AddFriendInput> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isFocused = widget.focusNode.hasFocus;
    // 假设初始预设内容为申请信息，当用户修改后或获得焦点时颜色加深
    // 这里简单判断是否有内容，或者是否获得焦点
    final bool hasText = widget.controller.text.isNotEmpty;

    return Container(
      height: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused ? AppColors.grey900 : AppColors.grey100,
          width: isFocused ? 1.5 : 1,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        maxLines: null,
        onChanged: (value) => setState(() {}),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: AppTextStyles.body.copyWith(
          fontSize: 14,
          color: (isFocused || hasText) ? AppColors.grey900 : AppColors.grey400,
          fontWeight: (isFocused || hasText)
              ? FontWeight.w500
              : FontWeight.normal,
        ),
      ),
    );
  }
}

/// 内部组件处理输入框状态
class _SetNoteNameInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const _SetNoteNameInput({required this.controller, required this.focusNode});

  @override
  State<_SetNoteNameInput> createState() => _SetNoteNameInputState();
}

class _SetNoteNameInputState extends State<_SetNoteNameInput> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isFocused = widget.focusNode.hasFocus;
    final bool isEmpty = widget.controller.text.isEmpty;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: (isEmpty && !isFocused) ? AppColors.grey100 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: (isEmpty && !isFocused)
            ? Border.all(color: Colors.transparent)
            : Border.all(color: AppColors.grey900),
      ),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        onChanged: (value) => setState(() {}),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: AppTextStyles.body.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.grey900,
        ),
      ),
    );
  }
}
