import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:paracosm/modules/im/listener/im_data_center.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../listener/group_state_center.dart';
import 'im_engine_manager.dart';

/// =======================================================
/// 群事件类型
/// =======================================================
enum GroupEventType {
  created,
  joined,
  quit,
  dismissed,
  infoChanged,
  memberChanged,
  removed,
}

/// =======================================================
/// 群事件
/// =======================================================
class GroupEvent {
  final GroupEventType type;

  final String groupId;

  final RCIMIWGroupInfo? groupInfo;

  final String? operatorUserId;

  final dynamic data;

  final List<String>? userIds;

  GroupEvent({
    required this.type,
    required this.groupId,
    this.operatorUserId,
    this.groupInfo,
    this.data, this.userIds,
  });
}

/// =======================================================
/// 群事件总线
/// =======================================================
class GroupEventBus {
  GroupEventBus._();

  static final GroupEventBus instance =
  GroupEventBus._();

  final StreamController<GroupEvent> _controller =
  StreamController<GroupEvent>.broadcast();

  Stream<GroupEvent> get stream =>
      _controller.stream;

  void fire(GroupEvent event) {
    if (_controller.isClosed) return;

    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}

/// =======================================================
/// 群管理器
/// =======================================================
class ImGroupManager {
  ImGroupManager._();

  static final ImGroupManager instance =
  ImGroupManager._();

  factory ImGroupManager() => instance;

  bool _initialized = false;

  RCIMIWEngine? get _engine =>
      IMEngineManager().engine;

  /// =======================================================
  /// 初始化监听
  /// =======================================================
  void initListener() {
    if (_initialized) return;

    _initialized = true;

    final engine = _engine;

    if (engine == null) {
      debugPrint('IM engine 未初始化');
      return;
    }

    /// ===================================================
    /// 群操作监听
    /// ===================================================
    engine.onGroupOperation = (
        String? groupId,
        RCIMIWGroupMemberInfo? operatorInfo,
        RCIMIWGroupInfo? groupInfo,
        RCIMIWGroupOperation? operation,
        List<RCIMIWGroupMemberInfo>? memberInfos,
        int? operationTime,
        ) async {
      debugPrint(
        '群操作: operation=$operation groupId=$groupId operatorInfo=${operatorInfo?.userId}',
      );

      if (groupId == null || groupId.isEmpty) {
        return;
      }

      switch (operation) {
      /// =========================
      /// 创建群
      /// =========================
        case RCIMIWGroupOperation.create:
          GroupEventBus.instance.fire(
            GroupEvent(
              type: GroupEventType.created,
              groupId: groupId,
              groupInfo: groupInfo,
              operatorUserId: operatorInfo?.userId
            ),
          );

          break;

      /// =========================
      /// 加入群
      /// =========================
        case RCIMIWGroupOperation.join:
          if (groupInfo == null) {
            await refreshGroup(groupId);
          }
          GroupEventBus.instance.fire(
            GroupEvent(
                type: GroupEventType.joined,
                groupId: groupId,
                groupInfo: groupInfo,
                operatorUserId: operatorInfo?.userId
            ),
          );

          break;

      /// =========================
      /// 退群
      /// =========================
        case RCIMIWGroupOperation.quit:
          GroupEventBus.instance.fire(
            GroupEvent(
                type: GroupEventType.quit,
                groupId: groupId,
                operatorUserId: operatorInfo?.userId
            ),
          );

          break;

      /// =========================
      /// 解散群
      /// =========================
        case RCIMIWGroupOperation.dismiss:
          GroupEventBus.instance.fire(
            GroupEvent(
              type: GroupEventType.dismissed,
              groupId: groupId,
            ),
          );

          break;

        default:
          break;
      }
    };

    /// ===================================================
    /// 群资料更新
    /// ===================================================
    engine.onGroupInfoChanged = (
        RCIMIWGroupMemberInfo? operatorInfo,
        RCIMIWGroupInfo? fullGroupInfo,
        RCIMIWGroupInfo? changedGroupInfo,
        int? operationTime,
        ) {
      if (fullGroupInfo == null) {
        return;
      }
      GroupEventBus.instance.fire(
        GroupEvent(
          type: GroupEventType.infoChanged,
          groupId: fullGroupInfo.groupId ?? '',
          groupInfo: fullGroupInfo,
        ),
      );
    };

    if (IMEngineManager().connection.isConnected){
    /// 首次拉取
    refreshAllGroups();
    }
  }

  /// =======================================================
  /// 拉取全部群
  /// =======================================================
  Future<List<RCIMIWGroupInfo>>
  getAllJoinedGroups() async {
    final List<RCIMIWGroupInfo> allGroups = [];

    String? pageToken;

    bool hasMore = true;

    while (hasMore) {
      final completer =
      Completer<
          RCIMIWPagingQueryResult<
              RCIMIWGroupInfo>>();

      final option = RCIMIWPagingQueryOption.create(
        count: 50,
        pageToken: pageToken,
        order: false,
      );

      final ret =
      await _engine?.getJoinedGroupsByRole(
        RCIMIWGroupMemberRole.undef,
        option,
        callback:
        IRCIMIWGetJoinedGroupsByRoleCallback(
          onSuccess: (result) {
            completer.complete(result);
          },
          onError: (code) {
            completer.completeError(code ?? -1);
          },
        ),
      );

      if (ret != null && ret != 0) {
        throw Exception(
          'getJoinedGroups error: $ret',
        );
      }

      final result = await completer.future;

      final list = result.data ?? [];

      allGroups.addAll(list);

      final nextToken = result.pageToken;

      hasMore =
          nextToken != null &&
              nextToken.isNotEmpty;

      if (nextToken == pageToken) {
        break;
      }

      pageToken = nextToken;
    }

    ImDataCenter().setGroupList(allGroups);

    return allGroups;
  }

  /// =======================================================
  /// 刷新全部群
  /// =======================================================
  Future<void> refreshAllGroups() async {
    try {
      await getAllJoinedGroups();
    } catch (e) {
      debugPrint('刷新群失败: $e');
    }
  }

  /// =======================================================
  /// 刷新单个群
  /// =======================================================
  Future<RCIMIWGroupInfo?> refreshGroup(
      String groupId,
      ) async {
    final result =
    await getGroupsInfo([groupId]);

    final group = result?.firstOrNull;

    if (group != null) {
      ImDataCenter().setGroup(group);
    }

    return group;
  }

  /// =======================================================
  /// 创建群
  /// =======================================================
  Future<String?> create({
    required List<String> inviteeUserIds,
    required String groupId,
    String? groupName,
  }) async {
    final groupInfo = RCIMIWGroupInfo.create(
      groupId: groupId,
      groupName: groupName ?? '[默认]',
      invitePermission: RCIMIWGroupOperationPermission.everyone,
      joinPermission: RCIMIWGroupJoinPermission.free
    );

    return createByGroupInfo(
      groupInfo,
      inviteeUserIds,
    );
  }

  Future<String?> createByGroupInfo(
      RCIMIWGroupInfo groupInfo,
      List<String> inviteeUserIds,
      ) async {
    final completer = Completer<String?>();

    try {
      groupInfo.extProfile ??= {};

      final engine = _engine;

      if (engine == null) {
        completer.complete(null);
        return completer.future;
      }

      await engine.createGroup(
        groupInfo,
        inviteeUserIds,
        callback: IRCIMIWCreateGroupCallback(
          onSuccess: (result) {
            GroupEventBus.instance.fire(
              GroupEvent(
                type: GroupEventType.created,
                groupId:
                groupInfo.groupId ?? '',
                groupInfo: groupInfo,
              ),
            );

            completer.complete(
              groupInfo.groupId,
            );
          },
          onError: (
              int? errorCode,
              String? errorInfo,
              ) {
            debugPrint(
              '创建群失败: '
                  'code=$errorCode info=$errorInfo',
            );

            completer.complete(null);
          },
        ),
      );
    } catch (e, stack) {
      debugPrint('创建群异常: $e');
      debugPrint('$stack');

      completer.complete(null);
    }

    return completer.future;
  }

  /// =======================================================
  /// 加入群
  /// =======================================================
  Future<bool> joinGroup(
      String groupId,
      ) async {
    final completer = Completer<bool>();

    final code = await _engine?.joinGroup(
      groupId,
      callback: IRCIMIWJoinGroupCallback(
        onSuccess: (code) async {
          if (code != 0) completer.complete(false);
          await GroupStateCenter().getGroupMembers(
            groupId,
            forceRefresh: true,
          );

          GroupEventBus.instance.fire(
            GroupEvent(
              type: GroupEventType.joined,
              groupId: groupId,
              operatorUserId: IMEngineManager().currentUserId,
            ),
          );

          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
        onError: (e) {
          debugPrint('inviteUsersToGroup error: $e');

          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      ),
    );

    /// SDK 调用失败
    if (code != 0) {
      return false;
    }

    return completer.future;
  }

  /// =======================================================
  /// 邀请加入群
  /// =======================================================
  Future<bool> inviteUsersToGroup(
      String groupId,
      List<String> userIds,
      ) async {
    final completer = Completer<bool>();

    final code = await _engine?.inviteUsersToGroup(
      groupId,
      userIds,
      callback: IRCIMIWInviteUsersToGroupCallback(
        onSuccess: (code) async {
          if (code != 0) completer.complete(false);
          await GroupStateCenter().getGroupMembers(
            groupId,
            forceRefresh: true,
          );

          GroupEventBus.instance.fire(
            GroupEvent(
              type: GroupEventType.joined,
              groupId: groupId,
              operatorUserId: IMEngineManager().currentUserId,
            ),
          );

          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
        onError: (e) {
          debugPrint('inviteUsersToGroup error: $e');

          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      ),
    );

    /// SDK 调用失败
    if (code != 0) {
      return false;
    }

    return completer.future;
  }

  /// =======================================================
  /// 移出群聊
  /// =======================================================
  Future<bool> kickGroupMembers(
      String groupId,
      List<String> userIds,
      ) async {
    final completer = Completer<bool>();
    final config = RCIMIWQuitGroupConfig.create();
    final code = await _engine?.kickGroupMembers(
        groupId,
        userIds,
        config,
      callback: IRCIMIWKickGroupMembersCallback(
        onCompleted: (int? code) async {
          if (code != 0) completer.complete(false);
          await GroupStateCenter().getGroupMembers(
            groupId,
            forceRefresh: true,
          );

          GroupEventBus.instance.fire(
            GroupEvent(
              type: GroupEventType.removed,
              groupId: groupId,
              userIds: userIds
            ),
          );

          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
      ),
    );
    /// SDK 调用失败
    if (code != 0) {
      return false;
    }

    return completer.future;
  }

  /// =======================================================
  /// 退出群
  /// =======================================================
  Future<bool> quitGroup(
      String groupId,
      ) async {
    final config = RCIMIWQuitGroupConfig.create(
      removeFollow: false,
      removeWhiteList: false,
      removeMuteStatus: false,
    );

    final code =
    await _engine?.quitGroup(
      groupId,
      config,
    );

    final success = code == 0;

    if (success) {
      await GroupStateCenter().getGroupMembers(
        groupId,
        forceRefresh: true,
      );

      GroupEventBus.instance.fire(
        GroupEvent(
          type: GroupEventType.quit,
          groupId: groupId,
          operatorUserId: IMEngineManager().currentUserId
        ),
      );
    }

    return success;
  }

  /// =======================================================
  /// 解散群
  /// =======================================================
  Future<bool> dismissGroup(
      String groupId,
      ) async {
    final code =
    await _engine?.dismissGroup(groupId);

    final success = code == 0;

    if (success) {
      GroupEventBus.instance.fire(
        GroupEvent(
          type: GroupEventType.dismissed,
          groupId: groupId,
        ),
      );
    }

    return success;
  }

  /// =======================================================
  /// 更新群信息
  /// =======================================================
  Future<bool> updateGroupInfo(
      RCIMIWGroupInfo groupInfo,
      ) async {
    final code =
    await _engine?.updateGroupInfo(
      groupInfo,
    );

    final success = code == 0;

    if (success) {
      GroupEventBus.instance.fire(
        GroupEvent(
          type: GroupEventType.infoChanged,
          groupId:
          groupInfo.groupId ?? '',
          groupInfo: groupInfo,
        ),
      );
    }

    return success;
  }

  /// =======================================================
  /// 获取群信息
  /// =======================================================
  Future<List<RCIMIWGroupInfo>?>
  getGroupsInfo(
      List<String> groupIds,
      ) async {
    final completer =
    Completer<List<RCIMIWGroupInfo>?>();

    final ret =
    await _engine?.getGroupsInfo(
      groupIds,
      callback: IRCIMIWGetGroupsInfoCallback(
        onSuccess: (infos) {
          completer.complete(infos);
        },
        onError: (code) {
          completer.complete(null);
        },
      ),
    );

    if (ret != null && ret != 0) {
      return null;
    }

    return completer.future;
  }

  /// =======================================================
  /// 搜索已加入群
  /// =======================================================
  Future<
      RCIMIWPagingQueryResult<
          RCIMIWGroupInfo>?>
  searchJoinedGroups({
    required String keyword,
  }) async {
    final completer =
    Completer<
        RCIMIWPagingQueryResult<
            RCIMIWGroupInfo>?>();

    final option = RCIMIWPagingQueryOption.create(
      count: 50,
      pageToken: null,
      order: false,
    );

    final ret =
    await _engine?.searchJoinedGroups(
      keyword,
      option,
      callback:
      IRCIMIWSearchJoinedGroupsCallback(
        onSuccess: (result) {
          completer.complete(result);
        },
        onError: (code) {
          completer.complete(null);
        },
      ),
    );

    if (ret != null && ret != 0) {
      return null;
    }

    return completer.future;
  }

  /// =======================================================
  /// 销毁
  /// =======================================================
  void dispose() {
    _initialized = false;
  }
}