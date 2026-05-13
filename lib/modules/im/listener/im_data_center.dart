import 'dart:async';

import 'package:paracosm/modules/im/manager/im_group_member_manager.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

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
  StreamController<Map<String, RCIMIWUserProfile>>.broadcast();

  final _groupMemberController =
  StreamController<Map<String, List<RCIMIWGroupMemberInfo>>>.broadcast();

  Stream<Map<String, PresenceState>> get presenceStream =>
      _presenceController.stream;

  Stream<Map<String, RCIMIWUserProfile>> get profileStream =>
      _profileController.stream;

  Stream<Map<String, List<RCIMIWGroupMemberInfo>>> get groupMemberStream =>
      _groupMemberController.stream;

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
      _emitProfile();
      _patchGroupMemberByProfile(map);
    });

    /// group member
    ImGroupMemberManager().stream.listen((map) {
      map.forEach((groupId, list) {
        _groupMemberCache[groupId] = list;
      });

      _emitGroupMember();
    });
  }

  /// =========================
  /// profile → patch group members
  /// =========================
  void _patchGroupMemberByProfile(
      Map<String, RCIMIWUserProfile> map,
      ) {
    bool changed = false;

    for (final entry in map.entries) {
      final userId = entry.key;
      final profile = entry.value;

      for (final groupList in _groupMemberCache.values) {
        for (final member in groupList) {
          if (member.userId == userId) {
            member.name = profile.name;
            member.portraitUri = profile.portraitUri;
            changed = true;
          }
        }
      }
    }

    if (changed) {
      _emitGroupMember();
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

  void _emitProfile() {
    if (!_profileController.isClosed) {
      _profileController.add(Map.unmodifiable(_profileCache));
    }
  }

  void _emitGroupMember() {
    if (!_groupMemberController.isClosed) {
      _groupMemberController.add(
        Map.unmodifiable(_groupMemberCache),
      );
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