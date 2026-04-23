import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../pages/dapp/dapp_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../common/app_network_image.dart';

class DappModals {
  /// =========================
  /// Connect Wallet
  /// =========================
  static Future<DAppConnectDecision?> showConnectSheet({
    required BuildContext context,
    required String host,
    required String title,
    required String faviconUrl,
    required String uri,
  }) {
    final addAuthRx = true.obs;

    return showModalBottomSheet<DAppConnectDecision>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (modalContext) {
        final theme = Theme.of(modalContext);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// favicon
                AppNetworkImage(
                  url: faviconUrl,
                  width: 40,
                  height: 40,
                  borderRadius: BorderRadius.circular(20),
                ),

                const SizedBox(height: 12),

                /// 标题
                Text(
                  '$host wants to connect to your wallet',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 6),

                /// URL
                Text(
                  uri,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.grey400,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                /// 权限说明
                _permissionItem('View wallet balance'),
                _permissionItem('Request transactions'),
                _permissionItem('Request signatures'),

                const SizedBox(height: 16),

                /// Remember
                Obx(
                  () => CheckboxListTile(
                    value: addAuthRx.value,
                    onChanged: (v) => addAuthRx.value = v ?? false,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Remember this site'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),

                const SizedBox(height: 16),

                /// 按钮
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(
                            modalContext,
                            const DAppConnectDecision(
                              approved: false,
                              remember: false,
                            ),
                          );
                        },
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(
                            modalContext,
                            DAppConnectDecision(
                              approved: true,
                              remember: addAuthRx.value,
                            ),
                          );
                        },
                        child: const Text('Connect'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  /// =========================
  /// Send Transaction
  /// =========================
  static Future<bool?> showTransactionDetail(
    BuildContext context, {
    required String amount,
    required String logo,
    required String from,
    required String to,
    String? walletLabel,
    String? feeDescription,
    BigInt? gasLimit,
    bool isContractCall = false,
    String? data,
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
                title: 'Payment Details',
                onClose: () => Navigator.pop(modalContext, false),
              ),
              _divider(),
              const SizedBox(height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '-$amount',
                    style: AppTextStyles.h1.copyWith(
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppNetworkImage(
                    url: logo,
                    width: 34,
                    height: 34,
                    borderRadius: BorderRadius.circular(17),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Turning out',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 26),
              _divider(),
              const SizedBox(height: 26),
              _sectionTitle('From', trailing: walletLabel),
              const SizedBox(height: 12),
              _valueCard(from),
              const SizedBox(height: 24),
              _sectionTitle('To'),
              const SizedBox(height: 12),
              _valueCard(to),
              const SizedBox(height: 24),
              _sectionTitle(
                'Network Fees',
                trailing: feeDescription,
                trailingIcon: Icons.chevron_right,
              ),
              const SizedBox(height: 12),
              _valueCard(
                gasLimit == null
                    ? 'Pending estimation'
                    : 'Gas limit ${gasLimit.toString()}',
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 18,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isContractCall
                          ? 'This request includes a contract call. Review the target and data before confirming.'
                          : 'Make sure this transaction is safe before confirming.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 14,
                        color: AppColors.error,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
              if (data != null && data.isNotEmpty) ...[
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'More transaction details  ›',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _valueCard(_shortHex(data)),
              ],
              const SizedBox(height: 24),
              _primaryAction(
                label: 'Confirm',
                onPressed: () => Navigator.pop(modalContext, true),
              ),
            ],
          ),
        );
      },
    );
  }

  /// =========================
  /// Sign Message
  /// =========================
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
              const SizedBox(height: 28),
              _siteMark(faviconUrl),
              const SizedBox(height: 12),
              Text(
                host,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 16,
                  color: AppColors.grey400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              _labeledCard(label: 'Message', value: message, minHeight: 132),
              const SizedBox(height: 28),
              _divider(),
              const SizedBox(height: 28),
              _sectionTitle('Signature Wallet', trailing: walletLabel),
              const SizedBox(height: 12),
              _valueCard(address),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: _secondaryAction(
                      label: 'Refused',
                      onPressed: () => Navigator.pop(modalContext, false),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _primaryAction(
                      label: 'Confirm',
                      onPressed: () => Navigator.pop(modalContext, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// =========================
  /// 工具组件
  /// =========================

  static Widget _permissionItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 6),
          Text(text),
        ],
      ),
    );
  }

  static String _shortHex(String value) {
    if (value.length <= 24) {
      return value;
    }
    return '${value.substring(0, 12)}...${value.substring(value.length - 8)}';
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 14, 28, 28),
            child: child,
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
          width: 110,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.grey200,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 26),
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.h1.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onClose,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 34, color: AppColors.grey700),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Widget _divider() {
    return Container(height: 1, color: AppColors.grey200);
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
            style: AppTextStyles.h2.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.grey600,
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
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 16,
                      color: AppColors.grey400,
                    ),
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 2),
                  Icon(trailingIcon, size: 22, color: AppColors.grey400),
                ],
              ],
            ),
          ),
      ],
    );
  }

  static Widget _valueCard(String value, {double minHeight = 88}) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        value,
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.grey900,
          height: 1.45,
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey200),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 15,
              color: AppColors.grey400,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.grey900,
              height: 1.35,
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
        width: 48,
        height: 48,
        borderRadius: BorderRadius.circular(24),
      );
    }
    return const Icon(
      Icons.layers_outlined,
      size: 54,
      color: AppColors.grey900,
    );
  }

  static Widget _primaryAction({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 72,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.grey900,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: AppTextStyles.h1.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
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
      height: 72,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.grey900,
          side: const BorderSide(color: AppColors.grey300, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: AppTextStyles.h1.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.grey900,
          ),
        ),
      ),
    );
  }
}

/// =========================
/// Add Chain
/// =========================
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
      useRootNavigator: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add Network',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 16),

                _item('Network Name', name),
                _item('Chain ID', '0x${chainId.toRadixString(16)}'),
                _item('Currency', symbol),
                _item('RPC URL', rpc),
                _item('Source', origin),

                const SizedBox(height: 16),

                const Text(
                  '⚠️ Make sure you trust this network',
                  style: TextStyle(color: Colors.orange),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _item(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
