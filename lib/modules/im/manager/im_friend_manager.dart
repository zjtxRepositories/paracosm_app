import 'dart:async';
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../result/im_callback_wrapper.dart';
import '../result/im_result.dart';
import 'im_engine_manager.dart';

class ImFriendManager {
  ImFriendManager._internal();

  static final ImFriendManager _instance =
  ImFriendManager._internal();

  factory ImFriendManager() => _instance;

  /// =========================
  /// 同步状态错误码
  /// =========================

  static const int syncingCode = 34329;

  /// 最大重试次数
  static const int maxRetryCount = 3;

  /// =========================
  /// Stream
  /// =========================

  final _controller =
  StreamController<List<RCIMIWFriendInfo>>.broadcast();

  Stream<List<RCIMIWFriendInfo>> get stream =>
      _controller.stream;

  /// 当前数据
  List<RCIMIWFriendInfo> get currentFriends =>
      List.unmodifiable(_friends);

  /// =========================
  /// 数据缓存
  /// =========================

  final List<RCIMIWFriendInfo> _friends = [];

  final Map<String, RCIMIWFriendInfo> _friendMap = {};

  UnmodifiableListView<RCIMIWFriendInfo> get friends =>
      UnmodifiableListView(_friends);

  /// =========================
  /// 状态
  /// =========================

  bool _disposed = false;

  bool get mounted => !_disposed;

  int _fetchVersion = 0;

  RCIMIWEngine? _bindEngine;

  Timer? _notifyTimer;

  /// =========================
  /// 初始化监听
  /// =========================

  void initListener() {
    final engine = IMEngineManager().engine;

    if (engine == null) {
      return;
    }

    /// 已绑定当前 engine
    if (_bindEngine == engine) {
      return;
    }

    _bindEngine = engine;

    /// =========================
    /// 新增好友
    /// =========================

    engine.onFriendAdded = (
        type,
        userId,
        name,
        portrait,
        time,
        ) async {
      if (!mounted) return;

      if (userId == null) return;

      debugPrint("好友新增: $userId");

      final friend = RCIMIWFriendInfo.create(
        userId: userId,
        name: name,
        portrait: portrait,
      );

      _upsert(friend);

      _notify();

      /// 拉完整信息
      await Future.delayed(
        const Duration(milliseconds: 300),
      );

      if (!mounted) return;

      await _refreshFriend(userId);
    };

    /// =========================
    /// 删除好友
    /// =========================

    engine.onFriendDeleted = (
        type,
        userIds,
        time,
        ) {
      if (!mounted) return;

      if (userIds == null || userIds.isEmpty) {
        return;
      }

      debugPrint("好友删除: $userIds");

      for (final userId in userIds) {
        _friendMap.remove(userId);
      }

      _rebuildFriends();

      _notify();
    };

    /// =========================
    /// 好友信息更新
    /// =========================

    engine.onFriendInfoChangedSync = (
        userId,
        remark,
        ext,
        time,
        ) async {
      if (!mounted) return;

      if (userId == null) return;

      debugPrint("好友信息更新: $userId");

      await _refreshFriend(userId);
    };
  }

  /// =========================
  /// 获取好友列表
  /// =========================

  Future<void> fetchFriends() async {
    final currentVersion = ++_fetchVersion;

    for (
    int retryCount = 0;
    retryCount < maxRetryCount;
    retryCount++
    ) {
      if (!mounted) return;

      final result = await _fetchFriendsInternal(
        currentVersion,
      );

      /// 成功
      if (result == 0) {
        return;
      }

      /// 同步中
      if (result == syncingCode) {
        debugPrint(
          "好友同步中，延迟重试: ${retryCount + 1}",
        );

        await Future.delayed(
          const Duration(seconds: 2),
        );

        continue;
      }

      throw result;
    }

    throw syncingCode;
  }

  /// =========================
  /// 内部获取好友
  /// =========================

  Future<int> _fetchFriendsInternal(
      int version,
      ) async {
    if (!mounted) {
      return -1;
    }

    final completer = Completer<int>();

    bool completed = false;

    void safeComplete(int value) {
      if (completed) return;

      completed = true;

      if (!completer.isCompleted) {
        completer.complete(value);
      }
    }

    final callback = IRCIMIWGetFriendsCallback(
      onSuccess: (list) {
        if (!mounted) {
          safeComplete(-1);
          return;
        }

        /// 旧请求
        if (version != _fetchVersion) {
          safeComplete(0);
          return;
        }

        _friendMap.clear();

        for (final item in (list ?? [])) {
          final userId = item.userId;

          if (userId == null) continue;

          _friendMap[userId] = item;
        }

        _rebuildFriends();

        _notify();

        debugPrint(
          "获取好友成功: ${_friends.length}",
        );

        safeComplete(0);
      },
      onError: (code) {
        debugPrint(
          "获取好友失败: $code",
        );

        safeComplete(code ?? -1);
      },
    );

    final ret = await IMEngineManager().engine?.getFriends(
      RCIMIWFriendType.both,
      callback: callback,
    );

    /// SDK直接失败
    if (ret != null && ret != 0) {
      safeComplete(ret);
    }

    return completer.future;
  }

  /// =========================
  /// 获取好友详情
  /// =========================

  Future<List<RCIMIWFriendInfo>?> getFriendsInfo(
      List<String> userIds,
      ) async {
    if (!mounted) return null;

    final completer =
    Completer<List<RCIMIWFriendInfo>?>();

    bool completed = false;

    void safeComplete(
        List<RCIMIWFriendInfo>? value,
        ) {
      if (completed) return;

      completed = true;

      if (!completer.isCompleted) {
        completer.complete(value);
      }
    }

    final ret =
    await IMEngineManager().engine?.getFriendsInfo(
      userIds,
      callback: IRCIMIWGetFriendsInfoCallback(
        onSuccess: (
            List<RCIMIWFriendInfo>? infos,
            ) {
          debugPrint(
            'getFriendsInfo success',
          );

          safeComplete(infos);
        },
        onError: (int? code) {
          debugPrint(
            'getFriendsInfo failed => $code',
          );

          safeComplete(null);
        },
      ),
    );

    if (ret != null && ret != 0) {
      return null;
    }

    return completer.future;
  }

  /// =========================
  /// 搜索好友
  /// =========================

  Future<List<RCIMIWFriendInfo>?> searchFriendsInfo(
      String keyword,
      ) async {
    if (!mounted) return null;

    final completer =
    Completer<List<RCIMIWFriendInfo>?>();

    bool completed = false;

    void safeComplete(
        List<RCIMIWFriendInfo>? value,
        ) {
      if (completed) return;

      completed = true;

      if (!completer.isCompleted) {
        completer.complete(value);
      }
    }

    final ret = await IMEngineManager()
        .engine
        ?.searchFriendsInfo(
      keyword,
      callback: IRCIMIWSearchFriendsInfoCallback(
        onSuccess: (
            List<RCIMIWFriendInfo>? infos,
            ) {
          debugPrint(
            'searchFriendsInfo success',
          );

          safeComplete(infos);
        },
        onError: (int? code) {
          debugPrint(
            'searchFriendsInfo failed => $code',
          );

          safeComplete(null);
        },
      ),
    );

    if (ret != null && ret != 0) {
      return null;
    }

    return completer.future;
  }

  /// =========================
  /// 设置好友信息
  /// =========================

  Future<bool> setFriendInfo({
    required String userId,
    required String remark,
  }) async {
    if (!mounted) return false;

    final completer = Completer<bool>();

    bool completed = false;

    void safeComplete(bool value) {
      if (completed) return;

      completed = true;

      if (!completer.isCompleted) {
        completer.complete(value);
      }
    }

    final friendInfo = RCIMIWFriendInfo.create(
      userId: userId,
      remark: remark,
    );

    final ret =
    await IMEngineManager().engine?.setFriendInfo(
      friendInfo,
      callback: IRCIMIWSetFriendInfoCallback(
        onSuccess: () async {
          debugPrint(
            'setFriendInfo success',
          );

          await _refreshFriend(userId);

          safeComplete(true);
        },
        onError: (
            int? code,
            List<String>? errorKeys,
            ) {
          debugPrint(
            'setFriendInfo failed => $code',
          );

          safeComplete(false);
        },
      ),
    );

    if (ret != null && ret != 0) {
      return false;
    }

    return completer.future;
  }

  /// =========================
  /// 添加好友
  /// =========================

  Future<ImResult<void>> addFriend({
    required String userId,
    String extra = "",
  }) async {
    final result =
    await ImCallbackWrapper.wrapAddFriend(
          (callback) {
        return IMEngineManager().engine!.addFriend(
          userId,
          RCIMIWFriendType.both,
          extra,
          callback: callback,
        );
      },
    );

    return result;
  }

  /// =========================
  /// 删除好友
  /// =========================

  Future<ImResult<void>> deleteFriends(
      List<String> userIds,
      ) async {
    final result = await ImCallbackWrapper.wrap(
          (callback) {
        return IMEngineManager().engine!.deleteFriends(
          userIds,
          RCIMIWFriendType.both,
          callback: callback,
        );
      },
    );

    if (result.success) {
      for (final userId in userIds) {
        _friendMap.remove(userId);
      }

      _rebuildFriends();

      _notify();
    }

    return result;
  }

  /// =========================
  /// 检查好友关系
  /// =========================

  Future<List<RCIMIWFriendRelationInfo>?>
  checkRelation(
      List<String> userIds,
      ) async {
    if (!mounted) return null;

    final completer =
    Completer<List<RCIMIWFriendRelationInfo>?>();

    bool completed = false;

    void safeComplete(
        List<RCIMIWFriendRelationInfo>? value,
        ) {
      if (completed) return;

      completed = true;

      if (!completer.isCompleted) {
        completer.complete(value);
      }
    }

    final callback =
    IRCIMIWCheckFriendsRelationCallback(
      onSuccess: (result) {
        safeComplete(result);
      },
      onError: (code) {
        safeComplete(null);
      },
    );

    final ret =
    await IMEngineManager().engine?.checkFriendsRelation(
      userIds,
      RCIMIWFriendType.both,
      callback: callback,
    );

    if (ret != null && ret != 0) {
      return null;
    }

    return completer.future;
  }

  /// =========================
  /// 获取单个好友
  /// =========================

  RCIMIWFriendInfo? getFriend(
      String userId,
      ) {
    return _friendMap[userId];
  }

  /// =========================
  /// 刷新单个好友
  /// =========================

  Future<void> _refreshFriend(
      String userId,
      ) async {
    if (!mounted) return;

    final infos = await getFriendsInfo(
      [userId],
    );

    if (!mounted) return;

    if (infos == null || infos.isEmpty) {
      return;
    }

    final friend = infos.first;

    _upsert(friend);

    _notify();
  }

  /// =========================
  /// 新增/更新
  /// =========================

  void _upsert(
      RCIMIWFriendInfo friend,
      ) {
    final userId = friend.userId;

    if (userId == null) return;

    _friendMap[userId] = friend;

    _rebuildFriends();
  }

  /// =========================
  /// 重建列表
  /// =========================

  void _rebuildFriends() {
    _friends
      ..clear()
      ..addAll(_friendMap.values);

    _sortFriends();
  }

  /// =========================
  /// 排序
  /// =========================

  void _sortFriends() {
    _friends.sort((a, b) {
      final aName =
          (a.remark?.isNotEmpty == true
              ? a.remark
              : a.name) ??
              '';

      final bName =
          (b.remark?.isNotEmpty == true
              ? b.remark
              : b.name) ??
              '';

      return aName.toLowerCase().compareTo(
        bName.toLowerCase(),
      );
    });
  }

  /// =========================
  /// 通知
  /// =========================

  void _notify() {
    if (!mounted) return;

    _notifyTimer?.cancel();

    _notifyTimer = Timer(
      const Duration(milliseconds: 50),
          () {
        if (!mounted) return;

        if (_controller.isClosed) {
          return;
        }

        _controller.add(
          List.unmodifiable(_friends),
        );
      },
    );
  }

  /// =========================
  /// 清空数据
  /// =========================

  void clear() {
    _friendMap.clear();

    _friends.clear();

    _notify();
  }

  /// =========================
  /// 销毁
  /// =========================

  void dispose() {
    _disposed = true;

    _notifyTimer?.cancel();

    _controller.close();
  }
}