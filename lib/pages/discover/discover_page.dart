import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/core/network/api/dapp_list_api.dart';
import 'package:paracosm/core/network/api/get_uer_info_api.dart';
import 'package:paracosm/core/network/models/dApp_hive.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_localizations_keys.dart';
import 'package:paracosm/widgets/base/app_page.dart';

import '../../widgets/common/app_network_image.dart';

/// 发现页面
class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  int _activeTabIndex = 0;
  List<DAppHive> dappList1 = [];
  List<DAppHive> dappList2 = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    dappList1 = await DappListApi.get(1);
    dappList2 = await DappListApi.get(2);
    setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final List<String> tabs = [
      l10n.discoverTabPopular,
      l10n.discoverTabRecommend,
      l10n.discoverTabRecent
    ];

    return AppPage(
      showNav: false, // 使用自定义头部
      backgroundColor: AppColors.grey100,
      child: Column(
        children: [
          _buildCustomHeader(context, l10n),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner 区域
                  _buildBanner(),

                  // 分类标签
                  // _buildTabBar(tabs),

                  // New arrivals 区域
                  _DiscoverSectionHeader(
                    title: l10n.discoverSectionNewArrivals,
                    onTap: () => context.push('/discover-list/${l10n.discoverSectionNewArrivals}',extra: dappList1),
                  ),
                  _buildNewArrivalsGrid(l10n),
                  
                  const SizedBox(height: 24),
                  
                  // Defi 区域
                  _DiscoverSectionHeader(
                    title: l10n.discoverSectionDefi,
                    onTap: () => context.push('/discover-list/${l10n.discoverSectionDefi}',extra: dappList1),
                  ),
                  _buildDefiGrid(l10n),
                  
                  const SizedBox(height: 24),
                  
                  // Airdrop 区域
                  // _DiscoverSectionHeader(
                  //   title: l10n.discoverSectionAirdrop,
                  //   onTap: () => context.push('/discover-list/${l10n.discoverSectionAirdrop}'),
                  // ),
                  // const SizedBox(height: 100), // 留白
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建自定义头部 (参考 community_page.dart)
  Widget _buildCustomHeader(BuildContext context, AppLocalizations l10n) {
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
          // 页面标题：Discover
          Text(
            l10n.discoverTitle,
            style: const TextStyle(
              fontSize: 24,
              color: AppColors.grey900,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // 搜索按钮
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
          const SizedBox(width: 16),
          // 扫码/更多按钮 (根据截图使用 scanner 图标)
          IconButton(
            onPressed: () {
              // TODO: 扫码逻辑
            },
            icon: Image.asset(
              'assets/images/chat/scan.png',
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

  /// 构建 Banner
  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/images/discover/top-bg.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// 构建分类标签栏
  Widget _buildTabBar(List<String> tabs) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final title = entry.value;
          final isActive = _activeTabIndex == index;

          return GestureDetector(
            onTap: () => setState(() => _activeTabIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? AppColors.grey900 : AppColors.grey400,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 12,
                    height: 3,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 构建 New arrivals 网格
  Widget _buildNewArrivalsGrid(AppLocalizations l10n) {
    // final items = [
    //   {'icon': 'assets/images/discover/arbitrum.png', 'label': l10n.discoverMockArbitrumLabel},
    //   {'icon': 'assets/images/discover/starknet.png', 'label': l10n.discoverMockStarknetLabel},
    //   {'icon': 'assets/images/discover/astar.png', 'label': l10n.discoverMockAstarLabel},
    //   {'icon': 'assets/images/discover/aelf.png', 'label': l10n.discoverMockAelfLabel},
    // ];

    return _buildItemGrid(dappList1.length > 4
        ? dappList1.sublist(0, 4).toList() : dappList1);
  }

  /// 构建 Defi 网格
  Widget _buildDefiGrid(AppLocalizations l10n) {
    // final items = [
    //   {'icon': 'assets/images/discover/magic.png', 'label': l10n.discoverMockMagicEdenLabel},
    //   {'icon': 'assets/images/discover/flux.png', 'label': l10n.discoverMockFluxLabel},
    //   {'icon': 'assets/images/discover/iagon.png', 'label': l10n.discoverMockIagonLabel},
    //   {'icon': 'assets/images/discover/cartesi.png', 'label': l10n.discoverMockCartesiLabel},
    // ];

    return _buildItemGrid(dappList2.length > 4
        ? dappList2.sublist(0, 4).toList() : dappList2);
  }

  /// 通用网格构建
  Widget _buildItemGrid(List<DAppHive> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
              onTap: (){
                context.push('/dapp',extra: item);
              },
            child: _DiscoverItem(icon: item.headUrl!, label: item.name ?? ''),
          );
        },
      ),
    );
  }
}

/// 发现页分类头部组件 (标题 + 箭头)
class _DiscoverSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const _DiscoverSectionHeader({required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.grey900),
          ],
        ),
      ),
    );
  }
}

/// 发现页列表项组件 (图标 + 文字)
class _DiscoverItem extends StatelessWidget {
  final String icon;
  final String label;

  const _DiscoverItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child:AppNetworkImage(
            url: icon,
            width: 48,
            height: 48,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.black,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
