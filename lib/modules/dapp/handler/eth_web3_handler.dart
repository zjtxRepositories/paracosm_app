import 'dart:typed_data';

import 'package:paracosm/modules/wallet/model/chain_account.dart';

/// ===== WebView handler =====
abstract class WebViewHandler {
  String get name;

  void handle(List<dynamic> arguments);
}

/// ===== Eth WebView handler =====
abstract class EthWebViewHandler extends WebViewHandler {
  final EthWeb3Handler web3handler;

  EthWebViewHandler(this.web3handler);

  Future<List<String>> injectScripts();

  void onChangeWallet();
}

/// ===== 标准事件 =====
class EthEvents {
  static const accountsChanged = 'accountsChanged';
  static const chainChanged = 'chainChanged';
  static const connect = 'connect';
  static const disconnect = 'disconnect';
}

/// ===== Eth Web3 handler（核心）=====
abstract class EthWeb3Handler {
  /// ===== 核心（EIP-1193）=====
  // Future<dynamic> request(String method, [List<dynamic>? params]);

  void emit(String event, dynamic data);

  /// ===== WebView =====
  Future<dynamic> evaluateJavascript(String source);

  /// ===== 基础 =====
  /// MUST return hex string, e.g. "0x1"
  ChainAccount get ethChain;

  String ethChainId();

  Future<String?> ethCoinbase([bool request = true]);

  Future<List<String>> ethAccounts([bool request = true]);

  Future<List<String>> ethRequestAccounts();

  Future<List<Map<String, dynamic>>> walletGetPermissions();

  Future<List<Map<String, dynamic>>> walletRequestPermissions([Map? data]);

  Future<String> ethBlockNumber();

  /// ===== 签名 =====
  Future<String> ethSign(String data);

  Future<String> personalSign(String data);

  Future<String> ethSignTypedData(String data);

  Future<String> ethSignTypedDataV3(String data);

  Future<String> ethSignTypedDataV4(String data);

  Future<String> ethSignTypedDataUint8List(Uint8List message, String data);

  Future<String> personalEcRecover(Map data);

  /// ===== 交易 =====
  Future<String> ethSendTransaction(Map data);

  Future<String> walletAddEthereumChain(Map data);

  Future<String> walletSwitchEthereumChain(Map data);

  Future<String> walletWatchAsset(Map data);

  /// ===== RPC =====
  Future<dynamic> rpcCall(String method, [List<dynamic>? params]);
}

class EthHandlerException implements Exception {
  final dynamic message;

  EthHandlerException(this.message);

  @override
  String toString() {
    return "$message";
  }
}
