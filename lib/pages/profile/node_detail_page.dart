import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';

/// 节点详情页面
class NodeDetailPage extends StatefulWidget {
  final String chainName;

  const NodeDetailPage({super.key, required this.chainName});

  @override
  State<NodeDetailPage> createState() => _NodeDetailPageState();
}

class _NodeDetailPageState extends State<NodeDetailPage> {
  int _selectedIndex = 1; // 默认选中第二个 web3

  final List<Map<String, dynamic>> _nodes = [
    {
      'name': 'geth',
      'url': 'https://web.3mytokenpocket.vip',
      'height': '18,452,693',
      'speedColor': const Color(0xFFA855F7), // 紫色
    },
    {
      'name': 'web3',
      'url': 'https://web.3mytokenpocket.vip',
      'height': '18,452',
      'speedColor': const Color(0xFFF97316), // 橙色
    },
    {
      'name': 'jccdex',
      'url': 'https://web.3mytokenpocket.vip',
      'height': '0',
      'speedColor': const Color(0xFF94A3B8), // 灰色
    },
  ];

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: widget.chainName,
      showNav: true,
      showNavBorder: true,
      navBorderColor: AppColors.grey100,
      backgroundColor: AppColors.white,
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: _nodes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final node = _nodes[index];
                final isSelected = _selectedIndex == index;
                return _buildNodeItem(node, index, isSelected);
              },
            ),
          ),
          _buildSpeedInfo(),
        ],
      ),
    );
  }

  /// 构建节点列表项
  Widget _buildNodeItem(Map<String, dynamic> node, int index, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.grey900 : AppColors.grey200,
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // 主体内容
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // 选中框
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.grey900 : AppColors.grey300,
                        width: 1,
                      ),
                      color: isSelected ? AppColors.grey900 : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  // 节点信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node['name'],
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.grey900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          node['url'],
                          style: AppTextStyles.body.copyWith(
                            fontSize: 12,
                            color: AppColors.grey400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 80), // 为右上角标签预留空间
                ],
              ),
            ),
            // 块高度标签 - 定位到右上角
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: node['speedColor'],
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(15), // 略小于父容器圆角，以更好贴合
                    bottomLeft: Radius.circular(10),
                  ),
                ),
                child: Text(
                  node['height'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建底部速度说明
  Widget _buildSpeedInfo() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        border: Border.all(
          color: AppColors.grey200,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppLocalizations.of(context)!.profileNodeDetailNodeSpeed,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey900,
                ),
              ),
              const Spacer(),
              _buildDotLabel(AppLocalizations.of(context)!.profileNodeDetailQuick, const Color(0xFFA855F7)),
              const SizedBox(width: 8),
              _buildDotLabel(AppLocalizations.of(context)!.profileNodeDetailMiddle, const Color(0xFFF97316)),
              const SizedBox(width: 8),
              _buildDotLabel(AppLocalizations.of(context)!.profileNodeDetailSlow, const Color(0xFFEF4444)),
              const SizedBox(width: 8),
              _buildDotLabel(AppLocalizations.of(context)!.profileNodeDetailNone, const Color(0xFF94A3B8)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.profileNodeDetailBlockHeightDesc,
            style: AppTextStyles.body.copyWith(
              fontSize: 12,
              color: AppColors.grey400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建说明中的小圆点标签
  Widget _buildDotLabel(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.body.copyWith(
            fontSize: 12,
            color: AppColors.grey700,
          ),
        ),
      ],
    );
  }
}
