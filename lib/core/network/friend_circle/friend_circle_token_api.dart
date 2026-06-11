import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../modules/wallet/chains/evm/evm_facade.dart';

typedef FriendCircleSignatureProvider =
    Future<String> Function(String userId, String message);

class FriendCircleTokenResult {
  final String token;
  final String userId;
  final int expiresAt;

  const FriendCircleTokenResult({
    required this.token,
    required this.userId,
    required this.expiresAt,
  });
}

class FriendCircleTokenApi {
  static const String baseUrl = 'https://imapi.zjtxy.top/moments/friend97';
  static const String path = '/app/user/getToken';

  final Dio _dio;
  final String Function() _nonceProvider;
  final int Function() _timestampProvider;
  final FriendCircleSignatureProvider _signatureProvider;

  FriendCircleTokenApi({
    Dio? dio,
    String Function()? nonceProvider,
    int Function()? timestampProvider,
    FriendCircleSignatureProvider? signatureProvider,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl,
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 15),
               contentType: Headers.jsonContentType,
               validateStatus: (status) => status != null && status < 500,
             ),
           ),
       _nonceProvider = nonceProvider ?? _defaultNonce,
       _timestampProvider =
           timestampProvider ??
           (() => DateTime.now().millisecondsSinceEpoch ~/ 1000),
       _signatureProvider =
           signatureProvider ??
           ((userId, message) {
             return EvmFacade.signMessage(userId, message, personal: true);
           }) {
    if (_dio.options.baseUrl.isEmpty) {
      _dio.options.baseUrl = baseUrl;
    }
  }

  Future<FriendCircleTokenResult> getToken({required String userId}) async {
    final safeUserId = userId.trim().toLowerCase();
    if (safeUserId.isEmpty) {
      throw Exception('FriendCircle userId is empty');
    }

    final timestamp = _timestampProvider();
    final nonce = _nonceProvider();
    final message = buildSignatureMessage(
      userId: safeUserId,
      timestamp: timestamp,
      nonce: nonce,
    );
    final signature = await _signatureProvider(safeUserId, message);

    final response = await _dio.post(
      path,
      data: {
        'userId': safeUserId,
        'signature': signature,
        'timestamp': timestamp,
        'nonce': nonce,
      },
      options: Options(contentType: Headers.jsonContentType),
    );

    final data = _normalizeResponseData(response.data);
    if (data is! Map) {
      throw Exception('FriendCircle getToken invalid response');
    }

    if (data['code'] != 1) {
      throw Exception('FriendCircle getToken failed: ${data['msg']}');
    }

    final payload = data['data'];
    if (payload is! Map) {
      throw Exception('FriendCircle getToken missing data');
    }

    final token = payload['token']?.toString() ?? '';
    final responseUserId = payload['userId']?.toString() ?? safeUserId;
    final expiresAt = int.tryParse(payload['expiresAt']?.toString() ?? '') ?? 0;
    if (token.isEmpty) {
      throw Exception('FriendCircle getToken missing token');
    }
    if (expiresAt <= 0) {
      throw Exception('FriendCircle getToken missing expiresAt');
    }

    return FriendCircleTokenResult(
      token: token,
      userId: responseUserId.toLowerCase(),
      expiresAt: expiresAt,
    );
  }

  static String buildSignatureMessage({
    required String userId,
    required int timestamp,
    required String nonce,
  }) {
    return 'FriendCircle getToken\n'
        'userId: $userId\n'
        'timestamp: $timestamp\n'
        'nonce: $nonce';
  }

  static String _defaultNonce() {
    return const Uuid().v4();
  }

  dynamic _normalizeResponseData(dynamic data) {
    if (data is String && data.isNotEmpty) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return data;
      }
    }
    return data;
  }
}
