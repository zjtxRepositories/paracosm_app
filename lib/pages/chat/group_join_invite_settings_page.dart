import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/core/models/group_model.dart';
import 'package:paracosm/modules/im/group_info_update_builder.dart';
import 'package:paracosm/modules/im/group_permission_policy.dart';
import 'package:paracosm/modules/im/listener/group_state_center.dart';
import 'package:paracosm/modules/im/manager/im_group_manager.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_button.dart';
import 'package:paracosm/widgets/common/app_checkbox.dart';
import 'package:paracosm/widgets/common/app_loading.dart';
import 'package:paracosm/widgets/common/app_toast.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

class GroupJoinInviteSettingsPage extends StatefulWidget {
  const GroupJoinInviteSettingsPage({super.key, required this.group});

  final GroupModel group;

  @override
  State<GroupJoinInviteSettingsPage> createState() =>
      _GroupJoinInviteSettingsPageState();
}

class _GroupJoinInviteSettingsPageState
    extends State<GroupJoinInviteSettingsPage> {
  late GroupModel _group;
  late RCIMIWGroupJoinPermission _joinPermission;
  late RCIMIWGroupInviteHandlePermission _inviteHandlePermission;

  bool get _canManage {
    return GroupPermissionPolicy(groupInfo: _group.info).canTransferOwner;
  }

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _joinPermission = _visibleJoinPermission(_group.info.joinPermission);
    _inviteHandlePermission =
        _group.info.inviteHandlePermission ??
        RCIMIWGroupInviteHandlePermission.free;
  }

  RCIMIWGroupJoinPermission _visibleJoinPermission(
    RCIMIWGroupJoinPermission? permission,
  ) {
    switch (permission) {
      case RCIMIWGroupJoinPermission.free:
        return RCIMIWGroupJoinPermission.free;
      case RCIMIWGroupJoinPermission.ownerverify:
      case RCIMIWGroupJoinPermission.ownerormanagerverify:
      case RCIMIWGroupJoinPermission.nooneallowed:
        return RCIMIWGroupJoinPermission.ownerverify;
      case null:
        return RCIMIWGroupJoinPermission.free;
    }
  }

  Future<void> _save() async {
    if (!_canManage) {
      AppToast.show(AppLocalizations.currentText('chat_group_no_permission'));
      return;
    }
    final groupId = _group.info.groupId ?? '';
    if (groupId.isEmpty) return;

    FocusScope.of(context).unfocus();
    AppLoading.show();
    try {
      final update = GroupInfoUpdateBuilder.buildPermissionUpdate(
        groupId: groupId,
        groupName: _group.info.groupName ?? '',
        portraitUri: _group.info.portraitUri,
        introduction: _group.info.introduction,
        notice: _group.info.notice,
        extProfile: _group.info.extProfile,
        joinPermission: _joinPermission,
        removeMemberPermission:
            _group.info.removeMemberPermission ??
            RCIMIWGroupOperationPermission.ownerormanager,
        invitePermission:
            _group.info.invitePermission ??
            RCIMIWGroupOperationPermission.everyone,
        inviteHandlePermission: _inviteHandlePermission,
        groupInfoEditPermission:
            _group.info.groupInfoEditPermission ??
            RCIMIWGroupOperationPermission.ownerormanager,
        memberInfoEditPermission:
            _group.info.memberInfoEditPermission ??
            RCIMIWGroupMemberInfoEditPermission.ownerorself,
      );
      final isOk = await ImGroupManager().updateGroupInfo(update);
      if (!mounted) return;
      if (!isOk) {
        AppToast.show(AppLocalizations.of(context)!.commonUpdateFailed);
        return;
      }
      GroupInfoUpdateBuilder.applyPermissionToLocal(
        target: _group.info,
        update: update,
      );
      final refreshed = await _fetchUpdatedGroup(
        groupId: groupId,
        joinPermission: _joinPermission,
        inviteHandlePermission: _inviteHandlePermission,
      );
      if (refreshed != null) {
        _group = GroupModel(info: refreshed);
      }
      if (!mounted) return;
      if (_group.info.joinPermission != _joinPermission ||
          _group.info.inviteHandlePermission != _inviteHandlePermission) {
        AppToast.show(AppLocalizations.of(context)!.commonUpdateFailed);
        return;
      }
      AppToast.show(AppLocalizations.of(context)!.commonUpdateSuccess);
      context.pop(_group);
    } finally {
      AppLoading.dismiss();
    }
  }

  Future<RCIMIWGroupInfo?> _fetchUpdatedGroup({
    required String groupId,
    required RCIMIWGroupJoinPermission joinPermission,
    required RCIMIWGroupInviteHandlePermission inviteHandlePermission,
  }) async {
    RCIMIWGroupInfo? latest;
    for (var i = 0; i < 5; i++) {
      latest = await GroupStateCenter().getGroup(groupId, forceRefresh: true);
      if (latest?.joinPermission == joinPermission &&
          latest?.inviteHandlePermission == inviteHandlePermission) {
        return latest;
      }
      if (i < 4) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    return latest;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppPage(
      title: l10n.chatGroupJoinInviteSettings,
      backgroundColor: Colors.white,
      showNavBorder: true,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                _buildSectionTitle(l10n.chatGroupJoinPermission),
                _buildJoinOption(
                  l10n.chatGroupJoinFree,
                  RCIMIWGroupJoinPermission.free,
                ),
                _buildJoinOption(
                  l10n.chatGroupJoinOwnerVerify,
                  RCIMIWGroupJoinPermission.ownerverify,
                ),
                const SizedBox(height: 24),
                _buildSectionTitle(l10n.chatGroupInviteConfirmation),
                _buildInviteOption(
                  l10n.chatGroupInviteFree,
                  RCIMIWGroupInviteHandlePermission.free,
                ),
                _buildInviteOption(
                  l10n.chatGroupInviteNeedConfirm,
                  RCIMIWGroupInviteHandlePermission.inviteeverify,
                  isLast: true,
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: AppButton(text: l10n.commonSave, onPressed: _save),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.grey400,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildJoinOption(
    String title,
    RCIMIWGroupJoinPermission value, {
    bool isLast = false,
  }) {
    return _buildOption(
      title: title,
      selected: _joinPermission == value,
      isLast: isLast,
      onTap: () => setState(() => _joinPermission = value),
    );
  }

  Widget _buildInviteOption(
    String title,
    RCIMIWGroupInviteHandlePermission value, {
    bool isLast = false,
  }) {
    return _buildOption(
      title: title,
      selected: _inviteHandlePermission == value,
      isLast: isLast,
      onTap: () => setState(() => _inviteHandlePermission = value),
    );
  }

  Widget _buildOption({
    required String title,
    required bool selected,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border(
            bottom: isLast
                ? BorderSide.none
                : const BorderSide(color: AppColors.grey100),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.body.copyWith(color: AppColors.grey900),
              ),
            ),
            AppCheckbox(value: selected, isRadio: true, size: 20),
          ],
        ),
      ),
    );
  }
}
