import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_localizations_keys.dart';
import 'package:paracosm/widgets/base/app_page.dart';

import '../../core/network/models/dApp_hive.dart';
import '../../widgets/common/app_network_image.dart';

/// 发现列表页面 (例如：New arrivals, Defi 等详情列表)
class DiscoverListPage extends StatelessWidget {
  final String title;
  final List<DAppHive> dappList;

  const DiscoverListPage({
    super.key,
    required this.title, required this.dappList,
  });


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // 模拟数据，实际开发中可以根据 title 从接口获取或从上一页传入
    return AppPage(
      title: title,
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: dappList.length,
        itemBuilder: (context, index) {
          final item = dappList[index];
          return _buildListItem(item, isLast: index == dappList.length - 1);
        },
      ),
    );
  }

  /// 构建列表项
  Widget _buildListItem(DAppHive item, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图标
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AppNetworkImage(
              url: item.headUrl,
              width: 48,
              height: 48,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          // 内容
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color:  AppColors.grey100,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name ?? '',
                    style: AppTextStyles.h2.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.des ?? '',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 12,
                      color: AppColors.grey400,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 获取模拟数据
  List<Map<String, String>> _getMockData(AppLocalizations l10n) {
    return [
      {
        'icon': 'assets/images/discover/arbitrum.png',
        'label': l10n.discoverMockArbitrumLabel,
        'desc': l10n.discoverMockArbitrumDesc,
      },
      {
        'icon': 'assets/images/discover/aelf.png',
        'label': l10n.discoverMockAelfLabel,
        'desc': l10n.discoverMockAelfDesc,
      },
      {
        'icon': 'assets/images/discover/starknet.png',
        'label': l10n.discoverMockStarknetLabel,
        'desc': l10n.discoverMockStarknetDesc,
      },
      {
        'icon': 'assets/images/discover/astar.png',
        'label': l10n.discoverMockAstarLabel,
        'desc': l10n.discoverMockAstarDesc,
      },
    ];
  }
}
