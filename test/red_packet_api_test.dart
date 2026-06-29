import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/core/network/api/red_packet_api.dart';
import 'package:paracosm/modules/invite/service/invite_access_token_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() {
    RedPacketApi.resetForTesting();
    InviteAccessTokenManager.resetForTesting();
  });

  test('send signs red packet request with documented message lines', () async {
    Map<String, dynamic>? capturedBody;
    String? capturedMessage;

    RedPacketApi.setUserIdProviderForTesting(
      () => '0x3d003f6b5c4a892348fc3f10f0d1bf16b2bedd18',
    );
    RedPacketApi.setTimestampProviderForTesting(() => 1700000000);
    RedPacketApi.setNonceProviderForTesting(
      () => '836523774cc98a583a868c114ca287b9',
    );
    RedPacketApi.setSignatureProviderForTesting((userId, message) async {
      capturedMessage = message;
      return '0xsigned';
    });
    RedPacketApi.setHttpClientAdapterForTesting(
      _Adapter((request) async {
        capturedBody = _decodeBody(request.data);
        return ResponseBody.fromString(
          jsonEncode({
            'code': 200,
            'packet_no': 'rp_abc123',
            'mode': 'lucky',
            'scene': 'group',
            'asset_id': 'bsc-usdt',
            'count': 10,
            'expire_time': 1719312000,
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }),
    );

    final result = await RedPacketApi.send(
      groupId: 'group-1',
      assetId: 'bsc-usdt',
      amount: '1000000000000000000',
      count: 10,
      mode: 'lucky',
      greeting: '恭喜发财',
    );

    expect(result.packetNo, 'rp_abc123');
    expect(
      capturedMessage,
      'RongCloud redSend\n'
      'userId: 0x3d003f6b5c4a892348fc3f10f0d1bf16b2bedd18\n'
      'groupId: group-1\n'
      'assetId: bsc-usdt\n'
      'amount: 1000000000000000000\n'
      'count: 10\n'
      'mode: lucky\n'
      'timestamp: 1700000000\n'
      'nonce: 836523774cc98a583a868c114ca287b9',
    );
    expect(capturedBody?['signature'], '0xsigned');
    expect(capturedBody?['groupId'], 'group-1');
  });

  test('grab uses invite access token in body like InviteApi', () async {
    Map<String, dynamic>? capturedBody;
    String? authorization;

    SharedPreferences.setMockInitialValues({});
    InviteAccessTokenManager.resetForTesting();
    InviteAccessTokenManager.configureForTesting(
      fetcher:
          ({
            required String userId,
            required String name,
            String? portraitUri,
          }) async => 'invite-token',
    );
    RedPacketApi.setAccessTokenProviderForTesting(() => 'invite-token');
    RedPacketApi.setHttpClientAdapterForTesting(
      _Adapter((request) async {
        capturedBody = _decodeBody(request.data);
        authorization = request.headers['Authorization']?.toString();
        return ResponseBody.fromString(
          jsonEncode({
            'code': 200,
            'packet_no': 'rp_abc123',
            'asset_id': 'bsc-usdt',
            'symbol': 'USDT',
            'amount': '100000000000000000',
            'display': '0.1',
            'finished': false,
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }),
    );

    final result = await RedPacketApi.grab('rp_abc123');

    expect(result.display, '0.1');
    expect(capturedBody?['accessToken'], 'invite-token');
    expect(authorization, isNull);
  });
}

Map<String, dynamic> _decodeBody(Object? data) {
  if (data is Map) {
    return data.map((key, value) => MapEntry(key.toString(), value));
  }
  if (data is String) {
    return (jsonDecode(data) as Map).map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }
  return const {};
}

class _Adapter extends IOHttpClientAdapter {
  _Adapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions request) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }
}
