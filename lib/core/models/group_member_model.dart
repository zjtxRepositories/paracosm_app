

import 'package:paracosm/modules/im/listener/user_display_state_center.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

class GroupMemberModel {
  RCIMIWGroupMemberInfo item;

  GroupMemberModel({
    required this.item,
  });

  String get name {
    final user = UserDisplayStateCenter().getDisplayModel(item.userId ?? '');
    final remark = user.friend?.remark ?? '';
    if (remark.isNotEmpty) return remark;
    final nickname = (item.nickname ?? '').replaceAll(' ', '');
    if (nickname.isNotEmpty) {
      return nickname;
    }
    return item.name ?? '';
  }
}
