import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../listener/im_data_center.dart';
import 'im_engine_manager.dart';

class ImUserManager {
  ImUserManager._internal();

  static final ImUserManager _instance =
  ImUserManager._internal();

  factory ImUserManager() => _instance;

  RCIMIWEngine? get _engine =>
      IMEngineManager().engine;

  /// =========================
  /// 获取当前用户信息
  /// =========================
  Future<RCIMIWUserProfile?> getMyUserProfile() async {
    try {
      final completer =
      Completer<RCIMIWUserProfile?>();

      final ret = await _engine?.getMyUserProfile(
        callback: IRCIMIWGetMyUserProfileCallback(
          onSuccess: (
              RCIMIWUserProfile? userProfile,
              ) {
            if (userProfile != null) {
              ImDataCenter().setProfile(userProfile);
            }

            completer.complete(userProfile);
          },
          onError: (int? code) {
            _log(
              'getMyUserProfile failed',
              code,
            );

            completer.complete(null);
          },
        ),
      );

      if (_isSdkError(ret)) {
        return null;
      }

      return completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
    } catch (e) {
      debugPrint(
        'getMyUserProfile exception => $e',
      );

      return null;
    }
  }

  /// =========================
  /// 批量获取用户信息
  /// =========================
  Future<List<RCIMIWUserProfile>?> getUserProfiles(
      List<String> userIds) async {
    try {
      final completer =
      Completer<List<RCIMIWUserProfile>?>();
      final ret = await _engine?.getUserProfiles(
        userIds,
        callback: IRCIMIWGetUserProfilesCallback(
          onSuccess: (
              List<RCIMIWUserProfile>? userProfiles,
              ) {
            if (userProfiles != null &&
                userProfiles.isNotEmpty) {
              ImDataCenter().setProfiles(
                userProfiles,
              );
            }

            completer.complete(userProfiles);
          },
          onError: (int? code) {
            _log(
              'getUserProfiles failed',
              code,
            );

            completer.complete(null);
          },
        ),
      );

      if (_isSdkError(ret)) {
        return null;
      }

      return completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
    } catch (e) {
      debugPrint(
        'getUserProfiles exception => $e',
      );

      return null;
    }
  }

  /// =========================
  /// 搜索用户
  /// =========================
  Future<RCIMIWUserProfile?>
  searchUserProfileByUniqueId(
      String uniqueId,
      ) async {
    try {
      final completer =
      Completer<RCIMIWUserProfile?>();

      final ret =
      await _engine?.searchUserProfileByUniqueId(
        uniqueId,
        callback:
        IRCIMIWSearchUserProfileByUniqueIdCallback(
          onSuccess: (
              RCIMIWUserProfile? userProfile,
              ) {
            if (userProfile != null) {
              ImDataCenter().setProfile(
                userProfile,
              );
            }

            completer.complete(userProfile);
          },
          onError: (int? code) {
            _log(
              'searchUserProfileByUniqueId failed',
              code,
            );

            completer.complete(null);
          },
        ),
      );

      if (_isSdkError(ret)) {
        return null;
      }

      return completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
    } catch (e) {
      debugPrint(
        'searchUserProfileByUniqueId exception => $e',
      );

      return null;
    }
  }

  /// =========================
  /// 更新当前用户信息
  /// =========================
  Future<bool> updateMyUserProfile({
    required RCIMIWUserProfile userProfile,
  }) async {
    try {
      final completer = Completer<bool>();

      final ret =
      await _engine?.updateMyUserProfile(
        userProfile,
        callback:
        IRCIMIWUpdateMyUserProfileCallback(
          onSuccess: () {
            ImDataCenter().setProfile(
              userProfile,
            );

            completer.complete(true);
          },
          onError: (
              int? code,
              List<String>? errorKeys,
              ) {
            debugPrint(
              'updateMyUserProfile failed => '
                  '$code $errorKeys',
            );

            completer.complete(false);
          },
        ),
      );

      if (_isSdkError(ret)) {
        return false;
      }

      return completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => false,
      );
    } catch (e) {
      debugPrint(
        'updateMyUserProfile exception => $e',
      );

      return false;
    }
  }

  /// =========================
  /// SDK invoke error
  /// =========================
  bool _isSdkError(int? ret) {
    if (ret != null && ret != 0) {
      debugPrint(
        'SDK invoke failed => $ret',
      );

      return true;
    }

    return false;
  }

  /// =========================
  /// log
  /// =========================
  void _log(
      String message,
      int? code,
      ) {
    debugPrint('$message => $code');
  }

  /// =========================
  /// dispose
  /// =========================
  void dispose() {}
}