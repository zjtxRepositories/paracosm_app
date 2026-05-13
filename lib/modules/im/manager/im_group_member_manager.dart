import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import 'im_engine_manager.dart';
import '../listener/im_data_center.dart';

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
  /// Stream Controller（核心新增）
  /// =========================
  final StreamController<
      Map<String, List<RCIMIWGroupMemberInfo>>> _controller =
  StreamController.broadcast();

  Stream<Map<String, List<RCIMIWGroupMemberInfo>>> get stream =>
      _controller.stream;

  /// =========================
  /// state getter
  /// =========================
  _GroupMemberPageState _getState(String groupId) {
    return _cache.putIfAbsent(
      groupId,
          () => _GroupMemberPageState(),
    );
  }

  /// =========================================================
  /// 订阅UI（Stream版本）
  /// =========================================================
  ValueNotifier<List<RCIMIWGroupMemberInfo>> watch(
      String groupId,
      ) {
    final state = _getState(groupId);

    final notifier = ValueNotifier<List<RCIMIWGroupMemberInfo>>(
      List.from(state.list),
    );

    /// 👇 同步 stream 更新到 notifier（可选）
    stream.listen((map) {
      final list = map[groupId];
      if (list != null) {
        notifier.value = List.from(list);
      }
    });

    return notifier;
  }

  /// =========================================================
  /// request
  /// =========================================================
  Future<List<RCIMIWGroupMemberInfo>> getGroupMembers(
      String groupId, {
        int count = 20,
        bool refresh = false,
      }) async {
    final state = _getState(groupId);

    if (!refresh && state.list.isNotEmpty) {
      return state.list;
    }

    if (!IMEngineManager().connection.isConnected) {
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
  /// request core
  /// =========================================================
  Future<List<RCIMIWGroupMemberInfo>> _request(
      String groupId, {
        int count = 20,
        bool refresh = false,
        bool reset = false,
      }) async {
    final state = _getState(groupId);

    if (state.loading) return state.list;

    state.loading = true;

    try {
      if (reset) {
        state.pageToken = "";
        state.hasMore = true;
      }

      final option = RCIMIWPagingQueryOption.create(
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

            state.pageToken = info?.pageToken ?? "";
            state.hasMore = data.length >= count;

            final latest = refresh
                ? data
                : _merge(state.list, data);

            state.list = latest;

            _emit(groupId, latest);

            completer.complete(latest);
          },
          onError: (_) {
            completer.complete(state.list);
          },
        ),
      );

      return completer.future;
    } finally {
      state.loading = false;
    }
  }

  /// =========================================================
  /// merge
  /// =========================================================
  List<RCIMIWGroupMemberInfo> _merge(
      List<RCIMIWGroupMemberInfo> oldList,
      List<RCIMIWGroupMemberInfo> newList,
      ) {
    final map = <String, RCIMIWGroupMemberInfo>{};

    for (final item in oldList) {
      map[item.userId ?? ""] = item;
    }

    for (final item in newList) {
      map[item.userId ?? ""] = item;
    }

    return map.values.toList();
  }

  /// =========================================================
  /// emit single group
  /// =========================================================
  void _emit(
      String groupId,
      List<RCIMIWGroupMemberInfo> list,
      ) {
    if (!_controller.isClosed) {
      _controller.add({groupId: List.from(list)});
    }
  }

  /// =========================================================
  /// emit all (profile change use)
  /// =========================================================
  void _emitAll() {
    if (_controller.isClosed) return;

    final map = <String, List<RCIMIWGroupMemberInfo>>{};

    _cache.forEach((key, value) {
      map[key] = List.from(value.list);
    });

    _controller.add(map);

    debugPrint('群成员因用户资料更新刷新');
  }

  /// =========================================================
  /// load more / refresh
  /// =========================================================
  Future<void> loadMore(String groupId, {int count = 20}) async {
    final state = _cache[groupId];

    if (state == null || state.loading || !state.hasMore) {
      return;
    }

    await _request(groupId, count: count);
  }

  Future<void> refresh(String groupId) async {
    await _request(
      groupId,
      refresh: true,
      reset: true,
    );
  }

  /// =========================================================
  /// dispose
  /// =========================================================
  void dispose() {
    _controller.close();
  }

  /// =========================================================
  /// hasMore
  /// =========================================================
  bool hasMore(String groupId) {
    return _cache[groupId]?.hasMore ?? false;
  }

  /// =========================================================
  /// clear
  /// =========================================================
  void clear(String groupId) {
    _cache.remove(groupId);

    if (!_controller.isClosed) {
      _controller.add({groupId: []});
    }
  }
}