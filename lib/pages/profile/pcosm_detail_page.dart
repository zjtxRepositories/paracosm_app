import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';

/// pCOSM 详情页面
class PcosmDetailPage extends StatefulWidget {
  const PcosmDetailPage({super.key});

  @override
  State<PcosmDetailPage> createState() => _PcosmDetailPageState();
}

class _PcosmDetailPageState extends State<PcosmDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
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
      showNav: false, // 隐藏默认导航栏以使背景图延伸
      title: '',
      backgroundColor: AppColors.grey100,
      child: Stack(
        children: [
          // 顶部背景图
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/profile/pcosm-bg.png',
              fit: BoxFit.cover,
              height: 160,
              errorBuilder: (context, error, stackTrace) =>
                  Container(height: 160, color: AppColors.grey100),
            ),
          ),
          // 自定义返回按钮
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Image.asset('assets/images/common/back-icon.png',width: 32,height: 32,),
            ),
          ),
          // 内容区域
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 84),
              _buildAssetCard(),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildTabs(),
                      Expanded(child: _buildHistoryList()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建资产卡片
  Widget _buildAssetCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200.withOpacity(0.5), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.profilePcosmDetailTotalAssets,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    color: AppColors.grey600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '0',
                      style: AppTextStyles.h1.copyWith(
                        fontSize: 27,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'pCOSM',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 14,
                        color: AppColors.grey900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.profilePcosmDetailAvailableAssets,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14,
                        color: AppColors.grey600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '0',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建标签栏 (复制自 TokenDetailPage)
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
        indicator: const _FixedUnderlineIndicator(),
        dividerColor: Colors.transparent,
        tabAlignment: TabAlignment.start,
        tabs: [
          Tab(text: AppLocalizations.of(context)!.profilePcosmDetailAll),
          Tab(text: AppLocalizations.of(context)!.profilePcosmDetailIncome),
          Tab(text: AppLocalizations.of(context)!.profilePcosmDetailSpending),
        ],
      ),
    );
  }

  /// 构建历史记录列表 (复制自 TokenDetailPage)
  Widget _buildHistoryList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: 4,
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
                          '0X5E4F...1EE4',
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
}

/// 固定宽度的下划线指示器 (Fixed-width Underline Indicator)
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
