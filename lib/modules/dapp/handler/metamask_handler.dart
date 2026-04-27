import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../throttle.dart';
import 'eth_web3_handler.dart';

class MetaMaskHandler extends EthWebViewHandler {
  MetaMaskHandler(super.web3handler);

  @override
  String get name => 'metamask';

  @override
  Future<List<String>> injectScripts() async {
    return [
      await rootBundle.loadString('assets/javascript/metamask/metamask.js'),
    ];
  }

  @override
  void handle(List<dynamic> arguments) {
    final args = jsonDecode(arguments.first);

    if (args['name'] != 'metamask-provider') return;

    final data = args['data'];
    final String origin = args['origin'];

    final int id = data['id'];
    final String method = data['method'];
    final List<dynamic>? params = data['params'];

    /// 🔥 优先走标准 request（核心）
    _handleRequest(id, origin, method, params);
  }

  /// ===== 核心分发 =====
  void _handleRequest(
    int id,
    String origin,
    String method,
    List<dynamic>? params,
  ) async {
    /// ===== fallback（兼容旧实现）=====
    switch (method) {
      case 'metamask_getProviderState':
        _handleProviderState(id, origin);
        break;

      case 'eth_chainId':
        handleMethod(id, origin, web3handler.ethChainId);
        break;

      case 'eth_coinbase':
        handleMethod(id, origin, () => web3handler.ethCoinbase(false));
        break;

      case 'eth_accounts':
        handleMethod(id, origin, () => web3handler.ethAccounts(false));
        break;

      case 'eth_requestAccounts':
        handleMethod(id, origin, web3handler.ethRequestAccounts);
        break;
      case 'wallet_getPermissions':
        handleMethod(id, origin, web3handler.walletGetPermissions);
        break;
      case 'wallet_requestPermissions':
        handleMethod(
          id,
          origin,
          () => web3handler.walletRequestPermissions(params?.first),
        );
        break;

      case 'eth_blockNumber':
        handleMethod(id, origin, web3handler.ethBlockNumber);
        break;

      case 'wallet_addEthereumChain':
        handleMethod(
          id,
          origin,
          () => web3handler.walletAddEthereumChain(params!.first),
        );
        break;
      case 'wallet_switchEthereumChain':
        handleMethod(
          id,
          origin,
          () => web3handler.walletSwitchEthereumChain(params!.first),
        );
        break;
      case 'net_version':
        handleMethod(id, origin, () => web3handler.ethChain.chainId);
        break;
      case 'eth_sign':
        Throttle.throttle(
          tag: 'dAppEthSign',
          func: () => handleMethod(
            id,
            origin,
            () => web3handler.ethSign(params!.first),
          ),
        );
        break;
      case 'personal_sign':
        Throttle.throttle(
          tag: 'dAppPersonalSign',
          func: () => handleMethod(
            id,
            origin,
            () => web3handler.personalSign(params!.first),
          ),
        );
        break;
      case 'eth_signTypedData':
        Throttle.throttle(
          tag: 'dAppSignTypedData',
          func: () => handleMethod(
            id,
            origin,
            () => web3handler.ethSignTypedData(params![1]),
          ),
        );
        break;
      case 'eth_signTypedData_v3':
        Throttle.throttle(
          tag: 'dAppSignTypedDataV3',
          func: () => handleMethod(
            id,
            origin,
            () => web3handler.ethSignTypedDataV3(params![1]),
          ),
        );
        break;
      case 'eth_signTypedData_v4':
        Throttle.throttle(
          tag: 'dAppSignTypedDataV4',
          func: () => handleMethod(
            id,
            origin,
            () => web3handler.ethSignTypedDataV4(params![1]),
          ),
        );
        break;
      case 'eth_sendTransaction':
        Throttle.throttle(
          tag: 'dAppSendTransaction',
          func: () => handleMethod(
            id,
            origin,
            () => web3handler.ethSendTransaction(params!.first),
          ),
        );
        break;
      case 'metamask_logWeb3ShimUsage':
        handleMethod(id, origin, () => null);
        break;
      case 'wallet_watchAsset':
        Throttle.throttle(
          tag: 'dAppWatchAsset',
          func: () => handleMethod(
            id,
            origin,
            () => web3handler.walletWatchAsset(params!.first),
          ),
        );
        break;
      case 'eth_call':
      case 'eth_estimateGas':
      case 'eth_getTransactionReceipt':
      case 'eth_getBalance':
      case 'eth_gasPrice':
      case 'eth_getTransactionByHash':
      case 'eth_getCode':
      case 'eth_getBlockByNumber':
        handleMethod(id, origin, () => web3handler.rpcCall(method, params));
        break;
      default:
        sendError(id, 'provider ($method) is not ready', origin);
        break;
    }
  }

  /// ===== Provider状态 =====
  void _handleProviderState(int id, String origin) {
    handleMethod(id, origin, () async {
      return {
        'accounts': await web3handler.ethAccounts(false),
        'chainId': web3handler.ethChainId(),
        'networkVersion': web3handler.ethChain.chainId.toString(),
        'isUnlocked': true,
      };
    });
  }

  /// ===== 通用执行 =====
  void handleMethod(int id, String origin, FutureOr Function() fn) async {
    try {
      final result = await Future.sync(fn);
      sendResponse(id, result, origin);
    } catch (e) {
      sendError(id, e, origin);
    }
  }

  /// ===== JS通信 =====
  void postMessage(Map msg, String origin) {
    final targetOrigin = _targetOrigin(origin);
    final js =
        '''
      window.postMessage(${json.encode(msg)}, '$targetOrigin');
    ''';
    web3handler.evaluateJavascript(js);
  }

  void sendResponse(int id, dynamic result, [String origin = '*']) {
    postMessage({
      'data': {'id': id, 'jsonrpc': '2.0', 'result': result},
      'name': 'metamask-provider',
    }, origin);
  }

  void sendError(int id, dynamic error, [String origin = '*']) {
    final err = error is Map ? error : _rpcError(-32000, error.toString());

    postMessage({
      'data': {'id': id, 'jsonrpc': '2.0', 'error': err},
      'name': 'metamask-provider',
    }, origin);
  }

  Map _rpcError(int code, String message) {
    return {'code': code, 'message': message};
  }

  String _targetOrigin(String origin) {
    if (origin == '*' || origin.isEmpty) {
      return '*';
    }

    final uri = Uri.tryParse(origin);
    if (uri == null) {
      return '*';
    }

    if (!uri.hasScheme || uri.host.isEmpty) {
      return '*';
    }

    return uri.origin;
  }

  /// ===== 事件（关键）=====
  void emit(String event, dynamic data) {
    final js =
        '''
      window.ethereum?.emit?.('$event', ${jsonEncode(data)});
    ''';
    web3handler.evaluateJavascript(js);
  }

  @override
  void onChangeWallet() {
    /// 示例（你可以传真实数据）
    emit('accountsChanged', []);
    emit('chainChanged', web3handler.ethChainId());
  }
}
