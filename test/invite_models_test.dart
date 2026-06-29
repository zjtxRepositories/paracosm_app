import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/modules/invite/model/invite_models.dart';

void main() {
  group('Invite models', () {
    test('parses profile response data with parent', () {
      final profile = InviteProfile.fromJson({
        'inviteCode': 'ABCD1234',
        'childrenCount': '12',
        'parent': {
          'userId': '0xparent',
          'nickname': 'Alice',
          'avatar': 'https://example.com/a.png',
          'boundAt': '2026-06-26T10:00:00Z',
        },
      });

      expect(profile.inviteCode, 'ABCD1234');
      expect(profile.childrenCount, 12);
      expect(profile.parent?.userId, '0xparent');
      expect(profile.parent?.displayName, 'Alice');
    });

    test('uses safe defaults when profile fields are missing', () {
      final profile = InviteProfile.fromJson({});

      expect(profile.inviteCode, isEmpty);
      expect(profile.childrenCount, 0);
      expect(profile.parent, isNull);
      expect(profile.inviteLink, isEmpty);
    });

    test('parses children list with top-level pagination', () {
      final page = InviteChildrenPage.fromResponse({
        'resultCode': 1,
        'message': 'success',
        'data': [
          {
            'userId': '0xchild',
            'nickname': '',
            'avatar': '',
            'boundAt': '2026-06-26T11:00:00Z',
            'status': 'BOUND',
          },
        ],
        'pagination': {
          'page': '1',
          'pageSize': '20',
          'totalItems': '1',
          'totalPages': '1',
        },
      });

      expect(page.children, hasLength(1));
      expect(page.children.first.displayName, '0xchild');
      expect(page.pagination.page, 1);
      expect(page.pagination.totalItems, 1);
      expect(page.hasMore, isFalse);
    });

    test('parses resolve response', () {
      final result = InviteResolveResult.fromJson({
        'inviteCode': 'ABCD1234',
        'inviterUserId': '0xparent',
        'inviterName': 'Alice',
        'inviterAvatar': '',
        'isValid': 'true',
      });

      expect(result.inviteCode, 'ABCD1234');
      expect(result.inviterUserId, '0xparent');
      expect(result.inviterName, 'Alice');
      expect(result.isValid, isTrue);
    });
  });
}
