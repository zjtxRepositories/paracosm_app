
import 'package:paracosm/modules/im/manager/im_token_manager.dart';

import '../manager/im_engine_manager.dart';

class ImConfig {
  static const String appKey = 'x18ywvqfxiqlc';
}

class ImService {

  /// 登录 IM
  static Future<void> loginIm(String accountId) async {
    String last8 = accountId.length > 8 ? accountId.substring(accountId.length - 8) : accountId;
    final token = await ImTokenManager.getToken(userId: accountId, name: last8);
    if (token == null) return;
    // print('userid-----$userId---$token');
    await IMEngineManager().connect(token, accountId);
  }

  /// 切换账号
  static Future<void> switchAccount(String accountId) async {
    await IMEngineManager().disconnect();
    await loginIm(accountId);
  }

  /// 登出
  static Future<void> logout() async {
    await IMEngineManager().disconnect();
  }

  /// token失效刷新（自动重连）
  static Future<void> refreshToken() async {
    final accountId = IMEngineManager().currentAccountId;
    if (accountId == null) return;
    await IMEngineManager().disconnect();
    await ImTokenManager.clear(accountId);
    await loginIm(accountId);
  }

  /// 重新连接
  static Future<void> reconnect() async {
    final accountId = IMEngineManager().currentAccountId;
    if (accountId == null) return;
    await loginIm(accountId);
  }

}