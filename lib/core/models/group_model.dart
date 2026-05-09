

import 'dart:math';

import 'package:paracosm/core/models/group_member_model.dart';
import 'package:paracosm/modules/im/manager/im_engine_manager.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import '../../modules/im/manager/im_group_member_manager.dart';

enum GroupType {
  normal,
  dao,
  club,
}

class GroupModel {
  RCIMIWGroupInfo info;
  String? showName;

  GroupModel({
    required this.info,
  });

  Future<String> get name async {
    final remark = info.remark;
    if (remark != null && remark.isNotEmpty) {
      return remark;
    }
    final name = info.groupName;
    if (name != null && name.isNotEmpty && name != '[默认]') {
      return name;
    }

    final groupId = info.groupId ?? '';
    if (groupId.isEmpty) return '';
    final result = await ImGroupMemberManager().getGroupMembers(groupId);

    final members = result ?? [];
    if (members.isEmpty) return '';
    final List<String> list = [];
    for (final e in members) {
      if (e.userId == IMEngineManager().currentUserId) continue;
      final member = GroupMemberModel(item: e);
      list.add(member.name);
    }
    return list.join("、");
  }

  Future<String> get memberName async {
    final groupId = info.groupId ?? '';
    if (groupId.isEmpty) return '';

    final result = await ImGroupMemberManager().getGroupMembers(groupId);
    final members = result ?? [];
    if (members.isEmpty) return '';
    final List<String> list = [];
    for (final e in members) {
      if (e.userId == IMEngineManager().currentUserId) continue;
      final member = GroupMemberModel(item: e);
      list.add(member.name);
    }
    return list.join("、");
  }

}

String generateGroupId(GroupType type) {
  const chars =
      'abcdefghijklmnopqrstuvwxyz0123456789';

  final random = Random();

  final randomId = List.generate(
    12,
        (_) => chars[random.nextInt(chars.length)],
  ).join();

  return 'group_${type.name}_$randomId';
}

String generateCommunityGroupId(GroupType type,String jid) {
  return 'group_${type.name}_$jid';
}