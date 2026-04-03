import 'package:flutter/material.dart';
import 'package:paracosm/core/util/string_util.dart';
import 'package:paracosm/modules/wallet/model/chain_account.dart';
import '../../modules/account/manager/account_manager.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'app_network_image.dart';

class AppChainSelector extends StatefulWidget {
  /// 选择回调
  final ValueChanged<ChainAccount> onSelected;

  const AppChainSelector({
    super.key,
    required this.onSelected,
  });

  @override
  State<AppChainSelector> createState() => _AppChainSelectorState();
}

class _AppChainSelectorState extends State<AppChainSelector> {
  final TextEditingController _searchController = TextEditingController();
  List<ChainAccount> _chains = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final manager = AccountManager();
    final wallet = manager.currentWallet;
    _chains = wallet?.chains ?? [];
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: _chains.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: AppColors.grey200.withValues(alpha: 0.5),
              indent: 60,
            ),
            itemBuilder: (context, index) {
              final network = _chains[index];
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
                  network.address.isEmpty ?  '同步 ${network.name}':network.name,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: AppColors.grey900,
                  ),
                ),
                subtitle:network.address.isEmpty ? SizedBox() : Text(
                  ellipsisMiddle(network.address),
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: AppColors.grey900,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/common/next.png',
                      width: 20,
                      height: 20,
                    ),
                  ],
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
