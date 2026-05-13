// import 'dart:async';
// import 'dart:collection';
//
// import 'package:paracosm/core/models/user_model.dart';
// import 'package:paracosm/modules/im/manager/im_friend_manager.dart';
// import 'package:paracosm/modules/im/listener/user_state_center.dart';
//
// class UserDisplayStateCenter {
//   UserDisplayStateCenter._();
//
//   static final UserDisplayStateCenter _instance =
//   UserDisplayStateCenter._();
//
//   factory UserDisplayStateCenter() => _instance;
//
//   /// =========================
//   /// cache
//   /// =========================
//   final Map<String, UserModel> _friendCache = {};
//   final Map<String, UserModel> _userCache = {};
//
//   /// =========================
//   /// pending（防重复请求）
//   /// =========================
//   final Map<String, Future<UserModel?>> _pending = {};
//
//   /// =========================
//   /// version（防乱序覆盖）
//   /// =========================
//   final Map<String, int> _version = {};
//
//   // =========================
//   // 核心获取方法
//   // =========================
//
//   Future<UserModel?> getUser(
//       String userId, {
//         bool forceRefresh = false,
//       }) async {
//     if (!forceRefresh) {
//       final friend = _friendCache[userId];
//       if (friend != null) return friend;
//
//       final user = _userCache[userId];
//       if (user != null) return user;
//     }
//
//     return _pending[userId] ??= _fetch(userId);
//   }
//
//   // =========================
//   // fetch
//   // =========================
//
//   Future<UserModel?> _fetch(String userId) async {
//     final version = (_version[userId] ?? 0) + 1;
//     _version[userId] = version;
//
//     UserModel? result;
//
//     /// 1️⃣ friend 优先
//     final friend = await ImFriendManager().getFriend(userId);
//     if (friend != null) {
//       result = UserModel.fromFriend(friend);
//       _friendCache[userId] = result;
//     } else {
//       /// 2️⃣ user fallback
//       final user = await UserStateCenter().getUser(userId);
//       if (user != null) {
//         result = user;
//         _userCache[userId] = result;
//       }
//     }
//
//     _pending.remove(userId);
//
//     /// 防乱序（轻量版）
//     if (result != null && version >= (_version[userId] ?? 0)) {
//       _cache(result);
//     }
//
//     return result;
//   }
//
//   // =========================
//   // cache merge
//   // =========================
//
//   void _cache(UserModel model) {
//     final id = model.profile.userId;
//
//     if (_friendCache.containsKey(id)) {
//       _friendCache[id] = model;
//     } else {
//       _userCache[id] = model;
//     }
//   }
//
//   // =========================
//   // push update
//   // =========================
//
//   void updateUser(UserModel model, {bool isFriend = false}) {
//     final id = model.profile.userId;
//     if (id == null) return;
//
//     if (isFriend) {
//       _friendCache[id] = model;
//     } else {
//       _userCache[id] = model;
//     }
//   }
//
//   // =========================
//   // UI API
//   // =========================
//
//   UserModel? getCached(String userId) {
//     return _friendCache[userId] ?? _userCache[userId];
//   }
//
//   UserModel getDisplayModel(String userId) {
//     return _friendCache[userId] ??
//         _userCache[userId] ??
//         UserModel.empty(userId);
//   }
//
//   // =========================
//   // snapshot
//   // =========================
//
//   Map<String, UserModel> snapshot() =>
//       UnmodifiableMapView({..._userCache, ..._friendCache});
// }