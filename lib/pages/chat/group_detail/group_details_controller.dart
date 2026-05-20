import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/modules/im/listener/group_state_center.dart';
import 'package:paracosm/modules/im/manager/im_conversation_manager.dart';
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
  bool get isManager =>
      group?.info.role == RCIMIWGroupMemberRole.manager ||
      group?.info.role == RCIMIWGroupMemberRole.owner;

  bool isPinned = false;
  bool isMuted = false;
  StreamSubscription? _groupSub;

  Future<void> init(BuildContext context) async {
    _fetchPinned();

    await _fetchGroupInfo();

    await _fetchGroupMembers();

    _groupSub = ImDataCenter().groupInfoStream.listen((groupIds) async {
      // print('groupInfoStream-------');
      if (!groupIds.contains(group?.info.groupId)) return;
      await _fetchGroupInfo();
      await _fetchGroupMembers();
    });
  }

  @override
  void dispose() {
    _groupSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchGroupInfo() async {
    final groupId = args?.targetId;
    if (groupId == null || groupId.isEmpty) {
      return;
    }

    final groupInfo = await GroupStateCenter().getGroup(groupId);

    if (groupInfo == null) {
      return;
    }
    group = GroupModel(info: groupInfo);
    isMuted = group?.info.groupStatus == RCIMIWGroupStatus.muted;
    notifyListeners();
  }

  Future<void> _fetchGroupMembers() async {
    if (group == null) {
      return;
    }
    members = await group!.members;
    notifyListeners();
  }

  List<GroupMemberModel> visibleMembers() {
    return members
        .take(
          (members.length > 13 ? 13 : members.length).clamp(0, members.length),
        )
        .toList();
  }

  Future<void> _fetchPinned() async {
    final targetId = args?.targetId;
    if (targetId == null || targetId.isEmpty) {
      return;
    }
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
    final groupInfo = group?.info;
    if (groupInfo == null) return;
    groupInfo.groupStatus = !isMuted
        ? RCIMIWGroupStatus.muted
        : RCIMIWGroupStatus.using;
    final isOk = await ImGroupManager().updateGroupInfo(groupInfo);
    if (!isOk) return;
    isMuted = !isMuted;
    notifyListeners();
  }

  Future<void> toggleDisband(BuildContext context) async {
    AppConfirmDialog.show(
      context,
      description: AppLocalizations.of(context)!.chatDisbandGroupConfirm,
      onConfirm: () async {
        context.pop();
        final groupId = args?.targetId;
        if (groupId == null) return;
        AppLoading.show();
        final isOk = await ImGroupManager().dismissGroup(groupId);
        AppLoading.dismiss();
        if (isOk) {
          AppToast.show(AppLocalizations.of(context)!.chatGroupDisbanded);
        }
        if (!context.mounted) return;
        context.pop();
      },
    );
  }

  Future<void> toggleLeave(BuildContext context) async {
    if (group?.info.role == RCIMIWGroupMemberRole.owner) {
      toggleDisband(context);
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
          AppToast.show(AppLocalizations.of(context)!.chatGroupLeft);
        }
        if (!context.mounted) return;
        context.pop();
      },
    );
  }

  Future<void> updateGroupInfo({String? notice, String? introduction}) async {
    final groupInfo = group?.info;
    if (groupInfo == null) return;
    if (notice != null) {
      groupInfo.notice = notice;
    }
    if (introduction != null) {
      groupInfo.introduction = introduction;
    }
    final isOk = await ImGroupManager().updateGroupInfo(groupInfo);
    if (!isOk) {
      AppToast.show(AppLocalizations.currentText('common_update_failed'));
      return;
    }
    notifyListeners();
  }

  Future<void> clearHistory(BuildContext context) async {
    if (args == null) return;
    context.pop();

    final isOk = await ImMessageManager().clearMessages(
      type: args!.conversationType,
      targetId: args!.targetId,
      channelId: args!.channelId,
      timestamp: 0,
    );
    if (isOk) {
      AppToast.show(AppLocalizations.of(context)!.chatClearHistorySuccess);
    } else {
      AppToast.show(AppLocalizations.of(context)!.chatClearHistoryFailed);
    }
  }

  Future<void> inviteUsersToGroup(List<String> userIds) async {
    final groupId = args?.targetId;
    if (groupId == null) return;
    AppLoading.show();
    final isOk = await ImGroupManager().inviteUsersToGroup(groupId, userIds);
    if (!isOk) {
      AppLoading.dismiss();
      AppToast.show(AppLocalizations.currentText('chat_invite_failed'));
      return;
    }
    final message = CustomMessage(
      targetId: groupId,
      customMessageType: CustomMessageType.groupInvited,
      conversationType: RCIMIWConversationType.group,
      userIds: userIds,
    );
    await ImSender.instance.send(message: message);
    AppLoading.dismiss();
  }

  Future<void> kickGroupMembers(List<String> userIds) async {
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
}
