import 'dart:async';

import 'package:flutter/material.dart';

import '../../modules/wallet/chains/model/gas_fee.dart';
import '../../modules/wallet/security/wallet_security.dart';
import 'dapp_models.dart';
import '../../widgets/base/app_localizations.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/modals/dapp_modals.dart';
import '../../widgets/modals/wallet_modals.dart';

class DAppModalService {
  static Future<DAppConnectDecision?> showConnect({
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

  static Future<DappTransactionDecision?> showTransaction({
    required BuildContext context,
    required String amount,
    required String logo,
    required String from,
    required String to,
    required GasLevel gasLevel,
    required String feeSymbol,
    String? walletLabel,
    String? feeDescription,
    BigInt? gasLimit,
    bool isContractCall = false,
    String? transactionType,
    String? approvalAmount,
    String? approvalSpender,
    String? data,
  }) {
    return DappModals.showTransactionDetail(
      context,
      amount: amount,
      logo: logo,
      from: from,
      to: to,
      gasLevel: gasLevel,
      feeSymbol: feeSymbol,
      walletLabel: walletLabel,
      feeDescription: feeDescription,
      gasLimit: gasLimit,
      isContractCall: isContractCall,
      transactionType: transactionType,
      approvalAmount: approvalAmount,
      approvalSpender: approvalSpender,
      data: data,
    );
  }

  static Future<bool?> showSign({
    required BuildContext context,
    required String message,
    required String address,
    required String host,
    required String faviconUrl,
    String? walletLabel,
  }) {
    return DappModals.showSignInfoModal(
      context,
      message: message,
      address: address,
      host: host,
      faviconUrl: faviconUrl,
      walletLabel: walletLabel,
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

  static Future<bool?> showWatchAsset({
    required BuildContext context,
    required String host,
    required String address,
    required String symbol,
    required int decimals,
    required String image,
    required String chainName,
  }) {
    return DappModals.showWatchAssetSheet(
      context,
      host: host,
      address: address,
      symbol: symbol,
      decimals: decimals,
      image: image,
      chainName: chainName,
    );
  }

  static Future<bool> showPassword({required BuildContext context}) async {
    final completer = Completer<bool>();

    await WalletModals.showPasswordModal(
      context: context,
      title: AppLocalizations.of(context)!.profileTransferPassword,
      onValidate: (password) async {
        final isResult = await WalletSecurity.verifyPassword(password);

        if (!isResult) {
          AppToast.show('密码错误！');
          return false;
        }

        return true;
      },
      onConfirm: (_) async {
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      },
      onCancel: () {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );

    if (!completer.isCompleted) {
      completer.complete(false);
    }

    return completer.future;
  }
}
