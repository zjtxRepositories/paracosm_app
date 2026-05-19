import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/modules/im/manager/im_burn_after_reading_manager.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImBurnAfterReadingManager', () {
    late ImBurnAfterReadingManager manager;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      manager = ImBurnAfterReadingManager();
    });

    test('uses only configured duration options', () async {
      expect(ImBurnAfterReadingManager.durationOptions, [
        0,
        10,
        60,
        300,
        600,
        1800,
      ]);
      expect(manager.durationForIndex(-1), 0);
      expect(manager.durationForIndex(2), 60);
      expect(manager.durationForIndex(99), 1800);
      expect(manager.indexForDuration(300), 3);
      expect(manager.indexForDuration(7), 0);

      final saved = await manager.setDurationSeconds(
        type: RCIMIWConversationType.private,
        targetId: 'alice',
        seconds: 7,
      );

      expect(saved, isTrue);
      expect(
        await manager.getDurationSeconds(
          type: RCIMIWConversationType.private,
          targetId: 'alice',
        ),
        0,
      );
    });

    test('persists and clears burn expire time by message key', () async {
      expect(await manager.getMessageExpireTime('uid:m1'), isNull);
      expect(await manager.saveMessageExpireTime('uid:m1', 123456), isTrue);
      expect(await manager.getMessageExpireTime('uid:m1'), 123456);
      expect(await manager.clearMessageExpireTime('uid:m1'), isTrue);
      expect(await manager.getMessageExpireTime('uid:m1'), isNull);
    });

    test('rejects invalid message expire time input', () async {
      expect(await manager.saveMessageExpireTime('', 123456), isFalse);
      expect(await manager.saveMessageExpireTime('uid:m1', 0), isFalse);
      expect(await manager.getMessageExpireTime(''), isNull);
      expect(await manager.clearMessageExpireTime(''), isFalse);
    });

    test(
      'ensureMessageExpireTime does not reset existing expire time',
      () async {
        final first = await manager.ensureMessageExpireTime(
          messageKey: 'uid:m1',
          startTime: 1000,
          durationSeconds: 10,
        );
        final second = await manager.ensureMessageExpireTime(
          messageKey: 'uid:m1',
          startTime: 5000,
          durationSeconds: 10,
        );

        expect(first, 11000);
        expect(second, 11000);
        expect(await manager.getMessageExpireTime('uid:m1'), 11000);
      },
    );
  });
}
