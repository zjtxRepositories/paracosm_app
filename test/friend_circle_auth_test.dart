import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/core/network/api/api_paths.dart';
import 'package:paracosm/core/network/client/base_client.dart';
import 'package:paracosm/core/network/client/friend_circle_base_client.dart';
import 'package:paracosm/core/network/friend_circle/friend_circle_token_api.dart';
import 'package:paracosm/core/network/friend_circle/friend_circle_token_manager.dart';
import 'package:paracosm/core/network/friend_circle/friend_circle_token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FriendCircleTokenApi', () {
    test('posts signed getToken request and parses token result', () async {
      late RequestOptions capturedRequest;
      late Map<String, dynamic> capturedBody;
      final api = FriendCircleTokenApi(
        dio: _dioWithHandler((options) {
          capturedRequest = options;
          capturedBody = jsonDecode(options.data as String);
          return {
            'code': 1,
            'msg': 'success',
            'data': {
              'token': 'jwt-token',
              'userId': _accountId,
              'expiresAt': 1780886400,
            },
          };
        }),
        nonceProvider: () => 'nonce-1',
        timestampProvider: () => 1780800000,
        signatureProvider: (userId, message) async {
          expect(userId, _accountId);
          expect(
            message,
            'FriendCircle getToken\n'
            'userId: $_accountId\n'
            'timestamp: 1780800000\n'
            'nonce: nonce-1',
          );
          return '0xsigned';
        },
      );

      final result = await api.getToken(userId: _accountId);

      expect(capturedRequest.baseUrl, 'http://192.168.0.111:8080');
      expect(capturedRequest.path, '/app/user/getToken');
      expect(
        capturedRequest.headers[Headers.contentTypeHeader],
        contains('application/json'),
      );
      expect(capturedBody, {
        'userId': _accountId,
        'signature': '0xsigned',
        'timestamp': 1780800000,
        'nonce': 'nonce-1',
      });
      expect(result.token, 'jwt-token');
      expect(result.userId, _accountId);
      expect(result.expiresAt, 1780886400);
    });

    test('throws when token response fails or misses token', () async {
      final failedApi = FriendCircleTokenApi(
        dio: _dioWithHandler((_) => {'code': 0, 'msg': 'invalid signature'}),
        signatureProvider: (userId, message) async => '0xsigned',
      );
      await expectLater(
        failedApi.getToken(userId: _accountId),
        throwsA(isA<Exception>()),
      );

      final missingTokenApi = FriendCircleTokenApi(
        dio: _dioWithHandler(
          (_) => {
            'code': 1,
            'msg': 'success',
            'data': {'expiresAt': 1780886400},
          },
        ),
        signatureProvider: (userId, message) async => '0xsigned',
      );
      await expectLater(
        missingTokenApi.getToken(userId: _accountId),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('FriendCircleTokenStore and manager', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      FriendCircleTokenManager.resetForTesting();
    });

    test('stores token by account id', () async {
      final store = FriendCircleTokenStore();
      await store.save(
        _accountId,
        const FriendCircleToken(token: 'jwt-token', expiresAt: 1780886400),
      );

      final token = await store.read(_accountId);

      expect(token?.token, 'jwt-token');
      expect(token?.expiresAt, 1780886400);
      await store.clear(_accountId);
      expect(await store.read(_accountId), isNull);
    });

    test('reuses unexpired token without fetching', () async {
      var fetchCount = 0;
      final store = FriendCircleTokenStore();
      await store.save(
        _accountId,
        const FriendCircleToken(token: 'cached-token', expiresAt: 2000),
      );
      FriendCircleTokenManager.configureForTesting(
        store: store,
        accountIdProvider: () => _accountId,
        nowSecondsProvider: () => 1000,
        tokenFetcher: (_) async {
          fetchCount++;
          return const FriendCircleTokenResult(
            token: 'new-token',
            userId: _accountId,
            expiresAt: 3000,
          );
        },
      );

      final token = await FriendCircleTokenManager.ensureValidToken();

      expect(token, 'cached-token');
      expect(fetchCount, 0);
    });

    test('refreshes expired token and force refresh token', () async {
      var fetchCount = 0;
      final store = FriendCircleTokenStore();
      await store.save(
        _accountId,
        const FriendCircleToken(token: 'old-token', expiresAt: 1001),
      );
      FriendCircleTokenManager.configureForTesting(
        store: store,
        accountIdProvider: () => _accountId,
        nowSecondsProvider: () => 1000,
        tokenFetcher: (_) async {
          fetchCount++;
          return FriendCircleTokenResult(
            token: 'new-token-$fetchCount',
            userId: _accountId,
            expiresAt: 3000,
          );
        },
      );

      expect(await FriendCircleTokenManager.ensureValidToken(), 'new-token-1');
      expect(
        await FriendCircleTokenManager.ensureValidToken(forceRefresh: true),
        'new-token-2',
      );
      final saved = await store.read(_accountId);
      expect(saved?.token, 'new-token-2');
      expect(fetchCount, 2);
    });

    test('uses configured api with named userId argument', () async {
      late Map<String, dynamic> capturedBody;
      final store = FriendCircleTokenStore();
      final api = FriendCircleTokenApi(
        dio: _dioWithHandler((options) {
          capturedBody = jsonDecode(options.data as String);
          return {
            'code': 1,
            'msg': 'success',
            'data': {
              'token': 'api-token',
              'userId': _accountId,
              'expiresAt': 3000,
            },
          };
        }),
        nonceProvider: () => 'nonce-2',
        timestampProvider: () => 1000,
        signatureProvider: (userId, message) async => '0xsigned',
      );
      FriendCircleTokenManager.configureForTesting(
        store: store,
        api: api,
        accountIdProvider: () => _accountId,
        nowSecondsProvider: () => 1000,
      );

      final token = await FriendCircleTokenManager.ensureValidToken();

      expect(token, 'api-token');
      expect(capturedBody['userId'], _accountId);
      expect((await store.read(_accountId))?.token, 'api-token');
    });
  });

  group('FriendCircleBaseClient', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      FriendCircleTokenManager.resetForTesting();
    });

    test('adds friend circle token header to requests', () async {
      late RequestOptions capturedRequest;
      FriendCircleTokenManager.configureForTesting(
        accountIdProvider: () => _accountId,
        nowSecondsProvider: () => 1000,
        tokenFetcher: (_) async => const FriendCircleTokenResult(
          token: 'jwt-token',
          userId: _accountId,
          expiresAt: 3000,
        ),
      );
      final client = FriendCircleBaseClient(
        dio: _dioWithHandler((options) {
          capturedRequest = options;
          return {'code': 1, 'data': []};
        }),
      );

      await client.get('/app/note/list');

      expect(capturedRequest.baseUrl, ApiPaths.circleUrl);
      expect(capturedRequest.headers['token'], 'jwt-token');
    });

    test('ordinary BaseClient does not use friend circle token', () async {
      late RequestOptions capturedRequest;
      FriendCircleTokenManager.configureForTesting(
        accountIdProvider: () => _accountId,
        nowSecondsProvider: () => 1000,
        tokenFetcher: (_) async => const FriendCircleTokenResult(
          token: 'jwt-token',
          userId: _accountId,
          expiresAt: 3000,
        ),
      );
      final client = BaseClient(
        'http://example.test',
        dio: _dioWithHandler((options) {
          capturedRequest = options;
          return {'code': 1};
        }),
      );

      await client.get('/normal');

      expect(capturedRequest.headers.containsKey('token'), isFalse);
    });
  });
}

const _accountId = '0x1111111111111111111111111111111111111111';

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
