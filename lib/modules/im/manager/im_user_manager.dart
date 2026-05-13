import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import 'im_engine_manager.dart';

class ImUserManager {
  ImUserManager._internal();

  static final ImUserManager _instance =
  ImUserManager._internal();

  factory ImUserManager() => _instance;

  final _profileController =
  StreamController<RCIMIWUserProfile>.broadcast();

  Stream<RCIMIWUserProfile> get profileStream =>
      _profileController.stream;

  bool _initialized = false;

  /// 用户缓存
  final Map<String, RCIMIWUserProfile> _profileCache = {};

  RCIMIWEngine? get _engine =>
      IMEngineManager().engine;

  /// =========================
  /// 获取当前用户信息
  /// =========================
  Future<RCIMIWUserProfile?> getMyUserProfile({
    bool refresh = false,
  }) async {
    try {
      final completer =
      Completer<RCIMIWUserProfile?>();

      final ret = await _engine?.getMyUserProfile(
        callback: IRCIMIWGetMyUserProfileCallback(
          onSuccess: (
              RCIMIWUserProfile? userProfile,
              ) {
            if (userProfile != null) {
              _cacheProfile(userProfile);
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
      List<String> userIds, {
        bool refresh = false,
      }) async {
    try {
      /// 命中缓存
      if (!refresh) {
        final cached = userIds
            .map((e) => _profileCache[e])
            .whereType<RCIMIWUserProfile>()
            .toList();

        if (cached.length == userIds.length) {
          return cached;
        }
      }

      final completer =
      Completer<List<RCIMIWUserProfile>?>();

      final ret = await _engine?.getUserProfiles(
        userIds,
        callback: IRCIMIWGetUserProfilesCallback(
          onSuccess: (
              List<RCIMIWUserProfile>? userProfiles,
              ) {
            if (userProfiles != null) {
              for (final item in userProfiles) {
                _cacheProfile(item);
              }
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
              _cacheProfile(userProfile);
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
            _cacheProfile(userProfile);

            _safeAdd(userProfile);

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
  /// 获取缓存
  /// =========================
  RCIMIWUserProfile? getCachedProfile(
      String userId,
      ) {
    return _profileCache[userId];
  }

  /// =========================
  /// 清空缓存
  /// =========================
  void clearCache() {
    _profileCache.clear();
  }

  /// =========================
  /// 缓存用户
  /// =========================
  void _cacheProfile(
      RCIMIWUserProfile profile,
      ) {
    final userId = profile.userId;

    if (userId == null || userId.isEmpty) {
      return;
    }

    _profileCache[userId] = profile;
  }

  /// =========================
  /// SDK 错误
  /// =========================
  bool _isSdkError(int? ret) {
    if (ret != null && ret != 0) {
      debugPrint('SDK invoke failed => $ret');
      return true;
    }

    return false;
  }

  /// =========================
  /// 安全通知
  /// =========================
  void _safeAdd(
      RCIMIWUserProfile profile,
      ) {
    if (_profileController.isClosed) {
      return;
    }

    _profileController.add(profile);
  }

  /// =========================
  /// 日志
  /// =========================
  void _log(
      String message,
      int? code,
      ) {
    debugPrint('$message => $code');
  }

  /// =========================
  /// 销毁
  /// =========================
  void dispose() {
    _profileCache.clear();

    _profileController.close();

    _initialized = false;
  }
}