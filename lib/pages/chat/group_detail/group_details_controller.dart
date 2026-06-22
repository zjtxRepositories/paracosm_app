import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/modules/im/group_info_update_builder.dart';
import 'package:paracosm/modules/im/group_ban_state.dart';
import 'package:paracosm/modules/im/group_permission_policy.dart';
import 'package:paracosm/modules/im/listener/group_state_center.dart';
import 'package:paracosm/modules/im/manager/im_conversation_manager.dart';
import 'package:paracosm/modules/im/manager/im_engine_manager.dart';
import 'package:paracosm/modules/im/manager/im_group_manager.dart';
import 'package:paracosm/modules/im/manager/im_message_manager.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/common/app_toast.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../../core/models/custom_message_model.dart';
import '../../../core/models/group_member_model.dart';
import '../../../core/models/group_model.dart';
import '../../../modules/im/listener/im_data_center.dart';
import '../../../modules/im/message/base/im_message.dart';
import '../../../modules/im/message/send/im_sender.dart';
import '../../../widgets/common/app_confirm_dialog.dart';
import '../../../widgets/common/app_loading.dart';
import '../chat_session_args.dart';

class GroupDetailsController extends ChangeNotifier {
  GroupDetailsController(this.args);

  final ChatSessionArgs? args;

  /// 群信息
  GroupModel? group;

  /// 群成员
  List<GroupMemberModel> members = [];

  bool get isMemberMore => members.length > 13;
  GroupPermissionPolicy get permission =>
      GroupPermissionPolicy(groupInfo: group?.info);
  bool get isManager => permission.isManager;
  bool get isOwner => permission.isOwner;

  bool isPinned = false;
  bool isMuted = false;
  StreamSubscription? _groupInfoSub;
  StreamSubscription? _groupMemberSub;

  Future<void> init() async {
    final groupId = args?.targetId;
    if (groupId == null || groupId.isEmpty) {
      return;
    }
    isMuted = args?.isMuted ?? false;
    notifyListeners();

    _loadCachedGroup(groupId);
    _loadCachedMembers(groupId);

    _groupInfoSub = ImDataCenter().groupInfoStream.listen((groupIds) async {
      if (!groupIds.contains(groupId)) return;
      await _fetchGroupInfo(groupId);
    });

    _groupMemberSub = ImDataCenter().groupMemberStream.listen((groupIds) async {
      if (!groupIds.contains(groupId)) return;
      await _fetchGroupMembers(groupId);
    });

    unawaited(_fetchPinned());

    await Future.wait([_fetchGroupInfo(groupId), _fetchGroupMembers(groupId)]);
  }

  @override
  void dispose() {
    _groupInfoSub?.cancel();
    _groupMemberSub?.cancel();
    super.dispose();
  }

  void _loadCachedGroup(String groupId) {
    final groupInfo = GroupStateCenter().getCachedGroup(groupId);
    if (groupInfo == null) return;
    group = GroupModel(info: groupInfo);
    isMuted = isGroupMuteAll(groupInfo);
    notifyListeners();
  }

  void _loadCachedMembers(String groupId) {
    final cached = GroupStateCenter().getMembers(groupId);
    if (cached.isEmpty) return;
    _setMembers(cached);
  }

  Future<void> _fetchGroupInfo(String groupId) async {
    final groupInfo = await GroupStateCenter().getGroup(groupId);

    if (groupInfo == null) {
      return;
    }
    group = GroupModel(info: groupInfo);
    isMuted = isGroupMuteAll(groupInfo);
    notifyListeners();
  }

  Future<void> _fetchGroupMembers(String groupId) async {
    final result = await GroupStateCenter().getGroupMembers(groupId);
    _setMembers(result);
  }

  void _setMembers(List<RCIMIWGroupMemberInfo> result) {
    members = result.map((e) => GroupMemberModel(item: e)).toList();
    notifyListeners();
  }

  List<GroupMemberModel> visibleMembers() {
    return members
        .take(
          (members.length > 13 ? 13 : members.length).clamp(0, members.length),
        )
        .toList();
  }

  void updateLocalGroup(GroupModel updatedGroup) {
    group = updatedGroup;
    isMuted = isGroupMuteAll(updatedGroup.info);
    notifyListeners();
  }

  Future<void> refreshGroupInfo() async {
    final groupId = args?.targetId;
    if (groupId == null || groupId.isEmpty) return;
    await _fetchGroupInfo(groupId);
  }

  Future<void> _fetchPinned() async {
    final targetId = args?.targetId;
    if (targetId == null || targetId.isEmpty) {
      return;
    }
    notifyListeners();
    final isTop = await ImConversationManager().getConversationTopStatus(
      type: args?.conversationType ?? RCIMIWConversationType.private,
      targetId: targetId,
    );
    isPinned = isTop ?? false;
    notifyListeners();
  }

  Future<void> togglePin() async {
    if (args == null) return;
    final isOk = await ImConversationManager().setConversationTopStatus(
      type: args!.conversationType,
      targetId: args!.targetId,
      top: !isPinned,
    );
    if (!isOk) return;
    isPinned = !isPinned;
    notifyListeners();
  }

  Future<void> toggleMute() async {
    if (args == null) return;
    if (!_ensurePermission(permission.canMuteAll)) return;
    final groupId = args!.targetId;
    if (groupId.isEmpty) return;
    final banned = !isMuted;
    final isOk = await ImGroupManager().setGroupBan(
      groupId: groupId,
      banned: banned,
    );
    if (!isOk) {
      notifyListeners();
      return;
    }
    isMuted = banned;
    notifyListeners();
  }

  Future<void> toggleDisband(BuildContext context) async {
    if (!_ensurePermission(permission.canDismissGroup)) return;
    final disbandedText = AppLocalizations.of(context)!.chatGroupDisbanded;
    AppConfirmDialog.show(
      context,
      description: AppLocalizations.of(context)!.chatDisbandGroupConfirm,
      onConfirm: () async {
        context.pop();
        final groupId = args?.targetId;
        if (groupId == null) return;
        AppLoading.show();
        final message = CustomMessage(
          targetId: groupId,
          customMessageType: CustomMessageType.groupDisbanded,
          conversationType: RCIMIWConversationType.group,
        );
        await ImSender.instance.send(message: message);
        final isOk = await ImGroupManager().dismissGroup(groupId);
        AppLoading.dismiss();
        if (isOk) {
          AppToast.show(disbandedText);
        }
        if (!context.mounted) return;
        context.pop();
      },
    );
  }

  Future<void> toggleLeave(BuildContext context) async {
    final leftText = AppLocalizations.of(context)!.chatGroupLeft;
    final leaveFailedText = AppLocalizations.of(context)!.chatLeaveGroupFailed;
    if (permission.canTransferOwner) {
      final nextOwner = members
          .where(
            (member) =>
                (member.item.userId ?? '') != IMEngineManager().currentUserId,
          )
          .firstOrNull;

      if (nextOwner == null) {
        toggleDisband(context);
        return;
      }
      final name = nextOwner.name;
      AppConfirmDialog.show(
        context,
        description: AppLocalizations.of(
          context,
        )!.chatOwnerLeaveTransferConfirm(name),
        onConfirm: () async {
          context.pop();
          final groupId = args?.targetId;
          final newOwnerId = nextOwner.item.userId;
          if (groupId == null || newOwnerId == null || newOwnerId.isEmpty) {
            return;
          }

          AppLoading.show();
          final message = CustomMessage(
            targetId: groupId,
            customMessageType: CustomMessageType.transfer,
            conversationType: RCIMIWConversationType.group,
            userIds: [newOwnerId],
          );
          await ImSender.instance.send(message: message);
          final isOk = await ImGroupManager().transferGroupOwner(
            groupId,
            newOwnerId,
            quitGroup: true,
          );
          AppLoading.dismiss();
          if (isOk) {
            AppToast.show(leftText);
          } else {
            AppToast.show(leaveFailedText);
          }
          if (!context.mounted || !isOk) return;
          context.pop();
        },
      );
      return;
    }
    AppConfirmDialog.show(
      context,
      description: AppLocalizations.of(context)!.chatLeaveGroupConfirm,
      onConfirm: () async {
        context.pop();
        final groupId = args?.targetId;
        if (groupId == null) return;
        AppLoading.show();
        final message = CustomMessage(
          targetId: groupId,
          customMessageType: CustomMessageType.quitGroup,
          conversationType: RCIMIWConversationType.group,
        );
        await ImSender.instance.send(message: message);
        final isOk = await ImGroupManager().quitGroup(groupId);
        AppLoading.dismiss();
        if (isOk) {
          AppToast.show(leftText);
        } else {
          AppToast.show(leaveFailedText);
        }
        if (!context.mounted || !isOk) return;
        context.pop();
      },
    );
  }

  Future<void> updateGroupInfo({String? notice, String? introduction}) async {
    if (!_ensurePermission(permission.canEditGroupInfo)) return;
    final currentGroupInfo = group?.info;
    if (currentGroupInfo == null) return;
    final groupInfo = GroupInfoUpdateBuilder.build(
      groupId: currentGroupInfo.groupId ?? '',
      groupName: currentGroupInfo.groupName ?? '',
      portraitUri: currentGroupInfo.portraitUri,
      introduction: introduction ?? currentGroupInfo.introduction,
      notice: notice ?? currentGroupInfo.notice,
      extProfile: currentGroupInfo.extProfile,
    );
    group?.setNoticeViewed(false);
    final isOk = await ImGroupManager().updateGroupInfo(groupInfo);
    if (!isOk) {
      AppToast.show(AppLocalizations.currentText('common_update_failed'));
      return;
    }
    GroupInfoUpdateBuilder.applyToLocal(
      target: currentGroupInfo,
      update: groupInfo,
    );
    notifyListeners();
  }

  Future<void> clearHistory(BuildContext context) async {
    if (args == null) return;
    final successText = AppLocalizations.of(context)!.chatClearHistorySuccess;
    final failedText = AppLocalizations.of(context)!.chatClearHistoryFailed;
    context.pop();

    final isOk = await ImMessageManager().clearMessages(
      type: args!.conversationType,
      targetId: args!.targetId,
      channelId: args!.channelId,
      timestamp: 0,
    );
    if (isOk) {
      AppToast.show(successText);
    } else {
      AppToast.show(failedText);
    }
  }

  Future<void> inviteUsersToGroup(List<String> userIds) async {
    if (!_ensurePermission(permission.canInviteMembers)) return;
    final groupId = args?.targetId;
    if (groupId == null) return;
    AppLoading.show();
    final result = await ImGroupManager().inviteUsersToGroup(groupId, userIds);
    final message = CustomMessage(
      targetId: groupId,
      customMessageType: CustomMessageType.groupInvited,
      conversationType: RCIMIWConversationType.group,
      userIds: userIds,
    );
    AppLoading.dismiss();
    switch (result.status) {
      case InviteGroupStatus.invited:
        await ImSender.instance.send(message: message);
      case InviteGroupStatus.waitingManagerApproval:
        AppToast.show(
          AppLocalizations.currentText('chat_group_join_waiting_approval'),
        );
      case InviteGroupStatus.waitingInviteeConfirm:
        AppToast.show(
          AppLocalizations.currentText('chat_group_application_wait_invitee'),
        );
      case InviteGroupStatus.failed:
        AppToast.show(AppLocalizations.currentText('chat_invite_failed'));
    }
  }

  Future<void> kickGroupMembers(List<String> userIds) async {
    if (!_ensurePermission(permission.canKickMembers)) return;
    final groupId = args?.targetId;
    if (groupId == null) return;

    AppLoading.show();
    final isOk = await ImGroupManager().kickGroupMembers(groupId, userIds);
    if (!isOk) {
      AppLoading.dismiss();
      AppToast.show(AppLocalizations.currentText('chat_remove_failed'));
      return;
    }
    final message = CustomMessage(
      targetId: groupId,
      customMessageType: CustomMessageType.groupRemoved,
      conversationType: RCIMIWConversationType.group,
      userIds: userIds,
    );
    await ImSender.instance.send(message: message);
    AppLoading.dismiss();
  }

  List<String> currentManagerUserIds() {
    return members
        .where((member) => member.item.role == RCIMIWGroupMemberRole.manager)
        .map((member) => member.item.userId ?? '')
        .where((userId) => userId.isNotEmpty)
        .toList();
  }

  Future<void> updateGroupManagers(List<String> selectedUserIds) async {
    if (!_ensurePermission(permission.canManageManagers)) return;
    final groupId = args?.targetId;
    if (groupId == null) return;

    final selected = selectedUserIds.toSet();
    final current = currentManagerUserIds().toSet();
    final addUserIds = selected.difference(current).toList();
    final removeUserIds = current.difference(selected).toList();

    if (addUserIds.isEmpty && removeUserIds.isEmpty) {
      return;
    }

    AppLoading.show();
    final addOk = await ImGroupManager().addGroupManagers(groupId, addUserIds);
    final removeOk = await ImGroupManager().removeGroupManagers(
      groupId,
      removeUserIds,
    );
    AppLoading.dismiss();

    if (!addOk || !removeOk) {
      AppToast.show(AppLocalizations.currentText('chat_set_manager_failed'));
      return;
    }

    if (addUserIds.isNotEmpty) {
      final message = CustomMessage(
        targetId: groupId,
        customMessageType: CustomMessageType.groupManagerSet,
        conversationType: RCIMIWConversationType.group,
        userIds: addUserIds,
      );
      await ImSender.instance.send(message: message);
    }

    await _fetchGroupMembers(groupId);
    AppToast.show(AppLocalizations.currentText('chat_set_manager_success'));
  }

  Future<void> transferGroupOwner(String newOwnerId) async {
    if (!_ensurePermission(permission.canTransferOwner)) return;
    final groupId = args?.targetId;
    if (groupId == null || groupId.isEmpty || newOwnerId.isEmpty) return;

    AppLoading.show();
    final isOk = await ImGroupManager().transferGroupOwner(
      groupId,
      newOwnerId,
      quitGroup: false,
    );

    if (!isOk) {
      AppLoading.dismiss();
      AppToast.show(AppLocalizations.currentText('chat_transfer_owner_failed'));
      return;
    }

    final message = CustomMessage(
      targetId: groupId,
      customMessageType: CustomMessageType.transfer,
      conversationType: RCIMIWConversationType.group,
      userIds: [newOwnerId],
    );
    await ImSender.instance.send(message: message);
    await Future.wait([_fetchGroupInfo(groupId), _fetchGroupMembers(groupId)]);
    AppLoading.dismiss();
    AppToast.show(AppLocalizations.currentText('chat_transfer_owner_success'));
  }

  bool _ensurePermission(bool allowed) {
    if (allowed) return true;
    AppToast.show(AppLocalizations.currentText('chat_group_no_permission'));
    return false;
  }
}
