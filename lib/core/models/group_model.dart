

import 'dart:math';

import 'package:paracosm/core/models/group_member_model.dart';
import 'package:paracosm/modules/im/manager/im_engine_manager.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import '../../modules/im/listener/group_state_center.dart';

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

  String? get displayName => info.groupName != '[默认]' ? info.groupName : null;

  Future<String> get name async {
    final remark = info.remark;
    if (remark != null && remark.isNotEmpty) {
      return remark;
    }
    final name = info.groupName;
    if (name != null && name.isNotEmpty && name != '[默认]') {
      return name;
    }

    final result = await memberName;
    return result;
  }

  Future<String> get memberName async {
    final memberList = await members;
    if (memberList.isEmpty) return '';
    final List<String> list = [];
    for (final e in memberList) {
      if (e.item.userId == IMEngineManager().currentUserId) continue;
      list.add(e.name);
    }
    return list.join("、");
  }

  Future<List<GroupMemberModel>> get members async {
    final groupId = info.groupId ?? '';

    if (groupId.isEmpty) {
      return [];
    }

    final result = await GroupStateCenter().getGroupMembers(groupId);

    if (result.isEmpty) {
      return [];
    }

    final List<GroupMemberModel> list = result
        .map((e) => GroupMemberModel(item: e))
        .toList();

    /// 群主排第一
    list.sort((a, b) {
      final aIsOwner = a.item.role == RCIMIWGroupMemberRole.owner;
      final bIsOwner = b.item.role == RCIMIWGroupMemberRole.owner;

      if (aIsOwner && !bIsOwner) {
        return -1;
      }

      if (!aIsOwner && bIsOwner) {
        return 1;
      }

      return 0;
    });

    return list;
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