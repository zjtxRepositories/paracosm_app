import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/core/models/moment_message_model.dart';
import 'package:paracosm/core/network/friend_circle/moment_message_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('按账号保存消息快照并识别新消息', () async {
    final cache = MomentMessageCache();
    final first = _message('message-1');
    final second = _message('message-2');

    expect(await cache.hasNewMessages('0xaccount', [first]), isTrue);

    await cache.save('0xaccount', [first]);

    expect(await cache.hasNewMessages('0xaccount', [first]), isFalse);
    expect(await cache.hasNewMessages('0xaccount', [first, second]), isTrue);
    expect(await cache.hasNewMessages('0xother', [first]), isTrue);
  });
}

MomentMessageModel _message(String id) {
  return MomentMessageModel.fromJson({
    'message_id': id,
    'type': 1,
    'action': 'like',
    'from': '0xfrom',
    'read': false,
  });
}
