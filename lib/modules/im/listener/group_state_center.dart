import 'dart:collection';

import 'package:paracosm/modules/im/manager/im_group_member_manager.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../manager/im_group_manager.dart';

class GroupStateCenter {
  GroupStateCenter._();

  static final GroupStateCenter _instance = GroupStateCenter._();

  factory GroupStateCenter() => _instance;

  /// =====================================================
  /// cache
  /// =====================================================

  final Map<String, RCIMIWGroupInfo> _groupCache = {};

  final Map<String, List<RCIMIWGroupMemberInfo>> _memberCache = {};

  /// =====================================================
  /// pending
  /// =====================================================

  final Map<String, Future<RCIMIWGroupInfo?>> _pendingGroup = {};

  final Map<String, Future<List<RCIMIWGroupMemberInfo>>> _pendingMembers = {};

  /// =====================================================
  /// generation
  /// clear/logout 后防止旧请求回写
  /// =====================================================

  int _generation = 0;

  Future<void> refreshGroup(String groupId) async {
    getGroup(groupId, forceRefresh: true);
    getGroupMembers(groupId, forceRefresh: true);
  }

  /// =====================================================
  /// get group
  /// =====================================================

  Future<RCIMIWGroupInfo?> getGroup(
    String groupId, {
    bool forceRefresh = false,
  }) async {
    if (groupId.isEmpty) {
      return null;
    }

    if (!forceRefresh) {
      final cached = _groupCache[groupId];

      if (cached != null) {
        return cached;
      }
    }

    if (forceRefresh) {
      _pendingGroup.remove(groupId);
    }

    return _pendingGroup[groupId] ??= _fetchGroup(groupId);
  }

  /// =====================================================
  /// get members
  /// =====================================================

  Future<List<RCIMIWGroupMemberInfo>> getGroupMembers(
    String groupId, {
    bool forceRefresh = false,
  }) async {
    if (groupId.isEmpty) {
      return [];
    }

    if (!forceRefresh) {
      final cached = _memberCache[groupId];

      if (cached != null) {
        return cached;
      }
    }

    if (forceRefresh) {
      _pendingMembers.remove(groupId);
    }

    return _pendingMembers[groupId] ??= _fetchGroupMembers(groupId);
  }

  /// =====================================================
  /// fetch group
  /// =====================================================

  Future<RCIMIWGroupInfo?> _fetchGroup(String groupId) async {
    final generation = _generation;

    try {
      final result = await ImGroupManager().getGroupsInfo([groupId]);

      /// clear/logout 后旧请求失效
      if (generation != _generation) {
        return null;
      }

      final group = result?.first;

      if (group == null) {
        return null;
      }

      _groupCache[groupId] = group;

      return group;
    } catch (_) {
      rethrow;
    } finally {
      _pendingGroup.remove(groupId);
    }
  }

  /// =====================================================
  /// fetch members
  /// =====================================================

  Future<List<RCIMIWGroupMemberInfo>> _fetchGroupMembers(String groupId) async {
    final generation = _generation;

    try {
      final result = await ImGroupMemberManager().getGroupMembers(groupId);

      /// clear/logout 后旧请求失效
      if (generation != _generation) {
        return [];
      }

      final immutable = _sortedMembers(result);

      _memberCache[groupId] = immutable;

      return immutable;
    } catch (_) {
      rethrow;
    } finally {
      _pendingMembers.remove(groupId);
    }
  }

  /// =====================================================
  /// update group
  /// =====================================================

  void updateGroupInfo(RCIMIWGroupInfo info) {
    final groupId = info.groupId;

    if (groupId == null || groupId.isEmpty) {
      return;
    }

    _groupCache[groupId] = info;
  }

  /// =====================================================
  /// update members
  /// =====================================================

  void updateMembers(String groupId, List<RCIMIWGroupMemberInfo> members) {
    _memberCache[groupId] = _sortedMembers(members);
  }

  /// =====================================================
  /// patch member profile
  /// =====================================================
  void patchMemberProfile({
    required String userId,
    String? name,
    String? portrait,
  }) {
    if (userId.isEmpty) {
      return;
    }

    final newCache = <String, List<RCIMIWGroupMemberInfo>>{};

    for (final entry in _memberCache.entries) {
      final groupId = entry.key;

      final list = entry.value;

      final newList = <RCIMIWGroupMemberInfo>[];

      for (final item in list) {
        if (item.userId != userId) {
          newList.add(item);
          continue;
        }

        /// clone
        final json = item.toJson();

        if (name != null) {
          json['name'] = name;
        }

        if (portrait != null) {
          json['portraitUri'] = portrait;
        }

        final newItem = RCIMIWGroupMemberInfo.fromJson(json);

        newList.add(newItem);
      }

      newCache[groupId] = _sortedMembers(newList);
    }

    _memberCache
      ..clear()
      ..addAll(newCache);
  }

  /// =====================================================
  /// remove group
  /// =====================================================

  void removeGroup(String groupId) {
    _groupCache.remove(groupId);

    _memberCache.remove(groupId);

    _pendingGroup.remove(groupId);

    _pendingMembers.remove(groupId);
  }

  void removeMembers(String groupId) {
    _memberCache.remove(groupId);

    _pendingMembers.remove(groupId);
  }

  /// =====================================================
  /// preload groups
  /// =====================================================

  Future<void> preloadGroups(List<String> groupIds) async {
    final tasks = groupIds.where((e) => e.isNotEmpty).map((e) => getGroup(e));

    await Future.wait(tasks);
  }

  /// =====================================================
  /// preload members
  /// =====================================================

  Future<void> preloadMembers(List<String> groupIds) async {
    final tasks = groupIds
        .where((e) => e.isNotEmpty)
        .map((e) => getGroupMembers(e));

    await Future.wait(tasks);
  }

  /// =====================================================
  /// getter
  /// =====================================================

  RCIMIWGroupInfo? getCachedGroup(String groupId) {
    return _groupCache[groupId];
  }

  List<RCIMIWGroupMemberInfo> getMembers(String groupId) {
    return _memberCache[groupId] ?? const [];
  }

  bool containsGroup(String groupId) {
    return _groupCache.containsKey(groupId);
  }

  bool containsMembers(String groupId) {
    return _memberCache.containsKey(groupId);
  }

  /// =====================================================
  /// snapshot
  /// =====================================================

  Map<String, RCIMIWGroupInfo> snapshotGroup() {
    return UnmodifiableMapView(_groupCache);
  }

  Map<String, List<RCIMIWGroupMemberInfo>> snapshotMember() {
    return UnmodifiableMapView({
      for (final e in _memberCache.entries)
        e.key: List<RCIMIWGroupMemberInfo>.unmodifiable(e.value),
    });
  }

  /// =====================================================
  /// clear
  /// =====================================================

  void clear() {
    /// 所有旧请求失效
    _generation++;

    _groupCache.clear();

    _memberCache.clear();

    _pendingGroup.clear();

    _pendingMembers.clear();
  }

  List<RCIMIWGroupMemberInfo> _sortedMembers(
    List<RCIMIWGroupMemberInfo> members,
  ) {
    final sorted = List<RCIMIWGroupMemberInfo>.of(members)
      ..sort((a, b) => _roleWeight(a.role).compareTo(_roleWeight(b.role)));

    return List<RCIMIWGroupMemberInfo>.unmodifiable(sorted);
  }

  int _roleWeight(RCIMIWGroupMemberRole? role) {
    switch (role) {
      case RCIMIWGroupMemberRole.owner:
        return 0;
      case RCIMIWGroupMemberRole.manager:
        return 1;
      default:
        return 2;
    }
  }
}
