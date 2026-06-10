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
  // Friend
  // ======================================================
  final Map<String, RCIMIWFriendInfo> _friendCache = {};

  final _friendListChangeController =
      StreamController<List<RCIMIWFriendInfo>>.broadcast();

  Stream<List<RCIMIWFriendInfo>> get friendListStream =>
      _friendListChangeController.stream;

  List<RCIMIWFriendInfo> get friendListSnapshot =>
      List.unmodifiable(_friendCache.values);

  // ======================================================
  // Presence
  // ======================================================
  final Map<String, PresenceState> _presenceCache = {};

  final _presenceChangeController =
      StreamController<Map<String, PresenceState>>.broadcast();

  Stream<Map<String, PresenceState>> get presenceStream =>
      _presenceChangeController.stream;

  // ======================================================
  // User display
  // ======================================================

  final _userDisplayChangeController =
      StreamController<List<String>>.broadcast();

  Stream<List<String>> get profileStream => _userDisplayChangeController.stream;

  final _groupMemberChangeController =
      StreamController<List<String>>.broadcast();

  Stream<List<String>> get groupMemberStream =>
      _groupMemberChangeController.stream;

  // ======================================================
  // Group
  // ======================================================
  final Map<String, RCIMIWGroupInfo> _groupCache = {};

  final _groupListChangeController =
      StreamController<List<RCIMIWGroupInfo>>.broadcast();

  Stream<List<RCIMIWGroupInfo>> get groupListStream =>
      _groupListChangeController.stream;

  List<RCIMIWGroupInfo> get groupListSnapshot =>
      List.unmodifiable(_groupCache.values);

  final _groupInfoChangeController = StreamController<List<String>>.broadcast();

  Stream<List<String>> get groupInfoStream => _groupInfoChangeController.stream;

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
      _notifyPresenceChanged();
    });

    // =========================
    // profile
    // =========================
    _subscribe.profileStream.listen((map) {
      _applyProfiles(map);
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
          _removeGroupAndConversation(event.groupId);
          break;
        case GroupEventType.quit:
          if (event.operatorUserId != IMEngineManager().currentUserId) {
            await _refreshGroupState(event.groupId);
            return;
          }
          _removeGroupAndConversation(event.groupId);
          break;
        case GroupEventType.removed:
          if (event.userIds == null) return;
          if (!event.userIds!.contains(IMEngineManager().currentUserId)) {
            await _refreshGroupState(event.groupId);
            return;
          }
          _removeGroupAndConversation(event.groupId);
          break;
        case GroupEventType.memberChanged:
        case GroupEventType.managerChanged:
        case GroupEventType.ownerTransferred:
          await _refreshGroupState(event.groupId);
          break;
      }
    });
  }

  // ======================================================
  // Friend API
  // ======================================================

  void setFriendList(List<RCIMIWFriendInfo> list) {
    _friendCache.clear();

    for (final item in list) {
      if (item.userId == null) continue;
      _friendCache[item.userId!] = item;
      UserDisplayStateCenter().updateFriend(item);
    }

    _notifyFriendListChanged();
  }

  void updateFriend(RCIMIWFriendInfo friend) {
    final userId = friend.userId;
    if (userId == null) return;
    UserDisplayStateCenter().updateFriend(friend);
    _friendCache[userId] = friend;

    _notifyFriendListChanged();
    _notifyUserDisplayChanged([userId]);

    if ((friend.remark ?? '').isNotEmpty){
      _patchGroupMemberByProfile({userId: RCIMIWUserProfile.create(userId: friend.userId,portraitUri: friend.portrait,name: friend.remark)});
    }
  }

  void removeFriend(String userId, {bool deletedMessage = true}) {
    _friendCache.remove(userId);
    _notifyFriendListChanged();
    UserDisplayStateCenter().removeFriend(userId);
    _notifyUserDisplayChanged([userId]);
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

    _applyProfiles({userId: profile});
    _patchGroupMemberByProfile({userId: profile});
  }

  void setProfiles(List<RCIMIWUserProfile> profiles) {
    final map = <String, RCIMIWUserProfile>{};

    for (final profile in profiles) {
      final userId = profile.userId;

      if (userId == null || userId.isEmpty) {
        continue;
      }

      map[userId] = profile;
    }

    if (map.isNotEmpty) {
      _applyProfiles(map);
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
      GroupStateCenter().updateGroupInfo(item);
    }
    _notifyGroupListChanged();
  }

  void setGroup(RCIMIWGroupInfo group) {
    final groupId = group.groupId;

    if (groupId == null || groupId.isEmpty) {
      return;
    }
    _groupCache[groupId] = group;
    GroupStateCenter().updateGroupInfo(group);
    _notifyGroupListChanged();
    _notifyGroupInfoChanged([groupId]);
  }

  void removeGroup(String groupId) {
    _groupCache.remove(groupId);
    GroupStateCenter().removeGroup(groupId);
    _notifyGroupListChanged();
    _notifyGroupInfoChanged([groupId]);
    _notifyGroupMemberChanged([groupId]);
  }

  void removeGroupAndConversation(String groupId) {
    removeGroup(groupId);
    _removeConversation(groupId, RCIMIWConversationType.group);
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
      final groupIds = affected.toList();
      _notifyGroupInfoChanged(groupIds);
      _notifyGroupMemberChanged(groupIds);
    }
  }

  void setGroupMembers(String groupId, List<RCIMIWGroupMemberInfo> list) {
    GroupStateCenter().updateMembers(groupId, list);
    _notifyGroupMemberChanged([groupId]);
    _notifyGroupInfoChanged([groupId]);
  }

  void removeGroupMembers(String groupId) {
    GroupStateCenter().removeMembers(groupId);
    _notifyGroupMemberChanged([groupId]);
    _notifyGroupInfoChanged([groupId]);
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
  // notify
  // ======================================================

  void _notifyFriendListChanged() {
    if (_friendListChangeController.isClosed) return;

    _friendListChangeController.add(_friendCache.values.toList());
  }

  void _notifyPresenceChanged() {
    if (_presenceChangeController.isClosed) return;

    _presenceChangeController.add(Map.unmodifiable(_presenceCache));
  }

  void _applyProfiles(Map<String, RCIMIWUserProfile> map) {
    final userIds = <String>[];
    var friendListChanged = false;

    map.forEach((userId, profile) {
      UserDisplayStateCenter().updateUserProfile(profile);
      userIds.add(userId);

      final friend = _friendCache[userId];
      if (friend != null) {
        var changed = false;
        final name = profile.name;
        if (name != null && name.isNotEmpty && friend.name != name) {
          friend.name = name;
          changed = true;
        }

        final portrait = profile.portraitUri;
        if (portrait != null &&
            portrait.isNotEmpty &&
            friend.portrait != portrait) {
          friend.portrait = portrait;
          changed = true;
        }

        if (changed) {
          UserDisplayStateCenter().updateFriend(friend);
          friendListChanged = true;
        }
      }
    });

    if (friendListChanged) {
      _notifyFriendListChanged();
    }

    _notifyUserDisplayChanged(userIds);
  }

  void _notifyUserDisplayChanged(List<String> userIds) {
    if (userIds.isEmpty || _userDisplayChangeController.isClosed) return;

    _userDisplayChangeController.add(List.unmodifiable(userIds));
  }

  void _notifyGroupListChanged() {
    if (_groupListChangeController.isClosed) return;

    _groupListChangeController.add(_groupCache.values.toList());
  }

  void _notifyGroupInfoChanged(List<String> groupIds) {
    if (groupIds.isEmpty || _groupInfoChangeController.isClosed) return;

    _groupInfoChangeController.add(List.unmodifiable(groupIds));
  }

  void _notifyGroupMemberChanged(List<String> groupIds) {
    if (groupIds.isEmpty || _groupMemberChangeController.isClosed) return;

    _groupMemberChangeController.add(List.unmodifiable(groupIds));
  }

  Future<void> _refreshGroupState(String groupId) async {
    if (groupId.isEmpty) return;

    try {
      final info = await GroupStateCenter().getGroup(
        groupId,
        forceRefresh: true,
      );
      if (info != null) {
        _groupCache[groupId] = info;
        _notifyGroupListChanged();
      }

      await GroupStateCenter().getGroupMembers(groupId, forceRefresh: true);

      _notifyGroupInfoChanged([groupId]);
      _notifyGroupMemberChanged([groupId]);
    } catch (_) {
      // 忽略单次远端刷新失败，后续事件或页面主动拉取会继续同步。
    }
  }

  void _removeGroupAndConversation(String groupId) {
    removeGroupAndConversation(groupId);
  }

  List<RCIMIWFriendInfo> get friends {
    return _friendCache.values.toList();
  }
  // ======================================================
  // dispose
  // ======================================================

  void dispose() {
    _friendListChangeController.close();
    _presenceChangeController.close();
    _userDisplayChangeController.close();
    _groupMemberChangeController.close();
    _groupInfoChangeController.close();
  }
}
