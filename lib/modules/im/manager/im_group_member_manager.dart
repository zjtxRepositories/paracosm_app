import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../listener/im_data_center.dart';
import 'im_engine_manager.dart';
import 'im_group_manager.dart';

class _GroupMemberPageState {
  String pageToken = "";

  bool hasMore = true;

  bool loading = false;
}

class _GroupMembersPageResult {
  final RCIMIWPagingQueryResult<RCIMIWGroupMemberInfo>? info;
  final int? errorCode;

  _GroupMembersPageResult({this.info, this.errorCode});
}

class ImGroupMemberManager {
  ImGroupMemberManager._();

  static const int _syncingCode = 34329;
  static const Duration _syncingRetryDelay = Duration(milliseconds: 800);
  static const int _maxRetryCount = 3;

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
    int retryCount = 0,
  }) async {
    final state = _getState(groupId);

    final oldList = ImDataCenter().getGroupMembers(groupId);

    if (state.loading) {
      return oldList;
    }

    state.loading = true;

    try {
      final engine = IMEngineManager().engine;
      if (engine == null) {
        return oldList;
      }

      var attempt = retryCount;

      while (true) {
        final pageToken = state.pageToken;
        final result = await _fetchPage(
          engine: engine,
          groupId: groupId,
          count: count,
          pageToken: pageToken,
        );

        final errorCode = result.errorCode;
        if (errorCode != null) {
          if (errorCode == 25418 || errorCode == 25410) {
            _notifyCurrentUserQuit(groupId);
          }

          if (errorCode == _syncingCode && attempt < _maxRetryCount) {
            attempt++;
            await _delayBeforeRetry(groupId, attempt, 'syncing');
            continue;
          }

          return oldList;
        }

        final info = result.info;
        final data = info?.data ?? [];
        if (_shouldRetryPage(
          data: data,
          totalCount: info?.totalCount,
          pageToken: pageToken,
        )) {
          if (attempt < _maxRetryCount) {
            attempt++;
            await _delayBeforeRetry(groupId, attempt, 'empty-data');
            continue;
          }

          debugPrint(
            '获取群成员异常数据重试已达上限: '
            'groupId=$groupId totalCount=${info?.totalCount} data=${data.length}',
          );
          return oldList;
        }

        state.pageToken = info?.pageToken ?? "";

        state.hasMore = data.length >= count;

        ImDataCenter().setGroupMembers(groupId, data);
        return data;
      }
    } finally {
      state.loading = false;
    }
  }

  Future<_GroupMembersPageResult> _fetchPage({
    required RCIMIWEngine engine,
    required String groupId,
    required int count,
    required String pageToken,
  }) async {
    final option = RCIMIWPagingQueryOption.create(
      count: count,
      pageToken: pageToken,
      order: false,
    );

    final completer = Completer<_GroupMembersPageResult>();

    final code = await engine.getGroupMembersByRole(
      groupId,
      RCIMIWGroupMemberRole.undef,
      option,
      callback: IRCIMIWGetGroupMembersByRoleCallback(
        onSuccess: (info) {
          _completePage(completer, _GroupMembersPageResult(info: info));
        },
        onError: (code) {
          _completePage(
            completer,
            _GroupMembersPageResult(errorCode: code ?? -1),
          );
        },
      ),
    );

    if (code != 0) {
      _completePage(completer, _GroupMembersPageResult(errorCode: code));
    }

    return completer.future;
  }

  bool _shouldRetryPage({
    required List<RCIMIWGroupMemberInfo> data,
    required int? totalCount,
    required String pageToken,
  }) {
    if (totalCount == null) return false;

    if (pageToken.isEmpty && totalCount > 0 && data.isEmpty) {
      return true;
    }

    return false;
  }

  Future<void> _delayBeforeRetry(
    String groupId,
    int retryCount,
    String reason,
  ) async {
    debugPrint('获取群成员重试: groupId=$groupId retry=$retryCount reason=$reason');
    await Future.delayed(_syncingRetryDelay);
  }

  void _notifyCurrentUserQuit(String groupId) {
    GroupEventBus.instance.fire(
      GroupEvent(
        type: GroupEventType.quit,
        groupId: groupId,
        operatorUserId: IMEngineManager().currentUserId,
      ),
    );
  }

  void _completePage(
    Completer<_GroupMembersPageResult> completer,
    _GroupMembersPageResult result,
  ) {
    if (!completer.isCompleted) {
      completer.complete(result);
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
