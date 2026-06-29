import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../../../modules/account/manager/account_manager.dart';
import '../../../modules/wallet/chains/evm/evm_facade.dart';
import 'invite_api.dart';

typedef InviteTokenSignatureProvider =
    Future<String> Function(String userId, String message);

class InviteTokenResult {
  final String accessToken;
  final String? userId;

  const InviteTokenResult({required this.accessToken, this.userId});
}

class InviteTokenApi {
  static const String path = '/user/getToken.json';

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: InviteApi.inviteBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: Headers.jsonContentType,
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  static String Function()? _nonceProviderForTesting;
  static int Function()? _timestampProviderForTesting;
  static String? Function()? _tokenProviderForTesting;
  static InviteTokenSignatureProvider? _signatureProviderForTesting;

  static Future<InviteTokenResult?> getToken({
    required String userId,
    required String name,
    String? portraitUri,
  }) async {
    final nonce = _nonce();
    final timestamp = _timestamp();
    final businessToken = _businessToken();

    try {
      final requestBody = await _requestBody(
        userId: userId,
        name: name,
        portraitUri: portraitUri,
        timestamp: timestamp,
        nonce: nonce,
      );
      debugPrint(
        'InviteTokenApi request: url=${InviteApi.inviteBaseUrl}$path, '
        'params=${{...requestBody, 'signature': _mask(requestBody['signature']?.toString()), 'hasBusinessToken': businessToken?.isNotEmpty == true}}',
      );
      final response = await _dio.post(
        path,
        data: requestBody,
        options: Options(
          contentType: Headers.jsonContentType,
          headers: {
            if (businessToken != null && businessToken.isNotEmpty)
              'token': businessToken,
          },
        ),
      );

      final data = _normalizeResponseData(response.data);
      if (data is Map) {
        if (data['code'] == 200) {
          return _parseResult(data);
        }

        throw Exception(
          'Invite token error: http=${response.statusCode}, '
          'code=${data['code']}, msg=${_messageOf(data)}',
        );
      }

      throw Exception(
        'Invalid invite token response: http=${response.statusCode}, '
        'data=$data',
      );
    } on DioException catch (e) {
      debugPrint(
        'InviteTokenApi error: $e, '
        'status=${e.response?.statusCode}, data=${e.response?.data}',
      );
      return null;
    } catch (e) {
      debugPrint('InviteTokenApi error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> _requestBody({
    required String userId,
    required String name,
    required int timestamp,
    required String nonce,
    String? portraitUri,
  }) async {
    return {
      'userId': userId,
      'name': name,
      if (portraitUri != null && portraitUri.isNotEmpty)
        'portraitUri': portraitUri,
      'timestamp': timestamp,
      'nonce': nonce,
      'signature': await _signature(userId, timestamp.toString(), nonce),
    };
  }

  static InviteTokenResult _parseResult(Map data) {
    final payload = data['data'] is Map ? data['data'] as Map : data;
    final accessToken = payload['accessToken']?.toString();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Invalid invite token response: missing accessToken');
    }

    return InviteTokenResult(
      accessToken: accessToken,
      userId: payload['userId']?.toString(),
    );
  }

  static Future<String> _signature(
    String userId,
    String timestamp,
    String nonce,
  ) {
    final content = _signatureMessage(userId, timestamp, nonce);
    final signatureProvider = _signatureProviderForTesting;
    if (signatureProvider != null) {
      return signatureProvider(userId, content);
    }
    return EvmFacade.signMessage(userId, content, personal: true);
  }

  static String _signatureMessage(
    String userId,
    String timestamp,
    String nonce,
  ) {
    return 'RongCloud getToken\n'
        'userId: $userId\n'
        'timestamp: $timestamp\n'
        'nonce: $nonce';
  }

  static String _nonce() {
    final nonceProvider = _nonceProviderForTesting;
    if (nonceProvider != null) return nonceProvider();

    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(99999).toString();
  }

  static int _timestamp() {
    final timestampProvider = _timestampProviderForTesting;
    if (timestampProvider != null) return timestampProvider();

    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  static String? _businessToken() {
    final tokenProvider = _tokenProviderForTesting;
    if (tokenProvider != null) return tokenProvider();

    return AccountManager().currentAccount?.token;
  }

  static dynamic _normalizeResponseData(dynamic data) {
    if (data is String && data.isNotEmpty) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return data;
      }
    }
    return data;
  }

  static String? _messageOf(Map data) {
    return data['errorMessage']?.toString() ??
        data['message']?.toString() ??
        data['msg']?.toString() ??
        data['error']?.toString();
  }

  static String _mask(String? value) {
    if (value == null || value.isEmpty) return '';
    if (value.length <= 12) return '***';
    return '${value.substring(0, 6)}...${value.substring(value.length - 6)}';
  }

  static void setHttpClientAdapterForTesting(HttpClientAdapter adapter) {
    _dio.httpClientAdapter = adapter;
  }

  static void setNonceProviderForTesting(String Function()? provider) {
    _nonceProviderForTesting = provider;
  }

  static void setTimestampProviderForTesting(int Function()? provider) {
    _timestampProviderForTesting = provider;
  }

  static void setTokenProviderForTesting(String? Function()? provider) {
    _tokenProviderForTesting = provider;
  }

  static void setSignatureProviderForTesting(
    InviteTokenSignatureProvider? provider,
  ) {
    _signatureProviderForTesting = provider;
  }

  static void resetForTesting() {
    _nonceProviderForTesting = null;
    _timestampProviderForTesting = null;
    _tokenProviderForTesting = null;
    _signatureProviderForTesting = null;
    _dio.httpClientAdapter = IOHttpClientAdapter();
  }
}
