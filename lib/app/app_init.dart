import 'package:paracosm/core/network/config/config_service.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/core/util/hive_utils.dart';

import '../modules/wallet/security/wallet_security.dart';


class AppInit {

  static Future<void> init() async {
    await ConfigService().init();
    await WalletSecurity().init();
    await AccountManager().init();
    HiveUtils.initHive();
    // await ImInit().init();
  }


}