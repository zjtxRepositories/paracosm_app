import 'dart:async';

import 'package:paracosm/modules/im/listener/group_state_center.dart';
import 'package:paracosm/modules/im/listener/user_display_state_center.dart';
import 'package:paracosm/modules/im/manager/im_conversation_manager.dart';
import 'package:paracosm/modules/im/manager/im_engine_manager.dart';
import 'package:paracosm/modules/im/manager/im_message_manager.dart';
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

  List<RCIMIWFriendInfo> get friendListSnapshot =>
      List.unmodifiable(_friendCache.values);

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

  final _profileController = StreamController<List<String>>.broadcast();

  Stream<List<String>> get profileStream => _profileController.stream;

  // ======================================================
  // Group member
  // ======================================================
  // final Map<String, List<RCIMIWGroupMemberInfo>> _groupMemberCache = {};

  final _groupMemberController = StreamController<List<String>>.broadcast();

  Stream<List<String>> get groupMemberStream => _groupMemberController.stream;

  // ======================================================
  // Group
  // ======================================================
  final Map<String, RCIMIWGroupInfo> _groupCache = {};

  final _groupListController =
      StreamController<List<RCIMIWGroupInfo>>.broadcast();

  Stream<List<RCIMIWGroupInfo>> get groupListStream =>
      _groupListController.stream;

  List<RCIMIWGroupInfo> get groupListSnapshot =>
      List.unmodifiable(_groupCache.values);

  final _groupInfoController = StreamController<List<String>>.broadcast();

  Stream<List<String>> get groupInfoStream => _groupInfoController.stream;

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
      _emitProfile(map);
      _patchGroupMemberByProfile(map);
    });

    // =========================
    // group info
    // =========================
    GroupEventBus.instance.stream.listen((event) async {
      switch (event.type) {
        case GroupEventType.created:
        case GroupEventType.joined:
        case GroupEventType.infoChanged:
          final info = event.groupInfo;
          if (info != null) {
            setGroup(info);
          }
          break;
        case GroupEventType.dismissed:
          removeGroup(event.groupId);
          _removeConversation(event.groupId, RCIMIWConversationType.group);
          break;
        case GroupEventType.quit:
          if (event.operatorUserId != IMEngineManager().currentUserId){
            GroupStateCenter().refreshGroup(event.groupId);
            return;
          }
          _removeGroup(event.groupId);
          break;
        case GroupEventType.removed:
          if (event.userIds == null) return;
          if (!event.userIds!.contains(IMEngineManager().currentUserId)){
            GroupStateCenter().refreshGroup(event.groupId);
            return;
          }
          _removeGroup(event.groupId);
          break;
        case GroupEventType.memberChanged:
        case GroupEventType.managerChanged:
        case GroupEventType.ownerTransferred:
          GroupStateCenter().refreshGroup(event.groupId);
          break;
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
    UserDisplayStateCenter().updateFriend(friend);
    _friendCache[userId] = friend;

    _emitFriendList();
    _emitFriend(userId);
  }

  void removeFriend(String userId, {bool deletedMessage = true}) {
    _friendCache.remove(userId);
    _emitFriendList();
    UserDisplayStateCenter().removeFriend(userId);
    _emitFriend(userId);
    _removeConversation(
      userId,
      RCIMIWConversationType.private,
      deletedMessage: deletedMessage,
    );
  }

  // ======================================================
  // Profile API
  // ======================================================

  void setProfile(RCIMIWUserProfile profile) {
    final userId = profile.userId;
    if (userId == null || userId.isEmpty) {
      return;
    }
    UserDisplayStateCenter().updateUserProfile(profile);
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
  // group API
  // ======================================================
  void setGroupList(List<RCIMIWGroupInfo> list) {
    _groupCache.clear();

    for (final item in list) {
      if (item.groupId == null) continue;
      _groupCache[item.groupId!] = item;
    }
    _emitGroupList();
  }

  void setGroup(RCIMIWGroupInfo group) {
    final groupId = group.groupId;

    if (groupId == null || groupId.isEmpty) {
      return;
    }
    _groupCache[groupId] = group;
    GroupStateCenter().updateGroupInfo(group);
    _emitGroup([groupId]);

  }

  void removeGroup(String groupId) {
    _groupCache.remove(groupId);
    _emitGroup([groupId]);

  }

  void _removeConversation(
    String targetId,
    RCIMIWConversationType type, {
    bool deletedMessage = true,
  }) {
    ImConversationManager().removeConversationByTargetId(targetId, type);
    if (!deletedMessage) return;
    ImMessageManager().clearMessages(
      type: type,
      targetId: targetId,
      timestamp: 0,
    );
  }

  // ======================================================
  // group member API
  // ======================================================
  void _patchGroupMemberByProfile(Map<String, RCIMIWUserProfile> map) {
    final Set<String> affected = {};

    GroupStateCenter().snapshotMember().forEach((groupId, list) {
      list.map((m) {
        final profile = map[m.userId];
        if (profile == null) return m;
        affected.add(groupId);
        return m;
      }).toList();
    });
    map.forEach((userId, profile) {
      GroupStateCenter().patchMemberProfile(
        userId: userId,
        name: profile.name,
        portrait: profile.portraitUri,
      );
    });

    if (affected.isNotEmpty) {
      _emitGroup(affected.toList());

    }
  }

  void setGroupMembers(String groupId, List<RCIMIWGroupMemberInfo> list) {
    GroupStateCenter().updateMembers(groupId, list);
    _emitGroup([groupId]);
  }

  void removeGroupMembers(String groupId) {
    GroupStateCenter().removeGroup(groupId);
    _emitGroup([groupId]);

  }

  List<RCIMIWGroupMemberInfo> getGroupMembers(String groupId) {
    return GroupStateCenter().getMembers(groupId);
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

    _friendListController.add(_friendCache.values.toList());
  }

  void _emitPresence() {
    if (_presenceController.isClosed) return;

    _presenceController.add(Map.unmodifiable(_presenceCache));
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

  void _emitGroupList() {
    if (_groupListController.isClosed) return;

    _groupListController.add(_groupCache.values.toList());
  }

  void _emitGroup(List<String> groupIds) {
    if (!_profileController.isClosed) {
      _groupInfoController.add(groupIds);
    }
  }


  Future<void> _removeGroup(String groupId) async {
    if (!_groupCache.containsKey(groupId)) return;
    removeGroup(groupId);
    GroupStateCenter().refreshGroup(groupId);
    _removeConversation(groupId,RCIMIWConversationType.group);
  }

  List<RCIMIWFriendInfo> get friends {
    return _friendCache.values.toList();
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
