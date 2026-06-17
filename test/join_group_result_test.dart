import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/modules/im/manager/im_group_manager.dart';

void main() {
  group('joinGroupResultFromCode', () {
    test('maps success code to joined', () {
      final result = joinGroupResultFromCode(0);

      expect(result.status, JoinGroupStatus.joined);
      expect(result.isJoined, isTrue);
      expect(result.code, 0);
    });

    test('maps 25424 to waiting manager approval', () {
      final result = joinGroupResultFromCode(25424);

      expect(result.status, JoinGroupStatus.waitingManagerApproval);
      expect(result.isJoined, isFalse);
      expect(result.code, 25424);
    });

    test('maps other codes to failed', () {
      final result = joinGroupResultFromCode(12345);

      expect(result.status, JoinGroupStatus.failed);
      expect(result.isJoined, isFalse);
      expect(result.code, 12345);
    });
  });
}
