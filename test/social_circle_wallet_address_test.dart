import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/core/models/social_Invitation_model.dart';
import 'package:paracosm/core/models/social_review_model.dart';
import 'package:paracosm/core/models/user_display_model.dart';
import 'package:paracosm/core/network/api/social_circle_note_api.dart';
import 'package:paracosm/core/network/api/social_circle_user_api.dart';
import 'package:paracosm/core/network/client/friend_circle_base_client.dart';
import 'package:paracosm/core/network/friend_circle/friend_circle_token_manager.dart';
import 'package:paracosm/core/network/friend_circle/friend_circle_token_api.dart';
import 'package:paracosm/modules/user/model/user_info.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FriendCircleTokenManager.resetForTesting();
    FriendCircleTokenManager.configureForTesting(
      accountIdProvider: () => _currentWallet,
      nowSecondsProvider: () => 1000,
      tokenFetcher: (_) async => const FriendCircleTokenResult(
        token: 'jwt-token',
        userId: _currentWallet,
        expiresAt: 3000,
      ),
    );
    SocialCircleNoteApi.setAccountIdProviderForTesting(() => _currentWallet);
    SocialCircleUserApi.setAccountIdProviderForTesting(() => _currentWallet);
  });

  tearDown(() {
    SocialCircleNoteApi.resetClientForTesting();
    SocialCircleNoteApi.resetAccountIdProviderForTesting();
    SocialCircleUserApi.resetClientForTesting();
    SocialCircleUserApi.resetAccountIdProviderForTesting();
    FriendCircleTokenManager.resetForTesting();
  });

  group('social wallet address helpers', () {
    test('uses user info account before social user id', () {
      final model = _invitation(
        userId: _otherWallet,
        account: _mixedCaseWallet,
      );

      expect(model.walletAddress, _mixedCaseWallet.toLowerCase());
    });

    test('uses social user id only when it is a wallet address', () {
      expect(
        _invitation(userId: _mixedCaseWallet).walletAddress,
        _mixedCaseWallet.toLowerCase(),
      );
      expect(_invitation(userId: 'business-user-id').walletAddress, isEmpty);
    });

    test('uses review display user id before raw review user id', () {
      final review = SocialReviewModel(
        'review-1',
        'business-user-id',
        'note-1',
        0,
        'hello',
        'business-to-user',
        const [],
        userFullInfo: UserDisplayModel(
          profile: RCIMIWUserProfile.create(userId: _mixedCaseWallet),
        ),
      );

      expect(review.walletAddress, _mixedCaseWallet.toLowerCase());
    });
  });

  group('social circle api wallet address params', () {
    test('normalizes follow and block target wallet address fields', () async {
      final bodies = <Map<String, dynamic>>[];
      final client = FriendCircleBaseClient(
        dio: _dioWithHandler((options) {
          bodies.add(_decodeBody(options.data));
          return {'code': 1};
        }),
      );
      SocialCircleUserApi.setClientForTesting(client);

      expect(
        await SocialCircleUserApi.socialCircleUserFollowToggle(
          _mixedCaseWallet,
          true,
        ),
        isTrue,
      );
      expect(
        await SocialCircleUserApi.socialCircleUserBlockToggle(
          _mixedCaseWallet,
          true,
        ),
        isTrue,
      );

      expect(bodies[0]['user_id'], _currentWallet);
      expect(bodies[0]['follow_user_id'], _mixedCaseWallet.toLowerCase());
      expect(bodies[1]['block_user_id'], _mixedCaseWallet.toLowerCase());
    });

    test('parses blocked user records and derives block user ids', () async {
      final paths = <String>[];
      final queryParams = <Map<String, dynamic>>[];
      final client = FriendCircleBaseClient(
        dio: _dioWithHandler((options) {
          paths.add(options.path);
          queryParams.add(options.queryParameters);
          return {
            'code': 1,
            'data': [
              {
                'user_id': _currentWallet.toUpperCase(),
                'block_user_id': _mixedCaseWallet,
                'timestamp': '1718083200',
              },
            ],
          };
        }),
      );
      SocialCircleUserApi.setClientForTesting(client);

      final records =
          await SocialCircleUserApi.getSocialCircleUserBlockRecords();
      final blockIds = await SocialCircleUserApi.getSocialCircleUserBlock();

      expect(paths, ['/app/user/block', '/app/user/block']);
      expect(queryParams.first['user_id'], _currentWallet);
      expect(records, hasLength(1));
      expect(records.first.userId, _currentWallet);
      expect(records.first.blockUserId, _mixedCaseWallet.toLowerCase());
      expect(records.first.timestamp, 1718083200);
      expect(blockIds, [_mixedCaseWallet.toLowerCase()]);
    });

    test(
      'parses relation object lists without casting map to string',
      () async {
        final queryParams = <Map<String, dynamic>>[];
        final client = FriendCircleBaseClient(
          dio: _dioWithHandler((options) {
            queryParams.add(options.queryParameters);
            if (options.path == '/app/user/fans') {
              return {
                'code': 1,
                'data': [
                  {'fans_user_id': _mixedCaseWallet},
                ],
              };
            }
            return {
              'code': 1,
              'data': [
                {'follow_user_id': _mixedCaseWallet},
              ],
            };
          }),
        );
        SocialCircleUserApi.setClientForTesting(client);

        final followRecords =
            await SocialCircleUserApi.getSocialCircleUserFollowRecords(
              page: 2,
              size: 20,
            );
        final fanRecords =
            await SocialCircleUserApi.getSocialCircleUserFansRecords(
              page: 3,
              size: 20,
            );
        final following = await SocialCircleUserApi.getSocialCircleUserFollow();
        final fans = await SocialCircleUserApi.getSocialCircleUserFans();

        expect(queryParams[0]['user_id'], _currentWallet);
        expect(queryParams[0]['page'], 2);
        expect(queryParams[0]['size'], 20);
        expect(queryParams[1]['page'], 3);
        expect(
          followRecords.single.getFollowingUserId(),
          _mixedCaseWallet.toLowerCase(),
        );
        expect(
          fanRecords.single.getFanUserId(),
          _mixedCaseWallet.toLowerCase(),
        );
        expect(following, [_mixedCaseWallet.toLowerCase()]);
        expect(fans, [_mixedCaseWallet.toLowerCase()]);
      },
    );

    test('unblock sends normalized block user id', () async {
      final bodies = <Map<String, dynamic>>[];
      final paths = <String>[];
      final client = FriendCircleBaseClient(
        dio: _dioWithHandler((options) {
          paths.add(options.path);
          bodies.add(_decodeBody(options.data));
          return {'code': 1};
        }),
      );
      SocialCircleUserApi.setClientForTesting(client);

      expect(
        await SocialCircleUserApi.socialCircleUserBlockToggle(
          _mixedCaseWallet,
          false,
        ),
        isTrue,
      );

      expect(paths, ['/app/user/unblock']);
      expect(bodies.single['user_id'], _currentWallet);
      expect(bodies.single['block_user_id'], _mixedCaseWallet.toLowerCase());
    });

    test(
      'does not send request when target wallet address is missing',
      () async {
        var requestCount = 0;
        final client = FriendCircleBaseClient(
          dio: _dioWithHandler((options) {
            requestCount++;
            return {'code': 1};
          }),
        );
        SocialCircleUserApi.setClientForTesting(client);

        expect(
          await SocialCircleUserApi.socialCircleUserFollowToggle(
            'business-user-id',
            true,
          ),
          isFalse,
        );

        expect(requestCount, 0);
      },
    );

    test('normalizes review share and forward user address fields', () async {
      final bodies = <Map<String, dynamic>>[];
      final client = FriendCircleBaseClient(
        dio: _dioWithHandler((options) {
          bodies.add(_decodeBody(options.data));
          return {'code': 1};
        }),
      );
      SocialCircleNoteApi.setClientForTesting(client);

      expect(
        await SocialCircleNoteApi.socialCircleNoteReview(
          'note-1',
          _mixedCaseWallet,
          'hello',
          'root-1',
        ),
        isTrue,
      );
      expect(
        await SocialCircleNoteApi.socialCircleNoteShare(
          _currentWallet.toUpperCase(),
          _mixedCaseWallet,
          'note-1',
        ),
        isTrue,
      );
      expect(
        await SocialCircleNoteApi.socialCircleNoteForward(
          _currentWallet.toUpperCase(),
          _mixedCaseWallet,
          'note-1',
        ),
        isTrue,
      );

      expect(bodies[0]['to_user_id'], _mixedCaseWallet.toLowerCase());
      expect(bodies[1]['from_user_id'], _currentWallet);
      expect(bodies[1]['to_user_id'], _mixedCaseWallet.toLowerCase());
      expect(bodies[2]['from_user_id'], _currentWallet);
      expect(bodies[2]['to_user_id'], _mixedCaseWallet.toLowerCase());
    });

    test('loads collect list with page and size params', () async {
      final paths = <String>[];
      final queryParams = <Map<String, dynamic>>[];
      final client = FriendCircleBaseClient(
        dio: _dioWithHandler((options) {
          paths.add(options.path);
          queryParams.add(options.queryParameters);
          return {
            'code': 1,
            'data': [
              {
                'note_id': 'note-collect-1',
                'user_id': _mixedCaseWallet,
                'timestamp': 1718083200,
                'content': 'collected post',
                'media': [],
                'is_collect': true,
              },
            ],
          };
        }),
      );
      SocialCircleNoteApi.setClientForTesting(client);

      final list = await SocialCircleNoteApi.getSocialCircleCollectList(
        page: 0,
        size: 20,
      );

      expect(paths, ['/app/note/collect']);
      expect(queryParams.single['user_id'], _currentWallet);
      expect(queryParams.single['page'], 0);
      expect(queryParams.single['size'], 20);
      expect(list, hasLength(1));
      expect(list.single.noteId, 'note-collect-1');
      expect(list.single.content, 'collected post');
      expect(list.single.isCollect, isTrue);
    });
  });
}

const _currentWallet = '0x1111111111111111111111111111111111111111';
const _otherWallet = '0x2222222222222222222222222222222222222222';
const _mixedCaseWallet = '0xAaAaAaAaAaAaAaAaAaAaAaAaAaAaAaAaAaAaAaAa';

SocialInvitationModel _invitation({
  required String userId,
  String account = '',
}) {
  return SocialInvitationModel(
    'note-1',
    userId,
    0,
    '',
    '',
    '',
    false,
    0,
    const [],
    0,
    0,
    0,
    0,
    0,
    false,
    false,
    const [],
    userInfoModel: account.isEmpty
        ? null
        : UserInfo(
            userId: 'business-user-id',
            nickname: '',
            avatar: '',
            token: '',
            account: account,
          ),
  );
}

Map<String, dynamic> _decodeBody(dynamic data) {
  if (data is String) {
    return jsonDecode(data) as Map<String, dynamic>;
  }
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }
  throw StateError('Unsupported body: ${data.runtimeType}');
}

Dio _dioWithHandler(Map<String, dynamic> Function(RequestOptions) handler) {
  final dio = Dio();
  dio.httpClientAdapter = _JsonAdapter(handler);
  return dio;
}

class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.handler);

  final Map<String, dynamic> Function(RequestOptions) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (requestStream != null) {
      final chunks = await requestStream.toList();
      options.data = utf8.decode(chunks.expand((chunk) => chunk).toList());
    }
    return ResponseBody.fromString(
      jsonEncode(handler(options)),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
