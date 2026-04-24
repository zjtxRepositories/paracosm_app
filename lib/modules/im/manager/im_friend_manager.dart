import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import '../result/im_callback_wrapper.dart';
import '../result/im_result.dart';
import 'im_engine_manager.dart';

class ImFriendManager {

  final _controller = StreamController<List<RCIMIWFriendInfo>>.broadcast();
  Stream<List<RCIMIWFriendInfo>> get stream => _controller.stream;

  final List<RCIMIWFriendInfo> _friends = [];

  /// =========================
  /// 初始化监听（核心🔥）
  /// =========================
  void initListener() {
    final engine = IMEngineManager().engine;

    /// ✅ 新增好友
    engine?.onFriendAdded = (
        type,
        userId,
        name,
        portrait,
        time,
        ) {
      if (userId == null) return;

      final friend = RCIMIWFriendInfo.create(
        userId: userId,
        name: name,
        portrait: portrait,
      );
      _upsert(friend);

      _notify();

      debugPrint("好友新增: $userId");
    };

    /// ✅ 删除好友
    engine?.onFriendDeleted = (
        type,
        userIds,
        time,
        ) {
      if (userIds == null) return;

      _friends.removeWhere((e) => userIds.contains(e.userId));

      _notify();

      debugPrint("好友删除: $userIds");
    };

    /// ✅ 备注/资料更新
    engine?.onFriendInfoChangedSync = (
        userId,
        remark,
        ext,
        time,
        ) {
      if (userId == null) return;

      final index = _friends.indexWhere((e) => e.userId == userId);

      if (index >= 0) {
        final old = _friends[index];
        _friends[index] = RCIMIWFriendInfo.create(
          userId: old.userId,
          name: old.name,
          portrait: old.portrait,
          remark: remark,
          extFields: ext,
        );
        _notify();
      }

      debugPrint("好友信息更新: $userId");
    };
  }

  /// =========================
  /// 获取好友列表（建议启动时调用）
  /// =========================
  Future<void> fetchFriends() async {
    final completer = Completer<void>();
    final callback = IRCIMIWGetFriendsCallback(
      onSuccess: (list) {
        _friends.clear();

        _friends.addAll(list ?? []);

        _notify();
        debugPrint("获取好友: ${_friends.length}");

        completer.complete();
      },
      onError: (code) {
        debugPrint("获取好友失败: $code");
        completer.completeError(code ?? -1);
      },
    );

    await IMEngineManager().engine?.getFriends(RCIMIWFriendType.both,callback: callback);

    return completer.future;
  }

  /// =========================
  /// 根据用户 ID 获取好友信息
  /// =========================
  Future<List<RCIMIWFriendInfo>?> getFriendsInfo(List<String> userIds) async {
    final completer = Completer<List<RCIMIWFriendInfo>?>();
    final ret = await IMEngineManager().engine?.getFriendsInfo(
      userIds,
      callback: IRCIMIWGetFriendsInfoCallback(
        onSuccess: (List<RCIMIWFriendInfo>? infos) {
          debugPrint('getFriendsInfo success');
          completer.complete(infos);
        },
        onError: (int? code) {
          debugPrint('getFriendsInfo failed => $code ');
          completer.complete(null);
        },
      ),
    );
    if (ret != null && ret != 0) {
      return null;
    }
    return completer.future;
  }

  /// =========================
  /// 根据好友昵称搜索好友信息
  /// =========================
  Future<List<RCIMIWFriendInfo>?> searchFriendsInfo(String keyword) async {
    final completer = Completer<List<RCIMIWFriendInfo>?>();
    final ret = await IMEngineManager().engine?.searchFriendsInfo(
      keyword,
      callback: IRCIMIWSearchFriendsInfoCallback(
        onSuccess: (List<RCIMIWFriendInfo>? infos) {
          debugPrint('searchFriendsInfo success');
          completer.complete(infos);
        },
        onError: (int? code) {
          debugPrint('searchFriendsInfo failed => $code ');
          completer.complete(null);
        },
      ),
    );
    if (ret != null && ret != 0) {
      return null;
    }
    return completer.future;
  }

  /// =========================
  /// 好友信息设置
  /// =========================
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
        onSuccess: () {
          debugPrint('setFriendInfo success');
          completer.complete(true);
        },
        onError: (int? code, List<String>? errorKeys) {
          debugPrint('setFriendInfo failed => $code $errorKeys');
          completer.complete(false);
        },
      ),
    );
    /// SDK 层直接失败
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
    return ImCallbackWrapper.wrapAddFriend(
          (callback) {
        return IMEngineManager().engine!.addFriend(
          userId,
          RCIMIWFriendType.both,
          extra,
          callback: callback,
        );
      },
    );
  }

  /// =========================
  /// 删除好友
  /// =========================
  Future<ImResult<void>> deleteFriends(List<String> userIds) async {
    return ImCallbackWrapper.wrap(
          (callback) {
        return IMEngineManager().engine!.deleteFriends(
          userIds,
          RCIMIWFriendType.both,
          callback: callback,
        );
      },
    );
  }

  /// =========================
  /// 查询关系
  /// =========================
  Future<List<RCIMIWFriendRelationInfo>?> checkRelation(List<String> userIds) async {

    final completer = Completer<List<RCIMIWFriendRelationInfo>?>();

    final callback = IRCIMIWCheckFriendsRelationCallback(
      onSuccess: (result) {
        completer.complete(result);
      },
      onError: (code) {
        completer.completeError(code ?? -1);
      },
    );

    await IMEngineManager().engine?.checkFriendsRelation(
      userIds,
      RCIMIWFriendType.both,
      callback: callback,
    );

    return completer.future;
  }

  /// =========================
  /// 内部方法
  /// =========================

  void _upsert(RCIMIWFriendInfo friend) {
    final index = _friends.indexWhere((e) => e.userId == friend.userId);

    if (index >= 0) {
      _friends[index] = friend;
    } else {
      _friends.insert(0, friend);
    }
  }

  void _notify() {
    _controller.add(List.from(_friends));
  }

  void dispose() {
    _controller.close();
  }
}