import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/modules/im/manager/im_conversation_manager.dart';
import 'package:paracosm/modules/im/manager/im_group_manager.dart';
import 'package:paracosm/modules/im/manager/im_message_manager.dart';
import 'package:paracosm/widgets/common/app_toast.dart';
import 'package:path/path.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../../core/models/group_member_model.dart';
import '../../../core/models/group_model.dart';
import '../chat_session_args.dart';

class GroupDetailsController extends ChangeNotifier {
  GroupDetailsController(this.args);

  final ChatSessionArgs? args;

  /// 群信息
  GroupModel? group;

  /// 群成员
  List<GroupMemberModel> members = [];

  bool get isMemberMore => members.length > 13;
  bool get isGroup => args?.isGroup ?? false;
  bool get isManager => group?.info.role == RCIMIWGroupMemberRole.manager || group?.info.role == RCIMIWGroupMemberRole.owner ;

  bool isPinned = false;
  bool isMuted = false;
  late final StreamSubscription sub;

  Future<void> init(BuildContext context) async {
    if (!isGroup) return;

    await _fetchGroupInfo();

    await _fetchGroupMembers();

    sub = GroupEventBus.instance.stream.listen(
          (event) {
        if (event.groupId != group?.info.groupId) {
          return;
        }

        switch (event.type) {
          case GroupEventType.quit:
          case GroupEventType.dismissed:
          context.go('/chat');
          break;

          case GroupEventType.joined:
          case GroupEventType.memberChanged:
            _fetchGroupMembers();
            break;

          case GroupEventType.infoChanged:
            _fetchGroupInfo();
            break;

          default:
            break;
        }
      },
    );
  }

  @override
  void dispose() {
    sub.cancel();
    super.dispose();
  }

  Future<void> _fetchGroupInfo() async {
    final groupId = args?.targetId;
    if (groupId == null || groupId.isEmpty) {
      return;
    }

    final groups = await ImGroupManager()
        .getGroupsInfo([groupId]);

    if (groups == null || groups.isEmpty) {
      return;
    }

    group = GroupModel(info: groups.first);

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
        .take((members.length > 13 ? 13 : members.length).clamp(0, members.length))
        .toList();
  }


  Future<void> togglePin() async {
    if (args == null) return;
    final isOk = await ImConversationManager().setConversationTopStatus(
        type: args!.conversationType,
        targetId: args!.targetId,
        top: !isPinned
    );
    if (!isOk) return;
    isPinned = !isPinned;
    notifyListeners();
  }

  void toggleMute() {
    isMuted = !isMuted;
    notifyListeners();
  }

  Future<void> toggleDisband(BuildContext context) async {
    final groupId = args?.targetId;
    if (groupId == null) return;
    final isOk = await ImGroupManager().dismissGroup(groupId);
    if (isOk){
      AppToast.show('群已解散！');
    }
  }

  Future<void> toggleLeave(BuildContext context) async {
    if (group?.info.role == RCIMIWGroupMemberRole.owner){
      toggleDisband(context);
      return;
    }
    final groupId = args?.targetId;
    if (groupId == null) return;
    final isOk = await ImGroupManager().quitGroup(groupId);
    if (isOk){
      AppToast.show('已退出群！');
    }
  }

  Future<void> updateGroupInfo({String? notice, String? introduction}) async {
    final groupInfo = group?.info;
    if (groupInfo == null) return;
    if (notice != null){
      groupInfo.notice = notice;
    }
    if (introduction != null){
      groupInfo.introduction = introduction;
    }
    final isOk = await ImGroupManager().updateGroupInfo(
        groupInfo
    );
    if (!isOk){
      AppToast.show('更新失败！');
      return;
    }
    notifyListeners();
  }

  Future<void> clearHistory(BuildContext context) async {
    if (args == null) return;
    final isOk = await ImMessageManager().clearMessages(
        type: args!.conversationType,
        targetId: args!.targetId,
        timestamp: 0
    );
    if (isOk){
      AppToast.show('已清空聊天记录');
    }
  }
}