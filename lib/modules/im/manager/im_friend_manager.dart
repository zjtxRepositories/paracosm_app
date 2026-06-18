import 'dart:async';

import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../listener/im_data_center.dart';
import '../result/im_callback_wrapper.dart';
import '../result/im_result.dart';
import 'im_engine_manager.dart';

class ImFriendManager {
  ImFriendManager._internal();

  static final ImFriendManager _instance = ImFriendManager._internal();

  factory ImFriendManager() => _instance;

  static const int syncingCode = 34329;
  static const int maxRetryCount = 3;

  bool _disposed = false;

  bool get mounted => !_disposed;

  int _fetchVersion = 0;

  RCIMIWEngine? _bindEngine;

  // ======================================================
  // init listener（只做事件转发）
  // ======================================================

  void initListener() {
    final engine = IMEngineManager().engine;

    if (engine == null) return;

    if (_bindEngine == engine) return;

    _bindEngine = engine;

    // =========================
    // 新增好友
    // =========================
    engine.onFriendAdded = (type, userId, name, portrait, time) async {
      if (!mounted || userId == null) return;

      await refreshFriend(userId);
    };

    // =========================
    // 删除好友
    // =========================
    engine.onFriendDeleted = (type, userIds, time) {
      if (!mounted) return;

      if (userIds == null || userIds.isEmpty) return;

      for (final id in userIds) {
        ImDataCenter().removeFriend(id);
      }
    };

    // =========================
    // 好友信息变更
    // =========================
    engine.onFriendInfoChangedSync = (userId, remark, ext, time) async {
      if (!mounted || userId == null) return;

      await refreshFriend(userId);
    };
  }

  // ======================================================
  // 获取好友列表（SDK → DataCenter）
  // ======================================================

  Future<void> fetchFriends() async {
    final currentVersion = ++_fetchVersion;

    for (int retry = 0; retry < maxRetryCount; retry++) {
      if (!mounted) return;

      final result = await _fetchFriendsInternal(currentVersion);

      if (result == 0) return;

      if (result == syncingCode) {
        await Future.delayed(const Duration(seconds: 2));
        continue;
      }

      throw result;
    }

    throw syncingCode;
  }

  Future<int> _fetchFriendsInternal(int version) async {
    final completer = Completer<int>();

    final callback = IRCIMIWGetFriendsCallback(
      onSuccess: (list) {
        if (!mounted) return;

        if (version != _fetchVersion) {
          completer.complete(0);
          return;
        }

        if (list != null) {
          ImDataCenter().setFriendList(list);
        }

        completer.complete(0);
      },
      onError: (code) {
        completer.complete(code ?? -1);
      },
    );

    final ret = await IMEngineManager().engine?.getFriends(
      RCIMIWFriendType.both,
      callback: callback,
    );

    if (ret != null && ret != 0) {
      return ret;
    }

    return completer.future;
  }

  // ======================================================
  // 单个好友刷新
  // ======================================================

  Future<void> refreshFriend(String userId) async {
    final delays = [
      Duration.zero,
      const Duration(milliseconds: 300),
      const Duration(seconds: 1),
    ];

    for (final delay in delays) {
      if (!mounted) return;
      if (delay != Duration.zero) {
        await Future.delayed(delay);
      }

      final infos = await getFriendsInfo([userId]);

      if (infos != null && infos.isNotEmpty) {
        ImDataCenter().updateFriend(infos.first);
        return;
      }
    }

    try {
      await fetchFriends();
    } catch (_) {
      // 忽略兜底刷新失败，下一次 SDK 事件或页面拉取会继续同步。
    }
  }

  // ======================================================
  // SDK API
  // ======================================================

  Future<List<RCIMIWFriendInfo>?> getFriendsInfo(List<String> userIds) async {
    final completer = Completer<List<RCIMIWFriendInfo>?>();

    final ret = await IMEngineManager().engine?.getFriendsInfo(
      userIds,
      callback: IRCIMIWGetFriendsInfoCallback(
        onSuccess: (infos) {
          completer.complete(infos);
        },
        onError: (code) {
          completer.complete(null);
        },
      ),
    );

    if (ret != null && ret != 0) return null;

    return completer.future;
  }

  Future<List<RCIMIWFriendInfo>?> searchFriendsInfo(String keyword) async {
    final completer = Completer<List<RCIMIWFriendInfo>?>();

    final ret = await IMEngineManager().engine?.searchFriendsInfo(
      keyword,
      callback: IRCIMIWSearchFriendsInfoCallback(
        onSuccess: (infos) {
          completer.complete(infos);
        },
        onError: (code) {
          completer.complete(null);
        },
      ),
    );

    if (ret != null && ret != 0) return null;

    return completer.future;
  }

  Future<bool> setFriendInfo({
    required String userId,
    required String remark,
  }) async {
    final completer = Completer<bool>();

    final friendInfo = RCIMIWFriendInfo.create(userId: userId, remark: remark);

    final ret = await IMEngineManager().engine?.setFriendInfo(
      friendInfo,
      callback: IRCIMIWSetFriendInfoCallback(
        onSuccess: () async {
          await refreshFriend(userId);
          completer.complete(true);
        },
        onError: (code, keys) {
          completer.complete(false);
        },
      ),
    );

    if (ret != null && ret != 0) return false;

    return completer.future;
  }

  Future<ImResult<int>> addFriend({
    required String userId,
    String extra = "",
  }) async {
    final result = await ImCallbackWrapper.wrapAddFriend((callback) {
      return IMEngineManager().engine!.addFriend(
        userId,
        RCIMIWFriendType.both,
        extra,
        callback: callback,
      );
    });

    if (result.success) {
      unawaited(refreshFriend(userId));
    }

    return result;
  }

  Future<ImResult<void>> deleteFriends(List<String> userIds) async {
    final result = await ImCallbackWrapper.wrap((callback) {
      return IMEngineManager().engine!.deleteFriends(
        userIds,
        RCIMIWFriendType.both,
        callback: callback,
      );
    });

    if (result.success) {
      for (final id in userIds) {
        ImDataCenter().removeFriend(id);
      }
    }

    return result;
  }

  Future<ImResult<void>> addToBlacklist(String userId) async {
    final completer = Completer<ImResult<void>>();
    final ret = await IMEngineManager().engine!.addToBlacklist(
      userId,
      callback: IRCIMIWAddToBlacklistCallback(
        onBlacklistAdded: (int? code, String? uid) {
          if (code == 0 && uid != null) {
            ImDataCenter().removeFriend(userId, deletedMessage: false);
            _completeIfPending(completer, ImResult.success());
            return;
          }
          _completeIfPending(completer, ImResult.error(code: code ?? -1));
        },
      ),
    );

    if (ret != 0) {
      return ImResult.error(code: ret);
    }

    return completer.future;
  }

  Future<ImResult<void>> removeFromBlacklist(String userId) async {
    final completer = Completer<ImResult<void>>();
    final ret = await IMEngineManager().engine!.removeFromBlacklist(
      userId,
      callback: IRCIMIWRemoveFromBlacklistCallback(
        onBlacklistRemoved: (int? code, String? uid) {
          if (code == 0 && uid != null) {
            _completeIfPending(completer, ImResult.success());
            return;
          }
          _completeIfPending(completer, ImResult.error(code: code ?? -1));
        },
      ),
    );

    if (ret != 0) {
      return ImResult.error(code: ret);
    }

    return completer.future;
  }

  Future<ImResult<List<String>>> getBlacklist() async {
    final completer = Completer<ImResult<List<String>>>();
    final ret = await IMEngineManager().engine!.getBlacklist(
      callback: IRCIMIWGetBlacklistCallback(
        onSuccess: (List<String>? userIds) {
          _completeIfPending(completer, ImResult.success(data: userIds ?? []));
        },
        onError: (int? code) {
          _completeIfPending(completer, ImResult.error(code: code ?? -1));
        },
      ),
    );

    if (ret != 0) {
      return ImResult.error(code: ret);
    }

    return completer.future;
  }

  void _completeIfPending<T>(
    Completer<ImResult<T>> completer,
    ImResult<T> result,
  ) {
    if (!completer.isCompleted) {
      completer.complete(result);
    }
  }

  // ======================================================
  // dispose
  // ======================================================

  void dispose() {
    _disposed = true;
  }
}
