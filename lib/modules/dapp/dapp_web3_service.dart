import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/wallet/model/chain_account.dart';
import 'package:paracosm/modules/wallet/model/token_model.dart';
import 'package:paracosm/modules/wallet/model/wallet_model.dart';
import 'package:paracosm/pages/dapp/dapp_modal_service.dart';
import 'package:paracosm/widgets/modals/dapp_modals.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

import '../../widgets/base/app_localizations.dart';
import '../wallet/chains/evm/client/evm_client_manager.dart';
import '../wallet/chains/evm/evm_facade.dart';
import '../wallet/manager/wallet_manager.dart';
import 'dapp_account_auth_hive.dart';
import 'handler/eth_web3_handler.dart';

class DAppWeb3Service implements EthWeb3Handler {
  final InAppWebViewController controller;
  WalletModel wallet;
  final BuildContext context;

  DAppWeb3Service(
      this.controller,this.wallet, {required this.context});

  // =========================================================
  // WebView
  // =========================================================
  @override
  Future evaluateJavascript(String source) {
    return controller.evaluateJavascript(source: source);
  }

  @override
  void emit(String event, data) {
    controller.evaluateJavascript(source: '''
      window.ethereum?.emit?.('$event', ${jsonEncode(data)});
    ''');
  }
  Future<String> get _favicon async {
    final favicons = await controller.getFavicons();
    return favicons.firstOrNull?.rel ?? '';
  }
  // =========================================================
  // sign message (兼容 MetaMask 参数顺序)
  // =========================================================
  Future<String> _signMessage(String data, bool personal) async {
    final uri = await controller.getUrl();
    final host = uri?.host ?? '';

    final address = ethChain.address;

    // 1. 授权检查
    if (!DAppAccountAuthHive.checkAuth(host)) {
      throw Exception('Unauthorized DApp');
    }

    // 2. UI确认
    final approved = await DAppModalService.showSign(
      context: context,
      message: data,
      address: address,
    ) ?? false;

    if (!approved) {
      throw Exception('User rejected signature');
    }

    // 3. 密码验证
    final passwordOk = await DAppModalService.showPassword(context: context);
    if (!passwordOk) {
      throw Exception('Password verification failed');
    }

    // 4. 执行签名
    final signature = await EvmFacade.signMessage(
      address,
      data,
      personal: personal,
    );

    return signature;
  }

  // =========================================================
  // sign message (兼容 MetaMask 参数顺序)
  // =========================================================
  Future<String> _signTypeData(String jsonData, TypedDataVersion version) async {
    final uri = await controller.getUrl();
    final host = uri?.host ?? '';

    final address = ethChain.address;

    // 1. 授权检查
    if (!DAppAccountAuthHive.checkAuth(host)) {
      throw Exception('Unauthorized DApp');
    }
    final decoded = jsonDecode(jsonData);
    final pretty = const JsonEncoder.withIndent('  ').convert(decoded);
    // 2. UI确认
    final approved = await DAppModalService.showSign(
      context: context,
      message: pretty,
      address: address,
    ) ?? false;

    if (!approved) {
      throw Exception('User rejected signature');
    }

    // 3. 密码验证
    final passwordOk = await DAppModalService.showPassword(context: context);
    if (!passwordOk) {
      throw Exception('Password verification failed');
    }

    // 4. 执行签名
    final signature = await EvmFacade.signTypedDataRaw(address, jsonData, version);

    return signature;
  }

  // =========================================================
  // send transaction
  // =========================================================
  Future<String> _sendTransaction(Map data) async {
    final chain = wallet.currentChain;

    if (chain == null) {
      throw Exception("Wallet not found");
    }

    final to = data['to'] ?? '';

    final value = data['value'] != null
        ? _parseHex(data['value'])
        : BigInt.zero;

    final dataHex = data['data'];
    final isContractCall = data['data'] != null;

    return await EvmFacade.send(
      chain: chain,
      to: to,
      amountWei: value,
      contractAddress: isContractCall ? to : null,
      customData: data['data'],
    );
  }

  String _formatEth(BigInt value) {
    return EtherAmount.inWei(value)
        .getValueInUnit(EtherUnit.ether)
        .toStringAsFixed(6);
  }

  BigInt _parseHex(String? value) {
    if (value == null || value.isEmpty) return BigInt.zero;
    if (!value.startsWith('0x')) return BigInt.parse(value);
    return hexToInt(value);
  }

  @override
  ChainAccount get ethChain => wallet.currentChain!;
  // =========================================================
  // wrapper APIs（全部走 dispatch）
  // =========================================================
  @override
  String ethChainId() {
    return '0x${BigInt.from(ethChain.chainId).toRadixString(16)}';
  }

  @override
  Future<List<String>> ethAccounts([bool request = true]) async {
    if (request) {
      return await ethRequestAccounts();
    }
    String host = (await controller.getUrl())!.host;
    if (DAppAccountAuthHive.checkAuth(host)) {
      return [ethChain.address.toLowerCase()];
    }
    return [];
  }

  @override
  Future<List<String>> ethRequestAccounts() async {
    final String faviconUrl = await _favicon;
    final uri = (await controller.getUrl())!;
    final title = (await controller.getTitle()) ?? '';
    final String host = uri.host;
    /// 已授权
    if (DAppAccountAuthHive.checkAuth(host)) {
      return [ethChain.address.toLowerCase()];
    }
    final result =
    await DAppModalService.showConnect(
        context: context,
        host: host,
        title: title,
        faviconUrl: faviconUrl,
        uri: uri.toString()) ?? false;
    if (!result){
      throw EthHandlerException("Request account rejected");
    }
    return [ethChain.address.toLowerCase()];
  }

  @override
  Future<String> ethCoinbase([bool request = true]) async {
    if (request) {
      return (await ethRequestAccounts()).first;
    }
    String host = (await controller.getUrl())!.host;
    if (DAppAccountAuthHive.checkAuth(host)) {
      return ethChain.address.toLowerCase();
    }
    return '';
  }

  @override
  Future<dynamic> rpcCall(String method, [List? params]) async {
    final chain = wallet.currentChain;

    return await EvmFacade.rpc(
      chain: chain!,
      method: method,
      params: params ?? [],
    );
  }

  // =========================================================
  // not yet implemented (可逐步扩展)
  // =========================================================

  @override
  Future<String> ethSign(String data) {
    return _signMessage(data, false);
  }

  @override
  Future<String> personalSign(String data){
    return _signMessage(data, true);
  }

  @override
  Future<String> ethSendTransaction(Map data) async {
    try {
      /// =========================
      /// 1. 基础信息
      /// =========================
      final faviconUrl = await _favicon;

      final uri = (await controller.getUrl())!;
      final origin = uri.host;

      final String from = data['from'];
      final String to = data['to'] ?? '';

      final BigInt value =
      data['value'] == null ? BigInt.zero : hexToInt(data['value']);

      final BigInt? gas =
      data['gas'] == null ? null : hexToInt(data['gas']);

      /// =========================
      /// 2. 权限校验（必须有）
      /// =========================
      final hasPermission =
      DAppAccountAuthHive.checkAuth(origin);

      if (!hasPermission) {
        throw Exception('Unauthorized DApp');
      }

      /// =========================
      /// 3. 金额格式化
      /// =========================
      final amount = _formatEth(value); // 👈 自己实现
      final logo = faviconUrl;

      /// =========================
      /// 4. 交易确认弹窗
      /// =========================
      final approved = await DAppModalService.showTransaction(
        context: context,
        amount: amount,
        logo: logo,
        from: from,
        to: to,
        gasLimit: gas
      ) ??
          false;

      if (!approved) {
        throw Exception('User rejected transaction');
      }

      /// =========================
      /// 5. 密码校验
      /// =========================
      final passwordOk =
      await DAppModalService.showPassword(context: context);

      if (!passwordOk) {
        throw Exception('Password verification failed');
      }

      /// =========================
      /// 6. 发送交易
      /// =========================
      final txHash = await _sendTransaction(data);

      return txHash;
    } catch (e) {
      print('ethSendTransaction error: $e');
      rethrow;
    }
  }

  @override
  Future<String> walletAddEthereumChain(Map data) async {
    try {
      // =========================
      // 基础解析（安全取值）
      // =========================
      final chainIdHex = data['chainId'];
      if (chainIdHex == null) {
        throw 'chainId missing';
      }

      final chainId = hexToDartInt(chainIdHex);
      final chainName = data['chainName'] ?? 'Unknown';

      final native = data['nativeCurrency'] ?? {};
      final symbol = native['symbol'] ?? 'ETH';
      final decimals = native['decimals'] ?? 18;
      final name = native['name'] ?? chainName;

      final rpcUrls = (data['rpcUrls'] as List?)
          ?.cast<String>()
          .where((e) => e.startsWith('http'))
          .toList() ??
          [];

      if (rpcUrls.isEmpty) {
        throw 'rpcUrls empty';
      }

      final blockExplorerUrls =
      (data['blockExplorerUrls'] as List?)?.cast<String>();

      final blockExplorerUrl =
      (blockExplorerUrls != null && blockExplorerUrls.isNotEmpty)
          ? blockExplorerUrls.first
          : null;

      final favicons = await controller.getFavicons();
      final faviconUrl = favicons.isNotEmpty ? favicons.first.url.toString() : '';

      final url = (await controller.getUrl())?.toString() ?? '';

      // =========================
      // ⚠️ 已存在检查
      // =========================
      if (wallet.hasChain(chainId)) {
        return '$chainName 已存在';
      }

      // =========================
      // ⚠️ 用户确认（关键）
      // =========================
      final approved = await DAppAddChainSheet.show(
        context,
        name: chainName,
        chainId: chainId,
        rpc: rpcUrls.first,
        symbol: symbol,
        origin: url,
      ) ?? false;

      if (!approved) {
        throw 'User rejected';
      }
      // =========================
      // 构建链
      // =========================
      final chain = ChainAccount(
        name: name,
        address: wallet.evmChain?.address ?? '',
        chainId: chainId,
        logo: faviconUrl,
        symbol: symbol,
        chainType: ChainType.evm,
        txApiUrl: blockExplorerUrl,
        nodes: rpcUrls,

        tokens: [
          TokenModel(
            symbol: symbol,
            name: name,
            address: '',
            balance: BigInt.zero,
            decimals: decimals,
            logo: faviconUrl,
            coinId: symbol.toLowerCase(),
            chainId: chainId,
          )
        ],
      );

      // =========================
      // 保存
      // =========================
      await WalletManager.addChain(wallet.id, chain);

      return '$chainName 已添加';
    } catch (e, s) {
      debugPrintStack(label: e.toString(), stackTrace: s);
      throw '链详情不完整';
    }
  }


  @override
  Future<String> walletWatchAsset(Map data) =>
      throw UnimplementedError();

  @override
  Future<String> walletSwitchEthereumChain(Map data) async {
    final chainId = hexToDartInt(data['chainId']);
     WalletManager.switchChain(wallet.id, chainId);
    wallet = AccountManager().currentWallet!;
    final l10n = AppLocalizations.of(context)!;
    final name = wallet.name ??
        '${l10n.profileProfileDetailsWallet} ${wallet.aIndex + 1}';
    return "$name 已切换";
  }

  @override
  Future<String> ethSignTypedData(String data) {
    return _signTypeData(data, TypedDataVersion.V1);
  }

  @override
  Future<String> ethSignTypedDataV3(String data) {
    return _signTypeData(data, TypedDataVersion.V3);
  }

  @override
  Future<String> ethSignTypedDataV4(String data) {
    return _signTypeData(data, TypedDataVersion.V4);
  }

  @override
  Future<String> ethSignTypedDataUint8List(
      Uint8List message, String data)=>
      throw UnimplementedError();

  @override
  Future<String> personalEcRecover(Map data) async {
    String? signature = data['signature'];
    String? message = data['message'];
    if (signature == null || message == null) {
      throw EthHandlerException("signature or message is missing");
    }
    try {
      return EthSigUtil.recoverPersonalSignature(
        signature: signature,
        message: hexToBytes(message),
      );
    } catch (e) {
      throw EthHandlerException(e.toString());
    }
  }

  @override
  Future<String> ethBlockNumber() async {
    final block = await EvmClientManager.withFallback(
      ethChain.chainId,
      ethChain.nodes,
          (client) => client.getBlockNumber(),
    );
    return '0x${block.toRadixString(16)}';
  }
}