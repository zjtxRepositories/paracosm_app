import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../listener/group_state_center.dart';
import 'im_engine_manager.dart';

enum GroupApplicationActionStatus { success, waitingInviteeConfirm, failed }

class GroupApplicationActionResult {
  const GroupApplicationActionResult(this.status, {this.code});

  final GroupApplicationActionStatus status;
  final int? code;

  bool get isSuccess => status == GroupApplicationActionStatus.success;
}

class ImGroupApplicationsManager {
  ImGroupApplicationsManager._internal();

  static final ImGroupApplicationsManager _instance =
      ImGroupApplicationsManager._internal();

  factory ImGroupApplicationsManager() => _instance;

  final _controller =
      StreamController<List<RCIMIWGroupApplicationInfo>>.broadcast();

  Stream<List<RCIMIWGroupApplicationInfo>> get stream => _controller.stream;

  final List<RCIMIWGroupApplicationInfo> _list = [];
  List<RCIMIWGroupApplicationInfo> get list => List.unmodifiable(_list);

  String? _pageToken;
  List<RCIMIWGroupApplicationDirection> _lastDirections = const [];
  List<RCIMIWGroupApplicationStatus> _lastStatuses = const [];

  void initListener() {
    IMEngineManager().engine?.onGroupApplicationEvent = (info) {
      if (info == null) return;
      _upsert(info);
      _notify();
    };
  }

  int get unhandledCount {
    return _list.where(_isUnhandled).length;
  }

  bool _isUnhandled(RCIMIWGroupApplicationInfo item) {
    if (item.direction ==
        RCIMIWGroupApplicationDirection.applicationreceived) {
      return item.status == RCIMIWGroupApplicationStatus.managerunhandled;
    }
    if (item.direction ==
        RCIMIWGroupApplicationDirection.invitationreceived) {
      return item.status == RCIMIWGroupApplicationStatus.inviteeunhandled;
    }
    return false;
  }

  Future<void> fetch({
    required List<RCIMIWGroupApplicationDirection> directions,
    required List<RCIMIWGroupApplicationStatus> statuses,
    bool loadMore = false,
    int count = 100,
  }) async {
    if (!loadMore ||
        !_sameDirections(directions, _lastDirections) ||
        !_sameStatuses(statuses, _lastStatuses)) {
      _pageToken = '';
      _lastDirections = List.of(directions);
      _lastStatuses = List.of(statuses);
    }

    final option = RCIMIWPagingQueryOption.create(
      pageToken: loadMore ? (_pageToken ?? '') : '',
      count: count,
      order: false,
    );

    final completer = Completer<void>();
    final code = await IMEngineManager().engine?.getGroupApplications(
      option,
      directions,
      statuses,
      callback: IRCIMIWGetGroupApplicationsCallback(
        onSuccess: (page) {
          final result = page?.data ?? [];
          if (!loadMore) {
            _list.clear();
          }
          _list.addAll(result);
          _pageToken = page?.pageToken;
          _notify();
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onError: (code) {
          debugPrint('获取群申请失败: $code');
          if (!completer.isCompleted) {
            completer.completeError(code ?? -1);
          }
        },
      ),
    );

    if (code != 0) {
      throw code ?? -1;
    }

    return completer.future;
  }

  Future<GroupApplicationActionResult> acceptGroupApplication({
    required String groupId,
    required String inviterId,
    required String applicantId,
  }) async {
    final completer = Completer<GroupApplicationActionResult>();
    final code = await IMEngineManager().engine?.acceptGroupApplication(
      groupId,
      inviterId,
      applicantId,
      callback: IRCIMIWAcceptGroupApplicationCallback(
        onSuccess: (processCode) async {
          final status = processCode == 25427
              ? GroupApplicationActionStatus.waitingInviteeConfirm
              : processCode == 0
              ? GroupApplicationActionStatus.success
              : GroupApplicationActionStatus.failed;
          if (status != GroupApplicationActionStatus.failed) {
            _updateLocalStatus(
              groupId: groupId,
              applicantId: applicantId,
              inviterId: inviterId,
              status: status == GroupApplicationActionStatus.success
                  ? RCIMIWGroupApplicationStatus.joined
                  : RCIMIWGroupApplicationStatus.inviteeunhandled,
            );
            unawaited(_refreshGroup(groupId));
          }
          if (!completer.isCompleted) {
            completer.complete(
              GroupApplicationActionResult(status, code: processCode),
            );
          }
        },
        onError: (code) {
          debugPrint('同意群申请失败: $code');
          if (!completer.isCompleted) {
            completer.complete(
              GroupApplicationActionResult(
                GroupApplicationActionStatus.failed,
                code: code,
              ),
            );
          }
        },
      ),
    );

    if (code != 0) {
      return GroupApplicationActionResult(
        GroupApplicationActionStatus.failed,
        code: code,
      );
    }

    return completer.future;
  }

  Future<bool> refuseGroupApplication({
    required String groupId,
    required String inviterId,
    required String applicantId,
    String reason = '',
  }) async {
    final completer = Completer<bool>();
    final code = await IMEngineManager().engine?.refuseGroupApplication(
      groupId,
      inviterId,
      applicantId,
      reason,
      callback: IRCIMIWRefuseGroupApplicationCallback(
        onCompleted: (code) {
          final isOk = code == 0;
          if (isOk) {
            _updateLocalStatus(
              groupId: groupId,
              applicantId: applicantId,
              inviterId: inviterId,
              status: RCIMIWGroupApplicationStatus.managerrefused,
            );
          }
          if (!completer.isCompleted) {
            completer.complete(isOk);
          }
        },
      ),
    );

    if (code != 0) return false;
    return completer.future;
  }

  Future<bool> acceptGroupInvite({
    required String groupId,
    required String inviterId,
  }) async {
    final completer = Completer<bool>();
    final code = await IMEngineManager().engine?.acceptGroupInvite(
      groupId,
      inviterId,
      callback: IRCIMIWAcceptGroupInviteCallback(
        onCompleted: (code) async {
          final isOk = code == 0;
          if (isOk) {
            _updateLocalStatus(
              groupId: groupId,
              inviterId: inviterId,
              status: RCIMIWGroupApplicationStatus.joined,
            );
            unawaited(_refreshGroup(groupId));
          }
          if (!completer.isCompleted) {
            completer.complete(isOk);
          }
        },
      ),
    );

    if (code != 0) return false;
    return completer.future;
  }

  Future<bool> refuseGroupInvite({
    required String groupId,
    required String inviterId,
    String reason = '',
  }) async {
    final completer = Completer<bool>();
    final code = await IMEngineManager().engine?.refuseGroupInvite(
      groupId,
      inviterId,
      reason,
      callback: IRCIMIWRefuseGroupInviteCallback(
        onCompleted: (code) {
          final isOk = code == 0;
          if (isOk) {
            _updateLocalStatus(
              groupId: groupId,
              inviterId: inviterId,
              status: RCIMIWGroupApplicationStatus.inviteerefused,
            );
          }
          if (!completer.isCompleted) {
            completer.complete(isOk);
          }
        },
      ),
    );

    if (code != 0) return false;
    return completer.future;
  }

  Future<void> refreshLastQuery() {
    if (_lastDirections.isEmpty || _lastStatuses.isEmpty) {
      return Future.value();
    }
    return fetch(directions: _lastDirections, statuses: _lastStatuses);
  }

  void _upsert(RCIMIWGroupApplicationInfo item) {
    final index = _list.indexWhere((old) {
      final sameGroup = old.groupId == item.groupId;
      final sameDirection = old.direction == item.direction;
      final sameApplicant =
          old.joinMemberInfo?.userId == item.joinMemberInfo?.userId;
      final sameInviter =
          old.inviterInfo?.userId == item.inviterInfo?.userId;
      return sameGroup && sameDirection && sameApplicant && sameInviter;
    });

    if (index >= 0) {
      _list[index] = item;
    } else {
      _list.insert(0, item);
    }
  }

  Future<void> _refreshGroup(String groupId) async {
    await Future.wait([
      GroupStateCenter().getGroup(groupId, forceRefresh: true),
      GroupStateCenter().getGroupMembers(groupId, forceRefresh: true),
    ]);
  }

  void _updateLocalStatus({
    required String groupId,
    String? applicantId,
    String? inviterId,
    required RCIMIWGroupApplicationStatus status,
  }) {
    final index = _list.indexWhere((item) {
      final sameGroup = item.groupId == groupId;
      final sameApplicant =
          applicantId == null ||
          applicantId.isEmpty ||
          item.joinMemberInfo?.userId == applicantId;
      final sameInviter =
          inviterId == null ||
          inviterId.isEmpty ||
          item.inviterInfo?.userId == inviterId;
      return sameGroup && sameApplicant && sameInviter;
    });

    if (index == -1) return;
    _list[index].status = status;
    _list[index].operationTime = DateTime.now().millisecondsSinceEpoch;
    _notify();
  }

  bool _sameDirections(
    List<RCIMIWGroupApplicationDirection> a,
    List<RCIMIWGroupApplicationDirection> b,
  ) {
    if (a.length != b.length) return false;
    return a.toSet().containsAll(b);
  }

  bool _sameStatuses(
    List<RCIMIWGroupApplicationStatus> a,
    List<RCIMIWGroupApplicationStatus> b,
  ) {
    if (a.length != b.length) return false;
    return a.toSet().containsAll(b);
  }

  void _notify() {
    if (!_controller.isClosed) {
      _controller.add(List.from(_list));
    }
  }

  void dispose() {
    _controller.close();
  }
}
