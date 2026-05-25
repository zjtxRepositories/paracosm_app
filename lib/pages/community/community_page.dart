import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/core/network/api/community_list_api.dart';
import 'package:paracosm/core/network/api/recommend_community_api.dart';
import 'package:paracosm/modules/im/manager/im_friend_manager.dart';
import 'package:paracosm/modules/scan/scan_result_handler.dart';
import 'package:paracosm/pages/chat/home/chat_controller.dart';
import 'package:paracosm/pages/community/community_list_page.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/util/string_util.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/chat/group_avatar_widget.dart';
import 'package:paracosm/widgets/common/app_action_pop_menu.dart';
import 'package:paracosm/widgets/common/app_modal.dart';
import 'package:paracosm/widgets/modals/community_modals.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../core/models/community_model.dart';
import '../../core/models/conversation_model.dart';
import '../../core/models/custom_message_model.dart';
import '../../core/models/group_model.dart';
import '../../modules/im/manager/im_conversation_manager.dart';
import '../../modules/im/manager/im_group_manager.dart';
import '../../modules/im/message/base/im_message.dart';
import '../../modules/im/message/send/im_sender.dart';
import '../../widgets/chat/select_members_modal.dart';
import '../../widgets/common/app_loading.dart';
import '../../widgets/common/app_toast.dart';

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
    // 'community_tab_key',
  ];
  List<CommunityModel> _recommends = [];
  List<CommunityModel> _daos = [];
  List<CommunityModel> _clubs = [];

  @override
  void initState() {
    super.initState();
    // 初始化 Tab 控制器，长度为 3 (DAO, Club, Key)
    _tabController = TabController(length: _tabKeys.length, vsync: this);
    _fetchRecommendCommunity();
  }

  Future<void> _fetchRecommendCommunity() async {
   final data = await RecommendCommunityApi.get();
   setState(() {
     _recommends = data;
   });
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

  void _showSelectDaoTypeModal() {
    CommunityModals.showSelectedDao(context: context,
    onSelected: (token){
      context.pop();
      context.push('/create-dao',extra: token);
    });
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
    ];

    return AppPage(
      showNav: true,
      showBack: false,
      isCustomHeader: true,
      renderCustomHeader: _buildCustomHeader(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _recommends.isEmpty ? SizedBox(): const SizedBox(height: 12),

          /// 推荐社区
          _recommends.isEmpty ? SizedBox():  _buildRecommendedSection(),

          _recommends.isEmpty ? SizedBox():  const SizedBox(height: 16),

          /// TabBar
          _buildTabBarSection(tabs),

          /// 列表页面
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                CommunityListPage(
                  type: RoomType.dao,
                ),
                CommunityListPage(
                  type: RoomType.club,
                ),
              ],
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
                    onTap: () async {
                      ChatController().createNormalGroup(context);
                    },
                  ),
                  AppActionPopMenuItem(
                    icon: 'assets/images/community/dao.png',
                    label: l10n.communityMenuCreateDao,
                    onTap: _showSelectDaoTypeModal
                    // onTap: () => context.push('/create-dao'),
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
      height: 96, // 给卡片内部三行内容留足垂直空间
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _recommends.length,
        itemBuilder: (context, index) {
          final item = _recommends[index];
          return _buildRecommendedCard(
            item: item,
            name: item.name ?? '',
            tags: item.tags,
            members: item.memberNum.toString(),
            address: item.displayAddress,
            desc: item.desc ?? '',
            groupId: item.communityParam?.groupId ?? '',
            avatar: item.avatarUrl ?? '',
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
    required CommunityModel item,
    required String name,
    List<String>? tags,
    required String members,
    required String address,
    required String desc,
    required String groupId,
    required String avatar,

  }) {
    // 判断趋势是否为正 (上涨)
    // final bool isPositive = trend?.startsWith('+') ?? true;
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => context.push('/community-detail',extra: item),
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
                GroupAvatarWidget(
                  groupId: groupId,
                  portraitUri: avatar,
                  size: 16,
                ),
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
                // if (trend != null) ...[
                //   const SizedBox(width: 4),
                //   Icon(
                //     isPositive ? Icons.trending_up : Icons.trending_down,
                //     size: 12,
                //     color: isPositive ? AppColors.primaryDark : AppColors.error,
                //   ),
                //   const SizedBox(width: 4),
                //   Text(
                //     ' ${trend.substring(1).trim()}',
                //     style: AppTextStyles.body.copyWith(
                //       fontSize: 10,
                //       color: isPositive
                //           ? AppColors.primaryDark
                //           : AppColors.error,
                //       fontWeight: FontWeight.w500,
                //     ),
                //   ),
                // ],
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
                    ' ${ellipsisMiddle(address,head: 5,tail: 5)}',
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
                desc,
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
          // IconButton(
          //   onPressed: _showFilterBottomSheet,
          //   icon: Image.asset(
          //     'assets/images/community/filter.png',
          //     width: 16,
          //     height: 16,
          //   ),
          //   padding: EdgeInsets.zero,
          //   constraints: const BoxConstraints(),
          //   tooltip: l10n.communityFilterTooltip,
          // ),
        ],
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
