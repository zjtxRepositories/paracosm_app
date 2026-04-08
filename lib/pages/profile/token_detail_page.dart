import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/core/util/string_util.dart';
import 'package:paracosm/modules/wallet/model/token_model.dart';
import 'package:paracosm/modules/wallet/service/block_chain_service.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_modal.dart';
import 'package:paracosm/widgets/common/app_network_selector.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';

import '../../modules/wallet/model/trade_model.dart';

/// 代币详情页面 (Token Detail Page)
class TokenDetailPage extends StatefulWidget {
  final TokenModel token;

  const TokenDetailPage({
    super.key,
    required this.token,
  });

  @override
  State<TokenDetailPage> createState() => _TokenDetailPageState();
}

class _TokenDetailPageState extends State<TokenDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isBalanceVisible = true;
  List<TradeModel> _list = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    load();
  }
  Future<void> load() async {
    final chain = widget.token.getChain();
    if (chain == null) return;
    setState(() {
      _isLoading = true; // 开始加载
    });
    try {
      final result = await BlockChainService().getTokenTransactions(
          chain, chain.address, contractAddress: widget.token.address);
      setState(() {
        _list = result;
      });
    } catch (e) {
      // 可以加个提示
      print("获取交易记录失败: $e");
    } finally {
      setState(() {
        _isLoading = false; // 结束加载
      });
    }


  }
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      showNav: true,
      title: widget.token.name,
      backgroundColor: AppColors.white,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildWalletCard(),
                  const SizedBox(height: 24),
                  _buildTabs(),
                  _tabController.index == 0
                      ? _buildHistoryList()
                      : _buildTokenOverview(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 复制自 ProfilePage 的钱包卡片构建方法 (L135-329)
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
                    '资产',
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
                            text: widget.token.displayBalance,
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
                      context.push('/transfer', extra: {
                        'token':widget.token
                      });
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
                          'symbol': widget.token.symbol,
                          'network': widget.token.name,
                          'address': widget.token.showAddress,
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
        indicator: const _FixedUnderlineIndicator(
          width: 12,
          height: 3,
          color: AppColors.primary,
          borderRadius: 19,
        ),
        dividerColor: Colors.transparent,
        tabAlignment: TabAlignment.start,
        tabs: const [
          Tab(text: 'Transfer History'),
          Tab(text: 'Token Overview'),
        ],
      ),
    );
  }

  /// 构建历史记录列表
  Widget _buildHistoryList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount:_list.length,
      itemBuilder: (context, index) {
        final model = _list[index];
        bool isSend = model.direction == TradeDirection.sell;
        final amount =
            '${model.direction == TradeDirection.buy ? '+' : '-'}${formatTrim(model.amount)}';
        final address =
        model.direction == TradeDirection.buy ? (model.from ?? '') : (model.to ?? '');
        return GestureDetector(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey200, width: 1),
            ),
            child: Row(
              children: [
                Image.asset(
                  isSend
                      ? 'assets/images/profile/send-history.png'
                      : 'assets/images/profile/receive-history.png',
                  width: 48,
                  height: 48,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                           ellipsisMiddle(address),
                            style: AppTextStyles.body.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey900,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Image.asset(
                            'assets/images/common/copy-grey.png',
                            width: 16,
                            height: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatTimeAgo(model.time),
                        style: AppTextStyles.body.copyWith(
                          fontSize: 12,
                          color: AppColors.grey600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  amount,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSend ? AppColors.error : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建代币概览
  Widget _buildTokenOverview() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey200, width: 1),
      ),
      child: Column(
        children: [
          // 代币图标和基本信息
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => context.push('/token-network'),
                  child: Image.asset(
                    'assets/images/profile/bnb-small.png',
                    fit: BoxFit.contain,
                    width: 48,
                    height: 48,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.token.symbol,
                  style: AppTextStyles.h2.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey900,
                  ),
                ),
                // const SizedBox(height: 2),
                // Text(
                //   'Binancestry(BSC)',
                //   style: AppTextStyles.body.copyWith(
                //     fontSize: 14,
                //     color: AppColors.grey400,
                //     fontWeight: FontWeight.w400,
                //   ),
                // ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildOverviewItem(
            title: AppLocalizations.of(context)!.profileTokenDetailTotalIssue,
            value: 'unknown',
          ),
          const SizedBox(height: 24),
          widget.token.address.isNotEmpty ? _buildOverviewItem(
            title: AppLocalizations.of(context)!.profileTokenDetailContractAddress,
            value: widget.token.address,
            showCopy: true,
          ) : SizedBox(),
        ],
      ),
    );
  }

  /// 构建概览详情项
  Widget _buildOverviewItem({
    required String title,
    required String value,
    bool showCopy = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                color: AppColors.grey600,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (showCopy)
              Image.asset(
                'assets/images/common/copy-grey.png',
                width: 20,
                height: 20,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.grey900,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

/// 固定宽度的下划线指示器 (Fixed-width Underline Tab Indicator)
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

/// 固定宽度的下划线指示器绘制器 (Fixed-width Underline Painter)
class _FixedUnderlinePainter extends BoxPainter {
  final _FixedUnderlineIndicator decoration;

  _FixedUnderlinePainter(this.decoration, VoidCallback? onChanged)
    : super(onChanged);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Rect rect = offset & configuration.size!;
    // 计算居中位置 (Calculate center position)
    final double x = rect.center.dx - decoration.width / 2;
    // 计算底部对齐位置 (Calculate bottom alignment)
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
