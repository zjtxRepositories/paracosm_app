import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:paracosm/modules/im/manager/im_conversation_manager.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

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
}

/// =======================================================
/// 群事件
/// =======================================================
class GroupEvent {
  final GroupEventType type;

  final String groupId;

  final RCIMIWGroupInfo? groupInfo;

  final dynamic data;

  GroupEvent({
    required this.type,
    required this.groupId,
    this.groupInfo,
    this.data,
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

  /// =======================================================
  /// 群列表流（UI监听）
  /// =======================================================
  final StreamController<List<RCIMIWGroupInfo>>
  _controller =
  StreamController<List<RCIMIWGroupInfo>>.broadcast();

  Stream<List<RCIMIWGroupInfo>> get stream =>
      _controller.stream;

  /// =======================================================
  /// 本地缓存
  /// =======================================================
  final List<RCIMIWGroupInfo> _groups = [];

  List<RCIMIWGroupInfo> get groups =>
      List.unmodifiable(_groups);

  /// =======================================================
  /// 初始化监听
  /// =======================================================
  void initListener() {
    final engine = IMEngineManager().engine;

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
        '群操作: operation=$operation groupId=$groupId',
      );

      if (groupId == null) return;

      switch (operation) {
        case RCIMIWGroupOperation.create:
          if (groupInfo != null) {
            _upsert(groupInfo);
          }

          GroupEventBus.instance.fire(
            GroupEvent(
              type: GroupEventType.created,
              groupId: groupId,
              groupInfo: groupInfo,
            ),
          );

          break;

        case RCIMIWGroupOperation.join:
          if (groupInfo != null) {
            _upsert(groupInfo);
          }

          GroupEventBus.instance.fire(
            GroupEvent(
              type: GroupEventType.joined,
              groupId: groupId,
              groupInfo: groupInfo,
            ),
          );

          break;

        case RCIMIWGroupOperation.quit:
          _groups.removeWhere(
                (e) => e.groupId == groupId,
          );

          GroupEventBus.instance.fire(
            GroupEvent(
              type: GroupEventType.quit,
              groupId: groupId,
            ),
          );

          break;

        case RCIMIWGroupOperation.dismiss:
          _groups.removeWhere(
                (e) => e.groupId == groupId,
          );

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

      _notify();
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
      if (fullGroupInfo == null) return;

      _upsert(fullGroupInfo);

      _notify();

      GroupEventBus.instance.fire(
        GroupEvent(
          type: GroupEventType.infoChanged,
          groupId: fullGroupInfo.groupId ?? '',
          groupInfo: fullGroupInfo,
        ),
      );
    };

    /// 首次拉取
    refreshAllGroups();
  }

  /// =======================================================
  /// 拉取全部已加入群
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
      await IMEngineManager()
          .engine
          ?.getJoinedGroupsByRole(
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
          nextToken != null && nextToken.isNotEmpty;

      if (nextToken == pageToken) {
        break;
      }

      pageToken = nextToken;
    }

    _groups
      ..clear()
      ..addAll(allGroups);

    _notify();

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

      final engine = IMEngineManager().engine;

      if (engine == null) {
        completer.complete(null);
        return completer.future;
      }

      await engine.createGroup(
        groupInfo,
        inviteeUserIds,
        callback: IRCIMIWCreateGroupCallback(
          onSuccess: (result) {
            debugPrint(
              '创建群成功: ${groupInfo.groupId}',
            );

            _upsert(groupInfo);

            _notify();

            GroupEventBus.instance.fire(
              GroupEvent(
                type: GroupEventType.created,
                groupId: groupInfo.groupId ?? '',
                groupInfo: groupInfo,
              ),
            );

            completer.complete(groupInfo.groupId);
          },
          onError: (
              int? errorCode,
              String? errorInfo,
              ) {
            debugPrint(
              '创建群失败: code=$errorCode info=$errorInfo',
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
  Future<bool> joinGroup(String groupId) async {
    int? code =
    await IMEngineManager()
        .engine
        ?.joinGroup(groupId);

    final success = code == 0;

    if (success) {
      refreshAllGroups();

      GroupEventBus.instance.fire(
        GroupEvent(
          type: GroupEventType.joined,
          groupId: groupId,
        ),
      );
    }

    return success;
  }

  /// =======================================================
  /// 退出群
  /// =======================================================
  Future<bool> quitGroup(String groupId) async {
    final config = RCIMIWQuitGroupConfig.create(
      removeFollow: false,
      removeWhiteList: false,
      removeMuteStatus: false,
    );

    int? code =
    await IMEngineManager()
        .engine
        ?.quitGroup(groupId, config);

    final success = code == 0;

    if (success) {
      _groups.removeWhere(
            (e) => e.groupId == groupId,
      );

      _notify();

      GroupEventBus.instance.fire(
        GroupEvent(
          type: GroupEventType.quit,
          groupId: groupId,
        ),
      );
    }

    return success;
  }

  /// =======================================================
  /// 解散群
  /// =======================================================
  Future<bool> dismissGroup(String groupId) async {
    int? code =
    await IMEngineManager()
        .engine
        ?.dismissGroup(groupId);

    final success = code == 0;

    if (success) {
      _groups.removeWhere(
            (e) => e.groupId == groupId,
      );

      _notify();

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
    int? code =
    await IMEngineManager()
        .engine
        ?.updateGroupInfo(groupInfo);

    final success = code == 0;

    if (success) {
      _upsert(groupInfo);

      _notify();

      GroupEventBus.instance.fire(
        GroupEvent(
          type: GroupEventType.infoChanged,
          groupId: groupInfo.groupId ?? '',
          groupInfo: groupInfo,
        ),
      );
    }

    return success;
  }

  /// =======================================================
  /// 获取群信息
  /// =======================================================
  Future<List<RCIMIWGroupInfo>?> getGroupsInfo(
      List<String> groupIds,
      ) async {
    final completer =
    Completer<List<RCIMIWGroupInfo>?>();

    final ret =
    await IMEngineManager()
        .engine
        ?.getGroupsInfo(
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
    await IMEngineManager()
        .engine
        ?.searchJoinedGroups(
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
  /// 本地新增或更新
  /// =======================================================
  void _upsert(RCIMIWGroupInfo group) {
    final index = _groups.indexWhere(
          (e) => e.groupId == group.groupId,
    );

    if (index >= 0) {
      _groups[index] = group;
    } else {
      _groups.insert(0, group);
    }
  }

  /// =======================================================
  /// 通知UI
  /// =======================================================
  void _notify() {
    _controller.add(List.from(_groups));
  }

  /// =======================================================
  /// 销毁
  /// =======================================================
  void dispose() {
    _controller.close();
  }
}