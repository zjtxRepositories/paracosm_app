import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import 'im_engine_manager.dart';

class ImUserManager {

  final _controller = StreamController<List<RCIMIWFriendInfo>>.broadcast();
  Stream<List<RCIMIWFriendInfo>> get stream => _controller.stream;

  /// =========================
  /// 初始化监听（核心🔥）
  /// =========================
  void initListener() {
    final engine = IMEngineManager().engine;

    engine?.onEventChange = (List<RCIMIWSubscribeInfoEvent>? subscribeEvents) {
      // 用户信息托管变更
    };

    engine?.onSubscriptionSyncCompleted = (RCIMIWSubscribeType? type) {
      // 订阅数据同步完成
    };

    engine?.onSubscriptionChangedOnOtherDevices = (
        List<RCIMIWSubscribeEvent>? subscribeEvents,
        ) {
      // 其他设备订阅信息变更
    };
  }

  /// =========================
  /// 获取当前用户信息
  /// =========================
  Future<RCIMIWUserProfile?> getMyUserProfile() async {
    final completer = Completer<RCIMIWUserProfile?>();
    final ret = await IMEngineManager().engine?.getMyUserProfile(
      callback: IRCIMIWGetMyUserProfileCallback(
        onSuccess: (RCIMIWUserProfile? userProfile) {
          debugPrint('getMyUserProfile success');
          completer.complete(userProfile);
        },
        onError: (int? code) {
          debugPrint('getMyUserProfile failed => $code ');
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
  /// 批量获取用户信息
  /// =========================
  Future<List<RCIMIWUserProfile>?> getUserProfiles(List<String> userIds) async {
    final completer = Completer<List<RCIMIWUserProfile>?>();
    final ret = await IMEngineManager().engine?.getUserProfiles(
      userIds,
      callback: IRCIMIWGetUserProfilesCallback(
        onSuccess: (List<RCIMIWUserProfile>? userProfiles) {
          debugPrint('getUserProfiles success---${userProfiles?.length}');
          completer.complete(userProfiles);
        },
        onError: (int? code) {
          debugPrint('getUserProfiles failed => $code ');
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
  /// 搜索用户
  /// =========================
  Future<RCIMIWUserProfile?> searchUserProfileByUniqueId( String uniqueId) async {
    final completer = Completer<RCIMIWUserProfile?>();
    final ret = await IMEngineManager().engine?.searchUserProfileByUniqueId(
      uniqueId,
      callback: IRCIMIWSearchUserProfileByUniqueIdCallback(
        onSuccess: (RCIMIWUserProfile? userProfile) {
          debugPrint('searchUserProfileByUniqueId success');
          completer.complete(userProfile);
        },
        onError: (int? code) {
          debugPrint('searchUserProfileByUniqueId failed => $code ');
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
  /// 设置用户信息
  /// =========================
  Future<bool> updateMyUserProfile({
    required RCIMIWUserProfile userProfile,
  }) async {
    final completer = Completer<bool>();
    final ret = await IMEngineManager().engine?.updateMyUserProfile(
      userProfile,
      callback: IRCIMIWUpdateMyUserProfileCallback(
        onSuccess: () {
          debugPrint('updateMyUserProfile success');
          completer.complete(true);
        },
        onError: (int? code, List<String>? errorKeys) {
          debugPrint('updateMyUserProfile failed => $code $errorKeys');
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
  /// 内部方法
  /// =========================
  void _notify() {
  }

  void dispose() {
    _controller.close();
  }
}