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
        print('获取好友申请:${_list.length}');
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
  Future<void> acceptFriendApplication(String userId) async {
    final IRCIMIWOperationCallback callback = IRCIMIWOperationCallback(
      onSuccess: () => debugPrint('acceptFriendApplication success'),
      onError: (int? code) => debugPrint('acceptFriendApplication failed => $code'),
    );

    await IMEngineManager().engine?.acceptFriendApplication(
      userId,
      callback: callback,
    );
  }

  /// =========================
  /// 拒绝加为好友
  /// =========================
  Future<void> refuseFriendApplication(String userId) async {
    final IRCIMIWOperationCallback callback = IRCIMIWOperationCallback(
      onSuccess: () => debugPrint('refuse success'),
      onError: (int? code) => debugPrint('refuse failed => $code'),
    );

    await IMEngineManager().engine?.refuseFriendApplication(
      userId,
      callback: callback,
    );
  }

  /// =========================
  /// 未处理数量（红点🔥）
  /// =========================
  int get unhandledCount {
    return _list.where((e) =>
    e.applicationStatus == RCIMIWFriendApplicationStatus.unhandled).length;
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

  /// =========================
  /// 释放
  /// =========================
  void dispose() {
    _controller.close();
  }
}