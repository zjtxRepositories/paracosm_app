import 'package:paracosm/modules/account/manager/account_manager.dart';
import '../manager/im_engine_manager.dart';
import '../service/im_service.dart';

class ImInit {

  Future<void> init() async {

    /// 1. 初始化 SDK
    await IMEngineManager().init();

    /// 2 初始化监听
    IMEngineManager().connection.initListener();
    IMEngineManager().message.initListener();
    IMEngineManager().friend.initListener();
    IMEngineManager().friendApplication.initListener();
    IMEngineManager().user.initListener();


    /// 3. 自动登录
    final account = AccountManager().currentAccount;

    if (account != null) {
      await ImService.loginIm(account.id.toLowerCase());
    }
  }
}