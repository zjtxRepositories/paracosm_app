import 'dart:async';

import 'package:flutter/material.dart';

import '../../modules/wallet/security/wallet_security.dart';
import '../../widgets/base/app_localizations.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/modals/dapp_modals.dart';
import '../../widgets/modals/wallet_modals.dart';

class DAppModalService {
  static Future<bool?> showConnect({
    required BuildContext context,
    required String host,
    required String title,
    required String faviconUrl,
    required String uri,
  }) {
    return DappModals.showConnectSheet(
      context: context,
      host: host,
      title: title,
      faviconUrl: faviconUrl,
      uri: uri,
    );
  }

  static Future<bool?> showTransaction({
    required BuildContext context,
    required String amount,
    required String logo,
    required String from,
    required String to,
    BigInt? gasLimit
  }) {
    return DappModals.showTransactionDetail(
      context,
      amount: amount,
      logo: logo,
      from: from,
      to: to,
    );
  }

  static Future<bool?> showSign({
    required BuildContext context,
    required String message,
    required String address,
  }) {
    return DappModals.showSignInfoModal(
      context,
      message: message,
      address: address,
    );
  }

  static Future<bool?> showAddChain({
    required BuildContext context,
    required String name,
    required int chainId,
    required String rpc,
    required String symbol,
    required String origin,
  }) {
    return DAppAddChainSheet.show(
      context,
      name: name,
      chainId: chainId,
      rpc: rpc,
      symbol: symbol,
      origin: origin,
    );
  }


  static Future<bool> showPassword({
    required BuildContext context,
  }) {
    final completer = Completer<bool>();

    WalletModals.showPasswordModal(
      context: context,
      title: AppLocalizations.of(context)!.profileTransferPassword,
      onConfirm: (password) async {
        final isResult = await WalletSecurity.verifyPassword(password);

        if (!isResult) {
          AppToast.show('密码错误！');
          return;
        }

        if (!completer.isCompleted) {
          completer.complete(true);
        }
      },
    );

    return completer.future;
  }
}