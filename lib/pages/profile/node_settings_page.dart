import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';

/// 节点设置页面
class NodeSettingsPage extends StatelessWidget {
  const NodeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> chains = [
      {
        'name': 'Ethereum',
        'icon': 'assets/images/profile/eth.png',
        'url': 'https://web.3mytokenpocket.vip'
      },
      {
        'name': 'Binance',
        'icon': 'assets/images/profile/bnb.png',
        'url': 'https://web.3mytokenpocket.vip'
      },
      {
        'name': 'Polygon',
        'icon': 'assets/images/profile/polygon.png',
        'url': 'https://web.3mytokenpocket.vip'
      },
    ];

    return AppPage(
      title: AppLocalizations.of(context)!.profileNodeSettingsNodeSettings,
      showNav: true,
      showNavBorder: true,
      navBorderColor: AppColors.grey100,
      backgroundColor: AppColors.white,
      child: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: chains.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final chain = chains[index];
          return _buildChainItem(context, chain);
        },
      ),
    );
  }

  /// 构建链列表项
  Widget _buildChainItem(BuildContext context, Map<String, String> chain) {
    return GestureDetector(
      onTap: () {
        context.push('/node-detail', extra: chain['name']);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200, width: 1),
        ),
        child: Row(
          children: [
            // 链图标
            ClipOval(
              child: Image.asset(
                chain['icon']!,
                width: 48,
                height: 48,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 48,
                  height: 48,
                  color: AppColors.grey100,
                  child: const Icon(Icons.link, color: AppColors.grey400),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // 链信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chain['name']!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chain['url']!,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 12,
                      color: AppColors.grey600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // 右侧箭头
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.grey300,
            ),
          ],
        ),
      ),
    );
  }
}
