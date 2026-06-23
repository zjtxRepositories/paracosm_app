import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

class FriendApplicationBuckets {
  const FriendApplicationBuckets({
    this.newRequests = const [],
    this.processedRequests = const [],
  });

  final List<RCIMIWFriendApplicationInfo> newRequests;
  final List<RCIMIWFriendApplicationInfo> processedRequests;

  bool get isEmpty => newRequests.isEmpty && processedRequests.isEmpty;

  int get unhandledCount => newRequests.length;
}

enum GroupApplicationViewMode { all, joinReview, inviteConfirmation }

class GroupApplicationBuckets {
  const GroupApplicationBuckets({
    this.joinUnhandled = const [],
    this.joinProcessed = const [],
    this.inviteUnhandled = const [],
    this.inviteProcessed = const [],
  });

  final List<RCIMIWGroupApplicationInfo> joinUnhandled;
  final List<RCIMIWGroupApplicationInfo> joinProcessed;
  final List<RCIMIWGroupApplicationInfo> inviteUnhandled;
  final List<RCIMIWGroupApplicationInfo> inviteProcessed;

  bool get isEmpty =>
      joinUnhandled.isEmpty &&
      joinProcessed.isEmpty &&
      inviteUnhandled.isEmpty &&
      inviteProcessed.isEmpty;

  int get joinUnhandledCount => joinUnhandled.length;
  int get inviteUnhandledCount => inviteUnhandled.length;
  int get unhandledCount => joinUnhandledCount + inviteUnhandledCount;
}

void upsertGroupApplication(
  List<RCIMIWGroupApplicationInfo> list,
  RCIMIWGroupApplicationInfo item,
) {
  final index = list.indexWhere((old) => isSameGroupApplication(old, item));

  if (index >= 0) {
    list[index] = item;
  } else {
    list.insert(0, item);
  }
}

bool isSameGroupApplication(
  RCIMIWGroupApplicationInfo a,
  RCIMIWGroupApplicationInfo b,
) {
  final sameGroup = a.groupId == b.groupId;
  final sameDirection = a.direction == b.direction;
  final sameApplicant = a.joinMemberInfo?.userId == b.joinMemberInfo?.userId;
  final sameInviter = a.inviterInfo?.userId == b.inviterInfo?.userId;
  return sameGroup && sameDirection && sameApplicant && sameInviter;
}

GroupApplicationBuckets splitGroupApplications(
  Iterable<RCIMIWGroupApplicationInfo> list, {
  GroupApplicationViewMode mode = GroupApplicationViewMode.all,
  String? groupId,
  bool Function(RCIMIWGroupApplicationInfo item)? isIgnored,
}) {
  final joinUnhandled = <RCIMIWGroupApplicationInfo>[];
  final joinProcessed = <RCIMIWGroupApplicationInfo>[];
  final inviteUnhandled = <RCIMIWGroupApplicationInfo>[];
  final inviteProcessed = <RCIMIWGroupApplicationInfo>[];

  for (final item in list) {
    if (!_matchesGroup(item, groupId)) continue;

    if (item.direction == RCIMIWGroupApplicationDirection.applicationreceived) {
      if (mode == GroupApplicationViewMode.inviteConfirmation) continue;
      final ignored = isIgnored?.call(item) ?? false;
      if (item.status == RCIMIWGroupApplicationStatus.managerunhandled &&
          !ignored) {
        joinUnhandled.add(item);
      } else {
        joinProcessed.add(item);
      }
    } else if (item.direction ==
        RCIMIWGroupApplicationDirection.invitationreceived) {
      if (mode == GroupApplicationViewMode.joinReview) continue;
      final ignored = isIgnored?.call(item) ?? false;
      if (item.status == RCIMIWGroupApplicationStatus.inviteeunhandled &&
          !ignored) {
        inviteUnhandled.add(item);
      } else {
        inviteProcessed.add(item);
      }
    }
  }

  return GroupApplicationBuckets(
    joinUnhandled: joinUnhandled,
    joinProcessed: joinProcessed,
    inviteUnhandled: inviteUnhandled,
    inviteProcessed: inviteProcessed,
  );
}

FriendApplicationBuckets splitFriendApplications(
  Iterable<RCIMIWFriendApplicationInfo> list, {
  bool Function(RCIMIWFriendApplicationInfo item)? isIgnored,
}) {
  final newRequests = <RCIMIWFriendApplicationInfo>[];
  final processedRequests = <RCIMIWFriendApplicationInfo>[];

  for (final item in list) {
    if (item.applicationType != RCIMIWFriendApplicationType.received) {
      continue;
    }

    final ignored = isIgnored?.call(item) ?? false;
    if (item.applicationStatus == RCIMIWFriendApplicationStatus.unhandled &&
        !ignored) {
      newRequests.add(item);
    } else {
      processedRequests.add(item);
    }
  }

  return FriendApplicationBuckets(
    newRequests: newRequests,
    processedRequests: processedRequests,
  );
}

bool _matchesGroup(RCIMIWGroupApplicationInfo item, String? groupId) {
  final targetGroupId = groupId?.trim() ?? '';
  return targetGroupId.isEmpty || item.groupId == targetGroupId;
}
