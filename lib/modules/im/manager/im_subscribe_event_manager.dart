import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import 'im_engine_manager.dart';

enum PresenceState {
  unknown,
  online,
  offline,
}

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

  /// =========================
  /// 在线状态缓存
  /// =========================
  final Map<String, PresenceState> _presenceCache = {};

  Map<String, PresenceState> get cache => _presenceCache;

  /// =========================
  /// Stream
  /// =========================
  final _controller =
  StreamController<Map<String, PresenceState>>.broadcast();

  Stream<Map<String, PresenceState>> get stream =>
      _controller.stream;

  Timer? _debounce;

  static const int _expiry = 180000;

  /// =========================
  /// 初始化监听
  /// =========================
  void initListener() {
    _engine?.onEventChange =
        (List<RCIMIWSubscribeInfoEvent>? events) {
      if (events == null || events.isEmpty) {
        return;
      }

      for (final event in events) {
        _handleSubscribeEvent(event);
      }
    };

    /// 订阅同步完成
    _engine?.onSubscriptionSyncCompleted = (type) {
      debugPrint("订阅同步完成: $type");
    };

    /// 多端同步
    _engine?.onSubscriptionChangedOnOtherDevices =
        (List<RCIMIWSubscribeEvent>? events) {
      if (events == null || events.isEmpty) {
        return;
      }

      for (final event in events) {
        _handleOtherDeviceEvent(event);
      }
    };
  }

  /// =========================
  /// 统一事件处理
  /// =========================
  void _handleSubscribeEvent(
      RCIMIWSubscribeInfoEvent event,
      ) {
    final userId = event.userId;
    final type = event.subscribeType;

    if (userId == null || type == null) {
      return;
    }

    debugPrint("""
订阅事件:
userId=$userId
type=$type
event=$event
""");

    switch (type) {
    /// =========================
    /// 在线状态
    /// =========================
      case RCIMIWSubscribeType.onlineStatus:
      case RCIMIWSubscribeType.friendOnlineStatus:
        _handlePresenceEvent(event);
        break;

    /// =========================
    /// 用户资料
    /// =========================
      case RCIMIWSubscribeType.userProfile:
      case RCIMIWSubscribeType.friendUserProfile:
        _handleProfileEvent(event);
        break;

      default:
        break;
    }
  }

  /// =========================
  /// 在线状态事件
  /// =========================
  void _handlePresenceEvent(
      RCIMIWSubscribeInfoEvent event,
      ) {
    final userId = event.userId;

    if (userId == null) return;

    /// TODO:
    /// 根据 SDK 实际字段解析
    ///
    /// 比如:
    /// final online = event.onlineStatus == 1;

    final online = _parseOnlineStatus(event);

    _presenceCache[userId] =
    online
        ? PresenceState.online
        : PresenceState.offline;

    debugPrint(
      "在线状态更新: $userId -> ${_presenceCache[userId]}",
    );

    _notify();
  }

  /// =========================
  /// 用户资料事件
  /// =========================
  void _handleProfileEvent(
      RCIMIWSubscribeInfoEvent event,
      ) {
    debugPrint("""
用户资料更新:
userId=${event.userId}
profile=${event.userProfile}
""");

    /// TODO:
    /// 更新用户资料缓存
  }

  /// =========================
  /// 多端同步事件
  /// =========================
  void _handleOtherDeviceEvent(
      RCIMIWSubscribeEvent event,
      ) {
    debugPrint("""
多端订阅同步:
userId=${event.userId}
type=${event.subscribeType}
""");
  }

  /// =========================
  /// 解析在线状态
  /// =========================
  bool _parseOnlineStatus(
      RCIMIWSubscribeInfoEvent event,
      ) {
    try {
      /// TODO:
      /// 根据 SDK 实际字段修改

      final dynamic value = event.toJson();

      debugPrint("在线状态原始数据: $value");

      /// 示例:
      ///
      /// return value["onlineStatus"] == 1;

      return true;
    } catch (e) {
      debugPrint("解析在线状态失败: $e");
      return false;
    }
  }

  /// =========================
  /// 订阅在线状态
  /// =========================
  Future<bool> subscribeOnlineStatus(
      List<String> userIds,
      ) async {
    final ids =
    userIds
        .where(
          (e) => !_subscribedUsers.contains(e),
    )
        .toList();

    if (ids.isEmpty) {
      return true;
    }

    final request =
    RCIMIWSubscribeEventRequest.create(
      subscribeType:
      RCIMIWSubscribeType.onlineStatus,
      expiry: _expiry,
      userIds: ids,
    );

    final completer = Completer<bool>();

    await _engine?.subscribeEvent(
      request,
      callback: IRCIMIWSubscribeEventCallback(
        onSuccess: () {
          _subscribedUsers.addAll(ids);

          for (final id in ids) {
            _presenceCache[id] ??=
                PresenceState.unknown;
          }

          debugPrint("订阅成功: $ids");

          _notify();

          completer.complete(true);
        },
        onError: (
            int? code,
            List<String>? failedUserIds,
            ) {
          debugPrint("""
订阅失败:
code=$code
failed=$failedUserIds
""");

          completer.complete(false);
        },
      ),
    );

    return completer.future;
  }

  /// =========================
  /// 取消订阅
  /// =========================
  Future<void> unsubscribe(
      List<String> userIds,
      ) async {
    if (userIds.isEmpty) return;

    final request =
    RCIMIWSubscribeEventRequest.create(
      subscribeType:
      RCIMIWSubscribeType.onlineStatus,
      expiry: 0,
      userIds: userIds,
    );

    await _engine?.unSubscribeEvent(
      request,
      callback: IRCIMIWSubscribeEventCallback(
        onSuccess: () {
          for (final id in userIds) {
            _subscribedUsers.remove(id);
            _presenceCache.remove(id);
          }

          _notify();

          debugPrint("取消订阅成功: $userIds");
        },
        onError: (
            int? code,
            List<String>? failedUserIds,
            ) {
          debugPrint("""
取消订阅失败:
code=$code
failed=$failedUserIds
""");
        },
      ),
    );
  }

  /// =========================
  /// 获取在线状态
  /// =========================
  PresenceState getPresence(
      String userId,
      ) {
    return _presenceCache[userId] ??
        PresenceState.unknown;
  }

  bool isOnline(String userId) {
    return getPresence(userId) ==
        PresenceState.online;
  }

  /// =========================
  /// 通知 UI（防抖）
  /// =========================
  void _notify() {
    _debounce?.cancel();

    _debounce = Timer(
      const Duration(milliseconds: 200),
          () {
        if (!_controller.isClosed) {
          _controller.add(
            Map.unmodifiable(_presenceCache),
          );
        }
      },
    );
  }
}