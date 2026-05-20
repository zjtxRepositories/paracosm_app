import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:paracosm/modules/wallet/model/token_model.dart';
import '../../modules/wallet/model/chain_account.dart';
import '../../modules/wallet/model/wallet_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../base/app_localizations.dart';
import '../common/app_network_image.dart';
import '../common/app_search_input.dart';

enum AssetType { token, nft }

class WalletSelectTokenModal extends StatefulWidget {
  final TokenModel? selectedToken;
  final WalletModel wallet;
  final AssetType type;

  final Future<void> Function(TokenModel token) onSelected;

  const WalletSelectTokenModal({
    super.key,
    this.selectedToken,
    required this.onSelected,
    required this.wallet,
    this.type = AssetType.token,
  });

  @override
  State<WalletSelectTokenModal> createState() => _WalletSelectTokenModalState();
}

class _WalletSelectTokenModalState extends State<WalletSelectTokenModal> {
  List<ChainAccount> _chains = [];

  final TextEditingController _searchController = TextEditingController();

  /// ⭐ 链滚动控制器
  // final ScrollController _chainScrollController =
  // ScrollController();
  late final ScrollController _chainScrollController;
  String _keyword = '';
  int _selectChainId = 0;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    _chains = widget.wallet.chains;

    /// ✅ 默认链
    if (widget.selectedToken != null) {
      _selectChainId = widget.selectedToken!.chainId;
    } else {
      _selectChainId = widget.wallet.currentChainId;
    }

    setState(() {});
    _scrollToSelectedChain();
  }

  void _scrollToSelectedChain() {
    /// ⭐ 提前算 index
    final index = _chains.indexWhere((c) => c.chainId == _selectChainId);

    const itemWidth = 100.0;
    final offset = index == -1 ? 0.0 : index * itemWidth;

    /// ⭐ 核心：初始就带 offset
    _chainScrollController = ScrollController(initialScrollOffset: offset);
  }

  @override
  Widget build(BuildContext context) {
    List<TokenModel> tokens = [];
    if (widget.type == AssetType.token) {
      final hasSearch = _keyword.isNotEmpty;
      if (hasSearch) {
        /// 👉 跨链搜索
        for (var c in _chains) {
          tokens.addAll(c.tokens);
        }
      } else {
        /// 👉 当前链
        final chain =
            _chains.where((c) => c.chainId == _selectChainId).isNotEmpty
            ? _chains.firstWhere((c) => c.chainId == _selectChainId)
            : null;

        tokens = chain?.tokens ?? [];
      }

      /// 🔍 搜索过滤
      tokens = tokens.where((t) {
        if (!hasSearch) return true;

        return t.address.toLowerCase().contains(_keyword) ||
            t.name.toLowerCase().contains(_keyword) ||
            t.symbol.toLowerCase().contains(_keyword);
      }).toList();

      /// 📊 排序（余额高在前）
      tokens.sort((a, b) => b.balance.compareTo(a.balance));
    }

    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 搜索框
        AppSearchInput(
          controller: _searchController,
          hintText: widget.type == AssetType.token
              ? l10n.communityModalSearchTokenHint
              : l10n.walletSearchNftNameOrContract,
          onChanged: (value) {
            if (_keyword == value) return;

            setState(() {
              _keyword = value.toLowerCase();
            });
          },
        ),
        const SizedBox(height: 12),
        // 网络筛选 Chip 列表
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_chains.length, (index) {
              final chain = _chains[index];

              return Padding(
                padding: EdgeInsets.only(
                  right: index == _chains.length - 1 ? 0 : 8,
                ),
                child: _buildNetworkChip(
                  icon: chain.logo,
                  label: chain.name,
                  isSelected: chain.chainId == _selectChainId,
                  showArrow: false,
                  onTap: () {
                    if (_selectChainId == chain.chainId) return;

                    setState(() {
                      _selectChainId = chain.chainId;
                    });
                  },
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 400,
          child: tokens.isEmpty
              ? SizedBox()
              : ListView.separated(
                  itemCount: tokens.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final token = tokens[index];

                    return _buildTokenModalItem(
                      icon: token.logo,
                      symbol: token.symbol,
                      amount: token.showBalance,
                      value: '\$${token.showUsdValue}',
                      onTap: () {
                        widget.onSelected(token);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// 构建弹窗中的网络筛选 Chip
  Widget _buildNetworkChip({
    required String icon,
    required String label,
    required bool isSelected,
    bool showArrow = false,
    GestureTapCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(left: 4, top: 5, right: 12, bottom: 5),
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
            AppNetworkImage(
              url: icon,
              width: 20,
              height: 20,
              fit: BoxFit.contain,
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
              const Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: AppColors.grey400,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建弹窗中的代币列表项
  Widget _buildTokenModalItem({
    required String icon,
    required String symbol,
    required String amount,
    required String value,
    GestureTapCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          // 代币图标
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: AppNetworkImage(
              url: icon,
              width: 44,
              height: 44,
              fit: BoxFit.contain,
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
      ),
    );
  }
}
