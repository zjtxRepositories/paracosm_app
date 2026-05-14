import 'dart:async';

import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../listener/im_data_center.dart';
import '../result/im_callback_wrapper.dart';
import '../result/im_result.dart';
import 'im_engine_manager.dart';

class ImFriendManager {
  ImFriendManager._internal();

  static final ImFriendManager _instance =
  ImFriendManager._internal();

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
    engine.onFriendAdded = (
        type,
        userId,
        name,
        portrait,
        time,
        ) async {
      if (!mounted || userId == null) return;

      final friend = RCIMIWFriendInfo.create(
        userId: userId,
        name: name,
        portrait: portrait,
      );

      // 可选：延迟刷新完整信息
      await Future.delayed(const Duration(milliseconds: 300));

      await _refreshFriend(userId);
    };

    // =========================
    // 删除好友
    // =========================
    engine.onFriendDeleted = (
        type,
        userIds,
        time,
        ) {
      if (!mounted) return;

      if (userIds == null || userIds.isEmpty) return;

      for (final id in userIds) {
        ImDataCenter().removeFriend(id);
      }
    };

    // =========================
    // 好友信息变更
    // =========================
    engine.onFriendInfoChangedSync = (
        userId,
        remark,
        ext,
        time,
        ) async {
      if (!mounted || userId == null) return;

      await _refreshFriend(userId);
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

  Future<void> _refreshFriend(String userId) async {
    final infos = await getFriendsInfo([userId]);

    if (infos == null || infos.isEmpty) return;

    ImDataCenter().updateFriend(infos.first);
  }

  // ======================================================
  // SDK API
  // ======================================================

  Future<List<RCIMIWFriendInfo>?> getFriendsInfo(
      List<String> userIds,
      ) async {
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

  Future<List<RCIMIWFriendInfo>?> searchFriendsInfo(
      String keyword,
      ) async {
    final completer = Completer<List<RCIMIWFriendInfo>?>();

    final ret = await IMEngineManager()
        .engine
        ?.searchFriendsInfo(
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

    final friendInfo = RCIMIWFriendInfo.create(
      userId: userId,
      remark: remark,
    );

    final ret = await IMEngineManager().engine?.setFriendInfo(
      friendInfo,
      callback: IRCIMIWSetFriendInfoCallback(
        onSuccess: () async {
          await _refreshFriend(userId);
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

  Future<ImResult<void>> addFriend({
    required String userId,
    String extra = "",
  }) async {
    return ImCallbackWrapper.wrapAddFriend((callback) {
      return IMEngineManager().engine!.addFriend(
        userId,
        RCIMIWFriendType.both,
        extra,
        callback: callback,
      );
    });
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
    final result = await ImCallbackWrapper.wrapAddBlock((callback) {
      return IMEngineManager().engine!.addToBlacklist(
        userId,
        callback: IRCIMIWAddToBlacklistCallback(onBlacklistAdded: (int? code, String? uid){
          if (uid != null && code == 0) {
            ImDataCenter().removeFriend(userId,deletedMessage: false);
          }
        }),
      );
    });

    return result;
  }

  // ======================================================
  // dispose
  // ======================================================

  void dispose() {
    _disposed = true;
  }
}