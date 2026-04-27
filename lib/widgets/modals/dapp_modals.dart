import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../modules/wallet/chains/model/gas_fee.dart';
import '../../pages/dapp/dapp_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../util/string_util.dart';
import '../base/app_localizations.dart';
import '../common/app_network_image.dart';
import '../slider/td_slider.dart';
import '../slider/td_slider_theme.dart';

class DappModals {
  static Future<DAppConnectDecision?> showConnectSheet({
    required BuildContext context,
    required String host,
    required String title,
    required String faviconUrl,
    required String uri,
  }) {
    final rememberSite = true.obs;

    return showModalBottomSheet<DAppConnectDecision>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return _sheetScaffold(
          context: modalContext,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHeader(
                modalContext,
                title: 'Connect Wallet',
                onClose: () => Navigator.pop(
                  modalContext,
                  const DAppConnectDecision(approved: false, remember: false),
                ),
              ),
              _divider(),
              const SizedBox(height: 24),
              _siteMark(faviconUrl),
              const SizedBox(height: 12),
              _centerTitle(host),
              const SizedBox(height: 4),
              _mutedText(uri, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              _infoCard(
                children: [
                  _permissionItem('View wallet balance'),
                  _permissionItem('Request transactions'),
                  _permissionItem('Request signatures'),
                ],
              ),
              const SizedBox(height: 8),
              Obx(
                () => CheckboxListTile(
                  value: rememberSite.value,
                  onChanged: (value) => rememberSite.value = value ?? false,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.grey900,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    'Remember this site',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _actionRow(
                secondaryLabel: 'Reject',
                primaryLabel: 'Connect',
                onSecondary: () => Navigator.pop(
                  modalContext,
                  const DAppConnectDecision(approved: false, remember: false),
                ),
                onPrimary: () => Navigator.pop(
                  modalContext,
                  DAppConnectDecision(
                    approved: true,
                    remember: rememberSite.value,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<DappTransactionDecision?> showTransactionDetail(
    BuildContext context, {
    required String amount,
    required String logo,
    required String from,
    required String to,
    required GasLevel gasLevel,
    required String feeSymbol,
    String? walletLabel,
    String? feeDescription,
    BigInt? gasLimit,
    bool isContractCall = false,
    String? data,
  }) {
    return showModalBottomSheet<DappTransactionDecision>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        final l10n = AppLocalizations.of(modalContext)!;
        var selectedLevel = FeeLevel.medium;
        var isExpanded = false;
        final displayGasLimit =
            gasLimit ??
            (isContractCall ? BigInt.from(100000) : BigInt.from(21000));

        return _paymentSheetScaffold(
          context: modalContext,
          title: l10n.profileTransferPaymentDetails,
          onClose: () => Navigator.pop(
            modalContext,
            const DappTransactionDecision(approved: false),
          ),
          confirmLabel: l10n.commonConfirm,
          onConfirm: () => Navigator.pop(
            modalContext,
            DappTransactionDecision(
              approved: true,
              gasFee: _gasFeeForLevel(gasLevel, selectedLevel),
            ),
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final selectedGas = _gasFeeForLevel(gasLevel, selectedLevel);
              final estimatedFee = _formatEvmFee(
                selectedGas,
                displayGasLimit,
                feeSymbol,
              );

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          '-$amount',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.h1.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      AppNetworkImage(
                        url: logo,
                        width: 20,
                        height: 20,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$estimatedFee (${l10n.profileTransferFeeEstimated})',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 12,
                      color: AppColors.grey400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _divider(),
                  const SizedBox(height: 16),
                  _field(label: 'From', value: from, trailing: walletLabel),
                  const SizedBox(height: 16),
                  _field(label: 'To', value: to),
                  const SizedBox(height: 16),
                  _field(
                    label: l10n.profileTransferNetworkFees,
                    value: '${l10n.profileTransferGasLimit} $displayGasLimit',
                    trailing: feeDescription,
                    trailingIcon: Icons.chevron_right,
                  ),
                  const SizedBox(height: 16),
                  _feeLevelSelector(
                    l10n: l10n,
                    selectedLevel: selectedLevel,
                    gasLevel: gasLevel,
                    gasLimit: displayGasLimit,
                    feeSymbol: feeSymbol,
                    onSelected: (level) {
                      setModalState(() => selectedLevel = level);
                    },
                  ),
                  const SizedBox(height: 12),
                  _warningText(
                    isContractCall
                        ? 'This request includes a contract call. Review the target and data before confirming.'
                        : 'Make sure this transaction is safe before confirming.',
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => setModalState(() => isExpanded = !isExpanded),
                    child: _linkAction(
                      label: isExpanded
                          ? l10n.profileTransferHideTransactionInfo
                          : l10n.profileTransferMoreTransactionInfo,
                      icon: isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                    ),
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 12),
                    _infoCard(
                      children: [
                        _detailItem('From', from, copyable: true),
                        _detailItem('To', to, copyable: true),
                        _detailItem(
                          l10n.profileTransferFeeLevel,
                          _feeLevelLabel(l10n, selectedLevel),
                        ),
                        _detailItem(
                          l10n.profileTransferEstimatedFee,
                          estimatedFee,
                        ),
                        _detailItem(
                          l10n.profileTransferFeeRate,
                          '${truncateDouble(GasCalculator.toGwei(selectedGas.gasPrice ?? selectedGas.maxFeePerGas), digits: 4)} Gwei',
                        ),
                        _detailItem(
                          l10n.profileTransferGasLimit,
                          displayGasLimit.toString(),
                        ),
                        if (data != null && data.isNotEmpty)
                          _detailItem(
                            l10n.profileTransferContractData,
                            _shortHex(data),
                            copyable: true,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        );
      },
    );
  }

  static Future<bool?> showSignInfoModal(
    BuildContext context, {
    required String message,
    required String address,
    required String host,
    required String faviconUrl,
    String? walletLabel,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return _sheetScaffold(
          context: modalContext,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHeader(
                modalContext,
                title: 'Request to Sign Information',
                onClose: () => Navigator.pop(modalContext, false),
              ),
              _divider(),
              const SizedBox(height: 24),
              _siteMark(faviconUrl),
              const SizedBox(height: 12),
              _centerTitle(host),
              const SizedBox(height: 24),
              _labeledCard(label: 'Message', value: message, minHeight: 132),
              const SizedBox(height: 24),
              _divider(),
              const SizedBox(height: 24),
              _field(
                label: 'Signature Wallet',
                value: address,
                trailing: walletLabel,
              ),
              const SizedBox(height: 24),
              _actionRow(
                secondaryLabel: 'Refused',
                primaryLabel: 'Confirm',
                onSecondary: () => Navigator.pop(modalContext, false),
                onPrimary: () => Navigator.pop(modalContext, true),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<bool?> showWatchAssetSheet(
    BuildContext context, {
    required String host,
    required String address,
    required String symbol,
    required int decimals,
    required String image,
    required String chainName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return _sheetScaffold(
          context: modalContext,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHeader(
                modalContext,
                title: 'Add Token',
                onClose: () => Navigator.pop(modalContext, false),
              ),
              _divider(),
              const SizedBox(height: 24),
              _siteMark(image),
              const SizedBox(height: 12),
              _centerTitle(symbol),
              const SizedBox(height: 4),
              _mutedText(host, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              _field(label: 'Network', value: address, trailing: chainName),
              const SizedBox(height: 24),
              _field(
                label: 'Token Details',
                value: 'Symbol $symbol\nDecimals $decimals',
              ),
              const SizedBox(height: 24),
              _actionRow(
                secondaryLabel: 'Reject',
                primaryLabel: 'Add Token',
                onSecondary: () => Navigator.pop(modalContext, false),
                onPrimary: () => Navigator.pop(modalContext, true),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _sheetScaffold({
    required BuildContext context,
    required Widget child,
  }) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 58),
            child: child,
          ),
        ),
      ),
    );
  }

  static Widget _paymentSheetScaffold({
    required BuildContext context,
    required String title,
    required Widget child,
    required String confirmLabel,
    required VoidCallback onClose,
    required VoidCallback onConfirm,
  }) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sheetHeader(context, title: title, onClose: onClose),
              _divider(),
              Flexible(child: SingleChildScrollView(child: child)),
              const SizedBox(height: 24),
              _primaryAction(label: confirmLabel, onPressed: onConfirm),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _sheetHeader(
    BuildContext context, {
    required String title,
    required VoidCallback onClose,
  }) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 5,
          decoration: BoxDecoration(
            color: AppColors.grey300,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.h1.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 24 / 16,
                ),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onClose,
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.close, size: 24, color: AppColors.grey700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  static Widget _field({
    required String label,
    required String value,
    String? trailing,
    IconData? trailingIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(label, trailing: trailing, trailingIcon: trailingIcon),
        const SizedBox(height: 12),
        _valueCard(value),
      ],
    );
  }

  static Widget _sectionTitle(
    String title, {
    String? trailing,
    IconData? trailingIcon,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.grey600,
              height: 22 / 14,
            ),
          ),
        ),
        if (trailing != null && trailing.isNotEmpty)
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    trailing,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 12,
                      color: AppColors.grey400,
                    ),
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 4),
                  Icon(trailingIcon, size: 20, color: AppColors.grey400),
                ],
              ],
            ),
          ),
      ],
    );
  }

  static Widget _valueCard(String value, {double minHeight = 58}) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        value,
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.grey900,
          height: 22 / 14,
        ),
      ),
    );
  }

  static Widget _labeledCard({
    required String label,
    required String value,
    double minHeight = 120,
  }) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.grey900,
              height: 22 / 14,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _siteMark(String faviconUrl) {
    if (faviconUrl.isNotEmpty) {
      return AppNetworkImage(
        url: faviconUrl,
        width: 44,
        height: 44,
        borderRadius: BorderRadius.circular(22),
      );
    }
    return const Icon(
      Icons.layers_outlined,
      size: 44,
      color: AppColors.grey900,
    );
  }

  static Widget _centerTitle(String text) {
    return Text(
      text,
      style: AppTextStyles.h1.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.grey900,
      ),
      textAlign: TextAlign.center,
    );
  }

  static Widget _mutedText(
    String text, {
    TextAlign textAlign = TextAlign.start,
  }) {
    return Text(
      text,
      style: AppTextStyles.caption.copyWith(
        fontSize: 12,
        color: AppColors.grey400,
      ),
      textAlign: textAlign,
    );
  }

  static Widget _warningText(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline, size: 16, color: AppColors.error),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(
              fontSize: 12,
              color: AppColors.error,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _linkAction({
    required String label,
    IconData icon = Icons.chevron_right,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.primaryLight,
            height: 24 / 16,
          ),
        ),
        const SizedBox(width: 4),
        Icon(icon, size: 16, color: AppColors.primaryLight),
      ],
    );
  }

  static Widget _infoCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  static Widget _permissionItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 18,
            color: AppColors.grey900,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 14,
                color: AppColors.grey900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _actionRow({
    required String secondaryLabel,
    required String primaryLabel,
    required VoidCallback onSecondary,
    required VoidCallback onPrimary,
  }) {
    return Row(
      children: [
        Expanded(
          child: _secondaryAction(
            label: secondaryLabel,
            onPressed: onSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _primaryAction(label: primaryLabel, onPressed: onPrimary),
        ),
      ],
    );
  }

  static Widget _primaryAction({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.grey900,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: AppTextStyles.h1.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
            height: 24 / 16,
          ),
        ),
      ),
    );
  }

  static Widget _secondaryAction({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.grey900,
          side: const BorderSide(color: AppColors.grey300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: AppTextStyles.h1.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.grey900,
            height: 24 / 16,
          ),
        ),
      ),
    );
  }

  static Widget _divider() {
    return Container(height: 1, color: AppColors.grey200);
  }

  static String _shortHex(String value) {
    if (value.length <= 24) return value;
    return '${value.substring(0, 12)}...${value.substring(value.length - 8)}';
  }

  static GasFee _gasFeeForLevel(GasLevel gasLevel, FeeLevel feeLevel) {
    switch (feeLevel) {
      case FeeLevel.slow:
        return gasLevel.slow;
      case FeeLevel.medium:
        return gasLevel.medium;
      case FeeLevel.fast:
        return gasLevel.fast;
    }
  }

  static String _feeLevelLabel(AppLocalizations l10n, FeeLevel level) {
    switch (level) {
      case FeeLevel.slow:
        return l10n.profileTransferSlow;
      case FeeLevel.medium:
        return l10n.profileTransferMiddle;
      case FeeLevel.fast:
        return l10n.profileTransferFast;
    }
  }

  static String _formatEvmFee(
    GasFee gasFee,
    BigInt gasLimit,
    String feeSymbol,
  ) {
    final fee = GasCalculator.calculateEthFee(gasLimit: gasLimit, fee: gasFee);
    return '${truncateDouble(fee)} $feeSymbol';
  }

  static double _sliderValueForFeeLevel(FeeLevel level) {
    switch (level) {
      case FeeLevel.slow:
        return 0;
      case FeeLevel.medium:
        return 0.5;
      case FeeLevel.fast:
        return 1;
    }
  }

  static FeeLevel _feeLevelFromSliderValue(double value) {
    if (value <= 0.25) return FeeLevel.slow;
    if (value < 0.75) return FeeLevel.medium;
    return FeeLevel.fast;
  }

  static Widget _feeLevelSelector({
    required AppLocalizations l10n,
    required FeeLevel selectedLevel,
    required GasLevel gasLevel,
    required BigInt gasLimit,
    required String feeSymbol,
    required ValueChanged<FeeLevel> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.profileTransferFeeLevel,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.grey600,
          ),
        ),
        const SizedBox(height: 10),
        TDSlider(
          value: _sliderValueForFeeLevel(selectedLevel),
          onChanged: (value) {
            onSelected(_feeLevelFromSliderValue(value));
          },
          sliderThemeData: TDSliderThemeData(
            min: 0,
            max: 1,
            divisions: 2,
            showScaleValue: true,
            scaleFormatter: (value) {
              return _feeLevelLabel(l10n, _feeLevelFromSliderValue(value));
            },
          ),
        ),
      ],
    );
  }

  static Widget _detailItem(
    String label,
    String value, {
    bool copyable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 12,
                color: AppColors.grey600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (copyable) ...[
            const Icon(Icons.copy, size: 14, color: AppColors.grey400),
            const SizedBox(width: 4),
          ],
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.caption.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.grey900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DAppAddChainSheet {
  static Future<bool?> show(
    BuildContext context, {
    required String name,
    required int chainId,
    required String rpc,
    required String symbol,
    required String origin,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return DappModals._sheetScaffold(
          context: modalContext,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DappModals._sheetHeader(
                modalContext,
                title: 'Add Network',
                onClose: () => Navigator.pop(modalContext, false),
              ),
              DappModals._divider(),
              const SizedBox(height: 24),
              DappModals._infoCard(
                children: [
                  _item('Network Name', name),
                  _item('Chain ID', '0x${chainId.toRadixString(16)}'),
                  _item('Currency', symbol),
                  _item('RPC URL', rpc),
                  _item('Source', origin),
                ],
              ),
              const SizedBox(height: 16),
              DappModals._warningText(
                'Make sure you trust this network before adding it.',
              ),
              const SizedBox(height: 24),
              DappModals._actionRow(
                secondaryLabel: 'Reject',
                primaryLabel: 'Approve',
                onSecondary: () => Navigator.pop(modalContext, false),
                onPrimary: () => Navigator.pop(modalContext, true),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _item(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(color: AppColors.grey600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 14,
                color: AppColors.grey900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
