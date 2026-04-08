import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:paracosm/modules/wallet/model/token_model.dart';
import '../../modules/wallet/model/chain_account.dart';
import '../../modules/wallet/model/wallet_model.dart';
import '../common/app_network_image.dart';
import '../common/app_search_input.dart';

class WalletSelectTokenModal extends StatefulWidget {
  final TokenModel? selectedToken;
  final WalletModel wallet;
  final Future<void> Function(TokenModel token) onSelected;

  const WalletSelectTokenModal({
    super.key,
    this.selectedToken,
    required this.onSelected,
    required this.wallet,
  });

  @override
  State<WalletSelectTokenModal> createState() =>
      _WalletSelectTokenModalState();
}

class _WalletSelectTokenModalState
    extends State<WalletSelectTokenModal> {
  List<ChainAccount> _chains = [];

  final TextEditingController _searchController =
  TextEditingController();

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
    final index = _chains.indexWhere(
          (c) => c.chainId == _selectChainId,
    );

    const itemWidth = 100.0;
    final offset = index == -1 ? 0.0 : index * itemWidth;

    /// ⭐ 核心：初始就带 offset
    _chainScrollController = ScrollController(
      initialScrollOffset: offset,
    );
  }
  @override
  Widget build(BuildContext context) {
    final hasSearch = _keyword.isNotEmpty;

    /// 🔥 获取 tokens
    List<TokenModel> tokens = [];

    if (hasSearch) {
      /// 👉 跨链搜索
      for (var c in _chains) {
        tokens.addAll(c.tokens);
      }
    } else {
      /// 👉 当前链
      final chain = _chains
          .where((c) => c.chainId == _selectChainId)
          .isNotEmpty
          ? _chains.firstWhere(
              (c) => c.chainId == _selectChainId)
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
    tokens.sort(
            (a, b) => b.balance.compareTo(a.balance));

    return SizedBox(
      height:
      MediaQuery.of(context).size.height * 0.5,
      child: Column(
        children: [
          /// 🔍 搜索
          Padding(
            padding: const EdgeInsets.all(12),
            child: AppSearchInput(
              controller: _searchController,
              hintText: '搜索代币名称、合约地址',
              onChanged: (value) {
                if (_keyword == value) return;

                setState(() {
                  _keyword = value.toLowerCase();
                });
              },
            ),
          ),

          /// 🧱 链选择
          if (!hasSearch)
            SizedBox(
              height: 40,
              child: ListView.builder(
                controller: _chainScrollController,
                scrollDirection: Axis.horizontal,
                itemCount: _chains.length,
                itemBuilder: (context, index) {
                  final chain = _chains[index];
                  final selected =
                      chain.chainId == _selectChainId;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectChainId = chain.chainId;
                      });
                    },
                    child: Container(
                      margin:
                      const EdgeInsets.only(
                          right: 8),
                      padding:
                      const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.blue
                            .withOpacity(0.1)
                            : Colors.grey
                            .withOpacity(0.1),
                        borderRadius:
                        BorderRadius.circular(
                            20),
                      ),
                      child: Row(
                        children: [
                          AppNetworkImage(
                            url: chain.logo,
                            width: 20,
                            height: 20,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            chain.name,
                            style: TextStyle(
                              color: selected
                                  ? Colors.blue
                                  : Colors.black87,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 12),

          /// 🪙 Token 列表
          Expanded(
            child: tokens.isEmpty
                ? const Center(
              child: Text('未找到代币'),
            )
                : ListView.builder(
              keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior
                  .onDrag,
              itemCount: tokens.length,
              itemBuilder:
                  (context, index) {
                final token =
                tokens[index];

                final isSelected =
                    widget.selectedToken
                        ?.symbol ==
                        token.symbol &&
                        widget.selectedToken
                            ?.chainId ==
                            token.chainId;

                return KeyedSubtree(
                  key: ValueKey(
                      '${token.chainId}-${token.symbol}'),
                  child: InkWell(
                    onTap: () async {
                      await widget
                          .onSelected(token);
                    },
                    child: Container(
                      padding:
                      const EdgeInsets
                          .symmetric(
                        vertical: 12,
                        horizontal: 4,
                      ),
                      child: Row(
                        children: [
                          /// icon
                          ClipRRect(
                            borderRadius:
                            BorderRadius
                                .circular(
                                20),
                            child:
                            AppNetworkImage(
                              url:
                              token.logo,
                              width: 36,
                              height: 36,
                              fit: BoxFit
                                  .cover,
                            ),
                          ),

                          const SizedBox(
                              width: 12),

                          /// 名称
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Text(
                                  token
                                      .symbol,
                                  style:
                                  const TextStyle(
                                    fontSize:
                                    15,
                                    fontWeight:
                                    FontWeight
                                        .w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          /// 余额
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .end,
                            children: [
                              Text(
                                token
                                    .showBalance,
                                style:
                                const TextStyle(
                                    fontSize:
                                    14),
                              ),
                              const SizedBox(
                                  height: 2),
                              Text(
                                '\$${token.showUsdValue}',
                                style:
                                const TextStyle(
                                  fontSize:
                                  12,
                                  color: Colors
                                      .grey,
                                ),
                              ),
                            ],
                          ),

                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}