import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paracosm/modules/wallet/chains/evm/evm_service.dart';
import 'package:paracosm/modules/wallet/model/chain_account.dart';
import 'package:paracosm/modules/wallet/service/mnemonic_service.dart';
import 'package:paracosm/modules/wallet/service/wallet_service.dart';
import 'package:paracosm/pages/wallet/wallet_import_page.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/common/app_button.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/widgets/common/app_toast.dart';

class WalletImportPrivateKeyPage extends StatefulWidget {
  final String password;
  final String walletId;
  final ChainType chainType;
  const WalletImportPrivateKeyPage({super.key, required this.password, required this.walletId, required this.chainType});

  @override
  State<WalletImportPrivateKeyPage> createState() => _WalletImportPrivateKeyPageState();
}

class _WalletImportPrivateKeyPageState extends State<WalletImportPrivateKeyPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _privateKeyController = TextEditingController();

  // 错误状态
  String? _privateKeyError;
  bool _isPrivateKeyInvalid = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    _privateKeyController.addListener(_validatePrivateKey);

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
    _privateKeyController.removeListener(_validatePrivateKey);
    _tabController.dispose();
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
                              '请通过私钥导入您的钱包',
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
                                          Tab(text: loc.walletImportPrivateKey),
                                          Tab(text: ''),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // 4. 内容区：使用 IndexedStack 替代 TabBarView，解决固定高度问题
                                  IndexedStack(
                                    index: _tabController.index,
                                    children: [
                                      _buildPrivateKeyInput(loc),
                                    ],
                                  ),

                                  const SizedBox(height: 16),
                                  // 5. 底部导入按钮
                                  AppButton(
                                    text: loc.walletImportAction,
                                    onPressed: ( _isPrivateKeyInvalid) ? () async {
                                      try {
                                        await WalletService.importPrivateKeyByChainType(
                                            privateKey: _privateKeyController.text,
                                            password: widget.password,
                                            walletId: widget.walletId,
                                            chainType: widget.chainType
                                        );
                                        context.push('/chat');
                                      }catch(e){
                                        AppToast.show('导入钱包错误: $e');
                                      }
                                      return;
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
