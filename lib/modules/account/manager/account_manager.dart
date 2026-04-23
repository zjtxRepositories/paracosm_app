import 'package:flutter/foundation.dart';
import 'package:paracosm/core/db/dao/account_dao.dart';
import 'package:paracosm/core/db/dao/wallet_dao.dart';
import 'package:paracosm/modules/wallet/manager/wallet_manager.dart';
import '../../../core/db/dao/app_config_dao.dart';
import '../../im/service/im_service.dart';
import '../../user/model/user_info.dart';
import '../../wallet/model/wallet_model.dart';
import '../model/account_model.dart';

class AccountManager extends ChangeNotifier {

  static final AccountManager _instance = AccountManager._();
  factory AccountManager() => _instance;
  AccountManager._();

  List<AccountModel> accounts = [];

  AccountModel? _currentAccount;
  WalletModel? _currentWallet;

  /// 是否已登录
  bool get isLogin => currentAccount != null;
  AccountModel? get currentAccount => _currentAccount;
  WalletModel? get currentWallet => _currentWallet;

  /// 初始化账号
  Future<void> init() async {
    final accountId = await AppConfigDao().getCurrentUser();

    if (accountId != null) {
      final account = await AccountDao().getAccountById(accountId);
      _currentAccount = account;
      _currentWallet = await WalletDao().getWalletById(accountId);
      accounts = await AccountDao().getAccounts();
      WalletManager.unlock(walletId: accountId);
      notifyListeners(); // ⚡初始化完成通知页面刷新
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
      nickname: user.nickname,
      token: user.token,
    );

    accounts.add(account);
    _currentWallet = wallet;
    _currentAccount = account;

    // // 保存到本地数据库
    // await AccountDao().insertAccount(account);
    // await WalletDao().insertWallet(wallet);
    // await AppConfigDao().setCurrentUser(account.id);

    // 🔔通知全局监听者：新增账号
    notifyListeners();

    return account;
  }

  /// 切换账号
  Future<void> switchAccount(String accountId) async {
    _currentAccount = accounts.firstWhere(
          (e) => e.id.toLowerCase() == accountId.toLowerCase(),
      orElse: () => accounts.first,
    );

    if (_currentAccount != null) {
      await AppConfigDao().setCurrentUser(accountId);
      _currentWallet = await WalletDao().getWalletById(accountId);
      await ImService.switchAccount(_currentAccount!.accountId);
      WalletManager.unlock(walletId: accountId);

      // 🔔通知全局监听者：切换账号
      notifyListeners();
    }
  }

  /// 刷新
  Future<void> refreshWallet() async {
    final accountId = await AppConfigDao().getCurrentUser();
    if (accountId != null) {
      _currentWallet = await WalletDao().getWalletById(accountId);
      notifyListeners();
    }
  }

  /// 删除账号
  Future<void> deleteAccount(String accountId) async {
    await AccountDao().deleteAccount(accountId);
    await WalletDao().deleteWallet(accountId);
    accounts = await AccountDao().getAccounts();

    _currentAccount = accounts.isNotEmpty ? accounts.first : null;
    await AppConfigDao().setCurrentUser(_currentAccount?.id ?? '');
    _currentWallet = _currentAccount != null
        ? await WalletDao().getWalletById(_currentAccount!.id)
        : null;

    // 🔔通知全局监听者：删除账号
    notifyListeners();
  }

  /// 更新用户信息
  Future<void> updateAccountUserInfo(String nickname,String avatar) async {
    if (_currentAccount == null) return;
    _currentAccount?.nickname = nickname;
    _currentAccount?.avatar = avatar;
    AccountDao().updateAccount(_currentAccount!);
    notifyListeners();
  }
}