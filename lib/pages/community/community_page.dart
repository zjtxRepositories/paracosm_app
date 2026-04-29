import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/modules/scan/scan_result_handler.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_action_pop_menu.dart';
import 'package:paracosm/widgets/common/app_modal.dart';

/// 社区主页面
/// 包含顶部推荐社区、分类 TabBar 以及社区列表
class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with SingleTickerProviderStateMixin {
  /// 加号按钮的 Key，用于定位弹出菜单
  final GlobalKey _addButtonKey = GlobalKey();

  /// 分类 Tab 控制器
  late TabController _tabController;

  /// Tab 键值列表，用于初始化控制器
  final List<String> _tabKeys = [
    'community_tab_dao',
    'community_tab_club',
    'community_tab_key',
  ];

  @override
  void initState() {
    super.initState();
    // 初始化 Tab 控制器，长度为 3 (DAO, Club, Key)
    _tabController = TabController(length: _tabKeys.length, vsync: this);
  }

  /// 显示筛选底部弹窗
  void _showFilterBottomSheet() {
    final filterKey = GlobalKey<_CommunityFilterBottomSheetState>();
    final l10n = AppLocalizations.of(context)!;

    AppModal.show(
      context,
      title: l10n.screening,
      cancelText: l10n.reset,
      cancelBorder: const BorderSide(color: AppColors.grey300, width: 1),
      confirmText: l10n.confirm,
      confirmColor: AppColors.grey900,
      onCancel: () {
        // 调用子组件的重置方法，且不关闭弹窗
        filterKey.currentState?.reset();
      },
      onConfirm: () {
        // TODO: 应用筛选逻辑
        Navigator.of(context, rootNavigator: true).pop();
      },
      child: _CommunityFilterBottomSheet(key: filterKey),
    );
  }

  @override
  void dispose() {
    // 销毁控制器
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 获取国际化后的 Tab 文本
    final tabs = [
      AppLocalizations.of(context)!.communityTabDao,
      AppLocalizations.of(context)!.communityTabClub,
      AppLocalizations.of(context)!.communityTabKey,
    ];

    return AppPage(
      showNav: true,
      showBack: false,
      isCustomHeader: true,
      // 使用自定义头部，包含搜索和添加按钮
      renderCustomHeader: _buildCustomHeader(context),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // 1. 顶部推荐社区横向滚动列表
                  _buildRecommendedSection(),
                  const SizedBox(height: 16),
                  // 2. 分类 TabBar 和 过滤图标区域
                  _buildTabBarSection(tabs),
                  // 3. 社区垂直列表
                  _buildCommunityList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建自定义头部 (标题 + 搜索 + 加号)
  /// 直接参考 chat_page.dart 的右侧功能实现，确保图标和间距一致
  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      color: AppColors.grey100,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 12,
      ),
      child: Row(
        children: [
          // 页面标题：社区
          Text(
            AppLocalizations.of(context)!.communityTitle,
            style: AppTextStyles.h1.copyWith(
              fontSize: 24,
              color: AppColors.grey900,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // 搜索按钮：跳转至聊天搜索页 (逻辑与 chat_page.dart 一致)
          IconButton(
            onPressed: () => context.push('/chat-search'),
            icon: Image.asset(
              'assets/images/chat/search.png',
              width: 32,
              height: 32,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16), // 图标间距
          // 添加按钮：弹出操作菜单 (逻辑与 chat_page.dart 一致)
          IconButton(
            key: _addButtonKey,
            onPressed: () {
              final l10n = AppLocalizations.of(context)!;
              AppActionPopMenu.show(
                context,
                buttonKey: _addButtonKey,
                items: [
                  AppActionPopMenuItem(
                    icon: 'assets/images/community/group.png',
                    label: l10n.communityMenuCreateGroup,
                    onTap: () {
                      // TODO: 跳转创建群组
                    },
                  ),
                  AppActionPopMenuItem(
                    icon: 'assets/images/community/dao.png',
                    label: l10n.communityMenuCreateDao,
                    onTap: () => context.push('/create-dao'),
                  ),
                  AppActionPopMenuItem(
                    icon: 'assets/images/community/club.png',
                    label: l10n.communityMenuCreateClub,
                    onTap: () => context.push('/create-club'),
                  ),
                  AppActionPopMenuItem(
                    icon: 'assets/images/chat/scanner.png',
                    label: l10n.communityMenuScan,
                    onTap: () {
                      ScanResultHandler.scanAndHandle(context);
                    },
                  ),
                ],
              );
            },
            icon: Image.asset(
              'assets/images/chat/add.png',
              width: 32,
              height: 32,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// 构建推荐社区板块
  /// 展示横向滚动的推荐社区卡片
  Widget _buildRecommendedSection() {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 110, // 给卡片内部三行内容留足垂直空间
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 4, // 模拟数据数量
        itemBuilder: (context, index) {
          // 模拟不同的推荐社区数据
          final mockData = [
            {
              'name': l10n.communityMockBkokGroup,
              'trend': '+ 0.19%',
              'tags': null,
              'members': l10n.communityMockMemberCount2k,
              'address': l10n.communityMockAddress1,
            },
            {
              'name': 'W',
              'trend': null,
              'tags': [l10n.filterTagAirdrop, l10n.filterTagMeme],
              'members': l10n.communityMockMemberCount1_2k,
              'address': l10n.communityMockAddress2,
            },
            {
              'name': 'PARACOSM',
              'trend': null,
              'tags': null,
              'members': l10n.communityMockMemberCount8_9k,
              'address': l10n.communityMockAddress3,
            },
            {
              'name': 'BIBI DAO',
              'trend': '+ 0.8%',
              'tags': [l10n.communityTabDao],
              'members': l10n.communityMockMemberCount5_0k,
              'address': l10n.communityMockAddress4,
            },
          ];
          final item = mockData[index % mockData.length];
          return _buildRecommendedCard(
            name: item['name'] as String,
            trend: item['trend'] as String?,
            tags: item['tags'] as List<String>?,
            members: item['members'] as String,
            address: item['address'] as String,
          );
        },
      ),
    );
  }

  /// 构建单个推荐卡片
  /// [name] 社区名称
  /// [trend] 趋势百分比 (如 +0.19%)
  /// [tags] 标签列表 (当没有趋势信息时展示)
  Widget _buildRecommendedCard({
    required String name,
    String? trend,
    List<String>? tags,
    required String members,
    required String address,
  }) {
    // 判断趋势是否为正 (上涨)
    final bool isPositive = trend?.startsWith('+') ?? true;
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => context.push('/community-detail/$name'),
      child: Container(
        width: 185,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 第一行：头像 + 名称 + 趋势
            Row(
              children: [
                _buildGroupAvatar(size: 16), // 小号群头像
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.grey900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (trend != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    size: 12,
                    color: isPositive ? AppColors.primaryDark : AppColors.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ' ${trend.substring(1).trim()}',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 10,
                      color: isPositive
                          ? AppColors.primaryDark
                          : AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            // 第二行：成员数和关联钱包地址
            Row(
              children: [
                Image.asset(
                  'assets/images/community/user.png',
                  width: 12,
                  height: 12,
                ),
                const SizedBox(width: 2),
                Text(
                  ' $members',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 10,
                    color: AppColors.grey400,
                  ),
                ),
                const SizedBox(width: 21),
                Image.asset(
                  'assets/images/community/location.png',
                  width: 12,
                  height: 12,
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    ' $address',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 10,
                      color: AppColors.grey400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // 第三行：标签或默认描述
            if (tags != null && tags.isNotEmpty)
              Wrap(
                spacing: 4,
                children: tags.map((tag) => _buildTag(tag)).toList(),
              )
            else
              Text(
                l10n.communityMockSalaryDesc,
                style: AppTextStyles.body.copyWith(
                  fontSize: 10,
                  color: AppColors.grey400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  /// 构建小标签组件
  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.grey200, width: 1),
      ),
      child: Text(
        text,
        style: AppTextStyles.body.copyWith(
          fontSize: 10,
          color: AppColors.grey400,
        ),
      ),
    );
  }

  /// 构建分类 TabBar 和 过滤图标
  /// 包含 DAO、Club、Key 三个分类，并提供过滤按钮
  Widget _buildTabBarSection(List<String> tabs) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // 确保 TabBar 和右侧图标垂直居中
        children: [
          // 分类 Tab 列表
          Expanded(
            child: SizedBox(
              height: 48, // 明确高度，确保 TabBar 内部文本与外部图标在同一基准线上
              child: TabBar(
                controller: _tabController,
                tabs: tabs.map((e) => Tab(text: e)).toList(),
                isScrollable: true,
                labelColor: AppColors.grey900,
                unselectedLabelColor: AppColors.grey400,
                labelStyle: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                unselectedLabelStyle: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
                // 自定义下划线指示器：固定宽度为 12
                indicator: _FixedWidthUnderlineTabIndicator(
                  borderSide: const BorderSide(
                    width: 3,
                    color: AppColors.primary,
                  ),
                  width: 12,
                ),
                dividerColor: Colors.transparent, // 隐藏分割线
                tabAlignment: TabAlignment.start,
                labelPadding: const EdgeInsets.only(right: 24),
                overlayColor: WidgetStateProperty.all(
                  Colors.transparent,
                ), // 移除点击水波纹
              ),
            ),
          ),
          // 右侧过滤操作按钮
          IconButton(
            onPressed: _showFilterBottomSheet,
            icon: Image.asset(
              'assets/images/community/filter.png',
              width: 16,
              height: 16,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: l10n.communityFilterTooltip,
          ),
        ],
      ),
    );
  }

  /// 构建社区垂直列表
  /// 展示不同分类下的社区列表项
  Widget _buildCommunityList() {
    final l10n = AppLocalizations.of(context)!;
    // 模拟社区数据源
    final List<Map<String, dynamic>> items = [
      {
        'name': l10n.communityMockBkokGroup,
        'desc': l10n.communityMockSalaryDesc,
        'trend': null,
        'members': l10n.communityMockMemberCount2_5k,
        'address': l10n.communityMockAddress1,
      },
      {
        'name': 'W',
        'desc': null,
        'tags': [
          l10n.filterTagAirdrop,
          l10n.filterTagMeme,
          l10n.filterTagGiveaway,
        ],
        'trend': null,
        'members': l10n.communityMockMemberCount1_2k,
        'address': l10n.communityMockAddress2,
      },
      {
        'name': 'PARACOSM',
        'desc': l10n.communityMockLazyMod,
        'trend': '- 0.19%',
        'members': l10n.communityMockMemberCount8_9k,
        'address': l10n.communityMockAddress3,
      },
      {
        'name': 'BIBI DAO',
        'desc': l10n.communityMockSparkPlan,
        'trend': null,
        'members': l10n.communityMockMemberCount5_0k,
        'address': l10n.communityMockAddress4,
      },
      {
        'name': 'RENA DAO',
        'desc': l10n.communityMockSalaryDesc,
        'trend': '+ 1.2%',
        'members': l10n.communityMockMemberCount3_4k,
        'address': l10n.communityMockAddress5,
      },
      {
        'name': 'SPARK DAO',
        'desc': l10n.communityMockLazyMod,
        'trend': null,
        'members': l10n.communityMockMemberCount1_1k,
        'address': l10n.communityMockAddress6,
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(), // 禁用内部滚动，由外部 SingleChildScrollView 处理
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildCommunityItem(
          name: item['name'],
          desc: item['desc'],
          tags: item['tags'] != null ? List<String>.from(item['tags']) : null,
          trend: item['trend'],
          members: item['members'],
          address: item['address'],
        );
      },
    );
  }

  /// 构建单个社区列表项
  /// [name] 社区名称
  /// [desc] 社区描述
  /// [tags] 标签列表
  /// [trend] 趋势信息
  /// [members] 成员数量
  /// [address] 关联地址
  Widget _buildCommunityItem({
    required String name,
    String? desc,
    List<String>? tags,
    String? trend,
    required String members,
    required String address,
  }) {
    return GestureDetector(
      onTap: () => context.push('/community-detail/$name'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200, width: 1),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左侧：社区群组头像 (2x2网格)
                  _buildGroupAvatar(size: 42),
                  const SizedBox(width: 8),
                  // 右侧：核心内容区域
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 第一行：社区名称 + 成员数 + 地址信息
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.h2.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.grey900,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Image.asset(
                              'assets/images/community/user.png',
                              width: 12,
                              height: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              ' $members',
                              style: AppTextStyles.body.copyWith(
                                fontSize: 10,
                                color: AppColors.grey400,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Image.asset(
                              'assets/images/community/location.png',
                              width: 12,
                              height: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              ' $address',
                              style: AppTextStyles.body.copyWith(
                                fontSize: 10,
                                color: AppColors.grey400,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // 第二行：描述信息/标签列表
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: trend != null ? 70 : 0,
                                ),
                                child: desc != null
                                    ? Text(
                                        desc,
                                        style: AppTextStyles.body.copyWith(
                                          fontSize: 10,
                                          color: AppColors.grey400,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : (tags != null
                                          ? Wrap(
                                              spacing: 4,
                                              children: tags
                                                  .map((tag) => _buildTag(tag))
                                                  .toList(),
                                            )
                                          : const SizedBox.shrink()),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (trend != null)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trend.startsWith('+')
                            ? Icons.trending_up
                            : Icons.trending_down,
                        size: 12,
                        color: trend.startsWith('+')
                            ? AppColors.primaryDark
                            : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trend.substring(1).trim(),
                        style: AppTextStyles.body.copyWith(
                          fontSize: 10,
                          color: trend.startsWith('+')
                              ? AppColors.primaryDark
                              : AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建群头像 (2x2网格展示，模拟多用户头像)
  Widget _buildGroupAvatar({double size = 44}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(2),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(4, (index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Image.asset(
              'assets/images/chat/avatar.png',
              fit: BoxFit.cover,
            ),
          );
        }),
      ),
    );
  }
}

/// 社区筛选底部弹窗内容组件
class _CommunityFilterBottomSheet extends StatefulWidget {
  const _CommunityFilterBottomSheet({super.key});

  @override
  State<_CommunityFilterBottomSheet> createState() =>
      _CommunityFilterBottomSheetState();
}

class _CommunityFilterBottomSheetState
    extends State<_CommunityFilterBottomSheet> {
  // 选中的过滤项 (存储原始值以保持逻辑一致，但在 UI 上展示翻译后的值)
  String selectedType = 'All';
  String selectedBlockchain = 'All';
  String selectedTag = 'All';

  /// 重置筛选状态
  void reset() {
    setState(() {
      selectedType = 'All';
      selectedBlockchain = 'All';
      selectedTag = 'All';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // 过滤选项定义 (Value -> Label)
    final List<Map<String, String>> typeOptions = [
      {'value': 'All', 'label': l10n.filterAll},
      {'value': 'Token', 'label': l10n.filterTypeToken},
      {'value': 'NFT', 'label': l10n.filterTypeNft},
    ];

    final List<Map<String, String>> blockchainOptions = [
      {'value': 'All', 'label': l10n.filterAll},
      {'value': 'BNB Chain', 'label': l10n.networkBnbChain},
      {'value': 'Solana', 'label': l10n.networkSolana},
      {'value': 'Ethereum', 'label': l10n.networkEthereum},
      {'value': 'Base', 'label': l10n.networkBase},
      {'value': 'Polygon', 'label': l10n.networkPolygon},
      {'value': 'Optimism', 'label': l10n.networkOptimism},
      {'value': 'Arbitrum', 'label': l10n.networkArbitrum},
      {'value': 'zkSync Era', 'label': l10n.networkZksyncEra},
      {'value': 'Avalanche', 'label': l10n.networkAvalanche},
      {'value': 'Fantom', 'label': l10n.networkFantom},
      {'value': 'Blast', 'label': l10n.networkBlast},
      {'value': 'Merlin', 'label': l10n.networkMerlin},
      {'value': 'Linea', 'label': l10n.networkLinea},
      {'value': 'Scroll', 'label': l10n.networkScroll},
      {'value': 'Bitlayer', 'label': l10n.networkBitlayer},
      {'value': 'Mantle', 'label': l10n.networkMantle},
      {'value': 'X Layer', 'label': l10n.networkXLayer},
      {'value': 'Bitcoin', 'label': l10n.networkBitcoin},
    ];

    final List<Map<String, String>> tagOptions = [
      {'value': 'All', 'label': l10n.filterAll},
      {'value': 'Game', 'label': l10n.filterTagGame},
      {'value': 'Social', 'label': l10n.filterTagSocial},
      {'value': 'Meme', 'label': l10n.filterTagMeme},
      {'value': 'Staking', 'label': l10n.filterTagStaking},
      {'value': 'Airdrop', 'label': l10n.filterTagAirdrop},
      {'value': 'News', 'label': l10n.filterTagNews},
      {'value': 'Alpha', 'label': l10n.filterTagAlpha},
      {'value': 'Fun', 'label': l10n.filterTagFun},
      {'value': 'Giveaway', 'label': l10n.filterTagGiveaway},
      {'value': 'Inscription', 'label': l10n.filterTagInscription},
      {'value': 'Layer2', 'label': l10n.filterTagLayer2},
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // By Type
        _buildSectionTitle(l10n.byType),
        const SizedBox(height: 8),
        _buildFilterGroup(
          options: typeOptions,
          selected: selectedType,
          onSelected: (val) => setState(() => selectedType = val),
        ),

        const SizedBox(height: 16),
        // Blockchain
        _buildSectionTitle(l10n.blockchain),
        const SizedBox(height: 8),
        _buildFilterGroup(
          options: blockchainOptions,
          selected: selectedBlockchain,
          onSelected: (val) => setState(() => selectedBlockchain = val),
        ),

        const SizedBox(height: 16),
        // By Tag
        _buildSectionTitle(l10n.byTag),
        const SizedBox(height: 8),
        _buildFilterGroup(
          options: tagOptions,
          selected: selectedTag,
          onSelected: (val) => setState(() => selectedTag = val),
        ),
        const SizedBox(height: 8), // 给 AppModal 底部留点余白
      ],
    );
  }

  /// 构建部分标题
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.body.copyWith(
        fontSize: 12,
        color: AppColors.grey400,
      ),
    );
  }

  /// 构建筛选项按钮组
  Widget _buildFilterGroup({
    required List<Map<String, String>> options,
    required String selected,
    required Function(String) onSelected,
  }) {
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: options.map((option) {
        final value = option['value']!;
        final label = option['label']!;
        final isSelected = value == selected;
        return GestureDetector(
          onTap: () => onSelected(value),
          child: Container(
            width: 77,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.white,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.grey200,
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: isSelected ? AppColors.grey900 : AppColors.grey700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 固定宽度的 TabBar 下划线指示器
class _FixedWidthUnderlineTabIndicator extends Decoration {
  final BorderSide borderSide;
  final double width;

  const _FixedWidthUnderlineTabIndicator({
    this.borderSide = const BorderSide(width: 3.0, color: AppColors.primary),
    this.width = 12.0,
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
    assert(configuration.size != null);
    final Rect rect = offset & configuration.size!;
    final Paint paint = decoration.borderSide.toPaint();
    paint.strokeCap = StrokeCap.round; // 设置圆角，匹配 UI 效果

    // 计算中心点坐标
    final double x = rect.center.dx;
    // 线条位于底部，且保持在 tabAlignment.start 的中心
    final double y = rect.bottom;

    canvas.drawLine(
      Offset(x - decoration.width / 2, y - decoration.borderSide.width / 2),
      Offset(x + decoration.width / 2, y - decoration.borderSide.width / 2),
      paint,
    );
  }
}
