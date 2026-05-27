import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/modules/update/app_update_api.dart';
import 'package:paracosm/modules/update/app_update_policy.dart';
import 'package:paracosm/modules/update/app_version_model.dart';

void main() {
  group('AppVersionModel', () {
    test('parses normal update payload', () {
      final model = AppVersionModel.fromJson({
        'isUpdate': true,
        'version': '2.0.2',
        'download': 'https://example.com/app.apk',
        'updateContent': '更新说明',
        'time': 1710000000,
        'isForceUpdate': 1,
      });

      expect(model.isUpdate, isTrue);
      expect(model.version, '2.0.2');
      expect(model.download, 'https://example.com/app.apk');
      expect(model.updateContent, '更新说明');
      expect(model.time, 1710000000);
      expect(model.isForceUpdate, 1);
      expect(model.isForce, isTrue);
      expect(model.canUpdate, isTrue);
    });

    test('falls back safely when fields are missing', () {
      final model = AppVersionModel.fromJson({});

      expect(model.isUpdate, isFalse);
      expect(model.version, isEmpty);
      expect(model.download, isEmpty);
      expect(model.updateContent, isEmpty);
      expect(model.time, 0);
      expect(model.isForceUpdate, 0);
      expect(model.isForce, isFalse);
      expect(model.canUpdate, isFalse);
    });

    test('converts flexible bool and force update values', () {
      final model = AppVersionModel.fromJson({
        'isUpdate': '1',
        'download': 'https://example.com/app.apk',
        'isForceUpdate': 'true',
      });

      expect(model.isUpdate, isTrue);
      expect(model.isForceUpdate, 1);
      expect(model.isForce, isTrue);
      expect(model.canUpdate, isTrue);
    });

    test('does not allow updates without update flag or download url', () {
      final noUpdate = AppVersionModel.fromJson({
        'isUpdate': false,
        'download': 'https://example.com/app.apk',
      });
      final noDownload = AppVersionModel.fromJson({
        'isUpdate': true,
        'download': '   ',
      });

      expect(noUpdate.canUpdate, isFalse);
      expect(noDownload.canUpdate, isFalse);
      expect(shouldShowAppUpdate(noUpdate), isFalse);
      expect(shouldShowAppUpdate(noDownload), isFalse);
    });
  });

  group('app update policy', () {
    test('requires Android and non-web platform', () {
      expect(
        isAndroidAppUpdateTarget(
          platform: TargetPlatform.android,
          isWeb: false,
        ),
        isTrue,
      );
      expect(
        isAndroidAppUpdateTarget(platform: TargetPlatform.iOS, isWeb: false),
        isFalse,
      );
      expect(
        isAndroidAppUpdateTarget(platform: TargetPlatform.android, isWeb: true),
        isFalse,
      );
    });

    test('requires non-empty auth key', () {
      expect(hasAppUpdateAuthKey('secret'), isTrue);
      expect(hasAppUpdateAuthKey('   '), isFalse);
      expect(AppUpdateApi(appAuthKey: 'secret').hasAuthKey, isTrue);
      expect(AppUpdateApi(appAuthKey: '').hasAuthKey, isFalse);
    });
  });
}
