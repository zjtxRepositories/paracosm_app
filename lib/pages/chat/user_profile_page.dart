import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:paracosm/core/models/friend_model.dart';
import 'package:paracosm/core/models/user_model.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/im/manager/im_friend_manager.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_localizations_keys.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';
import 'package:paracosm/widgets/common/app_button.dart';
import 'package:paracosm/widgets/common/app_loading.dart';

import 'package:paracosm/widgets/common/app_modal.dart';
import 'package:paracosm/widgets/common/app_toast.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../core/network/api/upload_file_api.dart';
import '../../modules/im/manager/im_send_manager.dart';
import '../../modules/im/message/custom_message.dart';
import '../../util/media_handle_util.dart';
import '../../modules/im/manager/im_user_manager.dart';
import '../../widgets/common/image_picker_sheet.dart';

/// 用户资料页面
class UserProfilePage extends StatefulWidget {
  final String userId;

  const UserProfilePage({
    super.key,
    required this.userId,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  UserModel? _user;
  bool _isSelf= false;
  bool _isFriend = false;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final manager = ImUserManager();
    final currentUserId = AccountManager().currentAccount?.accountId;
    RCIMIWUserProfile? profile;
    try {
      if (widget.userId == currentUserId) {
        profile = await manager.getMyUserProfile();
        _isSelf = true;
      }
      else {
        final result =
            await manager.getUserProfiles([widget.userId]) ?? [];
        if (result.isNotEmpty) {
          profile = result.first;
        }
        final List<RCIMIWFriendInfo> friends = await ImFriendManager().getFriendsInfo([widget.userId]) ?? [];
        if (friends.isNotEmpty){
          final friend = FriendModel(info: friends.first);
          profile?.name = friend.name;
          // print('dddd-----${friend.remark}');
          _isFriend = true;
        }
      }
      if (profile == null) return;
      if (!mounted) return;

      setState(() {
        _user = UserModel(profile: profile!);
      });
    } catch (e) {
      // 可以加日志
      debugPrint("fetchData error: $e");
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> toggleChat() async {
    if (!_isFriend){
      AppToast.show('请添加好友！');
      return;
    }
    // final targetId = _user?.profile.userId ?? '';
    // final content = "我们已成功添加为好友，现在可以开始聊天啦～";
    // final message = await CustomMessage.createFm(targetId: targetId, content: content);
    // if (message != null) {
    //  final result = await ImSendManager.instance.sendCustomMessage(message: message);
    //  if (result){
    //    print('发送-----发送消息成功');
    //  }
    // }
  }

  Future<void> toggleMoment() async {
    context.push('/moment-user-profile');
  }

  /// 显示添加好友弹窗
  void _showAddFriendModal() {
    if (_user == null) return;
    print('object----${AccountManager().currentAccount?.nickname}');
    String initialText = AppLocalizations.of(context)!.chatProfileAddFriendPlaceholder.replaceAll("XXX",
        AccountManager().currentAccount?.name ?? '');
    TextEditingController controller = TextEditingController(text: initialText);
    AppModal.show(
      context,
      title: AppLocalizations.of(context)!.chatProfileAddFriend,
      confirmText: AppLocalizations.of(context)!.commonConfirm,
      onConfirm: () async {
        AppLoading.show();
        final result = await ImFriendManager().addFriend(userId: _user!.profile.userId ?? '',extra: controller.text);
        AppLoading.dismiss();
        if (!result.success){
          AppToast.show('发送好友申请失败！');
          return;
        }
        AppToast.show('发送好友申请成功！');
        context.pop();
      },
      child: _AddFriendInputWrapper(
        initialText: initialText,
        controller: controller,
      ),
    );
  }

  /// 显示设置备注弹窗
  void _showSetNoteNameModal() {
    if (_user == null) return;
    TextEditingController controller = TextEditingController(text: _user!.profile.name ?? '');
    AppModal.show(
      context,
      title: AppLocalizations.of(context)!.chatProfileSetNote,
      confirmText: AppLocalizations.of(context)!.chatProfileSave,
      onConfirm: () async {
        AppLoading.show();
        _user!.profile.name = controller.text;
        final result = await ImUserManager().updateMyUserProfile(userProfile: _user!.profile);
        AppLoading.dismiss();
        if (!result){
          AppToast.show('设置备注失败！');
          return;
        }
        context.pop();
        setState(() {});
      },
      child: _SetNoteNameInputWrapper(
        controller: controller,
      ),
    );
  }

  /// 修改名称
  void _showSetNameModal() {
    if (_user == null) return;
    TextEditingController controller = TextEditingController(text: _user!.profile.name ?? '');
    AppModal.show(
      context,
      title: '修改名称',
      confirmText: AppLocalizations.of(context)!.chatProfileSave,
      onConfirm: () async {
        AppLoading.show();
        _user!.profile.name = controller.text;
        final result = await ImUserManager().updateMyUserProfile(userProfile: _user!.profile);
        AppLoading.dismiss();
        if (!result){
          AppToast.show('修改名称失败！');
          return;
        }
        setState(() {});
        context.pop();
        AccountManager().updateAccountUserInfo(_user!.profile.name ?? '', _user!.profile.portraitUri ?? '');
      },
      child: _SetNoteNameInputWrapper(
        controller: controller,
      ),
    );
  }

  /// 设置头像
  Future<void> _showPickAvatarAction() async {
    final path = await ImagePickerSheet.show(context);
    print('path-----$path');
    if (path == null) return;

    await _handleImage(path);
  }

  Future<void> _handleImage(String path) async {
    try {
      AppLoading.show();

      final compressed =
      await MediaHandleUtil.compressedImageQuality(path);

      final url = await UploadFileApi.uploadFileByPath(compressed);

      if (url == null || url.isEmpty) {
        AppToast.show('上传失败');
        return;
      }

      _user!.profile.portraitUri = url;

      final result = await ImUserManager()
          .updateMyUserProfile(userProfile: _user!.profile);

      if (!result) {
        AppToast.show('修改头像失败');
        return;
      }
      setState(() {});
      AccountManager().updateAccountUserInfo(_user!.profile.name ?? '', _user!.profile.portraitUri ?? '');
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
                  _isFriend ? _buildOptionList() :SizedBox(),
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
        userId: _user?.profile.userId,
        avatarUrl: _user?.profile.portraitUri,
        size: 80,
        borderRadius: BorderRadius.circular(16),
      )
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
            final text = _user?.profile.userId ?? '';
            await Clipboard.setData(ClipboardData(text: text));
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
            _user?.profile.userId ?? '',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.grey400,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        )
      ],
    );
  }

  /// 构建快捷操作按钮行
  Widget _buildActionRow() {
    final items = _isFriend
        ? [
      _buildActionItem(AppLocalizations.of(context)!.chatProfileMessage,
          'assets/images/common/msg.png',toggleChat),
      _buildActionItem(AppLocalizations.of(context)!.chatProfileCall,
          'assets/images/common/call.png',(){}),
      _buildActionItem(AppLocalizations.of(context)!.chatProfileVideo,
          'assets/images/common/video-dark.png',(){}),
      _buildActionItem(AppLocalizations.of(context)!.chatProfileMoment,
          'assets/images/common/moment.png',(){}),
    ]
        : [
      !_isSelf
          ? _buildActionItem(
          AppLocalizations.of(context)!.chatProfileMessage,
          'assets/images/common/msg.png',toggleChat)
          : _buildActionItem('头像',
          'assets/images/common/camera.png',_showPickAvatarAction),

      _buildActionItem(AppLocalizations.of(context)!.chatProfileMoment,
          'assets/images/common/moment.png',toggleMoment),
    ];
    if (items.length == 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            items[0],
            const SizedBox(width: 60),
            items[1],
          ],
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
          onTap: () {},
        ),
      ],
    );
  }

  /// 构建添加好友按钮
  Widget _buildAddFriendButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: _isFriend  ?
      AppButton(
        text: AppLocalizations.of(context)!.chatProfileDelete,
        textColor: AppColors.error,
        border: BorderSide(color:  AppColors.error),
        backgroundColor: Colors.white,
        onPressed: _showAddFriendModal,
      ):
      AppButton(
        text: _isSelf ? 'Modify nickname' : AppLocalizations.of(context)!.chatProfileAddFriend,
        textColor: Colors.white,
        backgroundColor: AppColors.grey900,
        onPressed:_isSelf ? _showSetNameModal : _showAddFriendModal,
      ),
    );
  }

  /// 构建底部删除按钮
  Widget _buildDeleteButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: AppButton(
        text: AppLocalizations.of(context)!.chatProfileDelete,
        textColor: const Color(0xFFF04438),
        backgroundColor: Colors.white,
        border: const BorderSide(color: Color(0xFFFDA29B)),
        onPressed: () {},
      ),
    );
  }

  /// 构建单个快捷操作项
  Widget _buildActionItem(String label, String iconPath, GestureTapCallback? onTap) {
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

  const _AddFriendInputWrapper({required this.initialText, required this.controller});

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
    return _AddFriendInput(
      controller: controller,
      focusNode: focusNode,
    );
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
    return _SetNoteNameInput(
      controller: controller,
      focusNode: focusNode,
    );
  }
}

/// 添加好友申请输入框组件
class _AddFriendInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const _AddFriendInput({
    required this.controller,
    required this.focusNode,
  });

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
          fontWeight: (isFocused || hasText) ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
    );
  }
}

/// 内部组件处理输入框状态
class _SetNoteNameInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const _SetNoteNameInput({
    required this.controller,
    required this.focusNode,
  });

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
