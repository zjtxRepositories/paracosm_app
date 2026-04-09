import 'package:dio/dio.dart';

import '../../../modules/account/manager/account_manager.dart';

class AuthInterceptor extends Interceptor {

  @override
  void onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) {

    String? token = AccountManager().currentAccount?.token;
    if (token != null) {
      options.headers["Authorization"] = "Bearer $token";
    }

    handler.next(options);
  }
}