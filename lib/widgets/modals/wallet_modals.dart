import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/widgets/common/app_chain_selector.dart';
import 'package:paracosm/widgets/modals/wallet_select_token_modal.dart';
import 'package:paracosm/widgets/modals/wallet_switcher_modal.dart';
import '../../modules/account/model/account_model.dart';
import '../../modules/wallet/manager/wallet_manager.dart';
import '../../modules/wallet/model/chain_account.dart';
import '../../modules/wallet/model/token_model.dart';
import '../../modules/wallet/model/wallet_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../base/app_localizations.dart';
import '../common/app_modal.dart';
import '../common/app_network_image.dart';
import '../common/app_network_selector.dart';

class WalletModals {
  /// =========================
  /// 网络选择
  /// =========================
  static void showNetworkSelector({
    required BuildContext context,
    required WalletModel wallet,
    required Function(ChainAccount) onSelected,
  }) {
    AppModal.show(
      context,
      title: AppLocalizations.of(context)!.profileProfileDetailsChooseNetwork,
      confirmText: null,
      onConfirm: () {},
      child: AppNetworkSelector(
        initialNetwork: wallet.currentChain ?? wallet.chains.first,
        networks: wallet.chains,
        onSelected: (network) async {
          WalletManager.switchChain(wallet.id, network.chainId);
          onSelected(network);
          context.pop();
        },
      ),
    );
  }

  /// =========================
  /// 链
  /// =========================
  static void showChainSelector({
    required BuildContext context,
    required WalletModel wallet,
    required Function(ChainAccount) onSelected,
  }) {
    AppModal.show(
      context,
      title: '选择导出地址',
      confirmText: null,
      onConfirm: () {},
      child: AppChainSelector(
        onSelected: (chain) async {
          onSelected(chain);
          context.pop();
        },
      ),
    );
  }

  /// =========================
  /// 代币选择
  /// =========================
  static void showTokenSelector({
    required BuildContext context,
    TokenModel? currentToken,
    required WalletModel wallet,
    required Function(TokenModel) onSelected,
  }) {
    AppModal.show(
      context,
      title: '选择转账代币',
      confirmText: null,
      onConfirm: () {},
      child: WalletSelectTokenModal(
        selectedToken: currentToken,
        wallet: wallet,
        onSelected: (token) async {
          onSelected(token);
          context.pop();
        },
      ),
    );
  }

  /// =========================
  /// 密码输入
  /// =========================
  static Future<void> showPasswordModal({
    required BuildContext context,
    required String title,
    required Future<void> Function(String password) onConfirm,
    Future<bool> Function(String password)? onValidate,
    VoidCallback? onCancel,
  }) {
    final passwordController = TextEditingController();
    bool isObscure = true;

    return AppModal.show(
      context,
      title: title,
      confirmText: AppLocalizations.of(context)!.profileProfileDetailsConfirm,
      cancelText: AppLocalizations.of(context)!.commonCancel,
      onCancel: onCancel,
      onConfirm: () async {
        final password = passwordController.text;
        if (onValidate != null) {
          final isValid = await onValidate(password);
          if (!isValid) {
            return;
          }
        }
        if (context.mounted) {
          context.pop();
        }
        await onConfirm(password);
      },
      child: StatefulBuilder(
        builder: (context, setModalState) {
          final isEmpty = passwordController.text.isEmpty;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: isEmpty ? AppColors.grey100 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isEmpty ? Colors.transparent : AppColors.grey900,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: passwordController,
                        obscureText: isObscure,
                        onChanged: (_) => setModalState(() {}),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setModalState(() => isObscure = !isObscure),
                      child: Image.asset(
                        isObscure
                            ? 'assets/images/common/eye-off-line.png'
                            : 'assets/images/common/eye-line.png',
                        width: 24,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  /// =========================
  /// 钱包管理
  /// =========================
  static void showWalletSwitcher(
    BuildContext context, {
    required List<AccountModel> accounts,
    required Map<String, WalletModel> walletMap,
    required String currentWalletId,
    required Future<void> Function(String address) onSwitch,
    required VoidCallback onAddWallet,
  }) {
    final l10n = AppLocalizations.of(context)!;
    AppModal.show(
      context,
      title: l10n.profileProfileDetailsWallet,
      confirmText: null,
      onConfirm: () {},
      child: WalletSwitcherModal(
        accounts: accounts,
        walletMap: walletMap,
        currentWalletId: currentWalletId,
        onSwitch: onSwitch,
        onAddWallet: onAddWallet,
      ),
    );
  }

  /// =========================
  /// 转账-支付详情
  /// =========================
  static void showPaymentDetails(
    BuildContext context, {
    required String amount,
    required String logo,
    required String absenteeism,
    required String from,
    required String to,
    required VoidCallback onConfirm,
  }) {
    Widget buildDetailRow(String label, String value) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.grey600,
            ),
          ),
          Text(
            value.length > 20
                ? '${value.substring(0, 8)}...${value.substring(value.length - 4)}'
                : value,
            style: AppTextStyles.body.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.grey800,
            ),
          ),
        ],
      );
    }

    AppModal.show(
      context,
      title: AppLocalizations.of(context)!.profileTransferPaymentDetails,
      confirmText: AppLocalizations.of(context)!.profileTransferConfirmPayment,
      onConfirm: onConfirm,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          // 金额显示
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
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
          // 预估金额
          Text(
            '$absenteeism (Absenteeism)',
            style: AppTextStyles.body.copyWith(
              fontSize: 12,
              color: AppColors.grey400,
            ),
          ),
          const SizedBox(height: 24),
          // 分割线
          Container(height: 1, color: AppColors.grey100),
          const SizedBox(height: 16),
          // 地址详情
          buildDetailRow('From', from),
          const SizedBox(height: 12),
          buildDetailRow('To', to),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
