import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import '../../../modules/im/service/im_service.dart';

class RongGetTokenApi {
  static const String _path = '/user/getToken.json';
  static const String _baseUrl = 'https://api.sg-light-api.com';
  static const String _appKey = ImConfig.appKey;
  static const String _appSecret = 'zmetBLCbins';

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  static String _nonce() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(99999).toString();
  }

  static String _signature(String nonce, String timestamp) {
    final content = _appSecret + nonce + timestamp;
    return sha1.convert(utf8.encode(content)).toString();
  }

  static Future<String?> getToken({
    required String userId,
    required String name,
    String? portraitUri,
  }) async {
    final nonce = _nonce();
    final timestamp =
    (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final signature = _signature(nonce, timestamp);

    try {
      final response = await _dio.post(
        _path,
        data: {
          'userId': userId,
          'name': name,
          if (portraitUri != null && portraitUri.isNotEmpty)
            'portraitUri': portraitUri,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'App-Key': _appKey,
            'Nonce': nonce,
            'Timestamp': timestamp,
            'Signature': signature,
          },
        ),
      );

      final data = response.data;

      if (data is Map) {
        if (data['code'] == 200) {
          return data['token'];
        }

        throw Exception(
          'RongCloud error: code=${data['code']}, msg=${data['errorMessage']}',
        );
      }

      throw Exception('Invalid response');
    } catch (e) {
      print('❌ RongGetTokenApi error: $e');
      return null;
    }
  }
}