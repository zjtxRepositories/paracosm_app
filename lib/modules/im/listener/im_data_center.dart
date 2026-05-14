import 'dart:async';

import 'package:paracosm/modules/im/listener/group_state_center.dart';
import 'package:paracosm/modules/im/listener/user_display_state_center.dart';
import 'package:paracosm/modules/im/manager/im_group_member_manager.dart';
import 'package:paracosm/modules/im/manager/im_subscribe_event_manager.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../manager/im_group_manager.dart';

class ImDataCenter {
  ImDataCenter._internal();

  static final ImDataCenter _instance = ImDataCenter._internal();

  factory ImDataCenter() => _instance;

  final ImSubscribeEventManager _subscribe = ImSubscribeEventManager();

  bool _inited = false;

  // ======================================================
  // Friend cache + stream（核心新增）
  // ======================================================
  final Map<String, RCIMIWFriendInfo> _friendCache = {};

  final _friendListController =
  StreamController<List<RCIMIWFriendInfo>>.broadcast();

  Stream<List<RCIMIWFriendInfo>> get friendListStream =>
      _friendListController.stream;

  // ======================================================
  // Presence
  // ======================================================
  final Map<String, PresenceState> _presenceCache = {};

  final _presenceController =
  StreamController<Map<String, PresenceState>>.broadcast();

  Stream<Map<String, PresenceState>> get presenceStream =>
      _presenceController.stream;

  // ======================================================
  // Profile
  // ======================================================
  final Map<String, RCIMIWUserProfile> _profileCache = {};

  final _profileController =
  StreamController<List<String>>.broadcast();

  Stream<List<String>> get profileStream =>
      _profileController.stream;

  // ======================================================
  // Group member
  // ======================================================
  final Map<String, List<RCIMIWGroupMemberInfo>> _groupMemberCache = {};

  final _groupMemberController =
  StreamController<List<String>>.broadcast();

  Stream<List<String>> get groupMemberStream =>
      _groupMemberController.stream;

  final _groupInfoController =
  StreamController<List<String>>.broadcast();

  Stream<List<String>> get groupInfoStream =>
      _groupInfoController.stream;

  // ======================================================
  // init
  // ======================================================
  void initListener() {
    if (_inited) return;
    _inited = true;

    _subscribe.initListener();

    // =========================
    // presence
    // =========================
    _subscribe.stream.listen((map) {
      _presenceCache.addAll(map);
      _emitPresence();
    });

    // =========================
    // profile
    // =========================
    _subscribe.profileStream.listen((map) {
      _profileCache.addAll(map);

      _emitProfile(map);
      _patchGroupMemberByProfile(map);
    });

    // =========================
    // group member
    // =========================
    ImGroupMemberManager().stream.listen((map) {
      map.forEach((groupId, list) {
        _groupMemberCache[groupId] = list;
      });
    });

    // =========================
    // group info
    // =========================
    GroupEventBus.instance.stream.listen((event) {
      if (event.type == GroupEventType.infoChanged &&
          event.groupInfo != null) {
        GroupStateCenter().updateGroupInfo(event.groupInfo!);

        _emitGroup([event.groupInfo!.groupId ?? '']);
      }
    });
  }

  // ======================================================
  // Friend API（核心）
  // ======================================================

  void setFriendList(List<RCIMIWFriendInfo> list) {
    _friendCache.clear();

    for (final item in list) {
      if (item.userId == null) continue;
      _friendCache[item.userId!] = item;
    }

    _emitFriendList();
  }

  void updateFriend(RCIMIWFriendInfo friend) {
    final userId = friend.userId;
    if (userId == null) return;

    _friendCache[userId] = friend;

    _emitFriendList();
    print('好友信息-------${friend.toJson()}');
    _emitFriend(userId);
  }

  void removeFriend(String userId) {
    _friendCache.remove(userId);
    _profileCache.remove(userId);

    _emitFriendList();
    _emitFriend(userId);
  }


  // ======================================================
  // Profile API
  // ======================================================

  void setProfile(RCIMIWUserProfile profile) {
    final userId = profile.userId;
    if (userId == null || userId.isEmpty) {
      return;
    }
    UserDisplayStateCenter().updateUserProfile(
      profile,
    );
  }

  void setProfiles(List<RCIMIWUserProfile> profiles) {
    for (final profile in profiles) {
      final userId = profile.userId;

      if (userId == null || userId.isEmpty) {
        continue;
      }
      UserDisplayStateCenter().updateUserProfile(profile);
    }
  }
  // ======================================================
  // Presence API
  // ======================================================

  bool isOnline(String userId) =>
      _presenceCache[userId] == PresenceState.online;

  PresenceState getPresence(String userId) =>
      _presenceCache[userId] ?? PresenceState.unknown;

  // ======================================================
  // subscribe
  // ======================================================

  Future<bool> subscribe(List<String> userIds) =>
      _subscribe.subscribeOnlineStatus(userIds);

  Future<void> unsubscribe(List<String> userIds) =>
      _subscribe.unsubscribe(userIds);

  // ======================================================
  // emit
  // ======================================================

  void _emitFriendList() {
    if (_friendListController.isClosed) return;

    _friendListController.add(
      _friendCache.values.toList(),
    );
  }

  void _emitPresence() {
    if (_presenceController.isClosed) return;

    _presenceController.add(
      Map.unmodifiable(_presenceCache),
    );
  }

  void _emitFriend(String userId) {
    if (!_profileController.isClosed) {
      _profileController.add([userId]);
    }
  }

  void _emitProfile(Map<String, RCIMIWUserProfile> map) {
    final userIds = <String>[];

    map.forEach((userId, profile) {
      UserDisplayStateCenter().updateUserProfile(profile);
      userIds.add(userId);
    });

    if (!_profileController.isClosed) {
      _profileController.add(userIds);
    }
  }

  void _emitGroup(List<String> groupIds) {
    if (!_profileController.isClosed) {
      _groupInfoController.add(groupIds);
    }

  }


  void _patchGroupMemberByProfile(Map<String, RCIMIWUserProfile> map) {
    final Set<String> affected = {};

    _groupMemberCache.forEach((groupId, list) {
      bool changed = false;

      final newList = list.map((m) {
        final profile = map[m.userId];
        if (profile == null) return m;

        changed = true;
        affected.add(groupId);

        // ✔ 正确：只处理当前 m
        m.name = profile.name;
        m.portraitUri = profile.portraitUri;

        return m;
      }).toList();

      if (changed) {
        _groupMemberCache[groupId] = List.unmodifiable(newList);
      }
    });
    if (affected.isNotEmpty) {
      _emitGroup(affected.toList());
    }
  }

  // ======================================================
  // dispose
  // ======================================================

  void dispose() {
    _friendListController.close();
    _presenceController.close();
    _profileController.close();
    _groupMemberController.close();
    _groupInfoController.close();
  }
}