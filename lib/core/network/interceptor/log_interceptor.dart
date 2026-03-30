import 'package:dio/dio.dart';

class LogInterceptor extends Interceptor {

  @override
  void onRequest(options, handler) {

    print("请求地址: ${options.uri}");
    print("请求参数: ${options.data}");

    handler.next(options);
  }

  @override
  void onResponse(response, handler) {

    print("响应数据: ${response.data}");

    handler.next(response);
  }

}