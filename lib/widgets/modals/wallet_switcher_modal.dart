import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:paracosm/widgets/modals/wallet_modals.dart';
import '../../modules/account/model/account_model.dart';
import '../../modules/wallet/chains/service/portfolio_service.dart';
import '../../modules/wallet/model/chain_account.dart';
import '../../modules/wallet/model/wallet_model.dart';
import '../base/app_localizations.dart';
import '../common/app_button.dart';
import '../wallet/wallet_card_widget.dart';
import '../wallet/wallet_item_widget.dart';

class WalletSwitcherModal extends StatefulWidget {
  final List<AccountModel> accounts;
  final Map<String, WalletModel> walletMap;
  final String currentWalletId;
  final Future<void> Function(String address) onSwitch;
  final VoidCallback onAddWallet;

  const WalletSwitcherModal({
    super.key,
    required this.accounts,
    required this.walletMap,
    required this.currentWalletId,
    required this.onSwitch,
    required this.onAddWallet,
  });

  @override
  State<WalletSwitcherModal> createState() => _WalletSwitcherModalState();
}
class _WalletSwitcherModalState extends State<WalletSwitcherModal> {
  bool _isSwitching = false;
  bool _isBalanceVisible = true;
  ChainAccount? _selectedNetwork;
  WalletModel? _walletModel;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final wallet = widget.walletMap[widget.currentWalletId];
    _walletModel = wallet;
    _selectedNetwork = _walletModel?.currentChain;
    setState(() {});
  }

  String _currentWalletName() {
    final wallet = widget.walletMap[widget.currentWalletId];
    final l10n = AppLocalizations.of(context)!;
    String showName = wallet?.name ?? '${l10n.profileProfileDetailsWallet} ${(wallet?.aIndex ?? 0) + 1}';
    return showName;
  }

  String? _currentNetworkSymbol() {
    return _selectedNetwork?.symbol;
  }

  String? _currentNetworkLogo() {
    return _selectedNetwork?.logo;
  }

  void _onNetworkTap() {
    WalletModals.showNetworkSelector(
        context: context,
        wallet: _walletModel!,
        onSelected: (chain){
          setState(() {
            _selectedNetwork = chain;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        /// 顶部卡片（你刚拆的组件）
        StreamBuilder<double>(
          stream: PortfolioService().totalUsdStream,
          builder: (_, snapshot) {
            return WalletCardWidget(
              walletName: _currentWalletName(),
              networkSymbol: _currentNetworkSymbol(),
              networkLogo: _currentNetworkLogo(),
              isBalanceVisible: _isBalanceVisible,
              totalBalance: snapshot.data ?? 0,
              onToggleBalance: () {
                setState(() => _isBalanceVisible = !_isBalanceVisible);
              },
              onWalletTap: () {},
              onNetworkTap: _onNetworkTap,
            );
          },
        ),

        const SizedBox(height: 24),

        /// 钱包列表
        ...widget.accounts.map((account) {
          final wallet = widget.walletMap[account.id];

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: WalletItemWidget(
              wallet: wallet,
              address: account.id,
              isSelected: account.id == widget.currentWalletId,
              onTap: _isSwitching
                  ? null
                  : () async {
                setState(() => _isSwitching = true);

                await widget.onSwitch(account.id);

                if (mounted) {
                  Navigator.of(context).pop(); // 关闭弹窗
                }
              },
            ),
          );
        }),

        const SizedBox(height: 24),

        /// 添加钱包

    AppButton( text: AppLocalizations.of(context)! .profileProfileDetailsAddWallet,
    onPressed:() {
      Navigator.of(context).pop();
      widget.onAddWallet();
    },
    )
      ],
    );
  }}