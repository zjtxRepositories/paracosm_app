import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import 'package:uuid/uuid.dart';
import 'im_engine_manager.dart';

class ImGroupManager {
  /// =========================
  /// 群数据流（UI监听）
  /// =========================
  final _controller = StreamController<List<RCIMIWGroupInfo>>.broadcast();
  Stream<List<RCIMIWGroupInfo>> get stream => _controller.stream;

  final List<RCIMIWGroupInfo> _groups = [];

  /// =========================
  /// 初始化监听（🔥核心）
  /// =========================
  void initListener() {
    final engine = IMEngineManager().engine;

    /// 群操作（创建 / 加入 / 退出 / 解散）
    engine?.onGroupOperation = (
        String? groupId,
        RCIMIWGroupMemberInfo? operatorInfo,
        RCIMIWGroupInfo? groupInfo,
        RCIMIWGroupOperation? operation,
        List<RCIMIWGroupMemberInfo>? memberInfos,
        int? operationTime,
        ) {
      debugPrint("群操作: $operation groupId=$groupId");

      /// 🔥 自动刷新
      refreshAllGroups();
    };

    /// 群信息更新
    engine?.onGroupInfoChanged = (
        RCIMIWGroupMemberInfo? operatorInfo,
        RCIMIWGroupInfo? fullGroupInfo,
        RCIMIWGroupInfo? changedGroupInfo,
        int? operationTime,
        ) {
      if (fullGroupInfo != null) {
        _upsert(fullGroupInfo);
        _notify();
      }
    };
    refreshAllGroups();
  }

  /// =========================
  /// 拉取全部群
  /// =========================
  Future<List<RCIMIWGroupInfo>> getAllJoinedGroups() async {
    final List<RCIMIWGroupInfo> allGroups = [];

    String? pageToken;
    bool hasMore = true;

    int page = 0;

    while (hasMore) {
      final completer =
      Completer<RCIMIWPagingQueryResult<RCIMIWGroupInfo>>();

      final option = RCIMIWPagingQueryOption.create(
        count: 20,
        pageToken: pageToken,
        order: false,
      );

      final ret = await IMEngineManager().engine?.getJoinedGroupsByRole(
        RCIMIWGroupMemberRole.undef,
        option,
        callback: IRCIMIWGetJoinedGroupsByRoleCallback(
          onSuccess: (result) {
            completer.complete(result);
          },
          onError: (code) {
            completer.completeError(code ?? -1);
          },
        ),
      );

      if (ret != null && ret != 0) {
        throw Exception("getJoinedGroups error: $ret");
      }

      final result = await completer.future;

      final list = result.data ?? [];

      allGroups.addAll(list);

      page++;

      /// 每3页更新一次UI
      if (page % 3 == 0) {
        _groups
          ..clear()
          ..addAll(allGroups);

        _notify();
      }

      final nextToken = result.pageToken;

      hasMore = nextToken != null && nextToken.isNotEmpty;

      if (nextToken == pageToken) {
        break;
      }

      pageToken = nextToken;
    }

    /// 最终刷新
    _groups
      ..clear()
      ..addAll(allGroups);

    _notify();

    return allGroups;
  }

  /// =========================
  /// 刷新全部群
  /// =========================
  Future<void> refreshAllGroups() async {
    _groups.clear();
    _notify();

  }

  /// =========================
  /// 创建群
  /// =========================
  Future<String?> create({
    required List<String> inviteeUserIds,
    required String groupId,
    String? groupName,
  }) async {
    final completer = Completer<String?>();

    final groupInfo = RCIMIWGroupInfo.create(
      groupId: groupId,
      groupName: groupName ?? '[默认]',
    );

    await IMEngineManager().engine?.createGroup(
      groupInfo,
      inviteeUserIds,
      callback: IRCIMIWCreateGroupCallback(
        onSuccess: (result) {
          debugPrint('创建群成功: $result');
          completer.complete(groupId);
        },
        onError: (int? errorCode, String? errorInfo) {
          debugPrint(
            '创建群失败: code=$errorCode info=$errorInfo',
          );

          completer.complete(null);
        },
      ),
    );

    return completer.future;
  }

  /// =========================
  /// 加入群
  /// =========================
  Future<bool> joinGroup(String groupId) async {
    int? code = await IMEngineManager().engine?.joinGroup(groupId);
    return code == 0;
  }

  /// =========================
  /// 退出群
  /// =========================
  Future<bool> quitGroup(String groupId) async {
    final config = RCIMIWQuitGroupConfig.create(
      removeFollow: false,
      removeWhiteList: false,
      removeMuteStatus: false,
    );

    int? code = await IMEngineManager().engine?.quitGroup(groupId, config);
    return code == 0;
  }

  /// =========================
  /// 解散群
  /// =========================
  Future<bool> dismissGroup(String groupId) async {
    int? code = await IMEngineManager().engine?.dismissGroup(groupId);
    return code == 0;
  }

  /// =========================
  /// 更新群信息
  /// =========================
  Future<bool> updateGroupInfo(RCIMIWGroupInfo groupInfo) async {
    int? code = await IMEngineManager().engine?.updateGroupInfo(groupInfo);
    return code == 0;
  }

  /// =========================
  /// 查询群信息
  /// =========================
  Future<List<RCIMIWGroupInfo>?> getGroupsInfo(List<String> groupIds) async {
    final completer = Completer<List<RCIMIWGroupInfo>?>();

    final ret = await IMEngineManager().engine?.getGroupsInfo(
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

    if (ret != null && ret != 0) return null;

    return completer.future;
  }

  Future<RCIMIWPagingQueryResult<RCIMIWGroupInfo>?> searchJoinedGroups({
    required String keyword,
  }) async {
    final completer =
    Completer<RCIMIWPagingQueryResult<RCIMIWGroupInfo>?>();

    final option = RCIMIWPagingQueryOption.create(
      count: 50,
      pageToken: null,
      order: false,
    );

    final ret = await IMEngineManager().engine?.searchJoinedGroups(
      keyword,
      option,
      callback: IRCIMIWSearchJoinedGroupsCallback(
        onSuccess: (result) {
          completer.complete(result);
        },
        onError: (code) {
          completer.complete(null);
        },
      ),
    );

    if (ret != null && ret != 0) return null;

    return completer.future;
  }

  /// =========================
  /// 内部：新增或更新
  /// =========================
  void _upsert(RCIMIWGroupInfo group) {
    final index = _groups.indexWhere((e) => e.groupId == group.groupId);

    if (index >= 0) {
      _groups[index] = group;
    } else {
      _groups.insert(0, group);
    }
  }

  void _notify() {
    _controller.add(List.from(_groups));
  }

  void dispose() {
    _controller.close();
  }
}