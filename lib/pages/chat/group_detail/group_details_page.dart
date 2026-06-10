import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/modules/im/listener/im_data_center.dart';
import 'package:paracosm/modules/im/manager/im_engine_manager.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/chat/group_avatar_widget.dart';
import 'package:paracosm/widgets/chat/remove_member_modal.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';
import 'package:paracosm/widgets/common/app_button.dart';
import 'package:paracosm/widgets/common/app_modal.dart';
import 'package:paracosm/widgets/common/app_toast.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../../core/models/group_member_model.dart';
import '../../../widgets/chat/select_members_modal.dart';
import '../chat_session_args.dart';
import 'group_details_controller.dart';

/// 群聊详情页面
/// 完全参考 [session_details_page.dart] 进行样式重构
class GroupDetailsPage extends StatefulWidget {
  final ChatSessionArgs? args;

  const GroupDetailsPage({super.key, this.args});

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  late final GroupDetailsController controller;
  @override
  void initState() {
    super.initState();
    controller = GroupDetailsController(widget.args);
    controller.addListener(_refresh);
    controller.init(context);
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    controller.removeListener(_refresh);
    controller.dispose();
    super.dispose();
  }

  Future<void> showChooseMembers() async {
    final friends = ImDataCenter().friends;
    final defaultSelectedUserIds = controller.members
        .map((item) => item.item.userId ?? '')
        .toList();
    final result = await SelectMembersModal.show(
      context,
      friends: friends,
      confirmText: AppLocalizations.of(context)!.commonDone,
      defaultSelectedUserIds: defaultSelectedUserIds,
      minSelectedCount: 3,
    );
    if (result == null || result.isEmpty) return;
    controller.inviteUsersToGroup(result);
  }

  Future<void> showRemoveMembers() async {
    List<GroupMemberModel> members = controller.members
        .where(
          (item) =>
              (item.item.userId ?? '') != IMEngineManager().currentUserId &&
              item.item.role != RCIMIWGroupMemberRole.owner,
        )
        .toList();

    final result = await RemoveMemberModal.show(context, members: members);
    if (result == null || result.isEmpty) return;
    controller.kickGroupMembers(result);
  }

  Future<void> showSetManagers() async {
    final members = controller.members
        .where((item) => item.item.role != RCIMIWGroupMemberRole.owner)
        .toList();

    final result = await RemoveMemberModal.show(
      context,
      members: members,
      title: AppLocalizations.of(context)!.chatSetManager,
      defaultSelectedUserIds: controller.currentManagerUserIds(),
    );
    if (result == null) return;
    controller.updateGroupManagers(result);
  }

  /// 显示清空记录确认弹窗
  void _showClearHistoryModal() {
    AppModal.show(
      context,
      title: AppLocalizations.of(context)!.commonRiskTips,
      description: AppLocalizations.of(context)!.chatSettingClearConfirm,
      confirmText: AppLocalizations.of(context)!.commonConfirm,
      cancelText: AppLocalizations.of(context)!.chatRequestCancel,
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
      onConfirm: () {
        controller.clearHistory(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: AppLocalizations.of(context)!.chatSettingTitle,
      backgroundColor: Colors.white,
      showNavBorder: true,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                _buildMemberGrid(),
                controller.isMemberMore ? _buildViewMore() : SizedBox(),
                controller.isMemberMore
                    ? const SizedBox(height: 12)
                    : SizedBox(),
                _buildOptionItem(
                  AppLocalizations.of(context)!.chatSettingGroupInfo,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildGroupAvatars(),
                      const SizedBox(width: 8),
                      Image.asset(
                        'assets/images/common/next.png',
                        width: 20,
                        height: 20,
                      ),
                    ],
                  ),
                  onTap: () {
                    context.push('/group-information', extra: controller.group);
                  },
                ),
                _buildOptionItem(
                  AppLocalizations.of(context)!.groupQrCodeTitle,
                  trailing: Row(
                    children: [
                      Image.asset(
                        'assets/images/profile/user/qrcode.png',
                        width: 20,
                        height: 20,
                        errorBuilder: (_, __, ___) =>
                        const Icon(Icons.qr_code_scanner, color: AppColors.grey900),
                      ),
                      const SizedBox(width: 8),
                      Image.asset(
                        'assets/images/common/next.png',
                        width: 20,
                        height: 20,
                      ),
                    ],
                  ),
                  onTap: () {
                    final group = controller.group;
                    if (group == null) return;
                    context.push('/group-qr-code', extra: group);
                  },
                ),
                _buildOptionItem(
                  AppLocalizations.of(context)!.chatSettingIntroduction,
                  subtitle: (controller.group?.info.introduction ?? '').isEmpty
                      ? AppLocalizations.of(context)!.chatSettingIntroEmpty
                      : controller.group?.info.introduction ?? '',
                  isArrow: controller.isManager,
                  onTap: controller.isManager
                      ? () async {
                          final text = await context.push<String>(
                            '/group-introduction',
                            extra: {
                              'title': AppLocalizations.of(
                                context,
                              )!.chatSettingIntroduction,
                              'initial':
                                  controller.group?.info.introduction ?? '',
                            },
                          );
                          if (text != null && text.isNotEmpty) {
                            controller.updateGroupInfo(introduction: text);
                          }
                        }
                      : null,
                ),
                _buildOptionItem(
                  AppLocalizations.of(context)!.chatSettingNotice,
                  subtitle: (controller.group?.info.notice ?? '').isEmpty
                      ? AppLocalizations.of(context)!.chatSettingIntroEmpty
                      : controller.group?.info.notice ?? '',
                  isFullBorder: true,
                  isArrow: controller.isManager,
                  onTap: controller.isManager
                      ? () async {
                          final text = await context.push<String>(
                            '/group-introduction',
                            extra: {
                              'title': AppLocalizations.of(
                                context,
                              )!.chatSettingNotice,
                              'initial': controller.group?.info.notice ?? '',
                            },
                          );
                          if (text != null && text.isNotEmpty) {
                            controller.updateGroupInfo(notice: text);
                          }
                        }
                      : null,
                ),
                Container(
                  height: 10,
                  decoration: const BoxDecoration(color: AppColors.grey100),
                ),
                _buildOptionItem(
                  AppLocalizations.of(context)!.chatSettingSearchHistory,
                  isFullBorder: true,
                  onTap: () {
                    if (widget.args == null) return;
                    context.push('/chat-history-search', extra: widget.args);
                  },
                ),
                Container(
                  height: 10,
                  decoration: const BoxDecoration(color: AppColors.grey100),
                ),
                _buildOptionItem(
                  AppLocalizations.of(context)!.chatSettingPin,
                  trailing: GestureDetector(
                    onTap: () => controller.togglePin(),
                    child: Image.asset(
                      controller.isPinned
                          ? 'assets/images/common/switch-active.png'
                          : 'assets/images/common/switch-default.png',
                      width: 52,
                      height: 28,
                    ),
                  ),
                ),
                controller.isManager
                    ? _buildOptionItem(
                        AppLocalizations.of(context)!.chatSettingMuteAll,
                        isFullBorder: true,
                        trailing: GestureDetector(
                          onTap: () => controller.toggleMute(),
                          child: Image.asset(
                            controller.isMuted
                                ? 'assets/images/common/switch-active.png'
                                : 'assets/images/common/switch-default.png',
                            width: 52,
                            height: 28,
                          ),
                        ),
                      )
                    : SizedBox(),
                Container(
                  height: 10,
                  decoration: const BoxDecoration(color: AppColors.grey100),
                ),
                controller.isOwner
                    ? _buildOptionItem(
                        AppLocalizations.of(context)!.chatSetManager,
                        onTap: showSetManagers,
                      )
                    : SizedBox(),
                controller.isOwner
                    ? _buildOptionItem(
                        AppLocalizations.of(context)!.chatSettingDisband,
                        isFullBorder: true,
                        onTap: () => controller.toggleDisband(context),
                      )
                    : SizedBox(),
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
                  onTap: () async {
                    final submittedText = AppLocalizations.of(
                      context,
                    )!.chatComplaintSubmitted;
                    final text = await context.push<String>(
                      '/group-introduction',
                      extra: {
                        'title': AppLocalizations.of(
                          context,
                        )!.sessionDetailsReport,
                        'initial': '',
                      },
                    );
                    if (text != null && text.isNotEmpty) {
                      AppToast.show(submittedText);
                    }
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          _buildLeaveButton(),
        ],
      ),
    );
  }

  /// 构建成员网格 (参考 session_details_page.dart 的 Wrap 结构)
  Widget _buildMemberGrid() {
    final visibleMembers = controller.visibleMembers();

    final items = [...visibleMembers, 'add'];

    if (controller.isManager) {
      items.add('remove');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5, // 每行5个
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          childAspectRatio: 0.62,
        ),
        itemBuilder: (context, index) {
          final item = items[index];

          if (item == 'add') {
            return GestureDetector(
              onTap: showChooseMembers,
              child: _buildActionMemberItem(
                'assets/images/common/add-member.png',
              ),
            );
          }

          if (item == 'remove') {
            return GestureDetector(
              onTap: () => showRemoveMembers(),
              child: _buildActionMemberItem(
                'assets/images/common/remove-member.png',
              ),
            );
          }
          if (item is GroupMemberModel) {
            return _buildMemberItem(item);
          }
          return SizedBox();
        },
      ),
    );
  }

  /// 单个成员项 (参考 session_details_page.dart)
  Widget _buildMemberItem(GroupMemberModel member) {
    final String name = member.name;
    String? avatarPath = member.item.portraitUri;
    final roleText = _roleText(member.item.role);

    return GestureDetector(
      onTap: () {
        context.push('/user-profile', extra: member.item.userId ?? '');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          UserAvatarWidget(
            userId: member.item.userId ?? '',
            avatarUrl: avatarPath,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 56,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.grey900,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          if (roleText != null) ...[
            const SizedBox(height: 2),
            Container(
              height: 16,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                roleText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.grey700,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _roleText(RCIMIWGroupMemberRole? role) {
    switch (role) {
      case RCIMIWGroupMemberRole.owner:
        return AppLocalizations.of(context)!.chatGroupOwner;
      case RCIMIWGroupMemberRole.manager:
        return AppLocalizations.of(context)!.chatGroupManager;
      default:
        return null;
    }
  }

  /// 添加/删除成员按钮 (参考 session_details_page.dart)
  Widget _buildActionMemberItem(String iconPath) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(iconPath, width: 44, height: 44, color: AppColors.grey900),
        const SizedBox(height: 4),
        const Text('', style: TextStyle(fontSize: 14)),
      ],
    );
  }

  /// 查看更多 (参考 session_details_page.dart 风格适配)
  Widget _buildViewMore() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)!.commonViewMore(2),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.grey400,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Image.asset(
            'assets/images/common/next.png',
            width: 16,
            height: 16,
            color: AppColors.grey400,
          ),
        ],
      ),
    );
  }

  /// 群组头像预览 (适配 session 风格)
  Widget _buildGroupAvatars() {
    return GroupAvatarWidget(
      groupId: controller.args?.targetId ?? '',
      portraitUri: controller.args?.avatar,
      size: 36,
    );
  }

  /// 通用选项行 (完全参考 session_details_page.dart 的 Stack 结构)
  Widget _buildOptionItem(
    String title, {
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isFullBorder = false,
    bool isArrow = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        color: Colors.white,
        child: Stack(
          children: [
            Positioned(
              left: isFullBorder ? 0 : 20,
              right: isFullBorder ? 0 : 20,
              bottom: 0,
              child: Container(height: 0.5, color: AppColors.grey200),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.grey900,
                            fontSize: 14,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.grey400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  trailing ??
                      (isArrow
                          ? Image.asset(
                              'assets/images/common/next.png',
                              width: 20,
                              height: 20,
                            )
                          : const SizedBox()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 退出按钮 (复用 AppButton)
  Widget _buildLeaveButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: AppButton(
        text: AppLocalizations.of(context)!.commonLeave,
        textColor: Colors.white,
        backgroundColor: const Color(0xFFF04438),
        onPressed: () => controller.toggleLeave(context),
      ),
    );
  }
}
