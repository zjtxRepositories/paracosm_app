import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/modules/im/group_info_update_builder.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

void main() {
  group('GroupInfoUpdateBuilder', () {
    test(
      'builds clean update payload without permission or readonly fields',
      () {
        final update = GroupInfoUpdateBuilder.build(
          groupId: 'group-1',
          groupName: 'New name',
          portraitUri: 'https://example.com/avatar.png',
          introduction: 'Intro',
          notice: 'Notice',
          extProfile: {'theme': 'blue'},
        );

        final json = update.toJson();

        expect(json['groupId'], 'group-1');
        expect(json['groupName'], 'New name');
        expect(json['portraitUri'], 'https://example.com/avatar.png');
        expect(json['introduction'], 'Intro');
        expect(json['notice'], 'Notice');
        expect(json['extProfile'], {'theme': 'blue'});
        expect(json['memberInfoEditPermission'], isNull);
        expect(json['groupInfoEditPermission'], isNull);
        expect(json['invitePermission'], isNull);
        expect(json['removeMemberPermission'], isNull);
        expect(json['role'], isNull);
        expect(json['ownerId'], isNull);
        expect(json['creatorId'], isNull);
      },
    );

    test('applies update fields without replacing local permission fields', () {
      final local = RCIMIWGroupInfo.create(
        groupId: 'group-1',
        groupName: 'Old name',
        portraitUri: 'old-avatar',
        introduction: 'Old intro',
        notice: 'Old notice',
        role: RCIMIWGroupMemberRole.manager,
        ownerId: 'owner-id',
        memberInfoEditPermission:
            RCIMIWGroupMemberInfoEditPermission.ownerorself,
        groupInfoEditPermission: RCIMIWGroupOperationPermission.ownerormanager,
      );
      final update = GroupInfoUpdateBuilder.build(
        groupId: 'group-1',
        groupName: 'New name',
        portraitUri: 'new-avatar',
        introduction: '',
        notice: '',
      );

      GroupInfoUpdateBuilder.applyToLocal(target: local, update: update);

      expect(local.groupName, 'New name');
      expect(local.portraitUri, 'new-avatar');
      expect(local.introduction, '');
      expect(local.notice, '');
      expect(local.role, RCIMIWGroupMemberRole.manager);
      expect(local.ownerId, 'owner-id');
      expect(
        local.memberInfoEditPermission,
        RCIMIWGroupMemberInfoEditPermission.ownerorself,
      );
      expect(
        local.groupInfoEditPermission,
        RCIMIWGroupOperationPermission.ownerormanager,
      );
    });
  });
}
