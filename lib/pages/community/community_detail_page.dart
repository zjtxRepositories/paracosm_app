import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_localizations_keys.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_button.dart';
import 'package:paracosm/widgets/common/app_modal.dart';
import 'package:paracosm/widgets/common/app_search_input.dart';

/// 社区详情页
/// 展示社区背景图、基本信息、成员列表以及 Tab 分类内容
class CommunityDetailPage extends StatefulWidget {
  final String communityName;

  const CommunityDetailPage({super.key, this.communityName = 'BKOK持仓群'});

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 延迟初始化 TabController，因为需要 context 来获取 tabs 长度
    _tabController = TabController(length: 3, vsync: this);
    // 添加监听器以触发页面重绘，从而更新下方内容列表
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
    final l10n = AppLocalizations.of(context)!;
    final List<String> tabs = [
      l10n.communityDetailTabDashboard,
      l10n.communityDetailTabAsset,
      l10n.communityDetailTabPick
    ];

    return AppPage(
      showNav: true,
      isCustomHeader: true,
      renderCustomHeader: _buildCustomHeader(context),
      extendBodyBehindAppBar: true,
      navBackgroundColor: Colors.transparent,
      child: Stack(
        children: [
          // 1. 全屏背景图
          Positioned.fill(
            child: Image.asset(
              'assets/images/community/dao-bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. 页面主内容
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部占位，确保背景图可见
                  const SizedBox(height: 140),

                  // 将所有内容包装在一个白色背景的容器中
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 140,
                    ),
                    decoration: const BoxDecoration(color: AppColors.white),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. 社区基本信息区域
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1.1 头像与 Join 按钮
                              _buildAvatarAndJoinAction(context, l10n),
                              const SizedBox(height: 16),
                              // 1.2 社区标题与地址
                              _buildCommunityTitleAndAddress(),
                              const SizedBox(height: 8),
                              // 1.3 社区描述
                              _buildDescription(l10n),
                              const SizedBox(height: 8),
                              // 1.4 社区标签
                              _buildTags(l10n),
                              const SizedBox(height: 12),
                              // 1.5 成员信息 (包含头像叠加)
                              _buildMemberInfo(l10n),
                              const SizedBox(height: 16),
                              const Divider(
                                height: 1,
                                color: AppColors.grey200,
                              ),
                            ],
                          ),
                        ),

                        // 2. Tab 分类区域
                        _buildTabBar(tabs),

                        // 3. 内容列表
                        _buildContentList(l10n),
                      ],
                    ),
                  ),
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
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 返回按钮
          GestureDetector(
            onTap: () => context.pop(),
            child: Image.asset(
              'assets/images/community/back.png',
              width: 32,
              height: 32,
            ),
          ),
          // 分享按钮
          GestureDetector(
            onTap: () {},
            child: Image.asset(
              'assets/images/community/share.png',
              width: 32,
              height: 32,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建头像及加入按钮
  Widget _buildAvatarAndJoinAction(BuildContext context, AppLocalizations l10n) {
    // 根据 Tab 动态切换按钮文字和样式
    final bool isPickTab = _tabController.index == 2;

    return SizedBox(
      height: 64, // 占位高度，决定了下方内容（标题）的垂直位置
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 社区头像 (2x2 网格)
          Positioned(
            top: -16, // 向上偏移半个头像的高度
            left: 0,
            child: _buildGridAvatar(),
          ),
          // 动态按钮 (Join 或 Chat)
          Positioned(
            bottom: 16,
            right: 0,
            child: isPickTab
                ? AppButton(
                    text: l10n.communityDetailBtnChat,
                    onPressed: () {},
                    width: 100,
                    height: 32,
                    borderRadius: 32,
                    backgroundColor: AppColors.white,
                    textColor: AppColors.grey900,
                    border: const BorderSide(color: AppColors.grey200, width: 1),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  )
                : AppButton(
                    text: l10n.communityDetailBtnJoin,
                    onPressed: () {},
                    width: 85,
                    height: 28,
                    borderRadius: 28,
                    backgroundColor: AppColors.grey900,
                    textColor: AppColors.white,
                    fontSize: 12,
                  ),
          ),
        ],
      ),
    );
  }

  /// 构建 2x2 网格头像 (参考 community_page.dart _buildGroupAvatar 优化)
  Widget _buildGridAvatar() {
    return SizedBox(
      width: 64, // 详情页展示，适当加大
      height: 64,
      // padding: const EdgeInsets.all(3), // 外部白色描边宽度
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        padding: EdgeInsets.zero, // 修复：必须设置 padding 为 zero，否则显示不全
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(4, (index) {
          return Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(7),
            ),
            child: ClipRRect(
              // borderRadius: BorderRadius.circular(7),
              child: Image.asset(
                'assets/images/chat/avatar.png',
                fit: BoxFit.cover,
              ),
            ),
          );
        }),
      ),
    );
  }

  /// 构建社区名称及地址
  Widget _buildCommunityTitleAndAddress() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.communityName,
              style: AppTextStyles.h1.copyWith(
                fontSize: 20, // 根据 UI 调整
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(width: 8),
            // 地址展示芯片
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.grey200, width: 1),
                borderRadius: BorderRadius.circular(61),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/common/copy-black.png',
                    width: 12,
                    height: 12,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    l10n.communityMockAddressDetail,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 10,
                      color: AppColors.grey900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建社区描述
  Widget _buildDescription(AppLocalizations l10n) {
    return Text(
      l10n.communityDetailMockDesc,
      style: AppTextStyles.body.copyWith(
        fontSize: 12,
        color: AppColors.grey400, // 稍微加深一点颜色
        height: 1.5,
      ),
    );
  }

  /// 构建标签列表
  Widget _buildTags(AppLocalizations l10n) {
    final tags = [
      l10n.filterTagAirdrop,
      l10n.filterTagMeme,
      l10n.filterTagGiveaway
    ];
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grey200, width: 1),
          ),
          child: Text(
            tag,
            style: AppTextStyles.body.copyWith(
              fontSize: 10,
              color: AppColors.grey400, // 调整标签文字颜色
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 构建成员信息区域 (头像叠放)
  Widget _buildMemberInfo(AppLocalizations l10n) {
    return Row(
      children: [
        Text(
          l10n.communityMockMemberCount1_2k,
          style: AppTextStyles.body.copyWith(
            fontSize: 14, // 根据 UI 调整
            fontWeight: FontWeight.w500,
            color: AppColors.grey900,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          l10n.communityDetailLabelMembers,
          style: AppTextStyles.body.copyWith(
            fontSize: 10,
            color: AppColors.grey400,
          ),
        ),
        const Spacer(),
        // 成员头像叠放效果
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 84, // 根据头像数量调整
              height: 20,
              child: Stack(
                children: List.generate(6, (index) {
                  return Positioned(
                    left: index * 14, // 调整叠放间距
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 1.5),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/chat/avatar.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 4),
            // 更多按钮
            GestureDetector(
              onTap: () {},
              child: Image.asset(
                'assets/images/community/more.png',
                width: 20,
                height: 20,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建 TabBar
  Widget _buildTabBar(List<String> tabs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TabBar(
        controller: _tabController,
        tabs: tabs.map((tab) => Tab(text: tab)).toList(),
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: AppColors.grey900,
        unselectedLabelColor: AppColors.grey400,
        labelStyle: AppTextStyles.h2.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ), // 加粗
        unselectedLabelStyle: AppTextStyles.body.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ), // 字体大小一致
        indicator: _FixedWidthUnderlineTabIndicator(
          borderSide: const BorderSide(
            width: 3,
            color: AppColors.primary,
          ), // 亮绿色指示器
          width: 12,
        ),
        dividerColor: Colors.transparent,
        labelPadding: const EdgeInsets.only(right: 24), // 增大间距
      ),
    );
  }

  /// 构建标签内容区域
  Widget _buildContentList(AppLocalizations l10n) {
    switch (_tabController.index) {
      case 0:
        return _buildDashboardTabContent(l10n);
      case 1:
        return _buildAssetTabContent(l10n);
      case 2:
        return _buildPickTabContent(l10n);
      default:
        return const SizedBox.shrink();
    }
  }

  /// 构建 Dashboard 标签页内容
  Widget _buildDashboardTabContent(AppLocalizations l10n) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      itemCount: 2,
      separatorBuilder: (context, index) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        return Column(
          children: [
            _buildPostItem(l10n),
            const SizedBox(height: 12),
            _buildPostInteraction(l10n),
          ],
        );
      },
    );
  }

  /// 构建 Asset 标签页内容
  Widget _buildAssetTabContent(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        // 1. 资产概览 (环形图 + DAO Assets)
        _buildAssetOverview(l10n),
        const SizedBox(height: 16),
        // 2. 资产统计卡片 (重构后的左右结构)
        _buildAssetStatsCard(l10n),
        const SizedBox(height: 24),
        // 3. 捐赠者排行榜 (Donor Ranking)
        _buildDonorRanking(l10n),
        const SizedBox(height: 24),
        // 4. 活动列表 (Activity)
        _buildActivityList(l10n),
        const SizedBox(height: 32),
      ],
    );
  }

  /// 构建 Pick 标签页内容
  Widget _buildPickTabContent(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 收益率统计栏 (Yield Since Added)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.grey100, // 浅灰色背景
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.grey200, width: 1), // 边框
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.communityDetailYieldSinceAdded,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12,
                    color: AppColors.grey400,
                  ),
                ),
                Text(
                  l10n.communityMockYieldValue,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 资产列表
          _buildPickListItem(
            icon: 'assets/images/profile/eth.png',
            name: l10n.communityDetailMockAssetEthName,
            fullName: l10n.communityDetailMockAssetEthFullName,
            price: l10n.communityMockAssetEthPrice,
            trend: l10n.communityMockAssetEthTrend,
            isUp: true,
          ),
          _buildPickListItem(
            icon: 'assets/images/profile/usdt.png',
            name: l10n.communityDetailMockAssetUsdtName,
            fullName: l10n.communityDetailMockAssetUsdtFullName,
            price: l10n.communityMockAssetUsdtPrice,
            trend: l10n.communityMockAssetUsdtTrend,
            isUp: false,
          ),
        ],
      ),
    );
  }

  /// 构建 Pick 列表项
  Widget _buildPickListItem({
    required String icon,
    required String name,
    required String fullName,
    required String price,
    required String trend,
    required bool isUp,
  }) {
    return GestureDetector(
      onTap: () => _showSelectDaoTypeModal(),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // 代币图标
            Image.asset(
              icon,
              width: 36,
              height: 36,
              errorBuilder: (_, __, ___) => Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.token, color: AppColors.grey400, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            // 名称和全称
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.h2.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey900,
                    ),
                  ),
                  Text(
                    fullName,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 12,
                      color: AppColors.grey400,
                    ),
                  ),
                ],
              ),
            ),
            // 价格和涨跌幅
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$$price',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      size: 24,
                      color: isUp ? AppColors.primaryDark : AppColors.error,
                    ),
                    const SizedBox(width: 0),
                    Text(
                      trend,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 12,
                        color: isUp
                            ? AppColors.primaryDark
                            : AppColors.error, // 绿色或红色
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 显示选择 DAO 类型弹窗
  void _showSelectDaoTypeModal() {
    final l10n = AppLocalizations.of(context)!;
    AppModal.show(
      context,
      title: l10n.communityModalSelectDaoTypeTitle,
      confirmText: null, // 移除底部确认按钮
      onConfirm: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDaoTypeCard(
            icon: 'assets/images/community/token.png',
            title: l10n.communityModalTokenHoldingGroupTitle,
            description: l10n.communityModalTokenHoldingGroupDesc,
            onTap: () {
              Navigator.pop(context);
              Future.microtask(() => _showSelectTokenModal());
            },
          ),
          const SizedBox(height: 16),
          _buildDaoTypeCard(
            icon: 'assets/images/community/nft.png',
            title: l10n.communityModalNftHoldingGroupTitle,
            description: l10n.communityModalNftHoldingGroupDesc,
            onTap: () {
              Navigator.pop(context);
              Future.microtask(() => _showSelectTokenModal());
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 显示选择代币弹窗
  void _showSelectTokenModal() {
    final l10n = AppLocalizations.of(context)!;
    AppModal.show(
      context,
      title: l10n.communityModalSelectTokenTitle,
      confirmText: null,
      onConfirm: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 搜索框
          AppSearchInput(
            hintText: l10n.communityModalSearchTokenHint,
          ),
          const SizedBox(height: 12),
          // 网络筛选 Chip 列表
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildNetworkChip(
                  icon: 'assets/images/profile/solana.png',
                  label: l10n.networkSolana,
                  isSelected: false,
                ),
                const SizedBox(width: 8),
                _buildNetworkChip(
                  icon: 'assets/images/profile/eth.png',
                  label: l10n.networkEthereum,
                  isSelected: true,
                ),
                const SizedBox(width: 8),
                _buildNetworkChip(
                  icon: 'assets/images/profile/usdt.png',
                  label: l10n.networkTether,
                  isSelected: false,
                ),
                const SizedBox(width: 8),
                _buildNetworkChip(
                  icon: 'assets/images/profile/bnb.png',
                  label: l10n.networkBnb,
                  isSelected: false,
                  showArrow: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 代币列表项
          _buildTokenModalItem(
            icon: 'assets/images/profile/eth.png',
            symbol: 'ETH',
            amount: '0',
            value: '\$0',
          ),
          _buildTokenModalItem(
            icon: 'assets/images/profile/eth.png',
            symbol: 'ETH',
            amount: '0',
            value: '\$0',
          ),
          const SizedBox(height: 400),
        ],
      ),
    );
  }

  /// 构建弹窗中的网络筛选 Chip
  Widget _buildNetworkChip({
    required String icon,
    required String label,
    required bool isSelected,
    bool showArrow = false,
  }) {
    return Container(
      padding: const EdgeInsets.only(left: 4,top: 5, right: 12, bottom: 5),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? Colors.transparent : AppColors.grey200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            icon,
            width: 20,
            height: 20,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.public, size: 20, color: AppColors.grey400),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.grey900,
            ),
          ),
          if (showArrow) ...[
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down,
                size: 16, color: AppColors.grey400),
          ],
        ],
      ),
    );
  }

  /// 构建弹窗中的代币列表项
  Widget _buildTokenModalItem({
    required String icon,
    required String symbol,
    required String amount,
    required String value,
  }) {
    return Row(
      children: [
        // 代币图标
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Image.asset(
            icon,
            width: 44,
            height: 44,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.token, size: 44, color: AppColors.grey200),
          ),
        ),
        const SizedBox(width: 8),
        // 右侧内容区域（带下划线）
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.grey100, width: 1),
              ),
            ),
            child: Row(
              children: [
                // 符号
                Expanded(
                  child: Text(
                    symbol,
                    style: AppTextStyles.h2.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey900,
                    ),
                  ),
                ),
                // 数量和价值
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amount,
                      style: AppTextStyles.h2.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 12,
                        color: AppColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建 DAO 类型选择卡片
  Widget _buildDaoTypeCard({
    required String icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200, width: 1),
        ),
        child: Row(
          children: [
            // 图标容器
            Image.asset(
              icon,
              width: 48,
              height: 48,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.stars,size: 48, color: AppColors.grey400),
            ),
            const SizedBox(width: 16),
            // 文本信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.h2.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            // 右侧箭头
            const Icon(Icons.chevron_right, color: AppColors.grey400, size: 24),
          ],
        ),
      ),
    );
  }

  /// 构建资产概览区域 (自定义环形图)
  Widget _buildAssetOverview(AppLocalizations l10n) {
    return Center(
      child: SizedBox(
        width: 224,
        height: 224,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 自定义环形图绘制器
            CustomPaint(
              size: const Size(224, 224),
              painter: _AssetDonutPainter(),
            ),
            // 中间文本内容
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${l10n.communityDetailDaoAssets} (\$)',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    color: AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.communityMockDaoAssetsValue,
                  style: AppTextStyles.h1.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 10),
                // Donate 按钮
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.grey200, width: 1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    l10n.communityDetailBtnDonate,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建资产统计卡片 (上面一行+下面一行的左右结构)
  Widget _buildAssetStatsCard(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200, width: 1),
      ),
      child: Column(
        children: [
          // 第一行：USDT (左) 和 vBOX (右)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAssetStatItem(
                label: l10n.communityDetailMockAssetUsdtName,
                value: '\$${l10n.communityMockAssetUsdtValue}',
                dotColor: AppColors.purple,
                isRight: false,
                l10n: l10n,
              ),
              _buildAssetStatItem(
                label: l10n.communityDetailMockAssetVboxName,
                value: '\$${l10n.communityMockAssetVboxValue}',
                dotColor: AppColors.purple,
                isRight: true,
                l10n: l10n,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 第二行：-- (左) 和 Others (右)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAssetStatItem(
                label: '--',
                value: '\$${l10n.communityMockAssetDefaultValue}',
                dotColor: AppColors.primaryDark,
                isRight: false,
                l10n: l10n,
              ),
              _buildAssetStatItem(
                label: l10n.communityDetailLabelOthers,
                value: l10n.communityDetailLabelMore,
                dotColor: const Color(0xFFFF8147),
                isRight: true,
                isMore: true,
                l10n: l10n,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建单个资产统计项
  Widget _buildAssetStatItem({
    required String label,
    required String value,
    required Color dotColor,
    required bool isRight,
    required AppLocalizations l10n,
    bool isMore = false,
  }) {
    final dot = Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
    );

    return Column(
      crossAxisAlignment: isRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        // 标签行
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isRight) ...[dot, const SizedBox(width: 4)],
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                color: AppColors.grey700,
              ),
            ),
            if (isRight) ...[const SizedBox(width: 4), dot],
          ],
        ),
        // const SizedBox(height: 4),
        // 数值或 "More >"
        if (isMore)
          GestureDetector(
            onTap: () {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.communityDetailLabelMore,
                  style: AppTextStyles.h2.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryLight,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.primaryLight, // 修改颜色
                ),
              ],
            ),
          )
        else
          Text(
            value,
            style: AppTextStyles.h2.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.grey900,
            ),
          ),
      ],
    );
  }

  /// 构建排行榜 (Donor Ranking)
  Widget _buildDonorRanking(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 13,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.communityDetailDonorRanking,
                style: AppTextStyles.h2.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
              const Spacer(),
              Text(
                l10n.communityDetailLabelViewMore,
                style: AppTextStyles.body.copyWith(
                  fontSize: 12,
                  color: AppColors.grey400,
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 12,
                color: AppColors.grey400,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDonorItem(0, l10n.communityDetailMockDonorName1, l10n.communityDetailMockDonorAddress, l10n.communityMockDonorAmount1),
          _buildDonorItem(1, l10n.communityDetailMockDonorName2, l10n.communityDetailMockDonorAddress, l10n.communityMockDonorAmount2),
          _buildDonorItem(2, l10n.communityDetailMockDonorName3, l10n.communityDetailMockDonorAddress, l10n.communityMockDonorAmount3),
        ],
      ),
    );
  }

  /// 构建单个排行榜项
  Widget _buildDonorItem(
    int index,
    String name,
    String address,
    String amount,
  ) {
    // 根据索引显示奖牌图标
    String medalAsset = 'assets/images/community/gold.png';
    if (index == 1) medalAsset = 'assets/images/community/silver.png';
    if (index == 2) medalAsset = 'assets/images/community/bronze.png';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // 奖牌
          Image.asset(
            medalAsset,
            width: 20,
            height: 20,
            errorBuilder: (_, __, ___) => Icon(
              Icons.emoji_events,
              size: 16,
              color: index == 0
                  ? Colors.orange
                  : (index == 1 ? Colors.grey : Colors.brown),
            ),
          ),
          const SizedBox(width: 12),
          // 头像
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.asset(
              'assets/images/chat/avatar.png',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          // 名称和地址
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey900,
                  ),
                ),
                Text(
                  address,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12,
                    color: AppColors.grey400,
                  ),
                ),
              ],
            ),
          ),
          // 金额
          Text(
            '\$ $amount',
            style: AppTextStyles.h2.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.grey900,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建活动列表 (Activity)
  Widget _buildActivityList(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 13,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.communityDetailActivity,
                style: AppTextStyles.h2.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
              const Spacer(),
              Text(
                l10n.communityDetailLabelViewMore,
                style: AppTextStyles.body.copyWith(
                  fontSize: 12,
                  color: AppColors.grey400,
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 12,
                color: AppColors.grey400,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActivityCard(
            l10n,
            '+0.1 USDT',
            'kliven.eth',
            '0xe69b...036f4c',
            '2024-08-30 18:08:12',
          ),
          _buildActivityCard(
            l10n,
            '+0.1 vBOX',
            'kliven.eth',
            '0xe69b...036f4c',
            '2024-08-30 18:08:12',
          ),
          _buildActivityCard(
            l10n,
            '+2 vBOX',
            'kliven.eth',
            '0xe69b...036f4c',
            '2024-08-30 18:08:12',
          ),
        ],
      ),
    );
  }

  /// 构建单个活动卡片
  Widget _buildActivityCard(
    AppLocalizations l10n,
    String title,
    String donor,
    String from,
    String time,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200, width: 1),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.h2.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildActivityInfoRow(l10n.communityDetailActivityLabelDonor, donor),
                const SizedBox(height: 4),
                _buildActivityInfoRow(l10n.communityDetailActivityLabelFrom, from, hasChevron: true),
                const SizedBox(height: 4),
                _buildActivityInfoRow(l10n.communityDetailActivityLabelTime, time),
              ],
            ),
          ),
          // 收益类型标识 (参考 CommunityPage 的 Positioned 定位和圆角)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/community/income.png',
                    width: 12,
                    height: 12,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.call_received,
                      size: 12,
                      color: AppColors.grey400,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.communityDetailActivityIncome,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 10,
                      color: AppColors.grey600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 活动卡片内的信息行
  Widget _buildActivityInfoRow(
    String label,
    String value, {
    bool hasChevron = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontSize: 12,
            color: AppColors.grey600,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: AppTextStyles.body.copyWith(
                fontSize: 12,
                color: AppColors.grey600,
              ),
            ),
            if (hasChevron) ...[
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right,
                size: 12,
                color: AppColors.grey400,
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// 构建动态列表 (Dashboard 原内容)
  Widget _buildPostItem(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 用户信息
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/chat/avatar.png',
                width: 36,
                height: 36,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kristen',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '22:03 2025-04-18',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 10,
                    color: AppColors.grey400,
                  ),
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 16),
        // 文字内容
        Text(
          'What kind of photos can a novice take after learning by himself for half a What kind of photos can a novice take after learning by himself for half 🚗🚗🚗',
          style: AppTextStyles.body.copyWith(
            fontSize: 14,
            color: const Color(0xFF404040),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        // 图片网格
        _buildPostImageGrid(),
        const SizedBox(height: 12),
      ],
    );
  }

  /// 构建动态图片网格
  Widget _buildPostImageGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double spacing = 4;
        final double size = (constraints.maxWidth - spacing * 2) / 3;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(6, (index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                'assets/images/moments/moment1.png',
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            );
          }),
        );
      },
    );
  }

  /// 构建帖子互动栏
  Widget _buildPostInteraction(AppLocalizations l10n) {
    return Row(
      children: [
        _buildInteractionItem(Icons.favorite_border, '1.2k'),
        const SizedBox(width: 24),
        _buildInteractionItem(Icons.chat_bubble_outline, '856'),
        const Spacer(),
        // 使用现有的 share.png
        Row(
          children: [
            Image.asset(
              'assets/images/community/share.png',
              width: 18,
              height: 18,
              color: AppColors.grey400,
            ),
            const SizedBox(width: 4),
            Text(
              l10n.communityDetailLabelShare,
              style: AppTextStyles.body.copyWith(
                fontSize: 12,
                color: AppColors.grey400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInteractionItem(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.grey400),
        const SizedBox(width: 4),
        Text(
          count,
          style: AppTextStyles.body.copyWith(
            fontSize: 12,
            color: AppColors.grey400,
          ),
        ),
      ],
    );
  }
}

/// 固定宽度的下划线指示器 (复用 community_page.dart 中的实现)
class _FixedWidthUnderlineTabIndicator extends Decoration {
  final BorderSide borderSide;
  final double width;

  const _FixedWidthUnderlineTabIndicator({
    this.borderSide = const BorderSide(width: 2.0, color: Colors.blue),
    this.width = 20.0,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _FixedWidthUnderlinePainter(this, onChanged);
  }
}

class _FixedWidthUnderlinePainter extends BoxPainter {
  final _FixedWidthUnderlineTabIndicator decoration;

  _FixedWidthUnderlinePainter(this.decoration, VoidCallback? onChanged)
    : super(onChanged);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Rect rect = offset & configuration.size!;
    final double center = rect.center.dx;
    final double left = center - decoration.width / 2;
    final double right = center + decoration.width / 2;
    final double bottom = rect.bottom;

    final Paint paint = decoration.borderSide.toPaint()
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(left, bottom), Offset(right, bottom), paint);
  }
}

/// 资产概览环形图绘制器
class _AssetDonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 12.0; // 调大线宽

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round; // 保持圆角

    // 绘制背景底色圆环 (浅灰色，如果有的话，但截图中似乎主要是两段色)
    // paint.color = const Color(0xFFF3F4F6);
    // canvas.drawCircle(center, radius - strokeWidth / 2, paint);

    // 准备各个分段的数据 (角度)
    // 根据 UI 截图精准还原
    // 右侧深蓝色段 (占大头)
    // 左侧淡紫色段 (占小头)
    final segments = [
      {
        'color': const Color(0xFF5D5FEF), // 深蓝色
        'startAngle': -87.0, // 从顶部偏右一点点开始
        'sweep': 212.0, // 扫过的角度
      },
      {
        'color': const Color(0xFFD3BFFF), // 淡紫色
        'startAngle': 128.0, // 底部偏左一点点开始
        'sweep': 142.0, // 扫过的角度
      },
    ];

    for (var segment in segments) {
      paint.color = segment['color'] as Color;
      final startAngle = segment['startAngle'] as double;
      final sweepAngle = segment['sweep'] as double;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        _degreeToRadian(startAngle),
        _degreeToRadian(sweepAngle),
        false,
        paint,
      );
    }
  }

  double _degreeToRadian(double degree) => degree * 3.1415926535897932 / 180;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
