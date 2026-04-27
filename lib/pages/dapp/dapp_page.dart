import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/core/db/dao/wallet_dao.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/account/model/account_model.dart';
import 'package:paracosm/modules/dapp/dapp_account_auth_hive.dart';
import 'package:paracosm/modules/wallet/model/wallet_model.dart';
import 'package:paracosm/pages/brower/browser_controller.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/modals/wallet_modals.dart';
import '../../core/models/dApp_hive.dart';
import '../../modules/dapp/dapp_web3_service.dart';
import '../../modules/dapp/handler/eth_web3_handler.dart';
import '../../modules/dapp/handler/metamask_handler.dart';

class DAppPage extends StatefulWidget {
  final DAppHive dapp;

  const DAppPage({super.key, required this.dapp});

  @override
  State<DAppPage> createState() => _DAppPageState();
}

class _DAppPageState extends State<DAppPage> {
  late DAppWeb3Service _web3Service;
  late EthWebViewHandler _handler;

  InAppWebViewController? _webViewController;
  UnmodifiableListView<UserScript>? _scripts;
  List<AccountModel> _accounts = [];
  Map<String, WalletModel> _walletMap = {};
  final Set<String> _sessionAuthorizedHosts = <String>{};
  bool _ready = false;

  bool _isHostAuthorized(String host) {
    final normalizedHost = DAppAccountAuthHive.normalizeHost(host);
    return _sessionAuthorizedHosts.contains(normalizedHost);
  }

  void _authorizeHost(String host) {
    _sessionAuthorizedHosts.add(DAppAccountAuthHive.normalizeHost(host));
  }

  // =========================================================
  // step 1: init scripts BEFORE WebView build
  // =========================================================
  Future<void> _prepare() async {
    final wallet = AccountManager().currentWallet;
    if (wallet == null) return;
    await _loadWalletData();
    if (!mounted) return;

    // 1. create dummy controller will be replaced later
    final tempController = InAppWebViewController.fromPlatform(
      platform: PlatformInAppWebViewController.static(),
    );

    _web3Service = DAppWeb3Service(
      tempController,
      wallet,
      context: context,
      isSessionHostAuthorized: _isHostAuthorized,
      authorizeSessionHost: _authorizeHost,
    );

    _handler = MetaMaskHandler(_web3Service);

    final scripts = await _handler.injectScripts();
    _scripts = UnmodifiableListView(
      scripts.map(
        (e) => UserScript(
          source: e,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      ),
    );

    if (!mounted) return;
    setState(() {
      _ready = true;
    });
  }

  // =========================================================
  // step 2: bind real webview controller
  // =========================================================
  Future<void> _onWebViewCreated(InAppWebViewController controller) async {
    _webViewController = controller;
    await _bindWeb3Controller(controller);
  }

  Future<void> _bindWeb3Controller(InAppWebViewController controller) async {
    _web3Service = DAppWeb3Service(
      controller,
      AccountManager().currentWallet!,
      context: context,
      isSessionHostAuthorized: _isHostAuthorized,
      authorizeSessionHost: _authorizeHost,
    );

    _handler = MetaMaskHandler(_web3Service);

    controller
      ..removeJavaScriptHandler(handlerName: _handler.name)
      ..addJavaScriptHandler(
        handlerName: _handler.name,
        callback: _handler.handle,
      );
  }

  Future<void> _loadWalletData() async {
    final accounts = AccountManager().accounts;
    final walletDao = WalletDao();
    final walletMap = <String, WalletModel>{};

    for (final account in accounts) {
      final wallet = await walletDao.getWalletById(account.id);
      if (wallet != null) {
        walletMap[account.id] = wallet;
      }
    }

    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      _walletMap = walletMap;
    });
  }

  String? _currentWalletName() {
    final wallet = AccountManager().currentWallet;
    if (wallet == null) return null;
    if (wallet.name?.isNotEmpty == true) {
      return wallet.name;
    }
    final l10n = AppLocalizations.of(context)!;
    return '${l10n.profileProfileDetailsWallet} ${wallet.aIndex + 1}';
  }

  String? _currentWalletAddress() {
    final wallet = AccountManager().currentWallet;
    return wallet?.currentChain?.address;
  }

  void _showWalletSwitcher() {
    final currentWallet = AccountManager().currentWallet;
    if (currentWallet == null || _walletMap.isEmpty) return;

    WalletModals.showWalletSwitcher(
      context,
      accounts: _accounts,
      walletMap: _walletMap,
      currentWalletId: currentWallet.id,
      onSwitch: (accountId) async {
        await AccountManager().switchAccount(accountId);
        await _loadWalletData();

        final controller = _webViewController;
        if (controller != null) {
          await _bindWeb3Controller(controller);
          await controller.reload();
        }

        if (mounted) {
          setState(() {});
        }
      },
      onAddWallet: () {
        context.push('/wallet-manager');
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  // =========================================================
  // UI
  // =========================================================
  @override
  Widget build(BuildContext context) {
    if (!_ready || _scripts == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return BrowserController(
      url: widget.dapp.url,
      name: widget.dapp.name,
      scripts: _scripts,
      walletName: _currentWalletName(),
      walletAddress: _currentWalletAddress(),
      onWebViewCreated: _onWebViewCreated,
      onSwitchWallet: _showWalletSwitcher,
      onClose: () => context.pop(),
    );
  }
}
