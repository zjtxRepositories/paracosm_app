import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import 'im_engine_manager.dart';

class ImSubscribeEventManager {
  ImSubscribeEventManager._internal();

  static final ImSubscribeEventManager _instance =
  ImSubscribeEventManager._internal();

  factory ImSubscribeEventManager() => _instance;

  RCIMIWEngine? get _engine => IMEngineManager().engine;

  /// =========================
  /// 已订阅用户
  /// =========================
  final Set<String> _subscribedUsers = {};

  /// 在线状态缓存（核心）
  final Map<String, bool> _onlineCache = {};

  /// =========================
  /// Stream（UI监听）
  /// =========================
  final _controller =
  StreamController<Map<String, bool>>.broadcast();

  Stream<Map<String, bool>> get stream => _controller.stream;

  Map<String, bool> get cache => _onlineCache;

  /// =========================
  /// 初始化监听 SDK 回调
  /// =========================
  void initListener() {
    /// 1️⃣ 实时在线变化
    _engine?.onEventChange =
        (List<RCIMIWSubscribeInfoEvent>? events) {
      if (events == null) return;

      for (final e in events) {
        final userId = e.userId;

        /// ⚠️ 这里不同SDK字段可能不同，通常是 status / value
        final status = e.subscribeType;

        if (userId == null || status == null) continue;

        /// 1 = online, 0 = offline（按常规IM定义）
        _onlineCache[userId] = status == RCIMIWSubscribeType.friendOnlineStatus;
      }

      _notify();
    };

    /// 2️⃣ 订阅同步完成
    _engine?.onSubscriptionSyncCompleted = (type) {
      debugPrint("订阅同步完成: $type");
      _notify();
    };

    /// 3️⃣ 多端同步
    _engine?.onSubscriptionChangedOnOtherDevices =
        (List<RCIMIWSubscribeEvent>? events) {
      if (events == null) return;

      for (final e in events) {
        final userId = e.userId;
        final status = e.subscribeType;

        if (userId == null || status == null) continue;

        _onlineCache[userId] = status == RCIMIWSubscribeType.friendOnlineStatus;
      }

      _notify();
    };
  }

  /// =========================
  /// 订阅在线状态
  /// =========================
  Future<bool> subscribeOnlineStatus(List<String> userIds) async {
    if (userIds.isEmpty) return false;

    final request = RCIMIWSubscribeEventRequest.create(
      subscribeType: RCIMIWSubscribeType.onlineStatus,
      expiry: 180000,
      userIds: userIds,
    );

    final completer = Completer<bool>();

    final callback = IRCIMIWSubscribeEventCallback(
      onSuccess: () {
        _subscribedUsers.addAll(userIds);

        for (final id in userIds) {
          _onlineCache[id] = _onlineCache[id] ?? false;
        }

        _notify();

        debugPrint("订阅成功: $userIds");

        completer.complete(true);
      },
      onError: (int? code, List<String>? failedUserIds) {
        debugPrint("订阅失败: $code $failedUserIds");

        completer.complete(false);
      },
    );

    await _engine?.subscribeEvent(
      request,
      callback: callback,
    );

    return completer.future;
  }

  /// =========================
  /// 取消订阅
  /// =========================
  Future<void> unsubscribe(List<String> userIds) async {
    if (userIds.isEmpty) return;

    final request = RCIMIWSubscribeEventRequest.create(
      subscribeType: RCIMIWSubscribeType.onlineStatus,
      expiry: 0,
      userIds: userIds,
    );

    await _engine?.unSubscribeEvent(
      request,
      callback: IRCIMIWSubscribeEventCallback(
        onSuccess: () {
          for (final id in userIds) {
            _subscribedUsers.remove(id);
            _onlineCache[id] = false;
          }

          _notify();
        },
        onError: (int? code, List<String>? failedUserIds) {
          debugPrint("取消订阅失败: $code");
        },
      ),
    );
  }

  /// =========================
  /// 查询在线状态
  /// =========================
  bool isOnline(String userId) {
    return _onlineCache[userId] ?? false;
  }

  /// =========================
  /// 批量订阅
  /// =========================
  Future<bool> subscribeBatch(List<String> userIds) async {
    return subscribeOnlineStatus(userIds);
  }

  /// =========================
  /// 通知 UI
  /// =========================
  void _notify() {
    if (!_controller.isClosed) {
      _controller.add(Map.from(_onlineCache));
    }
  }

  /// =========================
  /// 销毁
  /// =========================
  void dispose() {
    _controller.close();
  }
}