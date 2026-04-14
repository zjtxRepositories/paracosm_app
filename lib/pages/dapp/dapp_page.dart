import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:paracosm/core/network/models/dApp_hive.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/pages/brower/browser_controller.dart';

import '../../modules/dapp/dapp_web3_service.dart';
import '../../modules/dapp/handler/eth_web3_handler.dart';
import '../../modules/dapp/handler/metamask_handler.dart';
import '../../widgets/modals/dapp_modals.dart';

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
  bool _ready = false;

  // =========================================================
  // step 1: init scripts BEFORE WebView build
  // =========================================================
  Future<void> _prepare() async {
    final wallet = AccountManager().currentWallet;
    if (wallet == null) return;

    // 1. create dummy controller will be replaced later
    final tempController = InAppWebViewController.fromPlatform(platform: PlatformInAppWebViewController.static());

    _web3Service = DAppWeb3Service(tempController, wallet, context: context);

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

    setState(() {
      _ready = true;
    });
  }

  // =========================================================
  // step 2: bind real webview controller
  // =========================================================
  Future<void> _onWebViewCreated(InAppWebViewController controller) async {
    _web3Service = DAppWeb3Service(controller,
       AccountManager().currentWallet!, context: context);

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

  Future<List<String>> showConnectSheet({
     required BuildContext context,
     required String host,
     required String title,
     required String faviconUrl,
     required String uri,
     required String address,
   }){
     final completer = Completer<List<String>>();
     DappModals.showConnectSheet(
       context: context,
       host: host,
       title: title,
       faviconUrl: faviconUrl,
       uri: uri.toString(),
       onApprove: () {
         completer.complete([address]);
       },
       onReject: () {
         completer.completeError(
           EthHandlerException("Request account rejected"),
         );
       },
     );
     return completer.future;
   }
  // =========================================================
  // UI
  // =========================================================
  @override
  Widget build(BuildContext context) {
    if (!_ready || _scripts == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return BrowserController(
      url: widget.dapp.url,
      name: widget.dapp.name,
      scripts: _scripts,
      onWebViewCreated: _onWebViewCreated,
    );
  }
}