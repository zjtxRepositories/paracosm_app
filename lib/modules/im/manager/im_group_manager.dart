import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:paracosm/core/models/custom_message_model.dart';
import 'package:paracosm/core/network/api/rong_group_ban_api.dart';
import 'package:paracosm/modules/im/listener/im_data_center.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../group_ban_state.dart';
import '../group_info_update_builder.dart';
import '../listener/group_state_center.dart';
import '../message/base/im_message.dart';
import '../message/send/im_sender.dart';
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
  managerChanged,
  ownerTransferred,
}

enum JoinGroupStatus { joined, waitingManagerApproval, failed }

enum InviteGroupStatus {
  invited,
  waitingManagerApproval,
  waitingInviteeConfirm,
  failed,
}

class JoinGroupResult {
  const JoinGroupResult(this.status, {this.code});

  final JoinGroupStatus status;
  final int? code;

  bool get isJoined => status == JoinGroupStatus.joined;
}

class InviteGroupResult {
  const InviteGroupResult(this.status, {this.code});

  final InviteGroupStatus status;
  final int? code;

  bool get isInvited => status == InviteGroupStatus.invited;
}

JoinGroupResult joinGroupResultFromCode(int? code) {
  if (code == 0) {
    return const JoinGroupResult(JoinGroupStatus.joined, code: 0);
  }
  if (code == 25424) {
    return const JoinGroupResult(
      JoinGroupStatus.waitingManagerApproval,
      code: 25424,
    );
  }
  return JoinGroupResult(JoinGroupStatus.failed, code: code);
}

InviteGroupResult inviteGroupResultFromCode(int? code) {
  if (code == 0) {
    return const InviteGroupResult(InviteGroupStatus.invited, code: 0);
  }
  if (code == 25424) {
    return const InviteGroupResult(
      InviteGroupStatus.waitingManagerApproval,
      code: 25424,
    );
  }
  if (code == 25427) {
    return const InviteGroupResult(
      InviteGroupStatus.waitingInviteeConfirm,
      code: 25427,
    );
  }
  return InviteGroupResult(InviteGroupStatus.failed, code: code);
}

RCIMIWGroupInfo createDefaultNormalGroupInfo({
  required String groupId,
  String? groupName,
}) {
  return RCIMIWGroupInfo.create(
    groupId: groupId,
    groupName: groupName ?? '[默认]',
    invitePermission: RCIMIWGroupOperationPermission.everyone,
    joinPermission: RCIMIWGroupJoinPermission.free,
    inviteHandlePermission: RCIMIWGroupInviteHandlePermission.free,
    role: RCIMIWGroupMemberRole.owner,
    groupInfoEditPermission: RCIMIWGroupOperationPermission.ownerormanager,
    removeMemberPermission: RCIMIWGroupOperationPermission.ownerormanager,
  );
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
    this.data,
    this.userIds,
  });
}

/// =======================================================
/// 群事件总线
/// =======================================================
class GroupEventBus {
  GroupEventBus._();

  static final GroupEventBus instance = GroupEventBus._();

  final StreamController<GroupEvent> _controller =
      StreamController<GroupEvent>.broadcast();

  Stream<GroupEvent> get stream => _controller.stream;

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

  static final ImGroupManager instance = ImGroupManager._();

  factory ImGroupManager() => instance;

  bool _initialized = false;

  final Set<String> _locallyRemovedGroupIds = {};

  final Map<String, Future<bool>> _groupBanOperations = {};

  RCIMIWEngine? get _engine => IMEngineManager().engine;

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
    engine.onGroupOperation =
        (
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
              _markGroupActive(groupId);
              GroupEventBus.instance.fire(
                GroupEvent(
                  type: GroupEventType.created,
                  groupId: groupId,
                  groupInfo: groupInfo,
                  operatorUserId: operatorInfo?.userId,
                ),
              );

              break;

            /// =========================
            /// 加入群
            /// =========================
            case RCIMIWGroupOperation.join:
              _markGroupActive(groupId);
              if (groupInfo == null) {
                GroupStateCenter().refreshGroup(groupId);
              }
              GroupEventBus.instance.fire(
                GroupEvent(
                  type: GroupEventType.joined,
                  groupId: groupId,
                  groupInfo: groupInfo,
                  operatorUserId: operatorInfo?.userId,
                ),
              );

              break;

            /// =========================
            /// 踢出
            /// =========================
            case RCIMIWGroupOperation.kick:
              if (_locallyRemovedGroupIds.contains(groupId)) return;
              GroupEventBus.instance.fire(
                GroupEvent(
                  type: GroupEventType.removed,
                  groupId: groupId,
                  operatorUserId: operatorInfo?.userId,
                  userIds: _memberUserIds(memberInfos),
                ),
              );

              break;

            /// =========================
            /// 管理员变更
            /// =========================
            case RCIMIWGroupOperation.addmanager:
            case RCIMIWGroupOperation.removemanager:
              if (_locallyRemovedGroupIds.contains(groupId)) return;
              GroupEventBus.instance.fire(
                GroupEvent(
                  type: GroupEventType.managerChanged,
                  groupId: groupId,
                  operatorUserId: operatorInfo?.userId,
                  userIds: _memberUserIds(memberInfos),
                ),
              );

              break;

            /// =========================
            /// 转让群主
            /// =========================
            case RCIMIWGroupOperation.transfergroupowner:
              if (_locallyRemovedGroupIds.contains(groupId)) return;
              GroupEventBus.instance.fire(
                GroupEvent(
                  type: GroupEventType.ownerTransferred,
                  groupId: groupId,
                  operatorUserId: operatorInfo?.userId,
                  userIds: _memberUserIds(memberInfos),
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
                  operatorUserId: operatorInfo?.userId,
                ),
              );

              break;

            /// =========================
            /// 解散群
            /// =========================
            case RCIMIWGroupOperation.dismiss:
              GroupEventBus.instance.fire(
                GroupEvent(type: GroupEventType.dismissed, groupId: groupId),
              );
              break;
            default:
              break;
          }
        };

    /// ===================================================
    /// 群资料更新
    /// ===================================================
    engine.onGroupInfoChanged =
        (
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

    if (IMEngineManager().connection.isConnected) {
      /// 首次拉取
      refreshAllGroups();
    }
  }

  /// =======================================================
  /// 拉取全部群
  /// =======================================================
  Future<List<RCIMIWGroupInfo>> getAllJoinedGroups() async {
    final List<RCIMIWGroupInfo> allGroups = [];

    String? pageToken;

    bool hasMore = true;

    while (hasMore) {
      final completer = Completer<RCIMIWPagingQueryResult<RCIMIWGroupInfo>>();

      final option = RCIMIWPagingQueryOption.create(
        count: 50,
        pageToken: pageToken,
        order: false,
      );

      final ret = await _engine?.getJoinedGroupsByRole(
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
        throw Exception('getJoinedGroups error: $ret');
      }

      final result = await completer.future;

      final list = result.data ?? [];

      allGroups.addAll(list);

      final nextToken = result.pageToken;

      hasMore = nextToken != null && nextToken.isNotEmpty;

      if (nextToken == pageToken) {
        break;
      }

      pageToken = nextToken;
    }

    ImDataCenter().setGroupList(allGroups);
    for (final group in allGroups) {
      final groupId = group.groupId;
      if (groupId != null && groupId.isNotEmpty) {
        _markGroupActive(groupId);
      }
    }

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
  Future<RCIMIWGroupInfo?> refreshGroup(String groupId) async {
    final result = await getGroupsInfo([groupId]);

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
    final groupInfo = createDefaultNormalGroupInfo(
      groupId: groupId,
      groupName: groupName,
    );

    return createByGroupInfo(groupInfo, inviteeUserIds);
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
            _markGroupActive(groupInfo.groupId ?? '');
            GroupEventBus.instance.fire(
              GroupEvent(
                type: GroupEventType.created,
                groupId: groupInfo.groupId ?? '',
                groupInfo: groupInfo,
              ),
            );

            completer.complete(groupInfo.groupId);
          },
          onError: (int? errorCode, String? errorInfo) {
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
  Future<JoinGroupResult> joinGroupWithResult(
    String groupId, {
    RCIMIWGroupInfo? groupInfo,
  }) async {
    final completer = Completer<JoinGroupResult>();

    final code = await _engine?.joinGroup(
      groupId,
      callback: IRCIMIWJoinGroupCallback(
        onSuccess: (processCode) async {
          final result = joinGroupResultFromCode(processCode);
          if (result.status == JoinGroupStatus.waitingManagerApproval) {
            if (!completer.isCompleted) {
              completer.complete(result);
            }
            return;
          }
          if (!result.isJoined) {
            if (!completer.isCompleted) {
              completer.complete(result);
            }
            return;
          }
          _markGroupActive(groupId);
          await GroupStateCenter().getGroupMembers(groupId, forceRefresh: true);

          GroupEventBus.instance.fire(
            GroupEvent(
              type: GroupEventType.joined,
              groupId: groupId,
              operatorUserId: IMEngineManager().currentUserId,
            ),
          );

          if (!completer.isCompleted) {
            completer.complete(result);
          }
        },
        onError: (e) {
          debugPrint('joinGroup error: $e');

          if (!completer.isCompleted) {
            completer.complete(
              JoinGroupResult(JoinGroupStatus.failed, code: e),
            );
          }
        },
      ),
    );

    /// SDK 调用失败
    if (code != 0) {
      return JoinGroupResult(JoinGroupStatus.failed, code: code);
    }

    return completer.future;
  }

  Future<bool> joinGroup(String groupId) async {
    final result = await joinGroupWithResult(groupId);
    return result.isJoined;
  }

  /// =======================================================
  /// 邀请加入群
  /// =======================================================
  Future<InviteGroupResult> inviteUsersToGroup(
    String groupId,
    List<String> userIds,
  ) async {
    final completer = Completer<InviteGroupResult>();

    final code = await _engine?.inviteUsersToGroup(
      groupId,
      userIds,
      callback: IRCIMIWInviteUsersToGroupCallback(
        onSuccess: (processCode) async {
          final result = inviteGroupResultFromCode(processCode);
          if (!result.isInvited) {
            if (!completer.isCompleted) {
              completer.complete(result);
            }
            return;
          }
          await GroupStateCenter().getGroupMembers(groupId, forceRefresh: true);

          GroupEventBus.instance.fire(
            GroupEvent(
              type: GroupEventType.joined,
              groupId: groupId,
              operatorUserId: IMEngineManager().currentUserId,
            ),
          );

          if (!completer.isCompleted) {
            completer.complete(result);
          }
        },
        onError: (e) {
          debugPrint('inviteUsersToGroup error: $e');

          if (!completer.isCompleted) {
            completer.complete(
              InviteGroupResult(InviteGroupStatus.failed, code: e),
            );
          }
        },
      ),
    );

    /// SDK 调用失败
    if (code != 0) {
      return InviteGroupResult(InviteGroupStatus.failed, code: code);
    }

    return completer.future;
  }

  /// =======================================================
  /// 移出群聊
  /// =======================================================
  Future<bool> kickGroupMembers(String groupId, List<String> userIds) async {
    final completer = Completer<bool>();
    final config = RCIMIWQuitGroupConfig.create();
    final code = await _engine?.kickGroupMembers(
      groupId,
      userIds,
      config,
      callback: IRCIMIWKickGroupMembersCallback(
        onCompleted: (int? code) async {
          if (code != 0) {
            if (!completer.isCompleted) {
              completer.complete(false);
            }
            return;
          }
          await GroupStateCenter().getGroupMembers(groupId, forceRefresh: true);
          GroupEventBus.instance.fire(
            GroupEvent(
              type: GroupEventType.removed,
              groupId: groupId,
              userIds: userIds,
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
  Future<bool> quitGroup(String groupId) async {
    final config = RCIMIWQuitGroupConfig.create(
      removeFollow: false,
      removeWhiteList: false,
      removeMuteStatus: false,
    );

    final code = await _engine?.quitGroup(groupId, config);

    final success = code == 0;

    if (success) {
      _removeLocalGroupAndConversation(groupId);
    }

    return success;
  }

  /// =======================================================
  /// 解散群
  /// =======================================================
  Future<bool> dismissGroup(String groupId) async {
    final code = await _engine?.dismissGroup(groupId);

    final success = code == 0;

    if (success) {
      _removeLocalGroupAndConversation(groupId);
    }

    return success;
  }

  /// =======================================================
  /// 转让群主
  /// =======================================================
  Future<bool> transferGroupOwner(
    String groupId,
    String newOwnerId, {
    bool quitGroup = false,
  }) async {
    final completer = Completer<bool>();
    final config = RCIMIWQuitGroupConfig.create(
      removeFollow: false,
      removeWhiteList: false,
      removeMuteStatus: false,
    );

    final code = await _engine?.transferGroupOwner(
      groupId,
      newOwnerId,
      quitGroup,
      config,
      callback: IRCIMIWTransferGroupOwnerCallback(
        onCompleted: (int? code) async {
          if (!completer.isCompleted) {
            completer.complete(code == 0);
          }
        },
      ),
    );

    if (code != 0) {
      return false;
    }

    final success = await completer.future;

    if (success) {
      if (quitGroup) {
        _removeLocalGroupAndConversation(groupId);
      } else {
        GroupEventBus.instance.fire(
          GroupEvent(
            type: GroupEventType.ownerTransferred,
            groupId: groupId,
            operatorUserId: IMEngineManager().currentUserId,
            data: newOwnerId,
          ),
        );
      }
    }

    return success;
  }

  void _removeLocalGroupAndConversation(String groupId) {
    _locallyRemovedGroupIds.add(groupId);
    ImDataCenter().removeGroupAndConversation(groupId);
  }

  void _markGroupActive(String groupId) {
    _locallyRemovedGroupIds.remove(groupId);
  }

  List<String> _memberUserIds(List<RCIMIWGroupMemberInfo>? members) {
    if (members == null || members.isEmpty) return const [];

    return members
        .map((member) => member.userId ?? '')
        .where((userId) => userId.isNotEmpty)
        .toList();
  }

  /// =======================================================
  /// 添加群管理员
  /// =======================================================
  Future<bool> addGroupManagers(String groupId, List<String> userIds) async {
    if (userIds.isEmpty) return true;

    final completer = Completer<bool>();
    final code = await _engine?.addGroupManagers(
      groupId,
      userIds,
      callback: IRCIMIWAddGroupManagersCallback(
        onCompleted: (int? code) async {
          if (!completer.isCompleted) {
            completer.complete(code == 0);
          }
        },
      ),
    );

    if (code != 0) {
      return false;
    }

    final success = await completer.future;
    if (success) {
      await GroupStateCenter().getGroupMembers(groupId, forceRefresh: true);
      GroupEventBus.instance.fire(
        GroupEvent(
          type: GroupEventType.managerChanged,
          groupId: groupId,
          userIds: userIds,
        ),
      );
    }
    return success;
  }

  /// =======================================================
  /// 移除群管理员
  /// =======================================================
  Future<bool> removeGroupManagers(String groupId, List<String> userIds) async {
    if (userIds.isEmpty) return true;

    final completer = Completer<bool>();
    final code = await _engine?.removeGroupManagers(
      groupId,
      userIds,
      callback: IRCIMIWRemoveGroupManagersCallback(
        onCompleted: (int? code) async {
          if (!completer.isCompleted) {
            completer.complete(code == 0);
          }
        },
      ),
    );

    if (code != 0) {
      return false;
    }

    final success = await completer.future;
    if (success) {
      await GroupStateCenter().getGroupMembers(groupId, forceRefresh: true);
      GroupEventBus.instance.fire(
        GroupEvent(
          type: GroupEventType.managerChanged,
          groupId: groupId,
          userIds: userIds,
        ),
      );
    }
    return success;
  }

  /// =======================================================
  /// 更新群信息
  /// =======================================================
  Future<bool> updateGroupInfo(RCIMIWGroupInfo groupInfo) async {
    final completer = Completer<bool>();
    final groupId = groupInfo.groupId ?? '';

    final ret = await _engine?.updateGroupInfo(
      groupInfo,
      callback: IRCIMIWGroupInfoUpdatedCallback(
        onGroupInfoUpdated: (int? code, String? errorInfo) {
          completer.complete(code == 0);
        },
      ),
    );
    if (ret != null && ret != 0) {
      return false;
    }
    final success = await completer.future;
    if (success) {
      final mergedGroupInfo = _mergeUpdatedGroupInfo(groupInfo);
      GroupEventBus.instance.fire(
        GroupEvent(
          type: GroupEventType.infoChanged,
          groupId: groupId,
          groupInfo: mergedGroupInfo,
        ),
      );
    }
    return success;
  }

  RCIMIWGroupInfo _mergeUpdatedGroupInfo(RCIMIWGroupInfo update) {
    final groupId = update.groupId ?? '';
    final cached = GroupStateCenter().getCachedGroup(groupId);
    if (cached == null) return update;

    cached.groupName = update.groupName ?? cached.groupName;
    cached.portraitUri = update.portraitUri ?? cached.portraitUri;
    cached.introduction = update.introduction ?? cached.introduction;
    cached.notice = update.notice ?? cached.notice;
    cached.extProfile = update.extProfile ?? cached.extProfile;
    cached.joinPermission = update.joinPermission ?? cached.joinPermission;
    cached.removeMemberPermission =
        update.removeMemberPermission ?? cached.removeMemberPermission;
    cached.invitePermission =
        update.invitePermission ?? cached.invitePermission;
    cached.inviteHandlePermission =
        update.inviteHandlePermission ?? cached.inviteHandlePermission;
    cached.groupInfoEditPermission =
        update.groupInfoEditPermission ?? cached.groupInfoEditPermission;
    cached.memberInfoEditPermission =
        update.memberInfoEditPermission ?? cached.memberInfoEditPermission;
    return cached;
  }

  /// =======================================================
  /// 设置/取消群组全体禁言
  /// =======================================================
  Future<bool> setGroupBan({required String groupId, required bool banned}) {
    final id = groupId.trim();
    if (id.isEmpty) return Future.value(false);

    final running = _groupBanOperations[id];
    if (running != null) {
      return running;
    }

    final operation = _setGroupBan(id, banned);
    _groupBanOperations[id] = operation;
    return operation.whenComplete(() {
      if (_groupBanOperations[id] == operation) {
        _groupBanOperations.remove(id);
      }
    });
  }

  Future<bool> _setGroupBan(String groupId, bool banned) async {
    if (banned) {
      await _sendGroupBanNotification(groupId, banned: true);
    }

    final success = banned
        ? await RongGroupBanApi.add(groupId: groupId)
        : await RongGroupBanApi.rollback(groupId: groupId);
    if (!success) {
      return false;
    }
    final currentGroupInfo = await GroupStateCenter().getGroup(groupId);
    if (currentGroupInfo == null) {
      return false;
    }
    final groupInfo = GroupInfoUpdateBuilder.build(
      groupId: currentGroupInfo.groupId ?? '',
      groupName: currentGroupInfo.groupName ?? '',
      portraitUri: currentGroupInfo.portraitUri ?? '',
      introduction: currentGroupInfo.introduction ?? '',
      notice: currentGroupInfo.notice ?? '',
      extProfile: groupExtProfileWithMuteAll(
        currentGroupInfo.extProfile,
        banned: banned,
      ),
    );
    final updated = await updateGroupInfo(groupInfo);
    if (!updated) {
      return false;
    }

    if (!banned) {
      await _sendGroupBanNotification(groupId, banned: false);
    }
    return true;
  }

  Future<void> _sendGroupBanNotification(
    String groupId, {
    required bool banned,
  }) async {
    final messageSent = await ImSender.instance.sendAndWait(
      message: CustomMessage(
        targetId: groupId,
        customMessageType: banned
            ? CustomMessageType.groupBanEnabled
            : CustomMessageType.groupBanDisabled,
        conversationType: RCIMIWConversationType.group,
      ),
    );
    if (!messageSent) {
      debugPrint(
        'Send group ban notification failed: groupId=$groupId, banned=$banned',
      );
    }
  }

  /// =======================================================
  /// 获取群信息
  /// =======================================================
  Future<List<RCIMIWGroupInfo>?> getGroupsInfo(List<String> groupIds) async {
    final completer = Completer<List<RCIMIWGroupInfo>?>();

    final ret = await _engine?.getGroupsInfo(
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
  Future<RCIMIWPagingQueryResult<RCIMIWGroupInfo>?> searchJoinedGroups({
    required String keyword,
  }) async {
    final completer = Completer<RCIMIWPagingQueryResult<RCIMIWGroupInfo>?>();

    final option = RCIMIWPagingQueryOption.create(
      count: 50,
      pageToken: null,
      order: false,
    );

    final ret = await _engine?.searchJoinedGroups(
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
