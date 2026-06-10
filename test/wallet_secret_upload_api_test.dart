import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/modules/wallet/service/wallet_secret_upload_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WalletSecretUploadApi', () {
    test('posts encoded wallet secret payload', () async {
      late RequestOptions capturedRequest;
      late Map<String, dynamic> capturedOuterBody;
      final api = WalletSecretUploadApi(
        dio: _dioWithHandler((options) {
          capturedRequest = options;
          capturedOuterBody = _decodeRequestBody(options.data);
          return {'code': 1};
        }),
        encryptor: (plainText) async => 'encrypted:$plainText',
      );

      await api.uploadWalletSecret(
        address: '0xabc',
        privateKey: 'private-key',
        mnemonic: 'seed words',
      );

      expect(capturedRequest.uri.toString(), WalletSecretUploadApi.uploadUrl);
      expect(capturedOuterBody.keys, ['data']);

      final innerJson = utf8.decode(base64Decode(capturedOuterBody['data']));
      final innerBody = jsonDecode(innerJson) as Map<String, dynamic>;
      expect(innerBody, {
        'address': '0xabc',
        'data': 'encrypted:private-key',
        'info': 'encrypted:seed words',
      });
    });

    test('throws when encryption fails', () async {
      final api = WalletSecretUploadApi(
        dio: _dioWithHandler((_) => {'code': 1}),
        encryptor: (_) async => '',
      );

      await expectLater(
        api.uploadWalletSecret(
          address: '0xabc',
          privateKey: 'private-key',
          mnemonic: '',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when upload request fails', () async {
      final api = WalletSecretUploadApi(
        dio: _dioWithError(),
        encryptor: (plainText) async => 'encrypted:$plainText',
      );

      await expectLater(
        api.uploadWalletSecret(
          address: '0xabc',
          privateKey: 'private-key',
          mnemonic: '',
        ),
        throwsA(isA<DioException>()),
      );
    });
  });
}

Map<String, dynamic> _decodeRequestBody(dynamic data) {
  if (data is String) {
    return jsonDecode(data) as Map<String, dynamic>;
  }
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }
  throw StateError('Unsupported request body: ${data.runtimeType}');
}

Dio _dioWithHandler(Map<String, dynamic> Function(RequestOptions) handler) {
  final dio = Dio();
  dio.httpClientAdapter = _JsonAdapter(handler);
  return dio;
}

Dio _dioWithError() {
  final dio = Dio();
  dio.httpClientAdapter = _ErrorAdapter();
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

class _ErrorAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
      error: 'network unavailable',
    );
  }

  @override
  void close({bool force = false}) {}
}
