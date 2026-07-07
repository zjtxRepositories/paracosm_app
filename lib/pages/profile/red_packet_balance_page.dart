import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/core/network/api/red_packet_api.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/wallet/model/chain_account.dart';
import 'package:paracosm/modules/wallet/model/token_model.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_button.dart';
import 'package:paracosm/widgets/common/app_empty_view.dart';
import 'package:paracosm/widgets/common/app_toast.dart';

class RedPacketBalancePage extends StatefulWidget {
  const RedPacketBalancePage({super.key});

  static const depositAddress = '0x67e607F8aeB0C4d4F5A37cB26C0702069b18961f';

  @override
  State<RedPacketBalancePage> createState() => _RedPacketBalancePageState();
}

class _RedPacketBalancePageState extends State<RedPacketBalancePage> {
  static const int _balanceFractionDigits = 5;

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
    final l10n = AppLocalizations.of(context)!;

    return AppPage(
      title: l10n.profileRedPacketBalance,
      backgroundColor: AppColors.white,
      headerActions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextButton(
            onPressed: () => context.push('/red-packet-withdraw'),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              minimumSize: const Size(54, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              l10n.profileRedPacketWithdraw,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _assets.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 160),
                  AppEmptyView(
                    text: l10n.profileRedPacketNoAssets,
                    bottomOffset: 0,
                  ),
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
    final l10n = AppLocalizations.of(context)!;
    final display = _formatBalanceDisplay(balance);
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
                  l10n.profileRedPacketChainBalance(chain),
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
                  child: Text(l10n.profileRedPacketDeposit),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDepositSheet(RedPacketAsset asset) {
    final l10n = AppLocalizations.of(context)!;
    final target = _resolveTransferTarget(asset);
    if (target == null) {
      AppToast.show(l10n.profileRedPacketAssetUnsupported);
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
                  l10n.profileRedPacketDepositTitle(asset.symbol),
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.grey900,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.profileRedPacketDepositDesc(
                    chain: target.chain.name,
                    symbol: asset.symbol,
                  ),
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
                  text: l10n.profileRedPacketDepositConfirm,
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
                        'redPacketChainId': asset.chainId,
                        'redPacketContract': asset.contract,
                        'title': l10n.profileRedPacketDepositTitle(
                          asset.symbol,
                        ),
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

    final chainId = asset.chainId ?? _chainIdForAsset(asset);
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
      if (contract.isEmpty && (item.isNative || item.address.isEmpty)) {
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

  String _formatBalanceDisplay(RedPacketBalance? balance) {
    if (balance == null) {
      return _zeroBalanceDisplay();
    }

    final available = BigInt.tryParse(balance.available.trim());
    if (available != null) {
      return _formatUnitsFixed(
        available,
        balance.decimals,
        _balanceFractionDigits,
      );
    }

    return _formatDecimalFixed(balance.display, _balanceFractionDigits);
  }

  String _formatUnitsFixed(BigInt amount, int decimals, int fractionDigits) {
    final safeDecimals = decimals < 0 ? 0 : decimals;
    final safeDigits = fractionDigits < 0 ? 0 : fractionDigits;
    final sign = amount.isNegative ? '-' : '';
    final absAmount = amount.abs();
    final divisor = BigInt.from(10).pow(safeDecimals);
    final integer = absAmount ~/ divisor;

    if (safeDigits == 0) {
      return '$sign$integer';
    }

    final decimal = absAmount % divisor;
    var decimalText = safeDecimals == 0
        ? ''
        : decimal.toString().padLeft(safeDecimals, '0');
    decimalText = decimalText.padRight(safeDigits, '0');
    decimalText = decimalText.substring(0, safeDigits);

    return '$sign$integer.$decimalText';
  }

  String _formatDecimalFixed(String value, int fractionDigits) {
    final safeDigits = fractionDigits < 0 ? 0 : fractionDigits;
    final text = value.trim();
    if (text.isEmpty || text.startsWith('<')) {
      return _zeroBalanceDisplay();
    }

    final sign = text.startsWith('-') ? '-' : '';
    final unsigned = text.startsWith('-') || text.startsWith('+')
        ? text.substring(1)
        : text;
    final parts = unsigned.split('.');
    final integer = parts.isNotEmpty && parts.first.isNotEmpty
        ? parts.first
        : '0';
    final fraction = parts.length > 1 ? parts.sublist(1).join() : '';

    if (!RegExp(r'^\d+$').hasMatch(integer) ||
        (fraction.isNotEmpty && !RegExp(r'^\d+$').hasMatch(fraction))) {
      return text;
    }

    if (safeDigits == 0) {
      return '$sign$integer';
    }

    final decimalText = fraction
        .padRight(safeDigits, '0')
        .substring(0, safeDigits);
    return '$sign$integer.$decimalText';
  }

  String _zeroBalanceDisplay() {
    if (_balanceFractionDigits == 0) return '0';
    return '0.${'0' * _balanceFractionDigits}';
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
