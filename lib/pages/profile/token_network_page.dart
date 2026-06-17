import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/wallet/chains/service/nft_portfolio_service.dart';
import 'package:paracosm/modules/wallet/model/chain_account.dart';
import 'package:paracosm/modules/wallet/model/nft_asset_model.dart';
import 'package:paracosm/modules/wallet/model/token_model.dart';
import 'package:paracosm/modules/wallet/model/wallet_model.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/common/app_empty_view.dart';
import 'package:paracosm/widgets/common/app_network_image.dart';
import 'package:paracosm/widgets/modals/wallet_modals.dart';
import 'package:paracosm/widgets/wallet/nft_asset_tile.dart';

/// 代币网络详情页面
///
/// 展示指定网络下的钱包余额、操作按钮以及代币/NFT列表。
class TokenNetworkPage extends StatefulWidget {
  const TokenNetworkPage({super.key});

  @override
  State<TokenNetworkPage> createState() => _TokenNetworkPageState();
}

class _TokenNetworkPageState extends State<TokenNetworkPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final AccountManager _accountManager;
  bool _isBalanceVisible = true;

  WalletModel? _wallet;
  ChainAccount? _selectedNetwork;
  List<TokenModel> _tokens = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _accountManager = AccountManager();
    _accountManager.addListener(_loadCurrentChainTokens);
    _loadCurrentChainTokens();
  }

  @override
  void dispose() {
    _accountManager.removeListener(_loadCurrentChainTokens);
    _tabController.dispose();
    super.dispose();
  }

  void _loadCurrentChainTokens() {
    final wallet = _accountManager.currentWallet;
    final chain = wallet?.currentChain;
    final tokens = chain?.tokens.toList() ?? <TokenModel>[];
    tokens.sort((a, b) => b.balance.compareTo(a.balance));

    if (!mounted) return;
    setState(() {
      _wallet = wallet;
      _selectedNetwork = chain;
      _tokens = tokens;
    });
    if (wallet != null) {
      NftPortfolioService().start(wallet);
    }
  }

  void _showNetworkSelector() {
    final wallet = _wallet;
    if (wallet == null) return;

    WalletModals.showNetworkSelector(
      context: context,
      wallet: wallet,
      onSelected: (network) {
        final tokens = network.tokens.toList();
        tokens.sort((a, b) => b.balance.compareTo(a.balance));
        setState(() {
          _selectedNetwork = network;
          _tokens = tokens;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      // 使用 renderCustomHeader 实现自定义导航栏
      isCustomHeader: true,
      renderCustomHeader: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleSpacing: 0,
        leadingWidth: 60, // 20 (padding) + 32 (icon width) + 8 (extra)
        title: GestureDetector(
          onTap: _showNetworkSelector,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppNetworkImage(
                url: _selectedNetwork?.logo,
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Text(
                _selectedNetwork?.name ?? '',
                style: AppTextStyles.h2.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: AppColors.grey900,
              ),
            ],
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.only(left: 20),
          alignment: Alignment.centerLeft,
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Image.asset(
              'assets/images/common/back-icon.png',
              width: 32,
              height: 32,
            ),
            onPressed: () => context.pop(),
          ),
        ),
        // actions: [
        //   Padding(
        //     padding: const EdgeInsets.only(right: 20),
        //     child: IconButton(
        //       padding: EdgeInsets.zero,
        //       constraints: const BoxConstraints(),
        //       onPressed: () {
        //         // TODO: 跳转历史记录
        //       },
        //       icon: Image.asset(
        //         'assets/images/profile/clock.png',
        //         width: 24,
        //         height: 24,
        //       ),
        //     ),
        //   ),
        // ],
      ),
      backgroundColor: AppColors.white,
      child: Column(
        children: [
          // 1. 钱包卡片
          _buildWalletCard(),
          const SizedBox(height: 24),
          // 2. 标签栏
          _buildTabs(),
          // 3. 列表内容
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildTokenList(), _buildNftList()],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建钱包卡片 (复制自 token_detail_page.dart)
  Widget _buildWalletCard({
    bool showActions = true,
    EdgeInsetsGeometry margin = const EdgeInsets.only(
      top: 16,
      left: 20,
      right: 20,
      bottom: 24,
    ),
    VoidCallback? onEyeTap,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final walletName =
        _wallet?.name ??
        '${l10n.profileProfileDetailsWallet} ${(_wallet?.aIndex ?? 0) + 1}';
    final totalUsd = _tokens.fold<double>(
      0,
      (sum, token) => sum + token.usdValue,
    );

    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 钱包名称
              Row(
                children: [
                  Text(
                    walletName,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.grey400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 余额数值及显隐切换按钮
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _isBalanceVisible
                  ? Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '\$',
                            style: AppTextStyles.h1.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                          const WidgetSpan(child: SizedBox(width: 2)),
                          TextSpan(
                            text: totalUsd.toStringAsFixed(2),
                            style: AppTextStyles.h1.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Transform.translate(
                      offset: const Offset(0, 4),
                      child: Text(
                        '********',
                        style: AppTextStyles.h1.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                    ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() => _isBalanceVisible = !_isBalanceVisible);
                  onEyeTap?.call();
                },
                child: Image.asset(
                  _isBalanceVisible
                      ? 'assets/images/common/eye-line.png'
                      : 'assets/images/common/eye-off-line.png',
                  width: 20,
                  height: 20,
                ),
              ),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                // Send 按钮
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      context.push(
                        '/transfer',
                        extra: {'chain': _selectedNetwork},
                      );
                    },
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.grey900, // 深黑色背景
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(width: 6),
                          Image.asset(
                            'assets/images/profile/send.png',
                            width: 32,
                            height: 32,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.profileTokenNetworkSend,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Receive 按钮
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      context.push(
                        '/token-receive',
                        extra: {
                          'symbol': _selectedNetwork?.symbol,
                          'network': _selectedNetwork?.name,
                          'address': _selectedNetwork?.address,
                          'logo': _selectedNetwork?.logo,
                          'chainId': _selectedNetwork?.chainId,
                        },
                      );
                    },
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: AppColors.grey900,
                          width: 1,
                        ), // 黑色边框
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(width: 6),
                          Image.asset(
                            'assets/images/profile/receive.png',
                            width: 32,
                            height: 32,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.profileTokenNetworkReceive,
                            style: TextStyle(
                              color: AppColors.grey900,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 构建标签栏
  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerLeft,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppColors.grey900,
        unselectedLabelColor: AppColors.grey400,
        labelStyle: AppTextStyles.body.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.body.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        indicator: _FixedUnderlineIndicator(
          width: 12,
          height: 3,
          color: AppColors.primary,
          borderRadius: 19,
        ),
        dividerColor: Colors.transparent,
        tabAlignment: TabAlignment.start,
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        tabs: [
          Tab(text: AppLocalizations.of(context)!.profileTokenNetworkTokens),
          Tab(text: AppLocalizations.of(context)!.profileTokenNetworkNfts),
        ],
      ),
    );
  }

  /// 构建代币列表
  Widget _buildTokenList() {
    if (_tokens.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.profileTokenNetworkNoTokens,
          style: AppTextStyles.body.copyWith(
            fontSize: 14,
            color: AppColors.grey500,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _tokens.length,
      itemBuilder: (context, index) {
        final token = _tokens[index];
        return GestureDetector(
          onTap: () => context.push('/token-detail', extra: token),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.grey200, width: 1),
            ),
            child: Row(
              children: [
                // 代币图标 (叠加网络小图标)
                Stack(
                  children: [
                    AppNetworkImage(
                      url: token.logo,
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                        ),
                        child: AppNetworkImage(
                          url: _selectedNetwork?.logo,
                          width: 16,
                          height: 16,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // 代币名称
                Text(
                  token.symbol,
                  style: AppTextStyles.h2.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey900,
                  ),
                ),
                const Spacer(),
                // 余额信息
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      token.showBalance,
                      style: AppTextStyles.h2.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${token.showUsdValue}',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 12,
                        color: AppColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNftList() {
    return StreamBuilder<List<NftAssetModel>>(
      stream: NftPortfolioService().stream,
      initialData: NftPortfolioService().currentAssets,
      builder: (context, snapshot) {
        final chain = _selectedNetwork;
        final nfts = (snapshot.data ?? const <NftAssetModel>[])
            .where((asset) => chain == null || asset.chainId == chain.chainId)
            .where((asset) => !asset.isSpam && !asset.isHidden)
            .toList();
        if (nfts.isEmpty) {
          return AppEmptyView(
            text: AppLocalizations.of(context)!.profileTokenNetworkNoNft,
            imageSize: 96,
            bottomOffset: 24,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: nfts.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final asset = nfts[index];
            return NftAssetTile(
              asset: asset,
              networkLogo: chain?.logo,
              onTap: () => context.push('/nft-detail', extra: asset),
            );
          },
        );
      },
    );
  }
}

/// 固定宽度的下划线指示器
class _FixedUnderlineIndicator extends Decoration {
  final double width;
  final double height;
  final Color color;
  final double borderRadius;

  const _FixedUnderlineIndicator({
    this.width = 12,
    this.height = 3,
    this.color = AppColors.primary,
    this.borderRadius = 19,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _FixedUnderlinePainter(this, onChanged);
  }
}

class _FixedUnderlinePainter extends BoxPainter {
  final _FixedUnderlineIndicator decoration;

  _FixedUnderlinePainter(this.decoration, VoidCallback? onChanged)
    : super(onChanged);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Rect rect = offset & configuration.size!;
    final double x = rect.center.dx - decoration.width / 2;
    final double y = rect.bottom - decoration.height;
    final Rect indicator = Rect.fromLTWH(
      x,
      y,
      decoration.width,
      decoration.height,
    );
    final Paint paint = Paint()..color = decoration.color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        indicator,
        Radius.circular(decoration.borderRadius),
      ),
      paint,
    );
  }
}
