import 'dart:async';
import 'dart:collection';

import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../manager/im_group_manager.dart';

class GroupStateCenter {
  GroupStateCenter._();

  static final GroupStateCenter _instance = GroupStateCenter._();
  factory GroupStateCenter() => _instance;

  /// =========================
  /// cache
  /// =========================
  final Map<String, RCIMIWGroupInfo> _groupCache = {};
  final Map<String, List<RCIMIWGroupMemberInfo>> _memberCache = {};

  /// =========================
  /// pending (防重复请求)
  /// =========================
  final Map<String, Future<RCIMIWGroupInfo?>> _pendingGroup = {};

  /// =========================
  /// version（防乱序覆盖）
  /// =========================
  final Map<String, int> _version = {};

  // -------------------------
  // get group
  // -------------------------
  Future<RCIMIWGroupInfo?> getGroup(
      String groupId, {
        bool forceRefresh = false,
      }) async {
    if (!forceRefresh && _groupCache.containsKey(groupId)) {
      return _groupCache[groupId];
    }

    return _pendingGroup[groupId] ??= _fetchGroup(groupId);
  }

  // -------------------------
  // fetch group
  // -------------------------
  Future<RCIMIWGroupInfo?> _fetchGroup(String groupId) async {
    final version = (_version[groupId] ?? 0) + 1;
    _version[groupId] = version;

    final result = await ImGroupManager().getGroupsInfo([groupId]);
    final group = result?.first;
    if (group == null) return null;

    /// 防乱序覆盖
    if (version >= (_version[groupId] ?? 0)) {
      _groupCache[groupId] = group;
    }

    _pendingGroup.remove(groupId);
    return group;
  }

  // -------------------------
  // event update（IM push）
  // -------------------------
  void updateGroupInfo(RCIMIWGroupInfo info) {
    final groupId = info.groupId ?? '';
    if (groupId.isEmpty) return;

    _groupCache[groupId] = info;
  }

  // -------------------------
  // member update
  // -------------------------
  void updateMembers(
      String groupId,
      List<RCIMIWGroupMemberInfo> members,
      ) {
    _memberCache[groupId] =
        members.map((e) => e).toList(growable: false);
  }


  // -------------------------
  // getter
  // -------------------------
  RCIMIWGroupInfo? getCachedGroup(String id) => _groupCache[id];

  List<RCIMIWGroupMemberInfo> getMembers(String id) =>
      _memberCache[id] ?? [];

  // -------------------------
  // snapshot
  // -------------------------
  Map<String, RCIMIWGroupInfo> snapshotGroup() =>
      UnmodifiableMapView(_groupCache);

  Map<String, List<RCIMIWGroupMemberInfo>> snapshotMember() =>
      UnmodifiableMapView(_memberCache);
}