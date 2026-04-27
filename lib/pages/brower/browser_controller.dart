import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/util/string_util.dart';

class BrowserController extends StatefulWidget {
  final String url;
  final String? name;
  final String? walletName;
  final String? walletAddress;

  /// 由外部 Controller 注入
  final InAppWebViewController? controller;
  final UnmodifiableListView<UserScript>? scripts;

  /// 回调（交给外层处理逻辑）
  final Function(InAppWebViewController controller)? onWebViewCreated;
  final Function(int progress)? onProgressChanged;
  final Function(String? title)? onTitleChanged;
  final Function(bool canGoBack)? onCanGoBack;
  final VoidCallback? onSwitchWallet;
  final VoidCallback? onClose;

  const BrowserController({
    super.key,
    required this.url,
    this.name,
    this.walletName,
    this.walletAddress,
    this.controller,
    this.scripts,
    this.onWebViewCreated,
    this.onProgressChanged,
    this.onTitleChanged,
    this.onCanGoBack,
    this.onSwitchWallet,
    this.onClose,
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
  late final PullToRefreshController _pullToRefreshController;

  @override
  void initState() {
    super.initState();
    _title.value = widget.name ?? "Loading...";
    _pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(color: AppColors.primaryLight),
      onRefresh: () async {
        await _controller?.reload();
      },
    );
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

  Future<void> _updateCanGoBack(InAppWebViewController controller) async {
    final canGoBack = await controller.canGoBack();
    _canGoBack.value = canGoBack;
    widget.onCanGoBack?.call(canGoBack);
  }

  void _closePage() {
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    Get.back();
  }

  Widget _buildWalletAction() {
    final walletText = widget.walletName?.isNotEmpty == true
        ? widget.walletName!
        : widget.walletAddress ?? '';
    final subtitle = widget.walletAddress?.isNotEmpty == true
        ? ellipsisMiddle(widget.walletAddress!, head: 4, tail: 4)
        : '';

    return GestureDetector(
      onTap: widget.onSwitchWallet,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 132),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 16,
              color: AppColors.grey800,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    walletText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey900,
                      height: 1.1,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 9,
                        color: AppColors.grey500,
                        height: 1.1,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leadingWidth: 52,
        leading: Obx(
          () => IconButton(
            onPressed: _controller == null || !_canGoBack.value
                ? null
                : () => _controller?.goBack(),
            icon: Opacity(
              opacity: _canGoBack.value ? 1 : 0.35,
              child: Image.asset(
                'assets/images/common/back-icon.png',
                width: 32,
                height: 32,
              ),
            ),
          ),
        ),
        title: Obx(
          () => Text(
            _title.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.grey900,
            ),
          ),
        ),
        actions: [
          if (widget.onSwitchWallet != null) _buildWalletAction(),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.grey900),
            onPressed: _closePage,
          ),
          const SizedBox(width: 4),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.grey100),
        ),
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
            pullToRefreshController: _pullToRefreshController,
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
            onLoadStop: (controller, url) async {
              await _pullToRefreshController.endRefreshing();
              await _updateCanGoBack(controller);
            },
            onReceivedError: (controller, request, error) async {
              await _pullToRefreshController.endRefreshing();
            },
            onReceivedHttpError: (controller, request, errorResponse) async {
              await _pullToRefreshController.endRefreshing();
            },
            onUpdateVisitedHistory: (controller, url, isReload) async {
              await _updateCanGoBack(controller);
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
