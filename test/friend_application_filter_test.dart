import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/modules/im/group_application_filter.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

void main() {
  group('splitFriendApplications', () {
    test('splits received friend applications into new and processed', () {
      final buckets = splitFriendApplications([
        _application(
          type: RCIMIWFriendApplicationType.received,
          status: RCIMIWFriendApplicationStatus.unhandled,
        ),
        _application(
          type: RCIMIWFriendApplicationType.received,
          status: RCIMIWFriendApplicationStatus.accepted,
        ),
        _application(
          type: RCIMIWFriendApplicationType.sent,
          status: RCIMIWFriendApplicationStatus.unhandled,
        ),
      ]);

      expect(buckets.newRequests, hasLength(1));
      expect(buckets.processedRequests, hasLength(1));
      expect(buckets.unhandledCount, 1);
    });

    test('treats ignored unhandled items as processed', () {
      final item = _application(
        type: RCIMIWFriendApplicationType.received,
        status: RCIMIWFriendApplicationStatus.unhandled,
      );

      final buckets = splitFriendApplications(
        [item],
        isIgnored: (value) => identical(value, item),
      );

      expect(buckets.newRequests, isEmpty);
      expect(buckets.processedRequests, hasLength(1));
      expect(buckets.unhandledCount, 0);
    });
  });
}

RCIMIWFriendApplicationInfo _application({
  required RCIMIWFriendApplicationType type,
  required RCIMIWFriendApplicationStatus status,
}) {
  final info = RCIMIWFriendApplicationInfo.create(
    userId: 'user-1',
    applicationType: type,
    applicationStatus: status,
    operationTime: 1234567890,
  );
  return info;
}
