import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:paracosm/core/models/user_model.dart';
import 'package:paracosm/modules/im/listener/user_state_center.dart';
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

  /// =========================
  /// 用户资料缓存（新增）
  /// =========================
  final Map<String, RCIMIWUserProfile> _profileCache = {};

  Map<String, PresenceState> get cache => _presenceCache;
  Map<String, RCIMIWUserProfile> get profileCache => _profileCache;

  /// =========================
  /// Stream
  /// =========================
  final _presenceController =
  StreamController<Map<String, PresenceState>>.broadcast();

  final _profileController =
  StreamController<Map<String, RCIMIWUserProfile>>.broadcast();

  Stream<Map<String, PresenceState>> get stream =>
      _presenceController.stream;

  Stream<Map<String, RCIMIWUserProfile>> get profileStream =>
      _profileController.stream;

  Timer? _debounce;

  static const int _expiry = 180000;

  /// =========================
  /// 初始化监听
  /// =========================
  void initListener() {
    _engine?.onEventChange =
        (List<RCIMIWSubscribeInfoEvent>? events) {
      if (events == null || events.isEmpty) return;

      for (final event in events) {
        _handleSubscribeEvent(event);
      }
    };

    _engine?.onSubscriptionSyncCompleted = (type) {
      debugPrint("订阅同步完成: $type");
    };

    _engine?.onSubscriptionChangedOnOtherDevices =
        (List<RCIMIWSubscribeEvent>? events) {
      if (events == null || events.isEmpty) return;

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

    if (userId == null || type == null) return;

    debugPrint("""
订阅事件:
userId=$userId
type=$type
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
    /// 用户资料（新增完整实现）
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
  void _handlePresenceEvent(RCIMIWSubscribeInfoEvent event) {
    final userId = event.userId;
    if (userId == null) return;

    final online = _parseOnlineStatus(event);

    _presenceCache[userId] =
    online ? PresenceState.online : PresenceState.offline;

    debugPrint("在线状态更新: $userId -> ${_presenceCache[userId]}");

    _notifyPresence();
  }

  /// =========================
  /// 用户资料事件（新增核心）
  /// =========================
  void _handleProfileEvent(RCIMIWSubscribeInfoEvent event) {
    final profile = event.userProfile;
    final userId = profile?.userId ?? event.userId;

    if (userId == null || profile == null) return;

    _profileCache[userId] = profile;

    debugPrint("""
用户资料更新:
userId=$userId
name=${profile.name}
avatar=${profile.portraitUri}
""");

    _notifyProfile();
  }

  /// =========================
  /// 多端同步
  /// =========================
  void _handleOtherDeviceEvent(RCIMIWSubscribeEvent event) {
    debugPrint("""
多端订阅同步:
userId=${event.userId}
type=${event.subscribeType}
""");
  }

  /// =========================
  /// 解析在线状态
  /// =========================
  bool _parseOnlineStatus(RCIMIWSubscribeInfoEvent event) {
    try {
      final json = event.toJson();

      final details = json['details'];

      if (details is List && details.isNotEmpty) {
        return details.any((e) => e['eventValue'] == 1);
      }

      return false;
    } catch (e) {
      debugPrint("解析在线状态失败: $e");
      return false;
    }
  }

  /// =========================
  /// 订阅在线状态
  /// =========================
  Future<bool> subscribeOnlineStatus(List<String> userIds) async {
    final ids = userIds
        .where((e) => !_subscribedUsers.contains(e))
        .toList();

    if (ids.isEmpty) return true;

    final request = RCIMIWSubscribeEventRequest.create(
      subscribeType: RCIMIWSubscribeType.onlineStatus,
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
            _presenceCache[id] ??= PresenceState.unknown;
          }

          _notifyPresence();

          completer.complete(true);
        },
        onError: (code, failedUserIds) {
          debugPrint("订阅失败: $code $failedUserIds");
          completer.complete(false);
        },
      ),
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
            _presenceCache.remove(id);
            _profileCache.remove(id);
          }

          _notifyPresence();
          _notifyProfile();
        },
        onError: (code, failedUserIds) {
          debugPrint("取消订阅失败: $code $failedUserIds");
        },
      ),
    );
  }

  /// =========================
  /// 查询
  /// =========================
  PresenceState getPresence(String userId) {
    return _presenceCache[userId] ?? PresenceState.unknown;
  }

  RCIMIWUserProfile? getProfile(String userId) {
    return _profileCache[userId];
  }

  bool isOnline(String userId) {
    return getPresence(userId) == PresenceState.online;
  }

  /// =========================
  /// UI 通知
  /// =========================
  void _notifyPresence() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (!_presenceController.isClosed) {
        _presenceController.add(
          Map.unmodifiable(_presenceCache),
        );
      }
    });
  }

  void _notifyProfile() {
    if (!_profileController.isClosed) {
      _profileController.add(
        Map.unmodifiable(_profileCache),
      );
    }
  }
}