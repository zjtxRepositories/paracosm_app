import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/get_utils/src/extensions/widget_extensions.dart';

import '../../modules/dapp/dapp_account_auth_hive.dart';
import '../../modules/wallet/model/chain_account.dart';
import '../../modules/wallet/model/wallet_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../base/app_localizations.dart';
import '../common/app_modal.dart';
import '../common/app_network_image.dart';

class DappModals {
  static void showConnectSheet({
    required BuildContext context,
    required String host,
    required String title,
    required String faviconUrl,
    required String uri,
    required VoidCallback onApprove,
    required VoidCallback onReject,
  }) {

    final themeData = Theme.of(context);
    final addAuthRx = true.obs;

    AppModal.show(
      context,
      title: 'Request accounts',
      confirmText: null, // 你自己控制按钮
      onConfirm: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: double.infinity),

          /// favicon
          AppNetworkImage(
            url: faviconUrl,
            width: 16,
            height: 16,
            fit: BoxFit.contain,
              borderRadius: BorderRadius.all(Radius.circular(32))
          ),
          /// 标题
          Text(
            '$title wants to connect to your wallet',
            style: themeData.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ).marginOnly(left: 32, right: 32, top: 16, bottom: 8),

          /// URL
          Text(
            uri,
            style: themeData.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ).marginSymmetric(horizontal: 32),

          /// checkbox
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() {
                return Checkbox(
                  value: addAuthRx.value,
                  onChanged: (v) => addAuthRx.value = v ?? false,
                );
              }),
              Text('Never ask this app again in the future'),
            ],
          ),

          const SizedBox(height: 24),

          /// 按钮区域（自己控制）
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              /// Reject
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onReject();
                },
                child: Text('Reject'),
              ),

              /// Approve
              ElevatedButton(
                onPressed: () {
                  if (addAuthRx.value) {
                    DAppAccountAuthHive.add(host);
                  }
                  Navigator.pop(context);
                  onApprove();
                },
                child: Text('Connect'),
              ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }


  /// =========================
  /// dapp-支付详情
  /// =========================
  static void showTransactionDetail(
      BuildContext context, {
        required String amount,
        required String logo,
        required String absenteeism,
        required String from,
        required String to,
        required String max,
        required String detailUrl,
        required VoidCallback onConfirm,
      }) {
    AppModal.show(
      context,
      title: AppLocalizations.of(context)!.profileTokenDetailPaymentDetails,
      confirmText: AppLocalizations.of(context)!.profileTokenDetailConfirm,
      onConfirm: () {
        onConfirm();
        // 先关闭当前弹窗
        Navigator.of(context, rootNavigator: true).pop();
        // 确保在下一帧显示，避免 Navigator 状态锁定
        // WidgetsBinding.instance.addPostFrameCallback((_) {
        //   if (mounted) {
        //     _showSignInfoModal();
        //   }
        // });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 金额和状态 (Amount and Status)
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '-$amount',
                      style: AppTextStyles.h1.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(width: 4),
                    AppNetworkImage(
                      url: logo,
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Turning out',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.grey100, height: 1),
          const SizedBox(height: 24),

          // 交易时间 (Transaction Time)
          // 发送方 (From Address)
          buildDetailItem(
            label: AppLocalizations.of(context)!.profileTokenDetailFrom,
            subLabel: '(BSC-HD)',
            value: from,
          ),
          const SizedBox(height: 20),

          // 接收方 (To Address)
          buildDetailItem(
            label: AppLocalizations.of(context)!.profileTokenDetailTo,
            value: to,
          ),
          const SizedBox(height: 20),

          // 网络费用 (Network Fees)
          buildDetailItem(
            label: AppLocalizations.of(context)!.profileTokenDetailNetworkFees,
            subLabel: '(Estimated \$0~ maximum \$0)',
            value: '0 BNB~0 BNB',
            showArrow: true,
          ),
          const SizedBox(height: 8),

          // 风险提示 (Warning)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/images/common/tips-error-icon.png',
                width: 16,
                height: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'The transaction can be executed for free and can be opened at',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12,
                    color: AppColors.error,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 更多交易详情链接 (More Transaction Details Link)
          Center(
            child: GestureDetector(
              onTap: () {
                // TODO: 跳转到更多详情 (Navigate to more details)
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'More transaction details',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 16,
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.primaryLight,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// =========================
  /// dapp-支付详情
  /// =========================
  static void showSignInfoModal(
      BuildContext context, {
        required String amount,
        required String logo,
        required String absenteeism,
        required String from,
        required String to,
        required VoidCallback onConfirm,
        required bool isSend,
      }) {
    AppModal.show(
      context,
      title: AppLocalizations.of(context)!.profileTokenDetailRequestToSign,
      confirmText: AppLocalizations.of(context)!.profileTokenDetailConfirm,
      cancelText: AppLocalizations.of(context)!.profileTokenDetailRefused,
      confirmWidth: 160,
      cancelBorder: BorderSide(color: AppColors.grey200),
      cancelWidth: 160,
      onConfirm: () => Navigator.pop(context),
      onCancel: () => Navigator.pop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // 顶部图标和域名 (Top Icon and Domain)
          Center(
            child: Column(
              children: [
                Image.asset(
                  'assets/images/profile/layer.png',
                  width: 32,
                  height: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'www.PARACOSM markets',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12,
                    color: AppColors.grey400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.grey100, height: 1),
          const SizedBox(height: 24),

          // 消息部分 (Message Section)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 消息内容 (Message Content)
                Text(
                  'Message',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12,
                    color: AppColors.grey400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'login',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.grey100, height: 1),
          const SizedBox(height: 24),

          // 签名钱包 (Signature Wallet)
          buildDetailItem(
            label: AppLocalizations.of(context)!.profileTokenDetailSignatureWallet,
            value: '0485CF569D5f2D0f823A9c51a2ba66074481aEb89',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );

  }

  /// 构建详情项 (Build Detail Item Widget)
  static Widget buildDetailItem({
    required String label,
    String? subLabel,
    required String value,
    bool showArrow = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                color: AppColors.grey600,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                if (subLabel != null)
                  Text(
                    subLabel,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 12,
                      color: AppColors.grey400,
                    ),
                  ),
                if (showArrow) ...[
                  const SizedBox(width: 4),
                  Image.asset(
                    'assets/images/common/next.png',
                    width: 16,
                    height: 16,
                    color: AppColors.grey400,
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontSize: 14,
              color: AppColors.grey900,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

}