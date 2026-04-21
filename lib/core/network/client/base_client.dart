import 'package:dio/dio.dart';
import '../../../modules/account/manager/account_manager.dart';

class BaseClient {
  final Dio _dio;

  BaseClient(String baseUrl)
      : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  )) {
    _dio.interceptors.add(_TokenInterceptor());
  }

  Future<dynamic> get(
      String path, {
        Map<String, dynamic>? params,
      }) async {
    final res = await _dio.get(path, queryParameters: params);
    return res.data;
  }

  Future<dynamic> post(
      String path, {
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

/// 自动加 token
class _TokenInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = AccountManager().currentAccount?.token;
    if (token != null) {
      options.headers["token"] = token;
    }
    handler.next(options);
  }
}