// ignore_for_file: use_build_context_synchronously

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

import '../wallet/chains/evm/client/evm_client_manager.dart';
import '../wallet/chains/evm/evm_facade.dart';
import '../wallet/chains/model/gas_fee.dart';
import '../wallet/manager/wallet_manager.dart';
import 'dapp_account_auth_hive.dart';
import 'handler/eth_web3_handler.dart';

class DAppWeb3Service implements EthWeb3Handler {
  final InAppWebViewController controller;
  WalletModel wallet;
  final BuildContext context;
  final bool Function(String host) isSessionHostAuthorized;
  final void Function(String host) authorizeSessionHost;

  DAppWeb3Service(
    this.controller,
    this.wallet, {
    required this.context,
    required this.isSessionHostAuthorized,
    required this.authorizeSessionHost,
  });

  // =========================================================
  // WebView
  // =========================================================
  @override
  Future evaluateJavascript(String source) {
    return controller.evaluateJavascript(source: source);
  }

  @override
  void emit(String event, data) {
    controller.evaluateJavascript(
      source:
          '''
      window.ethereum?.emit?.('$event', ${jsonEncode(data)});
    ''',
    );
  }

  bool _isAuthorizedHost(String host) {
    return isSessionHostAuthorized(host) || DAppAccountAuthHive.checkAuth(host);
  }

  void _ensureContextMounted() {
    if (!context.mounted) {
      throw StateError('DApp context is no longer mounted');
    }
  }

  Future<String> get _favicon async {
    final favicons = await controller.getFavicons();
    return favicons.firstOrNull?.url.toString() ?? '';
  }

  int _parseDecimals(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String && value.isNotEmpty) {
      return int.tryParse(value) ??
          (throw EthHandlerException('Invalid token decimals'));
    }
    throw EthHandlerException('Invalid token decimals');
  }

  String? _normalizeHexData(String? data) {
    if (data == null || data.isEmpty) return null;
    final normalized = data.startsWith('0x') ? data : '0x$data';
    return normalized.toLowerCase();
  }

  bool _isApproveCall(String? data) {
    final normalized = _normalizeHexData(data);
    return normalized != null && normalized.startsWith('0x095ea7b3');
  }

  bool _isTokenTransferCall(String? data) {
    final normalized = _normalizeHexData(data);
    return normalized != null &&
        (normalized.startsWith('0xa9059cbb') ||
            normalized.startsWith('0x23b872dd'));
  }

  String? _slot(String normalizedData, int index) {
    final start = 10 + index * 64;
    final end = start + 64;
    if (normalizedData.length < end) return null;
    return normalizedData.substring(start, end);
  }

  BigInt? _slotBigInt(String normalizedData, int index) {
    final slot = _slot(normalizedData, index);
    if (slot == null) return null;
    return BigInt.tryParse(slot, radix: 16);
  }

  String? _slotAddress(String normalizedData, int index) {
    final slot = _slot(normalizedData, index);
    if (slot == null) return null;
    return '0x${slot.substring(24)}';
  }

  String? _addressArrayFirstAddress(String normalizedData, int offsetBytes) {
    final arrayStart = 10 + offsetBytes * 2;
    final firstItemStart = arrayStart + 64;
    final firstItemEnd = firstItemStart + 64;
    if (normalizedData.length < firstItemEnd) return null;
    final slot = normalizedData.substring(firstItemStart, firstItemEnd);
    return '0x${slot.substring(24)}';
  }

  String? _pathBytesTokenAddress(
    String normalizedData,
    int offsetBytes, {
    bool last = false,
  }) {
    final pathStart = 10 + offsetBytes * 2;
    final lengthSlotEnd = pathStart + 64;
    if (normalizedData.length < lengthSlotEnd) return null;
    final length = BigInt.tryParse(
      normalizedData.substring(pathStart, lengthSlotEnd),
      radix: 16,
    )?.toInt();
    if (length == null || length < 20) return null;

    final bytesStart = lengthSlotEnd;
    final pathHexLength = length * 2;
    final bytesEnd = bytesStart + pathHexLength;
    if (normalizedData.length < bytesEnd) return null;

    final pathHex = normalizedData.substring(bytesStart, bytesEnd);
    if (last) {
      return '0x${pathHex.substring(pathHex.length - 40)}';
    }
    return '0x${pathHex.substring(0, 40)}';
  }

  _ContractSpend? _contractSpend(String? data) {
    final normalized = _normalizeHexData(data);
    if (normalized == null || normalized.length < 10) return null;

    final selector = normalized.substring(0, 10);
    switch (selector) {
      case '0x38ed1739': // swapExactTokensForTokens
      case '0x18cbafe5': // swapExactTokensForETH
      case '0x5c11d795': // swapExactTokensForTokensSupportingFeeOnTransferTokens
      case '0x791ac947': // swapExactTokensForETHSupportingFeeOnTransferTokens
        final amount = _slotBigInt(normalized, 0);
        final pathOffset = _slotBigInt(normalized, 2)?.toInt();
        if (amount == null || pathOffset == null) return null;
        final tokenIn = _addressArrayFirstAddress(normalized, pathOffset);
        if (tokenIn == null) return null;
        return _ContractSpend(tokenAddress: tokenIn, amount: amount);

      case '0x8803dbee': // swapTokensForExactTokens
      case '0x4a25d94a': // swapTokensForExactETH
        final amountInMax = _slotBigInt(normalized, 1);
        final pathOffset = _slotBigInt(normalized, 2)?.toInt();
        if (amountInMax == null || pathOffset == null) return null;
        final tokenIn = _addressArrayFirstAddress(normalized, pathOffset);
        if (tokenIn == null) return null;
        return _ContractSpend(tokenAddress: tokenIn, amount: amountInMax);

      case '0x414bf389': // exactInputSingle
        final tokenIn = _slotAddress(normalized, 0);
        final amountIn = _slotBigInt(normalized, 5);
        if (tokenIn == null || amountIn == null) return null;
        return _ContractSpend(tokenAddress: tokenIn, amount: amountIn);

      case '0xdb3e2198': // exactOutputSingle
        final tokenIn = _slotAddress(normalized, 0);
        final amountInMax = _slotBigInt(normalized, 6);
        if (tokenIn == null || amountInMax == null) return null;
        return _ContractSpend(tokenAddress: tokenIn, amount: amountInMax);

      case '0xc04b8d59': // exactInput
        final pathOffset = _slotBigInt(normalized, 0)?.toInt();
        final amountIn = _slotBigInt(normalized, 3);
        if (pathOffset == null || amountIn == null) return null;
        final tokenIn = _pathBytesTokenAddress(normalized, pathOffset);
        if (tokenIn == null) return null;
        return _ContractSpend(tokenAddress: tokenIn, amount: amountIn);

      case '0xf28c0498': // exactOutput
        final pathOffset = _slotBigInt(normalized, 0)?.toInt();
        final amountInMax = _slotBigInt(normalized, 4);
        if (pathOffset == null || amountInMax == null) return null;
        final tokenIn = _pathBytesTokenAddress(
          normalized,
          pathOffset,
          last: true,
        );
        if (tokenIn == null) return null;
        return _ContractSpend(tokenAddress: tokenIn, amount: amountInMax);
    }

    return null;
  }

  TokenModel? _tokenByAddress(String address) {
    final tokenAddress = address.toLowerCase();
    if (tokenAddress.isEmpty) return null;
    for (final token in ethChain.tokens) {
      if (token.address.isNotEmpty &&
          token.address.toLowerCase() == tokenAddress) {
        return token;
      }
    }
    return null;
  }

  BigInt? _tokenTransferAmountValue(String? data) {
    final normalized = _normalizeHexData(data);
    if (normalized == null) return null;
    if (normalized.startsWith('0xa9059cbb')) {
      if (normalized.length < 138) return null;
      return BigInt.parse(normalized.substring(74, 138), radix: 16);
    }
    if (normalized.startsWith('0x23b872dd')) {
      if (normalized.length < 202) return null;
      return BigInt.parse(normalized.substring(138, 202), radix: 16);
    }
    return null;
  }

  String? _approveSpender(String? data) {
    final normalized = _normalizeHexData(data);
    if (normalized == null || normalized.length < 74) return null;
    return '0x${normalized.substring(34, 74)}';
  }

  BigInt? _approveAmountValue(String? data) {
    final normalized = _normalizeHexData(data);
    if (normalized == null || normalized.length < 138) return null;
    return BigInt.parse(normalized.substring(74, 138), radix: 16);
  }

  String? _approvalAmountLabel(String? data) {
    final amount = _approveAmountValue(data);
    if (amount == null) return null;
    if (amount == (BigInt.one << 256) - BigInt.one) {
      return '无限授权';
    }
    return amount.toString();
  }

  String _formatTokenAmount(BigInt value, int decimals) {
    final divisor = BigInt.from(10).pow(decimals);
    final integer = value ~/ divisor;
    final decimal = value % divisor;

    if (decimal == BigInt.zero) {
      return integer.toString();
    }

    final decimalText = decimal
        .toString()
        .padLeft(decimals, '0')
        .replaceFirst(RegExp(r'0+$'), '');

    return '$integer.$decimalText';
  }

  String _formatAmountWithSymbol(BigInt value, String symbol) {
    return '${_formatEth(value)} $symbol';
  }

  String _formatTokenAmountWithSymbol(BigInt value, TokenModel token) {
    if (value == (BigInt.one << 256) - BigInt.one) {
      return '无限授权 ${token.symbol}';
    }
    return '${_formatTokenAmount(value, token.decimals)} ${token.symbol}';
  }

  bool _hasAddedToken(String address) {
    final tokenAddress = address.toLowerCase();
    return ethChain.tokens.any((token) {
      return token.chainId == ethChain.chainId &&
          token.address.isNotEmpty &&
          token.address.toLowerCase() == tokenAddress &&
          token.isAdded == true;
    });
  }

  // =========================================================
  // sign message (兼容 MetaMask 参数顺序)
  // =========================================================
  Future<String> _signMessage(String data, bool personal) async {
    final uri = await controller.getUrl();
    final host = uri?.host ?? '';
    final faviconUrl = await _favicon;

    final address = ethChain.address;

    // 1. 授权检查
    if (!_isAuthorizedHost(host)) {
      throw Exception('Unauthorized DApp');
    }

    // 2. UI确认
    _ensureContextMounted();
    final approved =
        await DAppModalService.showSign(
          context: context,
          message: data,
          address: address,
          host: host,
          faviconUrl: faviconUrl,
          walletLabel: ethChain.name,
        ) ??
        false;

    if (!approved) {
      throw Exception('User rejected signature');
    }

    // 3. 密码验证
    _ensureContextMounted();
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
  Future<String> _signTypeData(
    String jsonData,
    TypedDataVersion version,
  ) async {
    final uri = await controller.getUrl();
    final host = uri?.host ?? '';
    final faviconUrl = await _favicon;

    final address = ethChain.address;

    // 1. 授权检查
    if (!_isAuthorizedHost(host)) {
      throw Exception('Unauthorized DApp');
    }
    final decoded = jsonDecode(jsonData);
    final pretty = const JsonEncoder.withIndent('  ').convert(decoded);
    // 2. UI确认
    _ensureContextMounted();
    final approved =
        await DAppModalService.showSign(
          context: context,
          message: pretty,
          address: address,
          host: host,
          faviconUrl: faviconUrl,
          walletLabel: ethChain.name,
        ) ??
        false;

    if (!approved) {
      throw Exception('User rejected signature');
    }

    // 3. 密码验证
    _ensureContextMounted();
    final passwordOk = await DAppModalService.showPassword(context: context);
    if (!passwordOk) {
      throw Exception('Password verification failed');
    }

    // 4. 执行签名
    final signature = await EvmFacade.signTypedDataRaw(
      address,
      jsonData,
      version,
    );

    return signature;
  }

  // =========================================================
  // send transaction
  // =========================================================
  Future<String> _sendTransaction(Map data, {GasFee? gasFee}) async {
    final chain = wallet.currentChain;

    if (chain == null) {
      throw Exception("Wallet not found");
    }

    final to = data['to'] ?? '';

    final value = data['value'] != null
        ? _parseHex(data['value'])
        : BigInt.zero;

    return await EvmFacade.send(
      chain: chain,
      to: to,
      amountWei: value,
      contractAddress: null,
      gasFee: gasFee,
      customData: data['data'],
    );
  }

  String _formatEth(BigInt value) {
    return EtherAmount.inWei(
      value,
    ).getValueInUnit(EtherUnit.ether).toStringAsFixed(6);
  }

  BigInt _parseHex(String? value) {
    if (value == null || value.isEmpty) return BigInt.zero;
    if (!value.startsWith('0x')) return BigInt.parse(value);
    return hexToInt(value);
  }

  int _parseChainId(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final chainId = value.trim();
      if (chainId.isEmpty) {
        throw EthHandlerException('chainId missing');
      }
      if (chainId.startsWith('0x') || chainId.startsWith('0X')) {
        return hexToDartInt(chainId);
      }
      return int.parse(chainId);
    }
    throw EthHandlerException('Invalid chainId');
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
    if (_isAuthorizedHost(host)) {
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
    final accounts = [ethChain.address.toLowerCase()];

    /// 已授权
    if (_isAuthorizedHost(host)) {
      _emitConnected(accounts);
      return accounts;
    }
    _ensureContextMounted();
    final result = await DAppModalService.showConnect(
      context: context,
      host: host,
      title: title,
      faviconUrl: faviconUrl,
      uri: uri.toString(),
    );
    if (result == null || !result.approved) {
      throw EthHandlerException("Request account rejected");
    }
    authorizeSessionHost(host);
    if (result.remember) {
      DAppAccountAuthHive.add(host);
    }
    _emitConnected(accounts);
    return accounts;
  }

  List<Map<String, dynamic>> _ethAccountPermissions(List<String> accounts) {
    return [
      {
        'parentCapability': 'eth_accounts',
        'caveats': [
          {'type': 'restrictReturnedAccounts', 'value': accounts},
        ],
      },
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> walletGetPermissions() async {
    final uri = await controller.getUrl();
    final host = uri?.host ?? '';
    if (!_isAuthorizedHost(host)) {
      return [];
    }

    return _ethAccountPermissions([ethChain.address.toLowerCase()]);
  }

  @override
  Future<List<Map<String, dynamic>>> walletRequestPermissions([
    Map? data,
  ]) async {
    final request = data ?? const {};
    if (request.isNotEmpty && !request.containsKey('eth_accounts')) {
      throw EthHandlerException('Only eth_accounts permission is supported');
    }

    final accounts = await ethRequestAccounts();
    return _ethAccountPermissions(accounts);
  }

  @override
  Future<String> ethCoinbase([bool request = true]) async {
    if (request) {
      return (await ethRequestAccounts()).first;
    }
    String host = (await controller.getUrl())!.host;
    if (_isAuthorizedHost(host)) {
      return ethChain.address.toLowerCase();
    }
    return '';
  }

  void _emitConnected(List<String> accounts) {
    emit(EthEvents.connect, {'chainId': ethChainId()});
    emit(EthEvents.accountsChanged, accounts);
    emit(EthEvents.chainChanged, ethChainId());
  }

  Future<void> _switchToChain(int chainId) async {
    wallet = AccountManager().currentWallet ?? wallet;
    if (!wallet.hasChain(chainId)) {
      throw {
        'code': 4902,
        'message': 'Unrecognized chain ID. Try adding the chain first.',
      };
    }
    await WalletManager.switchChain(wallet.id, chainId);
    wallet = AccountManager().currentWallet!;
    emit(EthEvents.accountsChanged, [ethChain.address.toLowerCase()]);
    emit(EthEvents.chainChanged, ethChainId());
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
  Future<String> personalSign(String data) {
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

      final BigInt value = data['value'] == null
          ? BigInt.zero
          : hexToInt(data['value']);

      final BigInt? gas = data['gas'] == null ? null : hexToInt(data['gas']);
      final String? callData = data['data'];
      final bool isContractCall = callData != null && callData.isNotEmpty;
      final bool isApproval = _isApproveCall(callData);
      final bool isTokenTransfer = _isTokenTransferCall(callData);
      final contractSpend = !isApproval && !isTokenTransfer
          ? _contractSpend(callData)
          : null;
      final tokenAmount = isTokenTransfer
          ? _tokenTransferAmountValue(callData)
          : isApproval
          ? _approveAmountValue(callData)
          : contractSpend?.amount;
      final transactionType = isApproval
          ? '授权额度'
          : isTokenTransfer
          ? '代币转账'
          : isContractCall
          ? '合约交互'
          : '转账';

      /// =========================
      /// 2. 权限校验（必须有）
      /// =========================
      final hasPermission = _isAuthorizedHost(origin);

      if (!hasPermission) {
        throw Exception('Unauthorized DApp');
      }

      /// =========================
      /// 3. 金额格式化
      /// =========================
      final tokenAddress = contractSpend?.tokenAddress ?? to;
      final token =
          (isTokenTransfer || isApproval || contractSpend != null) &&
              tokenAddress.isNotEmpty
          ? _tokenByAddress(tokenAddress) ??
                await EvmFacade.getTokenInfo(ethChain, tokenAddress)
          : null;
      final amount = token != null && tokenAmount != null
          ? _formatTokenAmountWithSymbol(tokenAmount, token)
          : _formatAmountWithSymbol(value, ethChain.symbol);
      final approvalAmount = isApproval && token != null && tokenAmount != null
          ? _formatTokenAmountWithSymbol(tokenAmount, token)
          : isApproval
          ? _approvalAmountLabel(callData)
          : null;
      final logo = faviconUrl;
      final gasLevel = await EvmFacade.gas(ethChain);

      /// =========================
      /// 4. 交易确认弹窗
      /// =========================
      _ensureContextMounted();
      final decision = await DAppModalService.showTransaction(
        context: context,
        amount: amount,
        logo: logo,
        from: from,
        to: to,
        gasLevel: gasLevel,
        feeSymbol: ethChain.symbol,
        walletLabel: ethChain.name,
        feeDescription: gas == null ? null : 'Estimated by gas limit',
        gasLimit: gas,
        isContractCall: isContractCall,
        transactionType: transactionType,
        approvalAmount: approvalAmount,
        approvalSpender: isApproval ? _approveSpender(callData) : null,
        data: callData,
      );

      if (decision == null || !decision.approved) {
        throw Exception('User rejected transaction');
      }

      /// =========================
      /// 5. 密码校验
      /// =========================
      _ensureContextMounted();
      final passwordOk = await DAppModalService.showPassword(context: context);

      if (!passwordOk) {
        throw Exception('Password verification failed');
      }

      /// =========================
      /// 6. 发送交易
      /// =========================
      final txHash = await _sendTransaction(data, gasFee: decision.gasFee);

      return txHash;
    } catch (e) {
      debugPrint('ethSendTransaction error: $e');
      rethrow;
    }
  }

  @override
  Future<void> walletAddEthereumChain(Map data) async {
    try {
      // =========================
      // 基础解析（安全取值）
      // =========================
      final chainIdHex = data['chainId'];
      if (chainIdHex == null) {
        throw 'chainId missing';
      }

      final chainId = _parseChainId(chainIdHex);
      final chainName = data['chainName'] ?? 'Unknown';

      final native = data['nativeCurrency'] ?? {};
      final symbol = native['symbol'] ?? 'ETH';
      final decimals = native['decimals'] ?? 18;
      final name = native['name'] ?? chainName;

      final rpcUrls =
          (data['rpcUrls'] as List?)
              ?.cast<String>()
              .where((e) => e.startsWith('http'))
              .toList() ??
          [];

      if (rpcUrls.isEmpty) {
        throw 'rpcUrls empty';
      }

      final blockExplorerUrls = (data['blockExplorerUrls'] as List?)
          ?.cast<String>();

      final blockExplorerUrl =
          (blockExplorerUrls != null && blockExplorerUrls.isNotEmpty)
          ? blockExplorerUrls.first
          : null;

      final favicons = await controller.getFavicons();
      final faviconUrl = favicons.isNotEmpty
          ? favicons.first.url.toString()
          : '';

      final url = (await controller.getUrl())?.toString() ?? '';

      // =========================
      // ⚠️ 已存在检查
      // =========================
      if (wallet.hasChain(chainId)) {
        if (wallet.currentChain?.chainId != chainId) {
          await _switchToChain(chainId);
        }
        return;
      }

      // =========================
      // ⚠️ 用户确认（关键）
      // =========================
      _ensureContextMounted();
      final approved =
          await DAppAddChainSheet.show(
            context,
            name: chainName,
            chainId: chainId,
            rpc: rpcUrls.first,
            symbol: symbol,
            origin: url,
          ) ??
          false;

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
          ),
        ],
      );

      // =========================
      // 保存
      // =========================
      await WalletManager.addChain(wallet.id, chain);
      await _switchToChain(chainId);
    } catch (e, s) {
      debugPrintStack(label: e.toString(), stackTrace: s);
      throw '链详情不完整';
    }
  }

  @override
  Future<bool> walletWatchAsset(Map data) async {
    if (ethChain.chainType != ChainType.evm) {
      throw EthHandlerException('wallet_watchAsset only supports EVM chains');
    }

    final type = data['type']?.toString();
    if (type != 'ERC20') {
      throw EthHandlerException('Only ERC20 assets are supported');
    }

    final options = data['options'];
    if (options is! Map) {
      throw EthHandlerException('Asset options missing');
    }

    final address = options['address']?.toString() ?? '';
    final symbol = options['symbol']?.toString() ?? '';
    final image = options['image']?.toString() ?? '';

    if (address.isEmpty || symbol.isEmpty || options['decimals'] == null) {
      throw EthHandlerException('Asset details missing');
    }

    final decimals = _parseDecimals(options['decimals']);
    if (decimals < 0) {
      throw EthHandlerException('Invalid token decimals');
    }

    if (!EvmFacade.isValidAddress(address)) {
      throw EthHandlerException('Invalid token address');
    }

    if (_hasAddedToken(address)) {
      return true;
    }

    final isContract = await EvmFacade.isContractAddress(ethChain, address);
    if (!isContract) {
      throw EthHandlerException('Token address is not a contract');
    }

    final uri = await controller.getUrl();
    final host = uri?.host ?? '';

    _ensureContextMounted();
    final approved =
        await DAppModalService.showWatchAsset(
          context: context,
          host: host,
          address: address,
          symbol: symbol,
          decimals: decimals,
          image: image,
          chainName: ethChain.name,
        ) ??
        false;

    if (!approved) {
      throw EthHandlerException('User rejected asset');
    }

    await WalletManager.addToken(
      wallet.id,
      TokenModel(
        symbol: symbol,
        name: symbol,
        address: EthereumAddress.fromHex(address).hex,
        balance: BigInt.zero,
        decimals: decimals,
        logo: image,
        coinId: symbol.toLowerCase(),
        chainId: ethChain.chainId,
        isAdded: true,
      ),
    );
    wallet = AccountManager().currentWallet!;
    return true;
  }

  @override
  Future<void> walletSwitchEthereumChain(Map data) async {
    final chainId = _parseChainId(data['chainId']);
    await _switchToChain(chainId);
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
  Future<String> ethSignTypedDataUint8List(Uint8List message, String data) =>
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

class _ContractSpend {
  final String tokenAddress;
  final BigInt amount;

  const _ContractSpend({required this.tokenAddress, required this.amount});
}
