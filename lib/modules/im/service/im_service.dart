
import '../manager/im_engine_manager.dart';

class ImService {

  /// 登录 IM
  static Future<void> loginIm(String userId) async {

    await IMEngineManager().connect("token", userId);
  }
  /// 切换账号
  static Future<void> switchAccount(String userId) async {
    await IMEngineManager().disconnect();
    await loginIm(userId);
  }

  /// 登出
  static Future<void> logout() async {
    await IMEngineManager().disconnect();
  }

}