import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/core/models/friend_application_model.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/im/manager/im_send_manager.dart';
import 'package:paracosm/modules/im/message/custom_message.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_localizations_keys.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_loading.dart';
import 'package:paracosm/widgets/common/app_modal.dart';
import 'package:paracosm/widgets/common/app_toast.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../core/models/custom_message_model.dart';
import '../../modules/im/manager/im_friend_applications_manager.dart';
import '../../widgets/chat/user_avatar_widget.dart';

/// 好友申请页面
class FriendRequestPage extends StatefulWidget {
  const FriendRequestPage({super.key});

  @override
  State<FriendRequestPage> createState() => _FriendRequestPageState();
}

class _FriendRequestPageState extends State<FriendRequestPage> {
  List<RCIMIWFriendApplicationInfo> _newRequests = [];
  List<RCIMIWFriendApplicationInfo> _processedRequests = [];
  final manager = ImFriendApplicationsManager();
  StreamSubscription<List<RCIMIWFriendApplicationInfo>>? _sub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    _listen();
    manager.fetch();
  }

  /// 监听（带防重复）
  void _listen() {
    /// 先取消旧的
    _sub?.cancel();

    _sub = manager.stream.listen((list) {
      final newList = <RCIMIWFriendApplicationInfo>[];
      final processedList = <RCIMIWFriendApplicationInfo>[];

      for (var e in list) {
        final isUnhandled =
            e.applicationStatus == RCIMIWFriendApplicationStatus.unhandled;
        final isReceived =
            e.applicationType == RCIMIWFriendApplicationType.received;

        if (isUnhandled && isReceived) {
          newList.add(e);
        } else if (!isUnhandled && isReceived) {
          processedList.add(e);
        }
      }

      if (mounted) {
        setState(() {
          _newRequests = newList;
          _processedRequests = processedList;
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _sub = null;
    super.dispose();
  }

  /// 显示同意确认弹窗
  Future<void> _showAgreeConfirmModal(FriendApplicationModel model) async {
    AppLoading.show();
    final targetId = model.info.userId ?? '';
    final isOk = await manager.acceptFriendApplication(targetId);
    AppLoading.dismiss();
    if (!isOk){
      AppToast.show('请求失败');
      return;
    }
    final message = await CustomMessage.createFm(targetId: targetId,type: CustomMessageType.friendAdd);
    if (message == null) return;
    final isSend = await ImSendManager.instance.sendCustomMessage(message: message);
    if (!isSend)return;
    print('去聊天呀');
  }

  /// 显示拒绝确认弹窗
  void _showRejectConfirmModal(FriendApplicationModel model) {
    AppModal.show(
        context,
        title: AppLocalizations.of(context)!.chatRequestHint,
        description: AppLocalizations.of(context)!.chatRequestRejectConfirm,
        confirmText: AppLocalizations.of(context)!.chatRequestSure,
        cancelText: AppLocalizations.of(context)!.chatRequestCancel,
        confirmWidth: 161,
        cancelWidth: 161,
        cancelBorder: const BorderSide(color: AppColors.grey300),
        icon: Image.asset(
          'assets/images/wallet/bell-icon.png',
          width: 120,
          height: 120,
          fit: BoxFit.contain,
        ),
        onConfirm: () async {
          context.pop();
          AppLoading.show();
          final isOk = await manager.refuseFriendApplication(model.info.userId ?? '');
          AppLoading.dismiss();
          if (!isOk){
            AppToast.show('请求失败');
            return;
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: AppLocalizations.of(context)!.chatFriendRequest,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 16),
          _newRequests.isNotEmpty ?  _buildSectionTitle(AppLocalizations.of(context)!.chatRequestNew) : SizedBox(),
          ..._newRequests.map((req) => _buildNewRequestItem(req)),
          _newRequests.isNotEmpty ? const SizedBox(height: 24) : SizedBox(),
          _processedRequests.isNotEmpty ?  _buildSectionTitle(AppLocalizations.of(context)!.chatRequestProcessed) : SizedBox(),
          ..._processedRequests.map((req) => _buildProcessedItem(req)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// 构建分组标题
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.grey400,
          fontSize: 12,
        ),
      ),
    );
  }

  /// 构建待处理申请项
  Widget _buildNewRequestItem(RCIMIWFriendApplicationInfo req) {
    final model = FriendApplicationModel(info: req);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          UserAvatarWidget(
            userId: req.userId,
            avatarUrl: req.portrait,
            size: 44,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(bottom: 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.grey100, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.name,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.grey900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 180,
                          child: Text(
                            model.info.remark ?? '',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.grey400,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _showRejectConfirmModal(model),
                    child: Image.asset(
                      'assets/images/chat/refuse.png',
                      width: 40,
                      height: 26,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showAgreeConfirmModal(model),
                    child: Image.asset(
                      'assets/images/chat/agree.png',
                      width: 40,
                      height: 26,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建已处理申请项
  Widget _buildProcessedItem(RCIMIWFriendApplicationInfo req) {
    final statusText = switch (req.applicationStatus) {
      RCIMIWFriendApplicationStatus.accepted =>
      AppLocalizations.of(context)!.chatRequestStatusAdded,

      RCIMIWFriendApplicationStatus.expired =>
      AppLocalizations.of(context)!.chatRequestStatusExpired,

      RCIMIWFriendApplicationStatus.refused =>
      AppLocalizations.of(context)!.chatRequestStatusRejected,
      RCIMIWFriendApplicationStatus.unhandled => '',

      null => '',
    };
    final model = FriendApplicationModel(info: req);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          UserAvatarWidget(
            userId: req.userId,
            avatarUrl: req.portrait,
            size: 44,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(bottom: 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.grey100, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.name,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.grey900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          req.remark ?? '',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.grey400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      if (req.applicationType == RCIMIWFriendApplicationType.sent) ...[
                        Image.asset(
                          'assets/images/chat/go.png',
                          width: 16,
                          height: 16,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        statusText,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.grey400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 同意好友申请输入框包装组件，管理自身状态
class _AgreeRequestInputWrapper extends StatefulWidget {
  final String initialText;

  const _AgreeRequestInputWrapper({required this.initialText});

  @override
  State<_AgreeRequestInputWrapper> createState() => _AgreeRequestInputWrapperState();
}

class _AgreeRequestInputWrapperState extends State<_AgreeRequestInputWrapper> {
  late TextEditingController controller;
  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialText);
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
    return _AgreeRequestInput(
      controller: controller,
      focusNode: focusNode,
    );
  }
}

/// 同意好友申请输入框组件
class _AgreeRequestInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const _AgreeRequestInput({
    required this.controller,
    required this.focusNode,
  });

  @override
  State<_AgreeRequestInput> createState() => _AgreeRequestInputState();
}

class _AgreeRequestInputState extends State<_AgreeRequestInput> {
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
    final bool hasText = widget.controller.text.isNotEmpty;

    return Container(
      height: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused ? AppColors.grey900 : Colors.transparent,
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
