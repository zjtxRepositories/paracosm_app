import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:paracosm/modules/wallet/model/chain_account.dart';
import 'package:paracosm/modules/wallet/model/wallet_model.dart';
import 'package:paracosm/widgets/modals/dapp_modals.dart';
import 'package:path/path.dart';
import 'package:web3dart/crypto.dart';

import '../wallet/chains/evm/client/evm_client_manager.dart';
import '../wallet/chains/evm/evm_facade.dart';
import '../wallet/manager/wallet_manager.dart';
import 'dapp_account_auth_hive.dart';
import 'handler/eth_web3_handler.dart';

class DAppWeb3Service implements EthWeb3Handler {
  final InAppWebViewController controller;
  final WalletModel wallet;
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

  // =========================================================
  // EIP-1193 entry
  // =========================================================
  @override
  Future<dynamic> request(String method, [List<dynamic>? params]) {
    print('ddd------');
    return _dispatch(method, params ?? []);
  }

  // =========================================================
  // core dispatcher（唯一业务入口）
  // =========================================================
  Future<dynamic> _dispatch(String method, List<dynamic> params) async {
    final chain = wallet.currentChain;

    if (chain == null) {
      throw Exception("Wallet not found");
    }

    switch (method) {

    // =========================
    // accounts
    // =========================
      case 'eth_requestAccounts':
      case 'eth_accounts':
        return [chain.address.toLowerCase()];

      case 'eth_coinbase':
        return chain.address.toLowerCase();

    // =========================
    // chain
    // =========================
      case 'eth_chainId':
        return '0x${chain.chainId.toRadixString(16)}';

      case 'net_version':
        return chain.chainId.toString();

    // =========================
    // block
    // =========================
      case 'eth_blockNumber':
        final block = await EvmClientManager.withFallback(
          chain.chainId,
          chain.nodes,
              (client) => client.getBlockNumber(),
        );
        return '0x${block.toRadixString(16)}';

    // =========================
    // balance
    // =========================
      case 'eth_getBalance':
        final address = params.isNotEmpty ? params[0] : chain.address;

        final balance = await EvmFacade.getBalance(chain, address);

        return '0x${balance.toRadixString(16)}';

    // =========================
    // tx
    // =========================
      case 'eth_sendTransaction':
        return _sendTransaction(params.isNotEmpty ? params[0] : {});

      case 'eth_sendRawTransaction':
        return await EvmClientManager.withFallback(
          chain.chainId,
          chain.nodes,
              (client) => client.sendRawTransaction(params[0]),
        );

    // =========================
    // call / gas
    // =========================
      case 'eth_call':
      case 'eth_estimateGas':
      case 'eth_gasPrice':
        return await EvmFacade.rpc(
          chain: chain,
          method: method,
          params: params,
        );

    // =========================
    // sign
    // =========================
      case 'personal_sign':
      case 'eth_sign':
        return _signMessage(params);

    // =========================
    // typed data
    // =========================
      case 'eth_signTypedData':
      case 'eth_signTypedData_v3':
      case 'eth_signTypedData_v4':
        return _signTypedData(params);

    // =========================
    // switch chain
    // =========================
      case 'wallet_switchEthereumChain':
        final chainIdHex = params[0]['chainId'];
        final chainId =
        int.parse(chainIdHex.substring(2), radix: 16);

        await WalletManager.switchChain(wallet.id, chainId);

        return chainIdHex;

    // =========================
    // add chain
    // =========================
      case 'wallet_addEthereumChain':
        return null;

    // =========================
    // fallback RPC
    // =========================
      default:
        return await EvmFacade.rpc(
          chain: chain,
          method: method,
          params: params,
        );
    }
  }

  // =========================================================
  // sign message (兼容 MetaMask 参数顺序)
  // =========================================================
  Future<String> _signMessage(List<dynamic> params) async {
    if (params.length < 2) {
      throw Exception("Invalid personal_sign params");
    }

    final a = params[0];
    final b = params[1];

    final address = (a is String && a.startsWith('0x'))
        ? a
        : b;

    final message = address == a ? b : a;

    return await EvmFacade.signMessage(address, message);
  }

  // =========================================================
  // typed data (v1/v3/v4 兼容)
  // =========================================================
  Future<String> _signTypedData(List<dynamic> params) async {
    if (params.length < 2) {
      throw Exception("Invalid typed data params");
    }

    final p0 = params[0];
    final p1 = params[1];

    final address =
    (p0 is String && p0.startsWith('0x')) ? p0 : p1;

    final typedData =
    address == p0 ? p1 : p0;

    final data = jsonDecode(typedData);

    return await EvmFacade.signTypedData(
      address,
      data,
    );
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
        ? BigInt.parse(data['value'].substring(2), radix: 16)
        : BigInt.zero;

    final dataHex = data['data'];

    return await EvmFacade.send(
      chain: chain,
      to: to,
      amountWei: value,
      contractAddress: dataHex != null ? to : "",
      customData: dataHex,
    );
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
    print('ethAccounts-------$request');
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
    final favicons = await controller.getFavicons();
    final String faviconUrl = favicons.first.rel ?? '';
    final uri = (await controller.getUrl())!;
    final title = (await controller.getTitle()) ?? '';
    final String host = uri.host;
    print('dddda-------112--$host');
    /// 已授权
    if (DAppAccountAuthHive.checkAuth(host)) {
      return [ethChain.address.toLowerCase()];
    }
    print('checkAuth-------${ethChain.address}---11');

    final completer = Completer<List<String>>();
    DappModals.showConnectSheet(
      context: context,
      host: host,
      title: title,
      faviconUrl: faviconUrl,
      uri: uri.toString(),

      onApprove: () {
        completer.complete([ethChain.address.toLowerCase()]);
      },

      onReject: () {
        completer.completeError(
          EthHandlerException("Request account rejected"),
        );
      },
    );
    return completer.future;
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
  Future<String> ethSign(String data) =>
      throw UnimplementedError();

  @override
  Future<String> personalSign(String data) =>
      throw UnimplementedError();

  @override
  Future<String> ethSendTransaction(Map data) async {
    final favicons = await controller.getFavicons();
    final String faviconUrl = favicons.first.rel ?? '';
    final uri = (await controller.getUrl())!;
    final String from = data['from'];
    final String? to = data['to'];
    final BigInt value = data['value'] == null
    ? BigInt.zero
        : hexToInt(data['value']);
    final BigInt? gas = data['gas'] == null ? null : hexToInt(data['gas']);
    print('data---------$data');
    return '';
    // DappModals.showTransactionDetail
    //   (context,
    //     amount: amount,
    //     logo: logo,
    //     absenteeism: absenteeism,
    //     max: ,
    //     from: from,
    //     to: to ?? '',
    //     detailUrl: '',
    //     onConfirm: (){
    //
    //     },
    //    );
    // return  _sendTransaction(data);
  }

  @override
  Future<String> walletAddEthereumChain(Map data) =>
      throw UnimplementedError();

  @override
  Future<String> walletWatchAsset(Map data) =>
      throw UnimplementedError();

  @override
  Future<String> walletSwitchEthereumChain(Map data) =>
      throw UnimplementedError();

  @override
  Future<String> ethSignTypedData(String data) =>
      throw UnimplementedError();

  @override
  Future<String> ethSignTypedDataV3(String data) =>
      throw UnimplementedError();

  @override
  Future<String> ethSignTypedDataV4(String data) =>
      throw UnimplementedError();

  @override
  Future<String> ethSignTypedDataUint8List(
      Uint8List message, String data) =>
      throw UnimplementedError();

  @override
  Future<String> personalEcRecover(Map data) =>
      throw UnimplementedError();

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