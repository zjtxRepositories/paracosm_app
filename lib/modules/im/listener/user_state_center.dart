import 'dart:collection';

import 'package:paracosm/core/models/user_model.dart';
import 'package:paracosm/modules/im/manager/im_user_manager.dart';

class UserStateCenter {
  UserStateCenter._();

  static final UserStateCenter _instance = UserStateCenter._();
  factory UserStateCenter() => _instance;

  /// ===== cache =====
  final Map<String, UserModel> _cache = {};

  /// ===== pending requests (防重复请求) =====
  final Map<String, Future<UserModel?>> _pending = {};

  /// ===== version control（防乱序覆盖）=====
  final Map<String, int> _version = {};

  // -------------------------
  // get user（核心方法）
  // -------------------------
  Future<UserModel?> getUser(String id, {bool forceRefresh = false}) async {
    if (!forceRefresh && _cache.containsKey(id)) {
      return _cache[id];
    }

    return _pending[id] ??= _fetchAndUpdate(id);
  }

  // -------------------------
  // 内部 fetch
  // -------------------------
  Future<UserModel?> _fetchAndUpdate(String id) async {
    final version = (_version[id] ?? 0) + 1;
    _version[id] = version;

    final users = await ImUserManager().getUserProfiles([id]);

    final userProfile = users?.isNotEmpty == true ? users!.first : null;
    if (userProfile == null) {
      _pending.remove(id);
      return null;
    }

    final newUser = UserModel(profile: userProfile);

    /// 🔥 关键：防乱序覆盖
    if (version >= (_version[id] ?? 0)) {
      _cache[id] = newUser;
    }

    _pending.remove(id);
    return newUser;
  }

  // -------------------------
  // 手动更新（IM push用）
  // -------------------------
  void updateUser(UserModel user) {
    final id = user.profile.userId;
    if (id == null) return;
    final old = _cache[id];

    if (old == null ||
        old.profile.name != user.profile.name ||
        old.profile.portraitUri != user.profile.portraitUri) {
      _cache[id] = user;
    }
  }

  // -------------------------
  // 只读访问
  // -------------------------
  UserModel? getCached(String id) => _cache[id];

  Map<String, UserModel> snapshot() => UnmodifiableMapView(_cache);
}