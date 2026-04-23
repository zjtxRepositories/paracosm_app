import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

class BrowserController extends StatefulWidget {
  final String url;
  final String? name;

  /// 由外部 Controller 注入
  final InAppWebViewController? controller;
  final UnmodifiableListView<UserScript>? scripts;

  /// 回调（交给外层处理逻辑）
  final Function(InAppWebViewController controller)? onWebViewCreated;
  final Function(int progress)? onProgressChanged;
  final Function(String? title)? onTitleChanged;
  final Function(bool canGoBack)? onCanGoBack;

  const BrowserController({
    super.key,
    required this.url,
    this.name,
    this.controller,
    this.scripts,
    this.onWebViewCreated,
    this.onProgressChanged,
    this.onTitleChanged,
    this.onCanGoBack,
  });

  @override
  State<BrowserController> createState() => _BrowserControllerState();
}

class _BrowserControllerState extends State<BrowserController> {
  /// UI状态（仅UI）
  final _title = ''.obs;
  final _progress = 0.obs;
  final _canGoBack = false.obs;

  InAppWebViewController? _controller;

  @override
  void initState() {
    super.initState();
    _title.value = widget.name ?? "Loading...";
  }

  void _handleWebViewCreated(InAppWebViewController controller) {
    _controller = controller;
    widget.onWebViewCreated?.call(controller);
  }

  bool _isTrustedDevHost(String? host) {
    if (host == null || host.isEmpty) {
      return false;
    }
    return host == 'test-frp.zjtxy.top' || host.endsWith('.zjtxy.top');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Obx(() {
          return _canGoBack.value
              ? BackButton(
                  onPressed: _controller == null
                      ? null
                      : () => _controller?.goBack(),
                )
              : CloseButton(onPressed: () => Get.back());
        }),
        title: Obx(() => Text(_title.value)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _controller == null ? null : () => _controller?.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri.uri(Uri.parse(widget.url)),
            ),
            initialSettings: InAppWebViewSettings(
              mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
            ),
            initialUserScripts: widget.scripts,
            onWebViewCreated: _handleWebViewCreated,
            onProgressChanged: (_, progress) {
              _progress.value = progress;
              widget.onProgressChanged?.call(progress);
            },
            onTitleChanged: (_, title) {
              if (title != null) {
                _title.value = title;
              }
              widget.onTitleChanged?.call(title);
            },
            onUpdateVisitedHistory: (controller, url, isReload) async {
              final canGoBack = await controller.canGoBack();
              _canGoBack.value = canGoBack;
              widget.onCanGoBack?.call(canGoBack);
            },
            onConsoleMessage: (_, consoleMessage) {
              debugPrint(
                'DApp console [${consoleMessage.messageLevel}]: ${consoleMessage.message}',
              );
            },
            onReceivedServerTrustAuthRequest: (_, challenge) async {
              final host = challenge.protectionSpace.host;
              if (_isTrustedDevHost(host)) {
                debugPrint('WebView trust challenge proceed for host=$host');
                return ServerTrustAuthResponse(
                  action: ServerTrustAuthResponseAction.PROCEED,
                );
              }
              return ServerTrustAuthResponse(
                action: ServerTrustAuthResponseAction.CANCEL,
              );
            },
          ),

          /// 进度条（纯UI）
          Obx(() {
            if (_progress.value == 100) {
              return const SizedBox();
            }
            return LinearProgressIndicator(
              value: _progress.value / 100,
              minHeight: 2,
            );
          }),
        ],
      ),
    );
  }
}
