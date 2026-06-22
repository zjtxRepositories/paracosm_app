import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/modules/moments/moment_profile_identity.dart';

void main() {
  test('uses explicit profile user id first', () {
    expect(
      resolveMomentProfileUserId(
        userId: 'Business-User',
        imUserId: '0x1111111111111111111111111111111111111111',
        isSelf: false,
        currentUserId: '0x2222222222222222222222222222222222222222',
      ),
      'business-user',
    );
  });

  test('falls back to im wallet address when profile user id is missing', () {
    expect(
      resolveMomentProfileUserId(
        userId: '',
        imUserId: '0xABCDEFabcdefABCDEFabcdefABCDEFabcdefABCD',
        isSelf: false,
        currentUserId: '',
      ),
      '0xabcdefabcdefabcdefabcdefabcdefabcdefabcd',
    );
  });

  test('falls back to current user id for self profile', () {
    expect(
      resolveMomentProfileUserId(
        userId: '',
        imUserId: '',
        isSelf: true,
        currentUserId: '0x3333333333333333333333333333333333333333',
      ),
      '0x3333333333333333333333333333333333333333',
    );
  });

  test('returns empty when no usable friend profile id exists', () {
    expect(
      resolveMomentProfileUserId(
        userId: '',
        imUserId: 'rong-user-id',
        isSelf: false,
        currentUserId: '',
      ),
      isEmpty,
    );
  });
}
