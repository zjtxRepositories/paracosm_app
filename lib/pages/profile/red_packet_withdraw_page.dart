import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/core/network/api/red_packet_api.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_button.dart';
import 'package:paracosm/widgets/common/app_modal.dart';
import 'package:paracosm/widgets/common/app_empty_view.dart';
import 'package:paracosm/widgets/common/app_toast.dart';
import 'package:paracosm/widgets/modals/dapp_modals.dart';

class RedPacketWithdrawPage extends StatefulWidget {
  const RedPacketWithdrawPage({super.key});

  @override
  State<RedPacketWithdrawPage> createState() => _RedPacketWithdrawPageState();
}

class _RedPacketWithdrawPageState extends State<RedPacketWithdrawPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  List<RedPacketAsset> _assets = const [];
  Map<String, RedPacketBalance> _balances = const {};
  RedPacketAsset? _selectedAsset;

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _addressController.dispose();
    super.dispose();
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
        _selectedAsset = assets.isEmpty ? null : assets.first;
        _loading = false;
      });
      _resetWithdrawAddress();
    } catch (e) {
      debugPrint('load withdraw data failed: $e');
      if (!mounted) return;
      setState(() => _loading = false);
      AppToast.show(
        AppLocalizations.of(context)!.profileRedPacketWithdrawAssetLoadFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppPage(
      title: l10n.profileRedPacketWithdrawTitle,
      backgroundColor: AppColors.white,
      headerActions: [
        IconButton(
          tooltip: l10n.profileRedPacketWithdrawRecords,
          onPressed: () => context.push('/red-packet-withdraw-record'),
          icon: const Icon(Icons.receipt_long_outlined, color: AppColors.black),
        ),
      ],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _assets.isEmpty
          ? AppEmptyView(
              text: l10n.profileRedPacketNoWithdrawAssets,
              bottomOffset: 0,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _buildAssetSelector(),
                const SizedBox(height: 18),
                _buildInput(
                  label: l10n.profileRedPacketWithdrawAmount,
                  controller: _amountController,
                  hintText: '0.00',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 18),
                _buildInput(
                  label: l10n.profileRedPacketWithdrawAddress,
                  controller: _addressController,
                  hintText: l10n.profileRedPacketWithdrawAddressHint,
                  multiline: true,
                ),
                const SizedBox(height: 14),
                _buildHint(),
                const SizedBox(height: 28),
                AppButton(
                  text: l10n.profileRedPacketWithdrawApply,
                  isLoading: _submitting,
                  onPressed:
                      _submitting || _amountController.text.trim().isEmpty
                      ? null
                      : _submit,
                  backgroundColor:
                      _amountController.text.trim().isEmpty || _submitting
                      ? AppColors.grey300
                      : AppColors.primaryDark,
                  textColor: Colors.white,
                ),
              ],
            ),
    );
  }

  Widget _buildAssetSelector() {
    final l10n = AppLocalizations.of(context)!;
    final selected = _selectedAsset;
    final selectedBalance = selected == null
        ? null
        : _balances[selected.assetId];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.profileRedPacketWithdrawAsset,
            style: AppTextStyles.caption.copyWith(color: AppColors.grey500),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _showAssetSelector,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selected == null
                        ? l10n.profileRedPacketSelectWithdrawAsset
                        : '${selected.symbol} (${_chainLabel(selected)})',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.grey900,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.grey400),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.profileRedPacketBalanceLabel(
              selectedBalance?.display ?? '0',
              selected?.symbol ?? '',
            ),
            style: AppTextStyles.caption.copyWith(color: AppColors.grey600),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    bool multiline = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.grey600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: multiline ? 78 : null,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grey200),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: multiline ? null : 1,
            style: AppTextStyles.body.copyWith(
              fontSize: 14,
              color: AppColors.grey900,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTextStyles.body.copyWith(
                fontSize: 14,
                color: AppColors.grey400,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
      ],
    );
  }

  void _showAssetSelector() {
    final l10n = AppLocalizations.of(context)!;

    AppModal.show(
      context,
      title: l10n.profileRedPacketChooseWithdrawAsset,
      confirmText: null,
      onConfirm: () {},
      child: SizedBox(
        height: 360,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: _assets.length,
          separatorBuilder: (context, index) =>
              Divider(color: AppColors.grey100),
          itemBuilder: (context, index) {
            final asset = _assets[index];
            final balance = _balances[asset.assetId];
            final selected = asset.assetId == _selectedAsset?.assetId;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                asset.symbol,
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.grey900,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                l10n.profileRedPacketAvailableLabel(
                  balance?.display ?? '0',
                  asset.symbol,
                ),
                style: AppTextStyles.body.copyWith(
                  color: AppColors.grey500,
                  fontSize: 12,
                ),
              ),
              trailing: selected
                  ? const Icon(Icons.check, color: AppColors.grey900)
                  : null,
              onTap: () {
                setState(() => _selectedAsset = asset);
                _resetWithdrawAddress(asset);
                context.pop();
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHint() {
    return Text(
      AppLocalizations.of(context)!.profileRedPacketWithdrawHint,
      style: AppTextStyles.caption.copyWith(
        color: AppColors.grey500,
        height: 1.45,
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final asset = _selectedAsset;
    if (asset == null) {
      AppToast.show(l10n.profileRedPacketSelectWithdrawAsset);
      return;
    }
    final amountText = _amountController.text.trim();
    final to = _addressController.text.trim();
    if (amountText.isEmpty) {
      AppToast.show(l10n.profileRedPacketEnterWithdrawAmount);
      return;
    }
    if (to.isEmpty) {
      AppToast.show(l10n.profileRedPacketMissingWithdrawAddress);
      return;
    }

    final amount = _amountToUnits(amountText, asset.decimals);
    if (amount == null || amount == '0') {
      AppToast.show(l10n.profileRedPacketInvalidWithdrawAmount);
      return;
    }

    RedPacketSignatureRequest signatureRequest;
    try {
      signatureRequest = RedPacketApi.prepareWithdrawSignature(
        assetId: asset.assetId,
        amount: amount,
        to: to,
      );
    } catch (e) {
      AppToast.show(l10n.profileRedPacketInvalidWithdrawParams);
      return;
    }

    final confirmed = await DappModals.showSignInfoModal(
      context,
      message: signatureRequest.message,
      address: signatureRequest.userId,
      host: 'RongCloud withdraw',
      faviconUrl: '',
      walletLabel: AccountManager().currentWallet?.name,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      await RedPacketApi.withdrawApply(
        assetId: asset.assetId,
        amount: amount,
        to: to,
        signatureRequest: signatureRequest,
      );
      if (!mounted) return;
      AppToast.show(l10n.profileRedPacketWithdrawSubmitted);
      _amountController.clear();
      unawaited(_loadData());
    } catch (e) {
      debugPrint('withdraw apply failed: $e');
      if (!mounted) return;
      AppToast.show(l10n.profileRedPacketWithdrawFailed);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _amountToUnits(String value, int decimals) {
    try {
      return redPacketDecimalToUnits(value, decimals);
    } catch (_) {
      return null;
    }
  }

  String _chainLabel(RedPacketAsset asset) {
    final wallet = AccountManager().currentWallet;
    final chainId = asset.chainId;
    if (wallet != null && chainId != null) {
      for (final chain in wallet.chains) {
        if (chain.chainId == chainId && chain.symbol.trim().isNotEmpty) {
          return chain.symbol.trim();
        }
      }
    }
    return asset.assetId.split('-').first.toUpperCase();
  }

  String _withdrawAddress(RedPacketAsset asset) {
    final wallet = AccountManager().currentWallet;
    final chainId = asset.chainId;
    if (wallet == null) return '';
    if (chainId != null) {
      for (final chain in wallet.chains) {
        if (chain.chainId == chainId && chain.address.trim().isNotEmpty) {
          return chain.address.trim();
        }
      }
    }
    return wallet.currentChain?.address.trim() ??
        AccountManager().currentAccount?.accountId.trim() ??
        '';
  }

  void _resetWithdrawAddress([RedPacketAsset? asset]) {
    final targetAsset = asset ?? _selectedAsset;
    if (targetAsset == null) return;
    _addressController.text = _withdrawAddress(targetAsset);
  }
}
