import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import 'im_engine_manager.dart';

class _GroupMemberPageState {
  List<RCIMIWGroupMemberInfo> list = [];

  String pageToken = "";

  bool hasMore = true;

  bool loading = false;
}

class ImGroupMemberManager {
  ImGroupMemberManager._();

  static final ImGroupMemberManager _instance =
  ImGroupMemberManager._();

  factory ImGroupMemberManager() => _instance;

  /// =========================
  /// cache
  /// =========================
  final Map<String, _GroupMemberPageState> _cache = {};

  /// =========================
  /// notifier
  /// =========================
  final Map<
      String,
      ValueNotifier<List<RCIMIWGroupMemberInfo>>>
  _notifiers = {};

  /// =========================
  /// watch
  /// =========================
  ValueNotifier<List<RCIMIWGroupMemberInfo>> watch(
      String groupId,
      ) {
    final state = _getState(groupId);

    return _notifiers.putIfAbsent(
      groupId,
          () => ValueNotifier(
        List.from(state.list),
      ),
    );
  }

  _GroupMemberPageState _getState(
      String groupId,
      ) {
    return _cache.putIfAbsent(
      groupId,
          () => _GroupMemberPageState(),
    );
  }

  /// =========================================================
  /// 获取成员
  /// =========================================================
  Future<List<RCIMIWGroupMemberInfo>> getGroupMembers(
      String groupId, {
        int count = 20,
        bool refresh = false,
      }) async {
    final state = _getState(groupId);

    /// cache first
    if (!refresh && state.list.isNotEmpty) {
      return state.list;
    }

    if (!IMEngineManager()
        .connection
        .isConnected) {
      return [];
    }

    return _request(
      groupId,
      count: count,
      refresh: refresh,
      reset: refresh,
    );
  }

  /// =========================================================
  /// load more
  /// =========================================================
  Future<void> loadMore(
      String groupId, {
        int count = 20,
      }) async {
    final state = _cache[groupId];

    if (state == null ||
        state.loading ||
        !state.hasMore) {
      return;
    }

    await _request(
      groupId,
      count: count,
    );
  }

  /// =========================================================
  /// refresh
  /// =========================================================
  Future<void> refresh(
      String groupId,
      ) async {
    await _request(
      groupId,
      refresh: true,
      reset: true,
    );
  }

  /// =========================================================
  /// 统一请求入口
  /// =========================================================
  Future<List<RCIMIWGroupMemberInfo>>
  _request(
      String groupId, {
        int count = 20,
        bool refresh = false,
        bool reset = false,
      }) async {
    final state = _getState(groupId);

    if (state.loading) {
      return state.list;
    }

    state.loading = true;

    try {
      /// reset
      if (reset) {
        state.pageToken = "";
        state.hasMore = true;
      }

      final option =
      RCIMIWPagingQueryOption.create(
        count: count,
        pageToken: state.pageToken,
        order: false,
      );

      final completer =
      Completer<List<RCIMIWGroupMemberInfo>>();

      await IMEngineManager()
          .engine
          ?.getGroupMembersByRole(
        groupId,
        RCIMIWGroupMemberRole.undef,
        option,
        callback:
        IRCIMIWGetGroupMembersByRoleCallback(
          onSuccess: (info) {
            final data = info?.data ?? [];

            state.pageToken =
                info?.pageToken ?? "";

            state.hasMore =
                data.length >= count;

            final latest = refresh
                ? data
                : _mergeMembers(
              state.list,
              data,
            );

            _updateIfChanged(
              groupId,
              latest,
            );

            completer.complete(latest);
          },
          onError: (_) {
            completer.complete(
              state.list,
            );
          },
        ),
      );

      return completer.future;
    } finally {
      state.loading = false;
    }
  }

  /// =========================================================
  /// merge + deduplicate
  /// =========================================================
  List<RCIMIWGroupMemberInfo>
  _mergeMembers(
      List<RCIMIWGroupMemberInfo> oldList,
      List<RCIMIWGroupMemberInfo> newList,
      ) {
    final map =
    <String, RCIMIWGroupMemberInfo>{};

    for (final item in oldList) {
      map[item.userId ?? ""] = item;
    }

    for (final item in newList) {
      map[item.userId ?? ""] = item;
    }

    return map.values.toList();
  }

  /// =========================================================
  /// update if changed
  /// =========================================================
  void _updateIfChanged(
      String groupId,
      List<RCIMIWGroupMemberInfo> newList,
      ) {
    final notifier = _notifiers[groupId];

    final oldList = notifier?.value ?? [];

    if (_isSameList(oldList, newList)) {
      return;
    }

    final state = _cache[groupId];

    if (state != null) {
      state.list = List.from(newList);
    }

    notifier?.value = List.from(newList);

    debugPrint(
      '群成员更新: $groupId',
    );
  }

  /// =========================================================
  /// diff
  /// =========================================================
  bool _isSameList(
      List<RCIMIWGroupMemberInfo> oldList,
      List<RCIMIWGroupMemberInfo> newList,
      ) {
    if (identical(oldList, newList)) {
      return true;
    }

    if (oldList.length != newList.length) {
      return false;
    }

    for (int i = 0; i < oldList.length; i++) {
      if (oldList[i].userId !=
          newList[i].userId) {
        return false;
      }
    }

    return true;
  }

  /// =========================
  /// has more
  /// =========================
  bool hasMore(String groupId) {
    return _cache[groupId]?.hasMore ??
        false;
  }

  /// =========================
  /// clear
  /// =========================
  void clear(String groupId) {
    _cache.remove(groupId);

    _notifiers[groupId]?.value = [];
  }

  void clearAll() {
    _cache.clear();

    for (final item
    in _notifiers.values) {
      item.value = [];
    }
  }
}