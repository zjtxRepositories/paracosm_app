import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../../../core/db/dao/account_dao.dart';
import '../../../core/db/dao/app_config_dao.dart';
import '../../../core/db/dao/wallet_dao.dart';
import '../../im/service/im_service.dart';
import '../../user/model/user_info.dart';
import '../../wallet/manager/wallet_manager.dart';
import '../../wallet/model/wallet_model.dart';
import '../model/account_model.dart';

class AccountManager extends ChangeNotifier {
  static final AccountManager _instance = AccountManager._();
  factory AccountManager() => _instance;
  AccountManager._();

  List<AccountModel> accounts = [];

  AccountModel? _currentAccount;
  WalletModel? _currentWallet;

  bool get isLogin => _currentAccount != null;
  AccountModel? get currentAccount => _currentAccount;
  WalletModel? get currentWallet => _currentWallet;

  /// =========================
  /// 初始化
  /// =========================
  Future<void> init() async {
    final accountId = await AppConfigDao().getCurrentUser();
    if (accountId != null && accountId.isNotEmpty) {
      final account = await AccountDao().getAccountById(accountId);

      if (account != null) {
        _currentAccount = account;
        _currentWallet = await WalletDao().getWalletById(accountId);
        await WalletManager.unlock(walletId: accountId);
        accounts = await AccountDao().getAccounts();
      }
    }

    notifyListeners();
  }

  /// =========================
  /// 创建账号
  /// =========================
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

    await AccountDao().insertAccount(account);
    await WalletDao().insertWallet(wallet);

    accounts = await AccountDao().getAccounts();

    _currentAccount = account;
    _currentWallet = wallet;

    await AppConfigDao().setCurrentUser(account.id);

    await ImService.loginIm(account.accountId);

    notifyListeners();

    return account;
  }

  /// =========================
  /// 切换账号
  /// =========================
  Future<void> switchAccount(String accountId) async {
    final account = await AccountDao().getAccountById(accountId);
    if (account == null) return;

    _currentAccount = account;
    _currentWallet = await WalletDao().getWalletById(accountId);

    await AppConfigDao().setCurrentUser(accountId);

    await WalletManager.unlock(walletId: accountId);

    await ImService.switchAccount(account.accountId);

    notifyListeners();
  }

  /// =========================
  /// 刷新钱包
  /// =========================
  Future<void> refreshWallet() async {
    final accountId = _currentAccount?.id;
    if (accountId == null) return;

    _currentWallet = await WalletDao().getWalletById(accountId);

    notifyListeners();
  }

  /// =========================
  /// 删除账号
  /// =========================
  Future<void> deleteAccount(String id) async {
    final isCurrent = _currentAccount?.id == id;

    await AccountDao().deleteAccount(id);
    await WalletDao().deleteWallet(id);

    accounts = await AccountDao().getAccounts();

    if (isCurrent) {
      await ImService.logout();

      _currentAccount = accounts.isNotEmpty ? accounts.first : null;

      if (_currentAccount != null) {
        await AppConfigDao().setCurrentUser(_currentAccount!.id);

        _currentWallet =
        await WalletDao().getWalletById(_currentAccount!.id);

        await ImService.loginIm(_currentAccount!.accountId);
      } else {
        _currentWallet = null;
        await AppConfigDao().setCurrentUser('');
      }
    }

    notifyListeners();
  }

  /// =========================
  /// 更新用户信息
  /// =========================
  Future<void> updateAccountUserInfo(
      String nickname, String avatar) async {
    if (_currentAccount == null) return;

    _currentAccount!.nickname = nickname;
    _currentAccount!.avatar = avatar;

    await AccountDao().updateAccount(_currentAccount!);
    notifyListeners();
  }
}