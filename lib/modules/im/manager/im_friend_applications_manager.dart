import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import 'im_engine_manager.dart';

class ImFriendApplicationsManager {
  ImFriendApplicationsManager._internal();
  static final ImFriendApplicationsManager _instance =
  ImFriendApplicationsManager._internal();

  factory ImFriendApplicationsManager() => _instance;

  final _controller = StreamController<List<RCIMIWFriendApplicationInfo>>.broadcast();

  Stream<List<RCIMIWFriendApplicationInfo>> get stream => _controller.stream;

  final List<RCIMIWFriendApplicationInfo> _list = [];
  List<RCIMIWFriendApplicationInfo> get list => _list;

  String? _pageToken;

  /// =========================
  /// 初始化监听
  /// =========================
  void initListener() {
    final engine = IMEngineManager().engine;

    engine?.onFriendApplicationStatusChanged = (
        String? userId,
        RCIMIWFriendApplicationType? type,
        RCIMIWFriendApplicationStatus? status,
        RCIMIWFriendType? friendType,
        int? time,
        String? extra,
        ) {

      if (userId == null || status == null || type == null) return;

      final item = RCIMIWFriendApplicationInfo.create(
        userId: userId,
        applicationStatus: status,
        applicationType: type,
        friendType: friendType,
        operationTime: time ?? 0,
        remark: extra,
      );

      /// 更新本地列表
      _upsert(item);

      /// 推送给 UI
      _controller.add(_list);

      debugPrint("好友申请变更: $userId $status");
    };

  }

  /// =========================
  /// 拉取好友申请（分页）
  /// =========================
  Future<void> fetch({bool loadMore = false}) async {
    final option = RCIMIWPagingQueryOption.create(
      pageToken: loadMore ? (_pageToken ?? '') : '',
      count: 100,
      order: false,
    );

    final completer = Completer<void>();

    final callback = IRCIMIWGetFriendApplicationsCallback(

      onSuccess: (page) {

        final result = page?.data ?? [];

        if (!loadMore) {
          _list.clear();
        }

        _list.addAll(result);

        _pageToken = page?.pageToken;

        _controller.add(_list);
        completer.complete();
      },

      onError: (code) {
        debugPrint("获取好友申请失败: $code");
        completer.completeError(code ?? -1);
      },
    );

    await IMEngineManager().engine?.getFriendApplications(
      [
        RCIMIWFriendApplicationType.sent,
        RCIMIWFriendApplicationType.received,
      ],
      [
        RCIMIWFriendApplicationStatus.unhandled,
        RCIMIWFriendApplicationStatus.accepted,
        RCIMIWFriendApplicationStatus.refused,
      ],
      option,
      callback: callback,
    );

    return completer.future;
  }

  /// =========================
  /// 同意加为好友
  /// =========================
  Future<bool> acceptFriendApplication(String userId) async {
    final completer = Completer<bool>();

    await IMEngineManager().engine?.acceptFriendApplication(
      userId,
      callback: IRCIMIWOperationCallback(
        onSuccess: () {
          debugPrint('acceptFriendApplication success');
          if (!completer.isCompleted) {
            _updateLocalStatus(
              userId,
              RCIMIWFriendApplicationStatus.accepted,
            );
            completer.complete(true);
          }
        },
        onError: (int? code) {
          debugPrint('acceptFriendApplication failed => $code');
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      ),
    );

    return completer.future;
  }

  /// =========================
  /// 拒绝加为好友
  /// =========================
  Future<bool> refuseFriendApplication(String userId) async {
    final completer = Completer<bool>();

    await IMEngineManager().engine?.refuseFriendApplication(
      userId,
      callback: IRCIMIWOperationCallback(
        onSuccess: () {
          debugPrint('refuse success');
          if (!completer.isCompleted) {
            _updateLocalStatus(
              userId,
              RCIMIWFriendApplicationStatus.refused,
            );

            completer.complete(true);
          }
        },
        onError: (int? code) {
          debugPrint('refuse failed => $code');
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      ),
    );

    return completer.future;
  }
  /// =========================
  /// 获取列表
  /// =========================
  List<RCIMIWFriendApplicationInfo> getList({
    RCIMIWFriendApplicationStatus? status,
    RCIMIWFriendApplicationType? applicationType,
  }) {
    return _list.where((e) {
      final matchStatus =
          status == null || e.applicationStatus == status;

      final matchType =
          applicationType == null || e.applicationType == applicationType;

      return matchStatus && matchType;
    }).toList();
  }

  /// =========================
  /// 未处理数量
  /// =========================
  int get unhandledCount {
    return _list.where((e) =>
    e.applicationStatus == RCIMIWFriendApplicationStatus.unhandled
    && e.applicationType == RCIMIWFriendApplicationType.received).length;
  }


  /// =========================
  /// 本地更新
  /// =========================
  void _upsert(RCIMIWFriendApplicationInfo item) {
    final index = _list.indexWhere((e) => e.userId == item.userId);

    if (index >= 0) {
      _list[index] = item;
    } else {
      _list.insert(0, item);
    }
  }

  void _updateLocalStatus(
      String userId,
      RCIMIWFriendApplicationStatus status,
      ) {
    final index = _list.indexWhere((e) => e.userId == userId);

    if (index != -1) {
      final old = _list[index];

      final updated = RCIMIWFriendApplicationInfo.create(
        userId: old.userId,
        applicationStatus: status,
        applicationType: old.applicationType,
        friendType: old.friendType,
        operationTime: DateTime.now().millisecondsSinceEpoch,
        remark: old.remark,
      );

      _list[index] = updated;
      _notify();
    }
  }
  void _notify() {
    if (!_controller.isClosed) {
      _controller.add(List.from(_list));
    }
  }
  /// =========================
  /// 释放
  /// =========================
  void dispose() {
    _controller.close();
  }
}