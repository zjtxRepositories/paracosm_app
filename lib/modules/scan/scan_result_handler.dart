import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/core/models/dApp_hive.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/pages/profile/transfer_scan_address.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/common/app_toast.dart';

import 'scan_result_parser.dart';

/// 支持的二维码格式：
/// 1. 网页：`https://example.com`、`http://example.com`、`example.com/path`
/// 2. 好友 JSON：`{"type":"friend","userId":"user_123"}`
/// 3. 好友 URI：`paracosm://friend?userId=user_123`
/// 4. 支付 JSON：`{"type":"payment","address":"0xabc","amount":"1.5","token":"BNB","chain":"bsc"}`
/// 5. 链支付 URI：`bitcoin:bc1...?amount=0.01`、`ethereum:0x...?amount=1`
class ScanResultHandler {
  ScanResultHandler._();

  /// 打开扫码页，并把返回内容交给统一分发逻辑。
  static Future<void> scanAndHandle(BuildContext context) async {
    final result = await context.push<String>('/qr-scan');
    if (!context.mounted || result == null || result.trim().isEmpty) {
      return;
    }

    handle(context, result);
  }

  /// 解析二维码内容，并按类型路由到对应业务。
  static void handle(BuildContext context, String raw) {
    final result = ScanResultParser.parse(raw);
    switch (result.type) {
      case ScanResultType.webUrl:
        _handleWebUrl(context, result);
        break;
      case ScanResultType.friend:
        _handleFriend(context, result);
        break;
      case ScanResultType.walletPayment:
        _handleWalletPayment(context, result);
        break;
      case ScanResultType.unknown:
        AppToast.show(
          AppLocalizations.of(context)?.discoverScanUnsupported ??
              AppLocalizations.currentText('discover_scan_unsupported'),
        );
        break;
    }
  }

  /// 网页 / DApp 链接。
  static void _handleWebUrl(BuildContext context, ScanResult result) {
    final url = result.url;
    if (url == null || url.isEmpty) {
      AppToast.show(AppLocalizations.of(context)!.scanWebQrInvalid);
      return;
    }

    context.push(
      '/dapp',
      extra: DAppHive(name: Uri.parse(url).host, url: url),
    );
  }

  /// 好友二维码。
  static void _handleFriend(BuildContext context, ScanResult result) {
    final userId = result.userId;
    if (userId == null || userId.isEmpty) {
      AppToast.show(AppLocalizations.of(context)!.scanFriendQrInvalid);
      return;
    }

    context.push('/user-profile', extra: userId);
  }

  /// 钱包支付二维码。
  static void _handleWalletPayment(BuildContext context, ScanResult result) {
    final address = result.address?.trim();
    if (address == null || address.isEmpty) {
      AppToast.show(
        AppLocalizations.of(context)?.discoverScanUnsupported ??
            AppLocalizations.currentText('discover_scan_unsupported'),
      );
      return;
    }

    final wallet = AccountManager().currentWallet;
    if (wallet == null) {
      AppToast.show(
        AppLocalizations.of(context)?.discoverScanUnsupported ??
            AppLocalizations.currentText('discover_scan_unsupported'),
      );
      return;
    }

    final prefill = TransferScanPrefill(
      address: address,
      amount: result.amount,
      tokenSymbol: result.tokenSymbol,
      chain: result.chain,
    );
    final match = matchTransferScanAsset(wallet, prefill);

    context.push(
      '/transfer',
      extra: {
        'token': match.token,
        'chain': match.chain,
        'prefillAddress': prefill.address,
        'prefillAmount': prefill.amount,
      },
    );
  }
}
