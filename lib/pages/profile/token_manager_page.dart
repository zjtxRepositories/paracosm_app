import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/modules/wallet/manager/wallet_manager.dart';
import 'package:paracosm/modules/wallet/model/token_model.dart';
import '../../modules/account/manager/account_manager.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../util/string_util.dart';
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
  final FocusNode _focusNode = FocusNode();
  final _searchController = TextEditingController();

  bool _hasFocus = false;
  List<TokenModel> _filteredTokens = [];
  final _wallet = AccountManager().currentWallet;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await reloadTokenList();
  }

  Future<void> reloadTokenList() async {
    final chains = _wallet?.chains;
    if (chains == null) return;
    tokenList = [];
    for (final chain in chains){
      tokenList.addAll(chain.tokens);
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _onSearchChanged(String query) async {
    if (_searchQuery == query) return;
    _searchQuery = query;
    final lower = _searchQuery.toLowerCase();

    final result = tokenList.where((item) {
      return item.symbol.toLowerCase().contains(lower) ||
          item.name.toLowerCase().contains(lower) ||
          item.address.toLowerCase().contains(lower);
    }).toList();
    setState(() => _filteredTokens = result);
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      showNav: true,
      title: '币种管理',
      backgroundColor: AppColors.white,
      child: Column(
        children: [
          _buildSearchBar(),
          if (!_hasFocus) _buildCustomTokenCard(),
          Expanded(
            child: _buildTokenSection(
              "热门代币",
              _hasFocus ? _filteredTokens : tokenList,
            ),
          ),
        ],
      )
    );
  }

  // ================= SEARCH =================
  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child:AppSearchInput(
        controller: _searchController,
        hintText: '搜索币种、合约地址',
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
                Text('自定义币种',
                  style: AppTextStyles.h2.copyWith(
                    fontSize: 18,
                    color: AppColors.black,
                  ),),
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
    tokens.sort((a, b) {
      return b.balance.compareTo(a.balance);
    });
    return Container(
      margin: EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hasFocus ? SizedBox():Text(title),
          SizedBox(height: 12),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              itemCount: tokens.length,
              itemBuilder: (_, i) {
                final t = tokens[i];
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

  /// 构建代币列表项
  Widget _buildTokenItem(TokenModel token,String name, String symbol,
      double price, double change, bool isUp, String iconName, bool isAdd) {
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
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
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
                          change > 0 ? '+${truncateDouble(change,digits: 2)}%' : '${truncateDouble(change,digits: 2)}%',
                          style: AppTextStyles.caption.copyWith(
                            color: isUp ? AppColors.primaryDark : AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    )
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
                          token.isAdded = !isAdd;
                          await WalletManager.updateToken(_wallet!.id, token);
                          if (mounted) setState(() {});
                        }
                    )
                  ],
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}