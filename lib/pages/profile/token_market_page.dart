import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:k_chart_plus/k_chart_plus.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/base/app_localizations.dart';
import '../../widgets/base/app_page.dart';

/// 代币市场/K线页面 (Token Market Page)
class TokenMarketPage extends StatefulWidget {
  final String symbol;

  const TokenMarketPage({super.key, required this.symbol});

  @override
  State<TokenMarketPage> createState() => _TokenMarketPageState();
}

class _TokenMarketPageState extends State<TokenMarketPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<KLineEntity> datas = [];
  bool showLoading = true;

  MainState? _mainState = MainState.MA;
  Set<SecondaryState> _secondaryStates = {SecondaryState.MACD};
  bool _volHidden = false;

  bool isLine = false;
  bool isChinese = true;
  bool _isHide = false;
  List<DepthEntity> _bids = [], _asks = [];

  ChartStyle chartStyle = ChartStyle();
  ChartColors chartColors = ChartColors();

  // 当前选择的时间周期
  String _selectedInterval = '15m';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    // 初始化图表颜色和样式
    chartColors = ChartColors(
      bgColor: AppColors.white,
      upColor: AppColors.success,
      dnColor: AppColors.error,
      volColor: AppColors.grey400,
      ma5Color: AppColors.primary,
      ma10Color: Colors.orange,
      ma30Color: Colors.blue,
    );

    // 配置图表样式
    chartStyle = ChartStyle();
    chartStyle.topPadding = 30.0;
    chartStyle.bottomPadding = 20.0;
    chartStyle.childPadding = 25.0;

    _initData();
  }

  void _initData() {
    // 模拟数据初始化
    // 在实际项目中，这里会从后端或 API 获取 K 线数据
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      final List<KLineEntity> list = [];
      // 简单生成一些模拟数据
      double lastPrice = 63000;
      for (int i = 0; i < 100; i++) {
        double open = lastPrice + (i % 5 == 0 ? -200 : 100);
        double close = open + (i % 3 == 0 ? 300 : -150);
        double high = (open > close ? open : close) + 100;
        double low = (open < close ? open : close) - 100;
        double vol = 100.0 + i * 5;

        KLineEntity entity = KLineEntity.fromJson({
          "open": open,
          "close": close,
          "high": high,
          "low": low,
          "vol": vol,
          "amount": vol * close,
          "time":
              DateTime.now().millisecondsSinceEpoch -
              (100 - i) * 15 * 60 * 1000,
        });
        list.add(entity);
        lastPrice = close;
      }

      // 计算技术指标
      DataUtil.calculate(list);

      if (mounted) {
        setState(() {
          datas = list;
          showLoading = false;
        });
      }
    });
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
      backgroundColor: AppColors.white,
      isCustomHeader: true,
      renderCustomHeader: _buildCustomHeader(context),

      child: Column(
        children: [
          _buildIntervalBar(),
          const Divider(height: 1, color: AppColors.grey100),
          _buildKLineChart(),
          _buildIndicatorBar(),
          const Divider(height: 1, color: AppColors.grey100),
          const SizedBox(height: 16),
          _buildTabs(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
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

  /// 构建自定义导航栏
  Widget _buildCustomHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.only(top: topPadding),
      child: SizedBox(
        height: kToolbarHeight,
        child: Row(
        children: [
          // IconButton(
          //   icon: Image.asset(
          //     'assets/images/common/back-icon.png',
          //     width: 32,
          //     height: 32,
          //   ),
          //   onPressed: () => context.pop(),
          // ),
          const SizedBox(width: 20),
          _buildHeaderTitle(),
          const Spacer(),
          IconButton(
            icon: Image.asset(
              'assets/images/profile/change.png',
              width: 32,
              height: 32,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: Image.asset(
              'assets/images/profile/more.png',
              width: 32,
              height: 32,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 20),
        ],
        ),
      ),
    );
  }

  /// 构建代币概览
  Widget _buildTokenOverview() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200, width: 1),
      ),
      child: Column(
        children: [
          // 代币图标和基本信息
         Row(
              children: [
                Image.asset(
                  'assets/images/profile/bnb-small.png',
                  fit: BoxFit.contain,
                  width: 48,
                  height: 48,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.symbol.split('/').first,
                      style: AppTextStyles.h2.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Binancestry(BSC)',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14,
                        color: AppColors.grey400,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
         ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.grey200),
          const SizedBox(height: 16),
          // Total Issue
          _buildOverviewItem(
            title: AppLocalizations.of(context)!.profileTokenMarketTotalIssue,
            value: AppLocalizations.of(context)!.profileTokenMarketUnknown,
          ),
          const SizedBox(height: 16),

          // Contract Address
          _buildOverviewItem(
            title: AppLocalizations.of(context)!.profileTokenMarketContractAddress,
            value: '0xc84sa01ua125d15uvcbv78fa98uu9daccf915uvc',
            showCopy: true,
          ),
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

  /// 构建历史记录列表
  Widget _buildHistoryList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        bool isSend = index % 2 == 0;
        return Container(
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
                          '0x5E4F...1EE4',
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
                      '20:10:59 2025-04-22',
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
                '${isSend ? '-' : '+'}\$250.00',
                style: AppTextStyles.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSend ? AppColors.error : AppColors.primaryDark,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建顶部标题区域
  Widget _buildHeaderTitle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.symbol == 'BTC/USDT' ? 'BTC/USDT' : '${widget.symbol}/USDT',
          style: AppTextStyles.h1.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.grey900,
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.arrow_drop_down, size: 22, color: AppColors.grey900),
        const SizedBox(width: 12),
        Text(
          '-0.12%',
          style: AppTextStyles.body.copyWith(
            fontSize: 12,
            color: AppColors.error,
          ),
        ),
      ],
    );
  }

  /// 构建时间周期选择栏
  Widget _buildIntervalBar() {
    final intervals = ['Time', '15m', '1h', '4h', '1D', 'More'];
    final intervalLabels = {
      'Time': AppLocalizations.of(context)!.profileTokenMarketTime,
      'More': AppLocalizations.of(context)!.profileTokenMarketMore,
    };

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...intervals.map(
                    (item) => GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedInterval = item;
                          isLine = (item == 'Time');
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          intervalLabels[item] ?? item,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 14,
                            fontWeight: _selectedInterval == item
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: _selectedInterval == item
                                ? AppColors.primary
                                : AppColors.grey400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _isHide = !_isHide;
              });
            },
            child: Row(
              children: [
                Text(
                  _isHide
                      ? AppLocalizations.of(context)!.profileTokenMarketShow
                      : AppLocalizations.of(context)!.profileTokenMarketHide,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12,
                    color: AppColors.grey800,
                  ),
                ),
                Icon(
                  _isHide ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                  size: 16,
                  color: AppColors.grey400,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建 K 线图
  Widget _buildKLineChart() {
    return Container(
      height: 400,
      width: double.infinity,
      child: showLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : KChartWidget(
              datas,
              chartStyle,
              chartColors,
              isTrendLine: false,
              isLine: isLine,
              mainStateLi: _mainState == null ? {} : {_mainState!},
              secondaryStateLi: _secondaryStates,
              volHidden: _volHidden,
              fixedLength: 2,
            ),
    );
  }

  /// 构建指标选择栏
  Widget _buildIndicatorBar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildIndicatorItem('MA', _mainState == MainState.MA, () {
            setState(() => _mainState = MainState.MA);
          }),
          _buildIndicatorItem('BOLL', _mainState == MainState.BOLL, () {
            setState(() => _mainState = MainState.BOLL);
          }),
          _buildIndicatorItem(
              AppLocalizations.of(context)!.profileTokenMarketNone,
              _mainState == null, () {
            setState(() => _mainState = null);
          }),
          const VerticalDivider(
            width: 20,
            indent: 10,
            endIndent: 10,
            color: AppColors.grey200,
          ),
          _buildIndicatorItem(
            'MACD',
            _secondaryStates.contains(SecondaryState.MACD),
            () {
              setState(() {
                if (_secondaryStates.contains(SecondaryState.MACD)) {
                  _secondaryStates.remove(SecondaryState.MACD);
                } else {
                  _secondaryStates.add(SecondaryState.MACD);
                }
              });
            },
          ),
          _buildIndicatorItem(
              AppLocalizations.of(context)!.profileTokenMarketNone,
              _secondaryStates.isEmpty, () {
            setState(() {
              _secondaryStates.clear();
            });
          }),
          _buildIndicatorItem(
            'KDJ',
            _secondaryStates.contains(SecondaryState.KDJ),
            () {
              setState(() {
                if (_secondaryStates.contains(SecondaryState.KDJ)) {
                  _secondaryStates.remove(SecondaryState.KDJ);
                } else {
                  _secondaryStates.add(SecondaryState.KDJ);
                }
              });
            },
          ),
          _buildIndicatorItem(
            'RSI',
            _secondaryStates.contains(SecondaryState.RSI),
            () {
              setState(() {
                if (_secondaryStates.contains(SecondaryState.RSI)) {
                  _secondaryStates.remove(SecondaryState.RSI);
                } else {
                  _secondaryStates.add(SecondaryState.RSI);
                }
              });
            },
          ),
          _buildIndicatorItem(
            'WR',
            _secondaryStates.contains(SecondaryState.WR),
            () {
              setState(() {
                if (_secondaryStates.contains(SecondaryState.WR)) {
                  _secondaryStates.remove(SecondaryState.WR);
                } else {
                  _secondaryStates.add(SecondaryState.WR);
                }
              });
            },
          ),
          const VerticalDivider(
            width: 20,
            indent: 10,
            endIndent: 10,
            color: AppColors.grey200,
          ),
          _buildIndicatorItem('VOL', !_volHidden, () {
            setState(() => _volHidden = !_volHidden);
          }),
        ],
      ),
    );
  }

  Widget _buildIndicatorItem(
    String title,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          title,
          style: AppTextStyles.body.copyWith(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.primary : AppColors.grey400,
          ),
        ),
      ),
    );
  }

  /// 构建标签栏 (从 TokenDetailPage 复制)
  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerLeft,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppColors.grey900,
        unselectedLabelColor: AppColors.grey400,
        indicatorColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        labelStyle: AppTextStyles.body.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.body.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(width: 3, color: AppColors.primary),
          borderRadius: BorderRadius.circular(19),
          insets: const EdgeInsets.symmetric(horizontal: 40),
        ),
        dividerColor: Colors.transparent,
        tabAlignment: TabAlignment.start,
        indicatorSize: TabBarIndicatorSize.label,
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        tabs: [
          Tab(text: AppLocalizations.of(context)!.profileTokenMarketTransferHistory),
          Tab(text: AppLocalizations.of(context)!.profileTokenMarketTokenOverview),
        ],
      ),
    );
  }
}
