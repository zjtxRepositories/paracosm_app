import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/modules/wallet/chains/service/portfolio_service.dart';
import 'package:paracosm/modules/wallet/manager/wallet_manager.dart';
import 'package:paracosm/modules/wallet/model/token_model.dart';
import '../../modules/account/manager/account_manager.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../util/string_util.dart';
import '../../widgets/base/app_localizations.dart';
import '../../widgets/base/app_page.dart';
import '../../widgets/common/app_network_image.dart';
import '../../widgets/common/app_search_input.dart';

class TokenManagerPage extends StatefulWidget {
  const TokenManagerPage({super.key});

  @override
  State<TokenManagerPage> createState() => _TokenManagerPageState();
}

class _TokenManagerPageState extends State<TokenManagerPage> {
  List<TokenModel> tokenList = [];
  String _searchQuery = '';
  final _searchController = TextEditingController();

  List<TokenModel> _filteredTokens = [];
  StreamSubscription<List<TokenModel>>? _portfolioSubscription;

  bool get _isSearching => _searchQuery.trim().isNotEmpty;

  List<TokenModel> get _displayTokens =>
      _isSearching ? _filteredTokens : tokenList;

  @override
  void initState() {
    super.initState();
    _portfolioSubscription = PortfolioService().stream.listen(
      _mergePortfolioTokens,
    );
    _init();
  }

  @override
  void dispose() {
    _portfolioSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await reloadTokenList();
  }

  Future<void> reloadTokenList() async {
    final chains = AccountManager().currentWallet?.chains;
    if (chains == null) {
      tokenList = [];
      _filteredTokens = [];
      if (!mounted) return;
      setState(() {});
      return;
    }
    tokenList = [];
    for (final chain in chains) {
      tokenList.addAll(chain.tokens);
    }
    _refreshFilteredTokens();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _onSearchChanged(String query) async {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _refreshFilteredTokens();
    setState(() {});
  }

  void _mergePortfolioTokens(List<TokenModel> tokens) {
    if (!mounted || tokens.isEmpty || tokenList.isEmpty) return;
    final tokenMap = {for (final token in tokens) _tokenKey(token): token};
    var changed = false;

    for (final token in tokenList) {
      final updated = tokenMap[_tokenKey(token)];
      if (updated == null) continue;
      if (updated.price != 0 && token.price != updated.price) {
        token.price = updated.price;
        changed = true;
      }
      if (updated.market != null && token.market != updated.market) {
        token.market = updated.market;
        changed = true;
      }
    }

    if (!changed) return;
    _refreshFilteredTokens();
    setState(() {});
  }

  void _refreshFilteredTokens() {
    _filteredTokens = _filterTokens(_searchQuery.toLowerCase());
  }

  List<TokenModel> _filterTokens(String lower) {
    final query = lower.trim();
    if (query.isEmpty) {
      return List<TokenModel>.from(tokenList);
    }
    return tokenList.where((item) {
      final chainLabel = _tokenSubtitle(item).toLowerCase();
      return item.symbol.toLowerCase().contains(query) ||
          item.name.toLowerCase().contains(query) ||
          item.address.toLowerCase().contains(query) ||
          chainLabel.contains(query);
    }).toList();
  }

  String _tokenKey(TokenModel token) {
    final address = token.address.trim().toLowerCase();
    if (address.isNotEmpty) {
      return '${token.chainId}:$address';
    }
    return '${token.chainId}:${token.symbol.toLowerCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      showNav: true,
      title: AppLocalizations.of(context)!.profileTokenManagerTitle,
      backgroundColor: AppColors.white,
      child: Column(
        children: [
          _buildSearchBar(),
          if (!_isSearching) _buildCustomTokenCard(),
          Expanded(
            child: _buildTokenSection(
              AppLocalizations.of(context)!.profileHotTokens,
              _displayTokens,
            ),
          ),
        ],
      ),
    );
  }

  // ================= SEARCH =================
  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: AppSearchInput(
        controller: _searchController,
        hintText: AppLocalizations.of(context)!.profileSearchTokenOrContract,
        onChanged: _onSearchChanged,
      ),
    );
  }

  // ================= 自定义 Token =================
  Widget _buildCustomTokenCard() {
    return GestureDetector(
      onTap: () async {
        await context.push('/add-token-manager');
        _init();
      },
      child: Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset('assets/images/wallet/icon_coin.png', width: 24),
                SizedBox(width: 10),
                Text(
                  AppLocalizations.of(context)!.profileCustomToken,
                  style: AppTextStyles.h2.copyWith(
                    fontSize: 18,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
            Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  // ================= Token Section =================
  Widget _buildTokenSection(String title, List<TokenModel> tokens) {
    if (tokens.isEmpty) return const SizedBox();
    final displayTokens = List<TokenModel>.from(tokens)
      ..sort(_compareDisplayTokens);
    return Container(
      margin: EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _isSearching ? SizedBox() : Text(title),
          SizedBox(height: 12),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              itemCount: displayTokens.length,
              itemBuilder: (_, i) {
                final t = displayTokens[i];
                return _buildTokenItem(
                  t,
                  t.name,
                  t.symbol,
                  t.market?.close ?? 0.0,
                  t.market?.chg ?? 0.0,
                  (t.market?.chg ?? 0.0) > 0,
                  t.logo,
                  t.isAdded ?? false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _compareDisplayTokens(TokenModel a, TokenModel b) {
    final addedCompare = _boolRank(
      b.isAdded == true,
    ).compareTo(_boolRank(a.isAdded == true));
    if (addedCompare != 0) return addedCompare;

    final balanceCompare = b.balance.compareTo(a.balance);
    if (balanceCompare != 0) return balanceCompare;

    final chainCompare = a.chainId.compareTo(b.chainId);
    if (chainCompare != 0) return chainCompare;

    final symbolCompare = a.symbol.toLowerCase().compareTo(
      b.symbol.toLowerCase(),
    );
    if (symbolCompare != 0) return symbolCompare;

    return a.address.toLowerCase().compareTo(b.address.toLowerCase());
  }

  int _boolRank(bool value) => value ? 1 : 0;

  /// 构建代币列表项
  Widget _buildTokenItem(
    TokenModel token,
    String name,
    String symbol,
    double price,
    double change,
    bool isUp,
    String iconName,
    bool isAdd,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.push('/token-detail', extra: token);
        },
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              // 1. 代币图标容器 (点击跳转代币详情 - 第二个截图页)
              AppNetworkImage(
                url: iconName,
                width: 36,
                height: 36,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              // 2. 代币名称 (同样点击跳转代币详情)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      symbol,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.grey900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _tokenSubtitle(token),
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w400,
                        fontSize: 11,
                        color: AppColors.grey400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Text(
                          '\$$price',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: AppColors.grey400,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          change > 0
                              ? '+${truncateDouble(change, digits: 2)}%'
                              : '${truncateDouble(change, digits: 2)}%',
                          style: AppTextStyles.caption.copyWith(
                            color: isUp
                                ? AppColors.primaryDark
                                : AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isAdd)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            token.showBalance,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.grey900,
                            ),
                          ),
                          Text(
                            '\$${token.showUsdValue}',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: AppColors.grey400,
                            ),
                          ),
                        ],
                      ),
                    IconButton(
                      icon: Icon(
                        isAdd ? Icons.remove_circle : Icons.add_circle,
                        color: isAdd ? Colors.red : Colors.green,
                      ),
                      onPressed: () async {
                        final walletId = AccountManager().currentWallet?.id;
                        if (walletId == null) return;
                        final updatedToken = _copyTokenWithAdded(token, !isAdd);
                        await WalletManager.updateToken(walletId, updatedToken);
                        await reloadTokenList();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _tokenSubtitle(TokenModel token) {
    final chain = token.getChain();
    final chainName = chain?.name.trim();
    if (chainName != null && chainName.isNotEmpty) {
      return chainName;
    }
    return 'Chain ${token.chainId}';
  }

  TokenModel _copyTokenWithAdded(TokenModel token, bool isAdded) {
    return TokenModel(
      symbol: token.symbol,
      name: token.name,
      address: token.address,
      balance: token.balance,
      decimals: token.decimals,
      logo: token.logo,
      coinId: token.coinId,
      chainId: token.chainId,
      isAdded: isAdded,
      isNative: token.isNative,
      market: token.market,
      price: token.price,
      protocol: token.protocol,
    );
  }
}
