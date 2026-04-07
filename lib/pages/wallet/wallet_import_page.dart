import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paracosm/modules/wallet/chains/evm/evm_service.dart';
import 'package:paracosm/modules/wallet/manager/wallet_manager.dart';
import 'package:paracosm/modules/wallet/service/mnemonic_service.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/common/app_button.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/widgets/common/app_loading.dart';
import 'package:paracosm/widgets/common/app_toast.dart';

import '../../modules/account/service/account_service.dart';
import '../../modules/wallet/security/wallet_security.dart';

/// 导入钱包页
///
/// 支持助记词导入和私钥导入两个 Tab 页签。
class WalletImportPage extends StatefulWidget {
  final String? password;
  const WalletImportPage({super.key, this.password});

  @override
  State<WalletImportPage> createState() => _WalletImportPageState();
}

/// 导入页面的提示项组件
class ImportTipItem extends StatelessWidget {
  final String? iconPath;
  final String text;
  final Color? textColor;
  final VoidCallback? onTap;

  const ImportTipItem({
    super.key,
    this.iconPath,
    required this.text,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (iconPath != null) ...[
          Image.asset(
            iconPath!,
            width: 16,
            height: 16,
            errorBuilder: (context, error, stackTrace) => Icon(
              iconPath!.contains('error')
                  ? Icons.error_outline
                  : Icons.help_outline,
              size: 14,
              color: textColor ?? AppColors.grey400,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: textColor ?? AppColors.grey400,
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );

    if (onTap != null) {
      content = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return Center(child: content);
  }
}

/// 导入页面的通用输入框组件
enum ImportInputState {
  none, // 未输入
  typing, // 输入中
  error, // 输入错误
}

class WalletImportInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ImportInputState state;
  final VoidCallback onPaste;

  const WalletImportInput({
    super.key,
    required this.controller,
    required this.hintText,
    required this.state,
    required this.onPaste,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    switch (state) {
      case ImportInputState.typing:
        borderColor = AppColors.grey900;
        break;
      case ImportInputState.error:
        borderColor = AppColors.error;
        break;
      case ImportInputState.none:
      default:
        borderColor = AppColors.grey200;
        break;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 70),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: TextField(
            controller: controller,
            maxLines: 6,
            style: AppTextStyles.body.copyWith(
              color: AppColors.grey900,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTextStyles.body.copyWith(
                color: AppColors.grey400,
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        // 粘贴按钮
        Positioned(
          bottom: -14,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: onPaste,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/wallet/word.png',
                      width: 16,
                      height: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.walletImportPaste,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grey900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletImportPageState extends State<WalletImportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _mnemonicController = TextEditingController();
  final TextEditingController _privateKeyController = TextEditingController();

  // 错误状态
  String? _mnemonicError;
  String? _privateKeyError;
  bool _isMnemonicInvalid = false;
  bool _isPrivateKeyInvalid = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    _mnemonicController.addListener(_validateMnemonic);
    _privateKeyController.addListener(_validatePrivateKey);

  }

  void _validateMnemonic() {
    if (!mounted) return;
    final isMnemonic = MnemonicService.validateMnemonic(_mnemonicController.text);
    setState(() {
      _mnemonicError = !isMnemonic ? '无效的助记词' : null;
      _isMnemonicInvalid = _mnemonicController.text.isNotEmpty && isMnemonic;
    });
  }

  void _validatePrivateKey() {
    if (!mounted) return;
    setState(() {
      final isPrivateKey = EvmService.isValidPrivateKey(_privateKeyController.text);
      setState(() {
        _privateKeyError = !isPrivateKey ? '无效的私钥' : null;
        _isPrivateKeyInvalid = _privateKeyController.text.isNotEmpty && isPrivateKey;
      });
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(() {});
    _mnemonicController.removeListener(_validateMnemonic);
    _privateKeyController.removeListener(_validatePrivateKey);
    _tabController.dispose();
    _mnemonicController.dispose();
    _privateKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AppPage(
      showNav: true,
      showBack: true,
      title: '',
      child: Stack(
        children: [
          // 1. 全屏背景网格图
          Positioned.fill(
            child: Image.asset(
              'assets/images/wallet/grid-bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. 页面内容
          Positioned.fill(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            // 顶部标题 - 导入钱包
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  loc.walletImportTitle.substring(
                                    0,
                                    loc.walletImportTitle.length - 2,
                                  ),
                                  style: AppTextStyles.h1.copyWith(
                                    fontSize: 24,
                                  ),
                                ),
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned(
                                      bottom: 4,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: 4,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    Text(
                                      loc.walletImportTitle.substring(
                                        loc.walletImportTitle.length - 2,
                                      ),
                                      style: AppTextStyles.h1.copyWith(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              loc.walletImportSubtitle,
                              style: AppTextStyles.body.copyWith(fontSize: 14),
                            ),
                            const SizedBox(height: 84),
                            // 3. TabBar 和内容区 (白色背景容器)
                            Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal: 16,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xffF5F5F5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Theme(
                                      data: ThemeData(
                                        useMaterial3: true,
                                        splashFactory: NoSplash.splashFactory,
                                        highlightColor: Colors.transparent,
                                      ),
                                      child: TabBar(
                                        controller: _tabController,
                                        dividerColor: Colors.transparent,
                                        indicator: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        labelColor: AppColors.grey900,
                                        unselectedLabelColor: AppColors.grey600,
                                        labelStyle: AppTextStyles.body.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                        unselectedLabelStyle: AppTextStyles.body
                                            .copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                        indicatorSize: TabBarIndicatorSize.tab,
                                        padding: const EdgeInsets.all(4),
                                        tabs: [
                                          Tab(text: loc.walletImportMnemonic),
                                          Tab(text: loc.walletImportPrivateKey),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // 4. 内容区：使用 IndexedStack 替代 TabBarView，解决固定高度问题
                                  IndexedStack(
                                    index: _tabController.index,
                                    children: [
                                      _buildMnemonicInput(loc),
                                      _buildPrivateKeyInput(loc),
                                    ],
                                  ),

                                  const SizedBox(height: 16),
                                  // 5. 底部导入按钮
                                  AppButton(
                                    text: loc.walletImportAction,
                                    onPressed: (_tabController.index == 0 ? _isMnemonicInvalid : _isPrivateKeyInvalid) ? () async {
                                      if (widget.password != null){
                                        try {
                                          AppLoading.show();
                                          await AccountService.creating(mnemonic: _tabController.index == 0 ?_mnemonicController.text : null,
                                              privateKey: _tabController.index == 1 ?_privateKeyController.text : null, password: widget.password!);
                                          AppLoading.dismiss();
                                          final result = await context.push('/wallet-setup');
                                          if (result == true) {
                                            context.go('/chat');
                                            return;
                                          }
                                          context.go('/chat');
                                          // GoRouter.of(context).pop();

                                        }catch(e){
                                          AppToast.show('导入钱包错误: $e');
                                        }
                                        return;
                                      }
                                      context.push('/wallet-import-password',  extra: {
                                        'mnemonic': _mnemonicController.text,
                                        'privateKey': _privateKeyController.text
                                      },);
                                    } : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建助记词输入界面
  Widget _buildMnemonicInput(AppLocalizations loc) {
    ImportInputState state = ImportInputState.none;
    if (_mnemonicController.text.isNotEmpty) {
      state = _mnemonicError != null
          ? ImportInputState.error
          : ImportInputState.typing;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WalletImportInput(
          controller: _mnemonicController,
          hintText: loc.walletImportMnemonicHint,
          state: state,
          onPaste: () async {
            final data = await Clipboard.getData(Clipboard.kTextPlain);
            if (data?.text != null) {
              _mnemonicController.text = data!.text!;
            }
          },
        ),
        const SizedBox(height: 27),
        // 动态提示区域
        Column(
          children: [
            // // 1. 未输入时的提示 (如何找回)
            // ImportTipItem(
            //   iconPath: 'assets/images/common/tips-normal-icon.png',
            //   text: loc.walletImportHowToFind,
            //   onTap: () {
            //     // TODO: 跳转帮助页
            //   },
            // ),
            const SizedBox(height: 8),
            // 2. 非英文提示
            ImportTipItem(text: loc.walletImportMnemonicNotEnglish),
            const SizedBox(height: 8),
            // 3. 错误提示 (单词数错误)
            _mnemonicError != null ? ImportTipItem(
              iconPath: 'assets/images/common/tips-error-icon.png',
              text: loc.walletImportMnemonicWordCountError,
              textColor: AppColors.error,
            ) : SizedBox(),
          ],
        ),
        // const SizedBox(height: 27),
        // // 外部云存储导入入口
        // Text(
        //   'iCLOUD/DROPBOX/GOOGLE DRIVE ${loc.walletImportCloud}',
        //   style: AppTextStyles.caption.copyWith(
        //     color: AppColors.grey700,
        //     fontWeight: FontWeight.w400,
        //     fontSize: 12,
        //   ),
        // ),
        const SizedBox(height: 24),
      ],
    );
  }

  /// 构建私钥输入界面
  Widget _buildPrivateKeyInput(AppLocalizations loc) {
    ImportInputState state = ImportInputState.none;
    if (_privateKeyController.text.isNotEmpty) {
      state = _privateKeyError != null
          ? ImportInputState.error
          : ImportInputState.typing;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WalletImportInput(
          controller: _privateKeyController,
          hintText: loc.walletImportPrivateKeyHint,
          state: state,
          onPaste: () async {
            final data = await Clipboard.getData(Clipboard.kTextPlain);
            if (data?.text != null) {
              _privateKeyController.text = data!.text!;
            }
          },
        ),
        const SizedBox(height: 27),
        // 动态提示区域
        Column(
          children: [
            // // 1. 未输入时的提示 (如何找回)
            // ImportTipItem(
            //   iconPath: 'assets/images/common/tips-normal-icon.png',
            //   text: loc.walletImportHowToFind,
            //   onTap: () {
            //     // TODO: 跳转帮助页
            //   },
            // ),
            // const SizedBox(height: 8),
            // 2. 错误提示
            _privateKeyError != null ? ImportTipItem(
              iconPath: 'assets/images/common/tips-error-icon.png',
              text: loc.walletImportPrivateKeyInvalidError,
              textColor: AppColors.error,
            ) : SizedBox(),
          ],
        ),
        const SizedBox(height: 27),
      ],
    );
  }
}
