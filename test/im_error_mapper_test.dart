import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/modules/im/result/im_error_mapper.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await AppLocalizations(const Locale('zh')).load();
  });

  test('maps RongCloud friend error codes to localized messages', () {
    const codes = [
      25460,
      25461,
      25462,
      25463,
      25464,
      25465,
      25466,
      25467,
      25468,
      25469,
      25470,
      25471,
      25472,
      25473,
    ];

    for (final code in codes) {
      final message = ImErrorMapper.message(code);
      expect(message, isNot(contains('未知错误')));
      expect(message, isNot('im_error_unknown'));
      expect(message, isNotEmpty);
    }
  });

  test('keeps unknown code fallback', () {
    expect(ImErrorMapper.message(999999), '未知错误(999999)');
  });
}
