import 'package:dio/dio.dart';

class ErrorInterceptor extends Interceptor {

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {

    switch (err.type) {

      case DioExceptionType.connectionTimeout:
        print("连接超时");
        break;

      case DioExceptionType.receiveTimeout:
        print("响应超时");
        break;

      case DioExceptionType.badResponse:
        print("服务器错误");
        break;

      default:
        print("未知错误");
    }

    handler.next(err);
  }
}