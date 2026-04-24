

import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

class FriendModel {
  RCIMIWFriendInfo info;

  FriendModel({
    required this.info,
  });

  String get name {
    final remark = info.remark;
    if (remark != null && remark.isNotEmpty) {
      return remark;
    }
    final name = info.name;
    if (name != null && name.isNotEmpty) {
      return name;
    }

    final userId = info.userId ?? '';
    if (userId.isEmpty) return '';

    return userId.length > 8
        ? userId.substring(userId.length - 8)
        : userId;
  }
}
