import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/dapp/dapp_account_auth_hive.dart';
import 'package:paracosm/pages/brower/browser_controller.dart';
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

  UnmodifiableListView<UserScript>? _scripts;
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
      onWebViewCreated: _onWebViewCreated,
    );
  }
}
