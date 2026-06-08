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
  String? _switchingAccountId;
  Future<void>? _switchAccountFuture;
  int _switchVersion = 0;

  bool get isLogin => _currentAccount != null;
  String get currentUserId => _currentAccount?.id ?? '';
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
    if (_currentAccount?.id == accountId) return;

    final switchingFuture = _switchAccountFuture;
    if (_switchingAccountId == accountId && switchingFuture != null) {
      return switchingFuture;
    }

    final future = _switchAccount(accountId, ++_switchVersion);
    _switchingAccountId = accountId;
    _switchAccountFuture = future;

    try {
      await future;
    } finally {
      if (_switchAccountFuture == future) {
        _switchingAccountId = null;
        _switchAccountFuture = null;
      }
    }
  }

  Future<void> _switchAccount(String accountId, int switchVersion) async {
    final result = await Future.wait<Object?>([
      AccountDao().getAccountById(accountId),
      WalletDao().getWalletById(accountId),
    ]);
    final account = result[0] as AccountModel?;
    if (account == null) return;
    final wallet = result[1] as WalletModel?;

    _currentAccount = account;
    _currentWallet = wallet;

    await AppConfigDao().setCurrentUser(accountId);
    notifyListeners();

    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        return _finishSwitchAccount(account, switchVersion);
      }),
    );
  }

  Future<void> _finishSwitchAccount(
    AccountModel account,
    int switchVersion,
  ) async {
    try {
      await WalletManager.unlock(walletId: account.id);
      if (_switchVersion != switchVersion ||
          _currentAccount?.id != account.id) {
        return;
      }

      _currentWallet = await WalletDao().getWalletById(account.id);
      if (_switchVersion != switchVersion ||
          _currentAccount?.id != account.id) {
        return;
      }

      await ImService.switchAccount(account.accountId);
      if (_switchVersion != switchVersion ||
          _currentAccount?.id != account.id) {
        return;
      }

      notifyListeners();
    } catch (error) {
      debugPrint('Finish switch account failed: $error');
    }
  }

  /// =========================
  /// 刷新钱包
  /// =========================
  Future<void> refreshWallet({
    bool isNotify = true,
    WalletModel? wallet,
  }) async {
    final accountId = _currentAccount?.id;
    if (accountId == null) return;

    if (wallet != null) {
      if (wallet.id != accountId) return;
      _currentWallet = wallet;
    } else {
      _currentWallet = await WalletDao().getWalletById(accountId);
    }

    if (!isNotify) return;
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

        _currentWallet = await WalletDao().getWalletById(_currentAccount!.id);

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
  Future<void> updateAccountUserInfo(String nickname, String avatar) async {
    if (_currentAccount == null) return;

    _currentAccount!.nickname = nickname;
    _currentAccount!.avatar = avatar;

    await AccountDao().updateAccount(_currentAccount!);
    notifyListeners();
  }
}
