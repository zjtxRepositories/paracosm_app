import 'package:dio/dio.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/account/service/account_service.dart';

class LogInterceptor extends Interceptor {
  bool _handlingTokenExpired = false;
  CancelToken _cancelToken = CancelToken();

  @override
  void onRequest(options, handler) {

    print("请求地址: ${options.uri}");
    print("请求参数: ${options.data}");

    handler.next(options);
  }

  @override
  Future<void> onResponse(response, handler) async {

    print("响应数据: ${response.data}");
    final resultCode = response.data['resultCode'];
    if (resultCode == 1030102) {
      await _handleTokenExpired();
      return handler.reject(DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: 'Token已失效',
      ));
    }
    handler.next(response);
  }

  /// 统一处理 token 过期
  Future<void> _handleTokenExpired() async {
    if (_handlingTokenExpired) return; // 防止重复处理
    _handlingTokenExpired = true;

    // 取消所有请求
    if (!_cancelToken.isCancelled) {
      _cancelToken.cancel('Token过期，取消所有请求');
    }
    _cancelToken = CancelToken(); // 重置新 token

    final currentAccount = AccountManager().currentAccount;
    if (currentAccount != null) {
      final wallet = AccountManager().currentWallet;
      await AccountManager().deleteAccount(currentAccount.id);
      await AccountService.login(wallet!, currentAccount);
    }

    print('已处理 token 过期');
    _handlingTokenExpired = false;
  }
}