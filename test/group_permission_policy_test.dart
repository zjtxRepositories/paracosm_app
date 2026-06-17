import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/modules/im/group_permission_policy.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

void main() {
  group('GroupPermissionPolicy', () {
    test('owner can use all management permissions', () {
      final policy = GroupPermissionPolicy(
        groupInfo: _groupInfo(role: RCIMIWGroupMemberRole.owner),
      );

      expect(policy.isOwner, isTrue);
      expect(policy.isManager, isTrue);
      expect(policy.canDismissGroup, isTrue);
      expect(policy.canTransferOwner, isTrue);
      expect(policy.canManageManagers, isTrue);
      expect(policy.canEditGroupInfo, isTrue);
      expect(policy.canKickMembers, isTrue);
      expect(policy.canMuteAll, isTrue);
      expect(policy.canAuditJoin, isTrue);
      expect(policy.canManageInvite, isTrue);
    });

    test('manager can manage group but cannot use owner-only permissions', () {
      final policy = GroupPermissionPolicy(
        groupInfo: _groupInfo(role: RCIMIWGroupMemberRole.manager),
      );

      expect(policy.isOwner, isFalse);
      expect(policy.isManager, isTrue);
      expect(policy.canDismissGroup, isFalse);
      expect(policy.canTransferOwner, isFalse);
      expect(policy.canManageManagers, isFalse);
      expect(policy.canEditGroupInfo, isTrue);
      expect(policy.canKickMembers, isTrue);
      expect(policy.canMuteAll, isTrue);
    });

    test('normal member cannot manage group', () {
      final policy = GroupPermissionPolicy(
        groupInfo: _groupInfo(role: RCIMIWGroupMemberRole.normal),
      );

      expect(policy.isOwner, isFalse);
      expect(policy.isManager, isFalse);
      expect(policy.canDismissGroup, isFalse);
      expect(policy.canManageManagers, isFalse);
      expect(policy.canEditGroupInfo, isFalse);
      expect(policy.canKickMembers, isFalse);
      expect(policy.canMuteAll, isFalse);
    });

    test('not joined cannot use permissions even with owner role', () {
      final policy = GroupPermissionPolicy(
        groupInfo: _groupInfo(role: RCIMIWGroupMemberRole.owner),
        isJoined: false,
      );

      expect(policy.isOwner, isFalse);
      expect(policy.isManager, isFalse);
      expect(policy.canInviteMembers, isFalse);
      expect(policy.canDismissGroup, isFalse);
    });

    test('missing invite permission defaults to allowing joined members', () {
      final policy = GroupPermissionPolicy(
        groupInfo: _groupInfo(role: RCIMIWGroupMemberRole.normal),
      );

      expect(policy.canInviteMembers, isTrue);
    });

    test('everyone invite permission allows normal members', () {
      final policy = GroupPermissionPolicy(
        groupInfo: _groupInfo(
          role: RCIMIWGroupMemberRole.normal,
          invitePermission: RCIMIWGroupOperationPermission.everyone,
        ),
      );

      expect(policy.canInviteMembers, isTrue);
    });

    test('owner or manager invite permission blocks normal members', () {
      final normalPolicy = GroupPermissionPolicy(
        groupInfo: _groupInfo(
          role: RCIMIWGroupMemberRole.normal,
          invitePermission: RCIMIWGroupOperationPermission.ownerormanager,
        ),
      );
      final managerPolicy = GroupPermissionPolicy(
        groupInfo: _groupInfo(
          role: RCIMIWGroupMemberRole.manager,
          invitePermission: RCIMIWGroupOperationPermission.ownerormanager,
        ),
      );

      expect(normalPolicy.canInviteMembers, isFalse);
      expect(managerPolicy.canInviteMembers, isTrue);
    });

    test('owner invite permission only allows owner', () {
      final managerPolicy = GroupPermissionPolicy(
        groupInfo: _groupInfo(
          role: RCIMIWGroupMemberRole.manager,
          invitePermission: RCIMIWGroupOperationPermission.owner,
        ),
      );
      final ownerPolicy = GroupPermissionPolicy(
        groupInfo: _groupInfo(
          role: RCIMIWGroupMemberRole.owner,
          invitePermission: RCIMIWGroupOperationPermission.owner,
        ),
      );

      expect(managerPolicy.canInviteMembers, isFalse);
      expect(ownerPolicy.canInviteMembers, isTrue);
    });

    test('only owner can manage join and invite settings', () {
      final ownerPolicy = GroupPermissionPolicy(
        groupInfo: _groupInfo(role: RCIMIWGroupMemberRole.owner),
      );
      final managerPolicy = GroupPermissionPolicy(
        groupInfo: _groupInfo(role: RCIMIWGroupMemberRole.manager),
      );
      final normalPolicy = GroupPermissionPolicy(
        groupInfo: _groupInfo(role: RCIMIWGroupMemberRole.normal),
      );

      expect(ownerPolicy.canManageJoinInviteSettings, isTrue);
      expect(managerPolicy.canManageJoinInviteSettings, isFalse);
      expect(normalPolicy.canManageJoinInviteSettings, isFalse);
    });

    test('group applications entry follows join permission', () {
      final ownerManagerVerifyOwner = GroupPermissionPolicy(
        groupInfo: _groupInfo(
          role: RCIMIWGroupMemberRole.owner,
          joinPermission: RCIMIWGroupJoinPermission.ownerormanagerverify,
        ),
      );
      final ownerManagerVerifyManager = GroupPermissionPolicy(
        groupInfo: _groupInfo(
          role: RCIMIWGroupMemberRole.manager,
          joinPermission: RCIMIWGroupJoinPermission.ownerormanagerverify,
        ),
      );
      final ownerManagerVerifyNormal = GroupPermissionPolicy(
        groupInfo: _groupInfo(
          role: RCIMIWGroupMemberRole.normal,
          joinPermission: RCIMIWGroupJoinPermission.ownerormanagerverify,
        ),
      );
      final ownerVerifyOwner = GroupPermissionPolicy(
        groupInfo: _groupInfo(
          role: RCIMIWGroupMemberRole.owner,
          joinPermission: RCIMIWGroupJoinPermission.ownerverify,
        ),
      );
      final ownerVerifyManager = GroupPermissionPolicy(
        groupInfo: _groupInfo(
          role: RCIMIWGroupMemberRole.manager,
          joinPermission: RCIMIWGroupJoinPermission.ownerverify,
        ),
      );
      final freeOwner = GroupPermissionPolicy(
        groupInfo: _groupInfo(
          role: RCIMIWGroupMemberRole.owner,
          joinPermission: RCIMIWGroupJoinPermission.free,
        ),
      );
      final noOneAllowedOwner = GroupPermissionPolicy(
        groupInfo: _groupInfo(
          role: RCIMIWGroupMemberRole.owner,
          joinPermission: RCIMIWGroupJoinPermission.nooneallowed,
        ),
      );
      final noOneAllowedManager = GroupPermissionPolicy(
        groupInfo: _groupInfo(
          role: RCIMIWGroupMemberRole.manager,
          joinPermission: RCIMIWGroupJoinPermission.nooneallowed,
        ),
      );
      final missingJoinPermissionManager = GroupPermissionPolicy(
        groupInfo: _groupInfo(role: RCIMIWGroupMemberRole.manager),
      );

      expect(ownerManagerVerifyOwner.canViewGroupApplications, isTrue);
      expect(ownerManagerVerifyManager.canViewGroupApplications, isTrue);
      expect(ownerManagerVerifyNormal.canViewGroupApplications, isFalse);
      expect(ownerVerifyOwner.canViewGroupApplications, isTrue);
      expect(ownerVerifyManager.canViewGroupApplications, isFalse);
      expect(freeOwner.canViewGroupApplications, isFalse);
      expect(noOneAllowedOwner.canViewGroupApplications, isTrue);
      expect(noOneAllowedManager.canViewGroupApplications, isFalse);
      expect(missingJoinPermissionManager.canViewGroupApplications, isFalse);
    });
  });
}

RCIMIWGroupInfo _groupInfo({
  required RCIMIWGroupMemberRole role,
  RCIMIWGroupOperationPermission? invitePermission,
  RCIMIWGroupJoinPermission? joinPermission,
}) {
  return RCIMIWGroupInfo.create(
    groupId: 'group-1',
    groupName: 'Group',
    role: role,
    invitePermission: invitePermission,
    joinPermission: joinPermission,
  );
}
