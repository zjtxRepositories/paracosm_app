import 'package:paracosm/core/db/dao/account_dao.dart';
import 'package:paracosm/modules/wallet/manager/wallet_manager.dart';
import 'package:paracosm/modules/wallet/model/wallet_model.dart';
import '../../../core/db/dao/app_config_dao.dart';
import '../../../core/db/dao/wallet_dao.dart';
import '../../im/service/im_service.dart';
import '../../user/service/user_service.dart';
import '../manager/account_manager.dart';
import '../model/account_model.dart';

class AccountService {

  /// 导入钱包 + 登录 + 创建账号
  static Future<AccountModel> creating(
      {String? mnemonic,String? privateKey,required String password}) async {

    /// 1 生成钱包
    final wallet = await WalletManager.createWallet(mnemonic: mnemonic,password: password);

    /// 2 登录
    return await login(wallet);
  }

  static Future<AccountModel> login(WalletModel wallet) async {
    final loginResp = await UserService.login(wallet.id.toLowerCase());
    final account =
    await AccountManager().createAccount(
      wallet: wallet,
      user: loginResp,
    );
    return account;
  }


  static Future _save(WalletModel wallet, AccountModel account) async {
    await AppConfigDao().setCurrentUser(wallet.id);
    await AccountDao().insertAccount(account);
    await WalletDao().insertWallet(wallet);
    await ImService.switchAccount(account.accountId);
  }

  static Future<void> loginOut(String id) async {
    await AccountManager().deleteAccount(id);
  }

}