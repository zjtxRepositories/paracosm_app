

import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

class GroupMemberModel {
  RCIMIWGroupMemberInfo item;

  GroupMemberModel({
    required this.item,
  });

  String get name {
    final nickname = (item.nickname ?? '').replaceAll(' ', '');
    if (nickname.isNotEmpty) {
      return nickname;
    }
    return item.name ?? '';
  }
}
