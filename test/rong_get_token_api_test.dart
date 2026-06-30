import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/core/network/api/rong_get_token_api.dart';

void main() {
  tearDown(RongGetTokenApi.resetForTesting);

  test('posts signed getToken request and parses rong token', () async {
    late RequestOptions capturedRequest;
    late Map<String, dynamic> capturedBody;
    RongGetTokenApi.setHttpClientAdapterForTesting(
      _JsonAdapter((options) {
        capturedRequest = options;
        capturedBody = Map<String, dynamic>.from(options.data as Map);
        return {'code': 200, 'token': 'rong-token', 'appKey': 'app-key'};
      }),
    );
    RongGetTokenApi.setNonceProviderForTesting(() => 'nonce-1');
    RongGetTokenApi.setTimestampProviderForTesting(() => 1780800000);
    RongGetTokenApi.setTokenProviderForTesting(() => null);
    RongGetTokenApi.setSignatureProviderForTesting((userId, message) async {
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

    final result = await RongGetTokenApi.getToken(userId: '0xabc', name: 'abc');

    expect(capturedRequest.baseUrl, 'https://rj.zjtxy.top');
    expect(capturedRequest.path, '/user/getToken.json');
    expect(capturedBody['userId'], '0xabc');
    expect(capturedBody['signature'], '0xsigned');
    expect(result?.token, 'rong-token');
    expect(result?.appKey, 'app-key');
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
