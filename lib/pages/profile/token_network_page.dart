import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';

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
  bool _isBalanceVisible = true;

  Map<String, dynamic> _selectedNetwork = {
    'name': 'BNB Chain',
    'symbol': 'BNB',
    'icon': 'bnb-small.png',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/profile/${_selectedNetwork['icon']}',
              width: 20,
              height: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _selectedNetwork['name'],
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                // TODO: 跳转历史记录
              },
              icon: Image.asset(
                'assets/images/profile/clock.png',
                width: 24,
                height: 24,
              ),
              
            ),
          ),
        ],
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
              children: [
                _buildTokenList(),
                Center(
                  child: Text(
                    AppLocalizations.of(context)!.profileTokenNetworkNoNft,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      color: AppColors.grey500,
                    ),
                  ),
                ),
              ],
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
                    'Wallet No. 1',
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
                            text: '7,859,942.00',
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
                      context.push('/transfer', extra: _selectedNetwork);
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
                          const Text(
                            'Send',
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
                          'symbol': 'ETH',
                          'network': 'Ethereum',
                          'address':
                              '0xc84sa01ua125d15uvcbv78fa98uu9daccf915uvc',
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
                          const Text(
                            'Receive',
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
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: 2,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _showTokenDetail(context),
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
                    Image.asset(
                      'assets/images/profile/eth-icon.png',
                      width: 44,
                      height: 44,
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
                        child: Image.asset(
                          'assets/images/profile/eth-icon.png',
                          width: 16,
                          height: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // 代币名称
                Text(
                  'ETH',
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
                      '0',
                      style: AppTextStyles.h2.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$0',
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

  /// 显示代币详情弹窗
  void _showTokenDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            top: 12,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部指示条
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 12),
              // 顶部工具栏 (浏览器 & 关闭)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      // TODO: 跳转浏览器查看
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(60),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/common/network.png',
                            width: 12,
                            height: 12,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Go to the browser to check',
                            style: AppTextStyles.body.copyWith(
                              fontSize: 10,
                              color: AppColors.grey900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const SizedBox(
                    height: 20,
                    child: VerticalDivider(width: 1, color: AppColors.grey200),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      size: 24,
                      color: AppColors.grey700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.grey100),
              const SizedBox(height: 40),
              // 代币图标 (大)
              Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/images/profile/eth-icon.png',
                    width: 68,
                    height: 68,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        'assets/images/profile/eth-icon.png',
                        width: 20,
                        height: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 余额
              Text(
                '0',
                style: AppTextStyles.h1.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '≈ \$0',
                style: AppTextStyles.body.copyWith(
                  fontSize: 14,
                  color: AppColors.grey400,
                ),
              ),
              const SizedBox(height: 24),
              // 操作按钮 (Send, Receive, Message)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: 'assets/images/profile/send.png',
                    label: AppLocalizations.of(context)!.profileTokenNetworkSend,
                    onTap: () {
                      context.push('/transfer', extra: _selectedNetwork);
                    },
                  ),
                  _buildActionButton(
                    icon: 'assets/images/profile/receive.png',
                    label: AppLocalizations.of(context)!.profileTokenNetworkReceive,
                    onTap: () {
                      context.push('/receive', extra: _selectedNetwork);
                    },
                  ),
                  _buildActionButton(
                    icon: 'assets/images/profile/swap.png',
                    label: AppLocalizations.of(context)!.profileTokenNetworkSwap,
                    onTap: () {},
                  ),
                  _buildActionButton(
                    icon: 'assets/images/profile/bridge.png',
                    label: AppLocalizations.of(context)!.profileTokenNetworkBridge,
                    onTap: () {},
                  ),
                  _buildActionButton(
                    icon: 'assets/images/profile/buy.png',
                    label: AppLocalizations.of(context)!.profileTokenNetworkBuy,
                    onTap: () {},
                  ),
                  _buildActionButton(
                    icon: 'assets/images/profile/sell.png',
                    label: AppLocalizations.of(context)!.profileTokenNetworkSell,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: AppColors.grey100),
              const SizedBox(height: 16),
              // 当前价格
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/images/common/money.png',
                    width: 16,
                    height: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'Current price',
                              style: AppTextStyles.body.copyWith(
                                fontSize: 14,
                                color: AppColors.grey900,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '\$0',
                              style: AppTextStyles.body.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: AppColors.grey400,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: AppColors.grey200),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  /// 构建弹窗中的操作按钮
  Widget _buildActionButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child:Image.asset(icon, width: 48, height: 48)
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.grey800,
          ),
        ),
      ],
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
