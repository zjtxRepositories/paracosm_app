import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../modules/dapp/dapp_account_auth_hive.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../common/app_network_image.dart';

class DappModals {
  /// =========================
  /// Connect Wallet
  /// =========================
  static Future<bool?> showConnectSheet({
    required BuildContext context,
    required String host,
    required String title,
    required String faviconUrl,
    required String uri,
  }) {
    final addAuthRx = true.obs;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        final theme = Theme.of(context);

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
                Obx(() => CheckboxListTile(
                  value: addAuthRx.value,
                  onChanged: (v) => addAuthRx.value = v ?? false,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Remember this site'),
                  controlAffinity: ListTileControlAffinity.leading,
                )),

                const SizedBox(height: 16),

                /// 按钮
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (addAuthRx.value) {
                            DAppAccountAuthHive.add(host);
                          }
                          Navigator.pop(context, true);
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
      }) {
    return showModalBottomSheet<bool>(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '-$amount',
                      style: AppTextStyles.h1.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    AppNetworkImage(
                      url: logo,
                      width: 20,
                      height: 20,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _detailItem('From', from),
                const SizedBox(height: 12),
                _detailItem('To', to),

                const SizedBox(height: 20),

                /// 风险提示
                Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Make sure this transaction is safe',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 12,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

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
                        child: const Text('Confirm'),
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

  /// =========================
  /// Sign Message
  /// =========================
  static Future<bool?> showSignInfoModal(
      BuildContext context, {
        required String message,
        required String address,
      }) {
    return showModalBottomSheet<bool>(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Signature Request',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 16),

                _detailItem('Address', address),

                const SizedBox(height: 12),

                /// Message
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    message,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      color: AppColors.grey800,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

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
                        child: const Text('Sign'),
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

  static Widget _detailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontSize: 12,
            color: AppColors.grey400,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontSize: 14,
              color: AppColors.grey900,
            ),
          ),
        ),
      ],
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
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}