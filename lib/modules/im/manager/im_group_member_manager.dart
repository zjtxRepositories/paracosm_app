import 'dart:async';

import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../listener/im_data_center.dart';
import 'im_engine_manager.dart';
import 'im_group_manager.dart';

class _GroupMemberPageState {
  String pageToken = "";

  bool hasMore = true;

  bool loading = false;
}

class ImGroupMemberManager {
  ImGroupMemberManager._();

  static const int _syncingCode = 34329;
  static const Duration _syncingRetryDelay = Duration(milliseconds: 800);

  static final ImGroupMemberManager _instance = ImGroupMemberManager._();

  factory ImGroupMemberManager() => _instance;

  /// =========================
  /// 分页状态
  /// =========================
  final Map<String, _GroupMemberPageState> _cache = {};

  _GroupMemberPageState _getState(String groupId) {
    return _cache.putIfAbsent(groupId, () => _GroupMemberPageState());
  }

  /// =========================================================
  /// 获取群成员
  /// =========================================================
  Future<List<RCIMIWGroupMemberInfo>> getGroupMembers(
    String groupId, {
    int count = 20,
  }) async {
    if (!IMEngineManager().connection.isConnected) {
      throw '';
    }
    _cache.remove(groupId);

    return _request(groupId, count: count);
  }

  /// =========================================================
  /// 请求
  /// =========================================================
  Future<List<RCIMIWGroupMemberInfo>> _request(
    String groupId, {
    int count = 20,
    bool retryOnSyncing = true,
  }) async {
    final state = _getState(groupId);

    final oldList = ImDataCenter().getGroupMembers(groupId);

    if (state.loading) {
      return oldList;
    }

    state.loading = true;

    try {
      final option = RCIMIWPagingQueryOption.create(
        count: count,
        pageToken: state.pageToken,
        order: false,
      );

      final completer = Completer<List<RCIMIWGroupMemberInfo>>();

      await IMEngineManager().engine?.getGroupMembersByRole(
        groupId,
        RCIMIWGroupMemberRole.undef,
        option,
        callback: IRCIMIWGetGroupMembersByRoleCallback(
          onSuccess: (info) {
            final data = info?.data ?? [];

            state.pageToken = info?.pageToken ?? "";

            state.hasMore = data.length >= count;

            ImDataCenter().setGroupMembers(groupId, data);
            completer.complete(data);
          },
          onError: (int? code) async {
            if (code == 25418 || code == 25410) {
              GroupEventBus.instance.fire(
                GroupEvent(
                  type: GroupEventType.quit,
                  groupId: groupId,
                  operatorUserId: IMEngineManager().currentUserId,
                ),
              );
            }
            if (code == _syncingCode && retryOnSyncing) {
              await Future.delayed(_syncingRetryDelay);
              state.loading = false;
              final result = await _request(
                groupId,
                count: count,
                retryOnSyncing: false,
              );
              if (!completer.isCompleted) {
                completer.complete(result);
              }
              return;
            }
            if (!completer.isCompleted) {
              completer.complete(oldList);
            }
          },
        ),
      );

      return completer.future;
    } finally {
      state.loading = false;
    }
  }

  /// =========================================================
  /// 加载更多
  /// =========================================================
  Future<void> loadMore(String groupId, {int count = 20}) async {
    final state = _cache[groupId];

    if (state == null || state.loading || !state.hasMore) {
      return;
    }

    await _request(groupId, count: count);
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

    ImDataCenter().removeGroupMembers(groupId);
  }

  /// =========================================================
  /// dispose
  /// =========================================================
  void dispose() {
    _cache.clear();
  }
}
