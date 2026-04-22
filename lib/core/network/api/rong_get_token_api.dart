import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:paracosm/modules/im/service/im_service.dart';

class RongGetTokenApi {
  static const String _path = '/user/getToken.json';
  static const String _baseUrl = 'https://api-cn.ronghub.com';
  static const String _appKey = ImConfig.appKey;
  static const String _appSecret = 'zmetBLCbins';

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  /// 生成随机数
  static String _nonce() {
    final random = Random();
    return (random.nextInt(900000) + 100000).toString();
  }

  /// 生成签名 SHA1(AppSecret + Nonce + Timestamp)
  static String _signature(String nonce, String timestamp) {
    final content = _appSecret + nonce + timestamp;
    print("🔵 signStr: $content");
    return sha1.convert(utf8.encode(content)).toString();
  }

  /// 获取 Token
  static Future<String?> getToken({
    required String userId,
    required String name,
    String? portraitUri,
  }) async {
    print("NOW: ${DateTime.now()}--$userId");
    print("MS: ${DateTime.now().millisecondsSinceEpoch}");
    final nonce = _nonce();
    final timestamp =
    (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final signature = _signature(nonce, timestamp);
    print("🔵 nonce: $nonce");
    print("🔵 timestamp: $timestamp");
    print("🔵 signature: $signature");
    try {
      final response = await _dio.post(
        _path,
        data: {
          'userId': userId,
          'name': name,
          'portraitUri': portraitUri ?? '',
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

      if (data is Map && data['code'] == 200) {
        return data['token'];
      }

      throw Exception('RongCloud getToken failed: ${data['code']}');
    } catch (e) {
      print('❌ RongGetTokenApi error: $e');
      return null;
    }
  }
}