import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

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
}) {
  final joinUnhandled = <RCIMIWGroupApplicationInfo>[];
  final joinProcessed = <RCIMIWGroupApplicationInfo>[];
  final inviteUnhandled = <RCIMIWGroupApplicationInfo>[];
  final inviteProcessed = <RCIMIWGroupApplicationInfo>[];

  for (final item in list) {
    if (!_matchesGroup(item, groupId)) continue;

    if (item.direction == RCIMIWGroupApplicationDirection.applicationreceived) {
      if (mode == GroupApplicationViewMode.inviteConfirmation) continue;
      if (item.status == RCIMIWGroupApplicationStatus.managerunhandled) {
        joinUnhandled.add(item);
      } else {
        joinProcessed.add(item);
      }
    } else if (item.direction ==
        RCIMIWGroupApplicationDirection.invitationreceived) {
      if (mode == GroupApplicationViewMode.joinReview) continue;
      if (item.status == RCIMIWGroupApplicationStatus.inviteeunhandled) {
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

bool _matchesGroup(RCIMIWGroupApplicationInfo item, String? groupId) {
  final targetGroupId = groupId?.trim() ?? '';
  return targetGroupId.isEmpty || item.groupId == targetGroupId;
}
