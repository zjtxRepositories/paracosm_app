import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/core/network/api/invite_api.dart';
import 'package:paracosm/core/network/api/invite_token_api.dart';

void main() {
  tearDown(InviteTokenApi.resetForTesting);

  test('posts signed invite getToken request and parses accessToken', () async {
    late RequestOptions capturedRequest;
    late Map<String, dynamic> capturedBody;
    InviteTokenApi.setHttpClientAdapterForTesting(
      _JsonAdapter((options) {
        capturedRequest = options;
        capturedBody = Map<String, dynamic>.from(options.data as Map);
        return {
          'code': 200,
          'token': 'rong-token-from-invite-service',
          'accessToken': 'v1.access',
          'userId': '0xabc',
          'appKey': 'app-key',
        };
      }),
    );
    InviteTokenApi.setNonceProviderForTesting(() => 'nonce-1');
    InviteTokenApi.setTimestampProviderForTesting(() => 1780800000);
    InviteTokenApi.setTokenProviderForTesting(() => null);
    InviteTokenApi.setSignatureProviderForTesting((userId, message) async {
      expect(userId, '0xabc');
      expect(
        message,
        'RongCloud getToken\n'
        'userId: 0xabc\n'
        'timestamp: 1780800000\n'
        'nonce: nonce-1',
      );
      return '0xsigned';
    });

    final result = await InviteTokenApi.getToken(userId: '0xabc', name: 'abc');

    expect(capturedRequest.baseUrl, InviteApi.inviteBaseUrl);
    expect(capturedRequest.path, '/user/getToken.json');
    expect(capturedBody['userId'], '0xabc');
    expect(capturedBody['signature'], '0xsigned');
    expect(result?.accessToken, 'v1.access');
    expect(result?.userId, '0xabc');
  });
}

class _JsonAdapter extends IOHttpClientAdapter {
  _JsonAdapter(this.handler);

  final Map<String, dynamic> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(handler(options)),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
