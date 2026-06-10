import 'dart:async';
import 'dart:collection';

import 'package:paracosm/core/models/user_display_model.dart';
import 'package:paracosm/modules/im/manager/im_engine_manager.dart';
import 'package:paracosm/modules/im/manager/im_friend_manager.dart';
import 'package:paracosm/modules/im/manager/im_user_manager.dart';

class UserDisplayStateCenter {
  UserDisplayStateCenter._();

  static final UserDisplayStateCenter _instance = UserDisplayStateCenter._();

  factory UserDisplayStateCenter() => _instance;

  /// =========================
  /// unified cache（核心优化）
  /// =========================
  final Map<String, UserDisplayModel> _cache = {};

  /// =========================
  /// request deduplication
  /// =========================
  final Map<String, Future<UserDisplayModel?>> _pending = {};

  // ======================================================
  // 获取用户（唯一入口）
  // ======================================================

  Future<UserDisplayModel?> getUser(
    String userId, {
    bool forceRefresh = false,
  }) {
    if (!forceRefresh) {
      final cached = _cache[userId];
      if (cached != null) return Future.value(cached);
    }

    return _pending[userId] ??= _fetch(userId);
  }

  // ======================================================
  // fetch（统一数据来源）
  // ======================================================

  Future<UserDisplayModel?> _fetch(String userId) async {
    try {
      UserDisplayModel? result;
      final currentUserId = IMEngineManager().currentUserId;

      /// =========================
      /// 1️⃣ 当前用户
      /// =========================
      if (userId == currentUserId) {
        final user = await ImUserManager().getMyUserProfile();
        if (user != null) {
          result = UserDisplayModel(profile: user);
        }
      } else {
        /// =========================
        /// 2️⃣ friend 优先
        /// =========================
        final friends = await ImFriendManager().getFriendsInfo([userId]);

        final friend = friends?.isNotEmpty == true ? friends!.first : null;

        if (friend != null) {
          final old = _cache[userId];
          result = (old ?? UserDisplayModel(friend: friend)).copyWith(
            friend: friend,
          );
        } else {
          /// =========================
          /// 3️⃣ user fallback
          /// =========================
          final users = await ImUserManager().getUserProfiles([userId]);

          final user = users?.isNotEmpty == true ? users!.first : null;

          if (user != null) {
            final old = _cache[userId];
            result = (old ?? UserDisplayModel(profile: user)).copyWith(
              profile: user,
            );
          }
        }
      }

      /// =========================
      /// cache commit
      /// =========================
      if (result != null) {
        _cache[userId] = result;
      }

      return result;
    } finally {
      /// 一定要清 pending（避免卡死）
      _pending.remove(userId);
    }
  }

  // ======================================================
  // IM push update（增量合并）
  // ======================================================

  void updateFriend(dynamic friend) {
    final userId = friend.userId;
    if (userId == null) return;

    final old = _cache[userId];

    _cache[userId] = (old ?? UserDisplayModel.empty(userId)).copyWith(
      friend: friend,
    );
  }

  void updateUserProfile(dynamic profile) {
    final userId = profile.userId;
    if (userId == null) return;

    final old = _cache[userId];

    _cache[userId] = (old ?? UserDisplayModel.empty(userId)).copyWith(
      profile: profile,
    );
  }

  void removeFriend(String userId) {
    final oldFriend = _cache[userId];

    if (oldFriend != null) {
      _cache[userId] = UserDisplayModel(
        friend: null,
        profile: oldFriend.profile,
      );
    }
  }

  // ======================================================
  // UI API
  // ======================================================

  UserDisplayModel? getCached(String userId) {
    return _cache[userId];
  }

  UserDisplayModel getDisplayModel(String userId) {
    return _cache[userId] ?? UserDisplayModel.empty(userId);
  }

  // ======================================================
  // snapshot（只保留单源）
  // ======================================================

  Map<String, UserDisplayModel> snapshot() => UnmodifiableMapView(_cache);

  void resetForTesting() {
    _cache.clear();
    _pending.clear();
  }
}
