import 'package:flutter/material.dart';
import 'package:paracosm/modules/wallet/model/chain_account.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'app_network_image.dart';
import 'app_search_input.dart';
import 'app_checkbox.dart';

/// 通用网络选择组件
class AppNetworkSelector extends StatefulWidget {
  /// 初始选中的网络
  final ChainAccount initialNetwork;
  /// 选择回调
  final ValueChanged<ChainAccount> onSelected;
  /// 网络列表数据（可选，不传则使用默认列表）
  final List<ChainAccount> networks;

  const AppNetworkSelector({
    super.key,
    required this.initialNetwork,
    required this.onSelected,
    required this.networks,
  });

  @override
  State<AppNetworkSelector> createState() => _AppNetworkSelectorState();
}

class _AppNetworkSelectorState extends State<AppNetworkSelector> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // late final List<Map<String, dynamic>> _networks;

  @override
  void initState() {
    super.initState();
    // _networks = widget.networks ?? [
    //   {'name': 'All', 'symbol': 'ALL', 'icon': 'all.png'},
    //   {'name': 'Solana', 'symbol': 'SOL', 'icon': 'solana.png'},
    //   {'name': 'Ethereum', 'symbol': 'ETH', 'icon': 'eth.png'},
    //   {'name': 'BNB Chain', 'symbol': 'BNB', 'icon': 'bnb.png'},
    //   {'name': 'Base', 'symbol': 'BASE', 'icon': 'base.png'},
    //   {'name': 'Polygon', 'symbol': 'MATIC', 'icon': 'polygon.png'},
    //   {'name': 'Optimism', 'symbol': 'OP', 'icon': 'optimism.png'},
    //   {'name': 'Arbitrum', 'symbol': 'ARB', 'icon': 'arbitrum.png'},
    // ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredNetworks = widget.networks.where((network) {
      final name = network.name.toString().toLowerCase();
      final symbol = network.symbol.toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || symbol.contains(query);
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSearchInput(
          controller: _searchController,
          hintText: 'Search Internet',
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: filteredNetworks.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: AppColors.grey200.withValues(alpha: 0.5),
              indent: 60,
            ),
            itemBuilder: (context, index) {
              final network = filteredNetworks[index];
              final isSelected = network.chainId == widget.initialNetwork.chainId;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                onTap: () {
                  widget.onSelected(network);
                },
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.grey100,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AppNetworkImage(
                      url: network.logo,
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                title: Text(
                  network.name,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: AppColors.grey900,
                  ),
                ),
                trailing: AppCheckbox(
                  value: isSelected,
                  isRadio: false,
                  onChanged: (val) {
                    if (val) {
                      widget.onSelected(network);
                    }
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
