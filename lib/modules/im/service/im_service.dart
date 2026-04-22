
import 'package:paracosm/modules/im/manager/im_token_manager.dart';

import '../manager/im_engine_manager.dart';

class ImConfig {
  static const String appKey = 'x18ywvqfxiqlc';
}

class ImService {

  /// 登录 IM
  static Future<void> loginIm(String userId) async {
    // final token = await ImTokenManager.getToken(userId: userId, name: userId);
    // if (token == null) return;
    await IMEngineManager().connect('Vqg1ngi7A5lizGd+lE6h294va9Em3oHNv+QLhpS6VPCAtls/lcE8yN3yIN0zSzBiZol1x+GbK2fTqMmzw4uu3Q==@qgvv.sg.rongnav.com;qgvv.sg.rongcfg.com', userId);
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