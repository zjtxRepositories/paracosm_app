

import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../modules/im/manager/im_group_member_manager.dart';

class GroupModel {
  RCIMIWGroupInfo info;

  GroupModel({
    required this.info,
  });

  Future<String> get name async {
    final remark = info.remark;
    if (remark != null && remark.isNotEmpty) {
      return remark;
    }
    final name = info.groupName;
    if (name != null && name.isNotEmpty) {
      return name;
    }

    final groupId = info.groupId ?? '';
    if (groupId.isEmpty) return '';
    final result = await ImGroupMemberManager().getGroupMembers(groupId);
    final members = result ?? [];
    if (members.isEmpty) return '';
    List<String> list = members
        .map((e) => e.nickname ?? e.name ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
    return list.join("、");
  }
}
