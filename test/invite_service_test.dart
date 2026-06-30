import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/core/network/api/invite_api.dart';
import 'package:paracosm/modules/invite/model/invite_models.dart';
import 'package:paracosm/modules/invite/service/invite_service.dart';
import 'package:paracosm/modules/invite/service/pending_invite_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('InviteService', () {
    test(
      'does not bind pending invite when current user already has parent',
      () async {
        SharedPreferences.setMockInitialValues({
          PendingInviteStore.inviteCodeKey: 'ABCD1234',
        });
        final api = _FakeInviteApi(
          profile: const InviteProfile(
            inviteCode: 'SELF1234',
            childrenCount: 0,
            parent: InviteUser(
              userId: '0xparent',
              nickname: 'Alice',
              avatar: '',
              boundAt: '2026-06-26T10:00:00Z',
            ),
          ),
        );
        final service = InviteService(api: api);

        final didBind = await service.tryBindPendingInviteIfNeeded();
        final pending = await service.getPendingInvite();

        expect(didBind, isFalse);
        expect(api.bindCalls, 0);
        expect(pending, isNull);
      },
    );

    test('binds pending invite when current user has no parent', () async {
      SharedPreferences.setMockInitialValues({
        PendingInviteStore.inviteCodeKey: 'ABCD1234',
      });
      final api = _FakeInviteApi(
        profile: const InviteProfile(inviteCode: 'SELF1234', childrenCount: 0),
      );
      final service = InviteService(api: api);

      final didBind = await service.tryBindPendingInviteIfNeeded();
      final pending = await service.getPendingInvite();

      expect(didBind, isTrue);
      expect(api.bindCalls, 1);
      expect(api.boundCode, 'ABCD1234');
      expect(pending, isNull);
    });

    test(
      'does not bind pending invite when code is current user invite code',
      () async {
        SharedPreferences.setMockInitialValues({
          PendingInviteStore.inviteCodeKey: ' self1234 ',
        });
        final api = _FakeInviteApi(
          profile: const InviteProfile(
            inviteCode: 'SELF1234',
            childrenCount: 0,
          ),
        );
        final service = InviteService(api: api);

        final didBind = await service.tryBindPendingInviteIfNeeded();
        final pending = await service.getPendingInvite();

        expect(didBind, isFalse);
        expect(api.bindCalls, 0);
        expect(pending, isNull);
      },
    );

    test(
      'skips invite code when it matches current user invite code',
      () async {
        SharedPreferences.setMockInitialValues({});
        final api = _FakeInviteApi(
          profile: const InviteProfile(
            inviteCode: 'SELF1234',
            childrenCount: 0,
          ),
        );
        final service = InviteService(api: api);

        final reason = await service.getInviteSkipReason(' self1234 ');

        expect(reason, InviteSkipReason.selfInviteCode);
      },
    );
  });
}

class _FakeInviteApi extends InviteApi {
  _FakeInviteApi({required this.profile});

  final InviteProfile profile;
  int bindCalls = 0;
  String? boundCode;

  @override
  Future<InviteProfile> getProfile() async => profile;

  @override
  Future<InviteBindResult> bind(String inviteCode) async {
    bindCalls += 1;
    boundCode = inviteCode;
    return const InviteBindResult(
      bound: true,
      alreadyBound: false,
      parentUserId: '0xparent',
      childUserId: '0xchild',
    );
  }
}
