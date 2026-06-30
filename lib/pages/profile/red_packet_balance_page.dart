import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/core/network/api/red_packet_api.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/wallet/model/chain_account.dart';
import 'package:paracosm/modules/wallet/model/token_model.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_button.dart';
import 'package:paracosm/widgets/common/app_empty_view.dart';
import 'package:paracosm/widgets/common/app_toast.dart';

class RedPacketBalancePage extends StatefulWidget {
  const RedPacketBalancePage({super.key});

  static const depositAddress = '0xb76E006da2E170511D30F35146964a0fC4173d58';

  @override
  State<RedPacketBalancePage> createState() => _RedPacketBalancePageState();
}

class _RedPacketBalancePageState extends State<RedPacketBalancePage> {
  bool _loading = true;
  List<RedPacketAsset> _assets = const [];
  Map<String, RedPacketBalance> _balances = const {};

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        RedPacketApi.assetList(),
        RedPacketApi.queryBalances(),
      ]);
      if (!mounted) return;
      final assets = results[0] as List<RedPacketAsset>;
      final balances = {
        for (final item in results[1] as List<RedPacketBalance>)
          item.assetId: item,
      };
      setState(() {
        _assets = assets;
        _balances = balances;
        _loading = false;
      });
    } catch (e) {
      debugPrint('load red packet balances failed: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: '红包余额',
      backgroundColor: AppColors.white,
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _assets.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 160),
                  AppEmptyView(text: '暂无红包资产', bottomOffset: 0),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: _assets.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final asset = _assets[index];
                  final balance = _balances[asset.assetId];
                  return _buildAssetTile(asset, balance);
                },
              ),
      ),
    );
  }

  Widget _buildAssetTile(RedPacketAsset asset, RedPacketBalance? balance) {
    final display = balance?.display ?? '0';
    final chain = asset.assetId.split('-').first.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFF1473E),
              shape: BoxShape.circle,
            ),
            child: Text(
              asset.symbol.characters.take(1).toString(),
              style: AppTextStyles.h2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.symbol,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.grey900,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$chain 红包余额',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.grey500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$display ${asset.symbol}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.grey900,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 30,
                child: OutlinedButton(
                  onPressed: () => _showDepositSheet(asset),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFF1473E)),
                    foregroundColor: const Color(0xFFF1473E),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text('充值'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDepositSheet(RedPacketAsset asset) {
    final target = _resolveTransferTarget(asset);
    if (target == null) {
      AppToast.show('当前钱包暂不支持该红包资产');
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${asset.symbol} 充值',
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.grey900,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '将通过 ${target.chain.name} 网络把 ${asset.symbol} 转入红包资金池，到账后计入红包余额。',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.grey600,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SelectableText(
                    RedPacketBalancePage.depositAddress,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey900,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: '确认充值',
                  onPressed: () {
                    if (!sheetContext.mounted) return;
                    Navigator.pop(sheetContext);
                    context.push(
                      '/transfer',
                      extra: {
                        'token': target.token,
                        'chain': target.chain,
                        'prefillAddress': RedPacketBalancePage.depositAddress,
                        'lockedTransferTarget': true,
                        'title': '红包充值',
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  _RedPacketTransferTarget? _resolveTransferTarget(RedPacketAsset asset) {
    final wallet = AccountManager().currentWallet;
    if (wallet == null) return null;

    final chainId = _chainIdForAsset(asset);
    ChainAccount? chain;
    for (final item in wallet.chains) {
      if (item.chainId == chainId) {
        chain = item;
        break;
      }
    }
    if (chain == null) return null;

    final contract = (asset.contract ?? '').trim().toLowerCase();
    final symbol = asset.symbol.trim().toUpperCase();
    TokenModel? token;
    for (final item in chain.tokens) {
      final itemAddress = item.address.trim().toLowerCase();
      final itemSymbol = item.symbol.trim().toUpperCase();
      if (contract.isNotEmpty && itemAddress == contract) {
        token = item;
        break;
      }
      if (contract.isEmpty && itemSymbol == symbol && item.address.isEmpty) {
        token = item;
        break;
      }
      if (itemSymbol == symbol && token == null) {
        token = item;
      }
    }
    if (token == null) return null;

    return _RedPacketTransferTarget(chain: chain, token: token);
  }

  int _chainIdForAsset(RedPacketAsset asset) {
    final prefix = asset.assetId.split('-').first.toLowerCase();
    switch (prefix) {
      case 'bsc':
        return 56;
      case 'eth':
      case 'ethereum':
        return 1;
      case 'polygon':
      case 'matic':
        return 137;
      case 'arb':
      case 'arbitrum':
        return 42161;
      case 'op':
      case 'optimism':
        return 10;
      case 'base':
        return 8453;
      case 'tron':
      case 'trx':
        return 728126428;
      case 'sol':
      case 'solana':
        return 101;
      case 'btc':
      case 'bitcoin':
        return 0;
      default:
        return 56;
    }
  }
}

class _RedPacketTransferTarget {
  const _RedPacketTransferTarget({required this.chain, required this.token});

  final ChainAccount chain;
  final TokenModel token;
}
