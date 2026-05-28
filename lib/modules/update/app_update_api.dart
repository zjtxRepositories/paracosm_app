import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'app_update_policy.dart';
import 'app_version_model.dart';

class AppUpdateApi {
  AppUpdateApi({Dio? dio, this.appAuthKey = defaultAppAuthKey})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

  static const String baseUrl = 'https://imapi.zjtxy.top';
  static const String checkUpdatePath = '/prod-api/im/channel/app/checkUpdate';
  static const String defaultAppAuthKey = String.fromEnvironment(
    'PARACOSM_APP_AUTH_KEY',
  );

  final Dio _dio;
  final String appAuthKey;

  bool get hasAuthKey => hasAppUpdateAuthKey(appAuthKey);

  Future<AppVersionModel?> checkUpdate(String version) async {
    if (!hasAuthKey) {
      return null;
    }

    try {
      final response = await _dio.get<Object?>(
        checkUpdatePath,
        queryParameters: {'appAuthKey': appAuthKey, 'version': version},
      );
      final payload = _decodeResponse(response.data);
      if (payload == null || !_isSuccessCode(payload['code'])) {
        return null;
      }

      final data = payload['data'];
      if (data is! Map) {
        return null;
      }

      return AppVersionModel.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      debugPrint(
        'App update check failed: ${error.response?.statusCode ?? error.type}',
      );
      return null;
    } catch (error) {
      debugPrint('App update check failed: ${error.runtimeType}');
      return null;
    }
  }

  Map<String, dynamic>? _decodeResponse(Object? data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }
    return null;
  }

  bool _isSuccessCode(Object? code) {
    if (code == 200) {
      return true;
    }
    if (code is String) {
      return code.trim() == '200';
    }
    return false;
  }
}
