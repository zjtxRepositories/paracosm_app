import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

class GroupPermissionPolicy {
  const GroupPermissionPolicy({required this.groupInfo, this.isJoined = true});

  final RCIMIWGroupInfo? groupInfo;
  final bool isJoined;

  RCIMIWGroupMemberRole? get role => groupInfo?.role;

  bool get isOwner => isJoined && role == RCIMIWGroupMemberRole.owner;

  bool get isManager =>
      isJoined &&
      (role == RCIMIWGroupMemberRole.owner ||
          role == RCIMIWGroupMemberRole.manager);

  bool get canDismissGroup => isOwner;

  bool get canTransferOwner => isOwner;

  bool get canManageManagers => isOwner;

  bool get canEditGroupInfo => isManager;

  bool get canKickMembers => isManager;

  bool get canMuteAll => isManager;

  bool get canAuditJoin => isManager;

  bool get canManageInvite => isManager;

  bool get canInviteMembers {
    if (!isJoined) return false;

    final permission = groupInfo?.invitePermission;
    if (permission == null) return true;

    switch (permission) {
      case RCIMIWGroupOperationPermission.everyone:
        return true;
      case RCIMIWGroupOperationPermission.ownerormanager:
        return isManager;
      case RCIMIWGroupOperationPermission.owner:
        return isOwner;
    }
  }
}
