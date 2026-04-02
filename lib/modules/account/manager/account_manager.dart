import 'package:paracosm/core/db/dao/account_dao.dart';
import 'package:paracosm/core/db/dao/wallet_dao.dart';
import 'package:paracosm/modules/account/service/account_service.dart';
import 'package:paracosm/modules/wallet/manager/wallet_manager.dart';
import '../../../core/db/dao/app_config_dao.dart';
import '../../im/service/im_service.dart';
import '../../user/model/user_info.dart';
import '../../wallet/model/wallet_model.dart';
import '../../wallet/security/wallet_security.dart';
import '../model/account_model.dart';

class AccountManager {

  static final AccountManager _instance =
  AccountManager._();

  factory AccountManager() => _instance;

  AccountManager._();

  List<AccountModel> accounts = [];

  AccountModel? _currentAccount;
  WalletModel? _currentWallet;

  /// 是否已登录
  bool get isLogin => currentAccount != null;
  AccountModel? get currentAccount => _currentAccount;
  WalletModel? get currentWallet => _currentWallet;

  Future<void> init() async {

    final accountId = await AppConfigDao().getCurrentUser();

    if (accountId != null) {
      final account = await AccountDao().getAccountById(accountId);
      _currentAccount = account;
      _currentWallet = await WalletDao().getWalletById(accountId);
      accounts = await AccountDao().getAccounts();
      WalletManager.unlock(walletId: accountId);
    }
  }

  /// 创建钱包 + 绑定用户信息
  Future<AccountModel> createAccount({
    required WalletModel wallet,
    required UserInfo user,
  }) async {
    final account = AccountModel(
      id: wallet.id,
      userId: user.userId,
      avatar: user.avatar,
      nickname:user.nickname,
      token: user.token,
    );

    accounts.add(account);
    _currentWallet = wallet;
    _currentAccount = account;
    return account;

  }


  /// 切换账号
  Future<void> switchAccount(String accountId) async {
    _currentAccount =
        accounts.firstWhere((e) => e.id.toLowerCase() == accountId.toLowerCase());
    if (_currentAccount != null){
      await AppConfigDao().setCurrentUser(accountId);
      _currentWallet = await WalletDao().getWalletById(accountId);
      await ImService.switchAccount(_currentAccount!.id);
    }
  }

}