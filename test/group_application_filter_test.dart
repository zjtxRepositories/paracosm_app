import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/modules/im/group_application_filter.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

void main() {
  group('splitGroupApplications', () {
    test('splits join review and invite confirmation buckets', () {
      final buckets = splitGroupApplications([
        _application(
          direction: RCIMIWGroupApplicationDirection.applicationreceived,
          status: RCIMIWGroupApplicationStatus.managerunhandled,
        ),
        _application(
          direction: RCIMIWGroupApplicationDirection.applicationreceived,
          status: RCIMIWGroupApplicationStatus.managerrefused,
        ),
        _application(
          direction: RCIMIWGroupApplicationDirection.invitationreceived,
          status: RCIMIWGroupApplicationStatus.inviteeunhandled,
        ),
        _application(
          direction: RCIMIWGroupApplicationDirection.invitationreceived,
          status: RCIMIWGroupApplicationStatus.inviteerefused,
        ),
      ]);

      expect(buckets.joinUnhandledCount, 1);
      expect(buckets.joinProcessed, hasLength(1));
      expect(buckets.inviteUnhandledCount, 1);
      expect(buckets.inviteProcessed, hasLength(1));
      expect(buckets.unhandledCount, 2);
    });

    test('filters to invite confirmation mode', () {
      final buckets = splitGroupApplications([
        _application(
          direction: RCIMIWGroupApplicationDirection.applicationreceived,
          status: RCIMIWGroupApplicationStatus.managerunhandled,
        ),
        _application(
          direction: RCIMIWGroupApplicationDirection.invitationreceived,
          status: RCIMIWGroupApplicationStatus.inviteeunhandled,
        ),
      ], mode: GroupApplicationViewMode.inviteConfirmation);

      expect(buckets.joinUnhandled, isEmpty);
      expect(buckets.inviteUnhandledCount, 1);
      expect(buckets.unhandledCount, 1);
    });

    test('filters to a group id', () {
      final buckets = splitGroupApplications([
        _application(
          groupId: 'group-1',
          direction: RCIMIWGroupApplicationDirection.invitationreceived,
          status: RCIMIWGroupApplicationStatus.inviteeunhandled,
        ),
        _application(
          groupId: 'group-2',
          direction: RCIMIWGroupApplicationDirection.invitationreceived,
          status: RCIMIWGroupApplicationStatus.inviteeunhandled,
        ),
      ], groupId: 'group-1');

      expect(buckets.inviteUnhandledCount, 1);
      expect(buckets.inviteUnhandled.single.groupId, 'group-1');
    });

    test('upsert replaces matching callback item', () {
      final list = [
        _application(
          direction: RCIMIWGroupApplicationDirection.invitationreceived,
          status: RCIMIWGroupApplicationStatus.inviteeunhandled,
        ),
      ];

      upsertGroupApplication(
        list,
        _application(
          direction: RCIMIWGroupApplicationDirection.invitationreceived,
          status: RCIMIWGroupApplicationStatus.joined,
        ),
      );

      expect(list, hasLength(1));
      expect(list.single.status, RCIMIWGroupApplicationStatus.joined);
    });

    test(
      'upsert keeps join review and invite confirmation as separate items',
      () {
        final list = [
          _application(
            direction: RCIMIWGroupApplicationDirection.applicationreceived,
            status: RCIMIWGroupApplicationStatus.managerunhandled,
          ),
        ];

        upsertGroupApplication(
          list,
          _application(
            direction: RCIMIWGroupApplicationDirection.invitationreceived,
            status: RCIMIWGroupApplicationStatus.inviteeunhandled,
          ),
        );

        expect(list, hasLength(2));
        expect(
          list.map((item) => item.direction),
          containsAll([
            RCIMIWGroupApplicationDirection.applicationreceived,
            RCIMIWGroupApplicationDirection.invitationreceived,
          ]),
        );
      },
    );
  });
}

RCIMIWGroupApplicationInfo _application({
  String groupId = 'group-1',
  required RCIMIWGroupApplicationDirection direction,
  required RCIMIWGroupApplicationStatus status,
}) {
  final info = RCIMIWGroupApplicationInfo.fromJson({});
  info.groupId = groupId;
  info.direction = direction;
  info.status = status;
  info.joinMemberInfo = RCIMIWGroupMemberInfo.fromJson({'userId': 'invitee-1'});
  info.inviterInfo = RCIMIWGroupMemberInfo.fromJson({'userId': 'inviter-1'});
  return info;
}
