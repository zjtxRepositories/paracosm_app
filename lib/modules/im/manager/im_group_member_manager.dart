import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import 'im_engine_manager.dart';

class ImGroupMemberManager {

  /// =========================
  /// 分页获取群成员信息
  /// =========================
  Future<List<RCIMIWGroupMemberInfo>?> getGroupMembers(String groupId) async {
    final completer = Completer<List<RCIMIWGroupMemberInfo>?>();
    RCIMIWPagingQueryOption option = RCIMIWPagingQueryOption.create(
      count: 9,
      pageToken: "",
      order: false,  // 按加入群组时间正序、倒序获取。true：正序；false：倒序
    );
    final ret = await IMEngineManager().engine?.getGroupMembersByRole(
      groupId,
      RCIMIWGroupMemberRole.undef,
      option,
      callback: IRCIMIWGetGroupMembersByRoleCallback(
        onSuccess: (info) {
          completer.complete(info?.data);
        },
        onError: (code) {
          completer.complete(null);
        },
      ),
    );

    if (ret != null && ret != 0) return null;

    return completer.future;
  }

}