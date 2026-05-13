import 'dart:async';

import 'package:paracosm/modules/im/listener/group_state_center.dart';
import 'package:paracosm/modules/im/listener/user_state_center.dart';
import 'package:paracosm/modules/im/manager/im_group_manager.dart';
import 'package:paracosm/modules/im/manager/im_group_member_manager.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../../core/models/user_model.dart';
import '../manager/im_subscribe_event_manager.dart';

class ImDataCenter {
  ImDataCenter._internal();

  static final ImDataCenter _instance = ImDataCenter._internal();

  factory ImDataCenter() => _instance;

  final ImSubscribeEventManager _subscribe = ImSubscribeEventManager();

  bool _inited = false;

  /// =========================
  /// cache
  /// =========================
  final Map<String, PresenceState> _presenceCache = {};
  final Map<String, RCIMIWUserProfile> _profileCache = {};
  final Map<String, List<RCIMIWGroupMemberInfo>> _groupMemberCache = {};

  /// =========================
  /// stream
  /// =========================
  final _presenceController =
  StreamController<Map<String, PresenceState>>.broadcast();

  final _profileController =
  StreamController<List<String>>.broadcast();

  final _groupMemberController =
  StreamController<List<String>>.broadcast();

  final _groupInfoController =
  StreamController<List<String>>.broadcast();

  Stream<Map<String, PresenceState>> get presenceStream =>
      _presenceController.stream;

  Stream<List<String>> get profileStream =>
      _profileController.stream;

  Stream<List<String>> get groupMemberStream =>
      _groupMemberController.stream;

  Stream<List<String>> get groupInfoStream =>
      _groupInfoController.stream;

  /// =========================
  /// init（防重复）
  /// =========================
  void initListener() {
    if (_inited) return;
    _inited = true;

    _subscribe.initListener();

    /// presence
    _subscribe.stream.listen((map) {
      _presenceCache.addAll(map);
      _emitPresence();
    });

    /// profile
    _subscribe.profileStream.listen((map) {
      _profileCache.addAll(map);
      _emitProfile(map);
      _patchGroupMemberByProfile(map);
    });

    /// group member
    ImGroupMemberManager().stream.listen((map) {
      map.forEach((groupId, list) {
        _groupMemberCache[groupId] = list;
      });
    });

    /// group
    GroupEventBus.instance.stream.listen((event) {
      if (event.type == GroupEventType.infoChanged && event.groupInfo != null) {
        GroupStateCenter().updateGroupInfo(event.groupInfo!);
        _emitGroup([event.groupInfo!.groupId ?? '']);
      }

    });

  }

  /// =========================
  /// profile → patch group members
  /// =========================
  void _patchGroupMemberByProfile(
      Map<String, RCIMIWUserProfile> map,
      ) {
    bool changed = false;

    final Set<String> affectedGroupIds = {};

    _groupMemberCache.forEach((groupId, groupList) {
      final newList = groupList.map((member) {
        final profile = map[member.userId];
        if (profile == null) return member;

        changed = true;
        affectedGroupIds.add(groupId);
        member.name = profile.name;
        member.portraitUri = profile.portraitUri;
        return member;
      }).toList();

      if (changed) {
        _groupMemberCache[groupId] =
            List.unmodifiable(newList);
      }
    });

    if (affectedGroupIds.isNotEmpty) {
      _emitGroupMember(affectedGroupIds.toList());
    }
  }

  /// =========================
  /// API - presence
  /// =========================
  bool isOnline(String userId) {
    return _presenceCache[userId] == PresenceState.online;
  }

  PresenceState getPresence(String userId) {
    return _presenceCache[userId] ?? PresenceState.unknown;
  }

  /// =========================
  /// API - profile
  /// =========================
  RCIMIWUserProfile? getProfile(String userId) {
    return _profileCache[userId];
  }

  String getUserName(String userId) {
    return _profileCache[userId]?.name ?? '';
  }

  String getAvatar(String userId) {
    return _profileCache[userId]?.portraitUri ?? '';
  }

  /// =========================
  /// API - group member
  /// =========================
  List<RCIMIWGroupMemberInfo> getGroupMembers(String groupId) {
    return _groupMemberCache[groupId] ?? [];
  }

  /// =========================
  /// subscribe
  /// =========================
  Future<bool> subscribe(List<String> userIds) {
    return _subscribe.subscribeOnlineStatus(userIds);
  }

  Future<void> unsubscribe(List<String> userIds) {
    return _subscribe.unsubscribe(userIds);
  }

  /// =========================
  /// emit
  /// =========================
  void _emitPresence() {
    if (!_presenceController.isClosed) {
      _presenceController.add(Map.unmodifiable(_presenceCache));
    }
  }

  void _emitProfile(Map<String, RCIMIWUserProfile> map) {
    List<String> userIds = [];
    map.forEach((userId, profile) {
      UserStateCenter().updateUser(UserModel(profile: profile));
      userIds.add(userId);
    });
    if (!_profileController.isClosed) {
      _profileController.add(userIds);
    }
  }

  void _emitGroupMember(List<String> groupIds) {
    if (!_groupMemberController.isClosed) {
      _groupMemberController.add(groupIds);
    }
  }

  void _emitGroup(List<String> groupIds) {
    if (!_groupInfoController.isClosed) {
      _groupInfoController.add(groupIds);
    }
  }
  /// =========================
  /// dispose
  /// =========================
  void dispose() {
    _presenceController.close();
    _profileController.close();
    _groupMemberController.close();
  }
}