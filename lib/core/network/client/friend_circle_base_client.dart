import 'package:dio/dio.dart';

import '../api/api_paths.dart';
import '../friend_circle/friend_circle_token_manager.dart';

class FriendCircleBaseClient {
  final Dio _dio;

  FriendCircleBaseClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiPaths.circleUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ),
          ) {
    if (_dio.options.baseUrl.isEmpty) {
      _dio.options.baseUrl = ApiPaths.circleUrl;
    }
    _dio.interceptors.add(_FriendCircleTokenInterceptor());
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    final res = await _dio.get(path, queryParameters: params);
    return res.data;
  }

  Future<dynamic> post({
    required String path,
    dynamic data,
    Options? options,
    void Function(int, int)? onSendProgress,
  }) async {
    final res = await _dio.post(
      path,
      data: data,
      options: options,
      onSendProgress: onSendProgress,
    );
    return res.data;
  }
}

class _FriendCircleTokenInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await FriendCircleTokenManager.ensureValidToken();
      if (token.isNotEmpty) {
        options.headers['token'] = token;
      }
      handler.next(options);
    } catch (e) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: e,
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
