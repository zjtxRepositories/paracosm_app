import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/core/db/dao/wallet_dao.dart';
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
      title: AppLocalizations.of(context)!
          .profileProfileDetailsChooseNetwork,
      confirmText: null,
      onConfirm: () {},
      child: AppNetworkSelector(
        initialNetwork:
        wallet.currentChain ?? wallet.chains.first,
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
  static void showPasswordModal({
    required BuildContext context,
    required String title,
    required Function(String password) onConfirm,
  }) {
    final passwordController = TextEditingController();
    bool isObscure = true;

    AppModal.show(
      context,
      title: title,
      confirmText:
      AppLocalizations.of(context)!
          .profileProfileDetailsConfirm,
      onConfirm: () {
        onConfirm(passwordController.text);
        context.pop();
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
                  color: isEmpty
                      ? AppColors.grey100
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isEmpty
                        ? Colors.transparent
                        : AppColors.grey900,
                  ),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: passwordController,
                        obscureText: isObscure,
                        onChanged: (_) =>
                            setModalState(() {}),
                        decoration:
                        const InputDecoration(
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setModalState(
                              () => isObscure = !isObscure),
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
    Widget _buildDetailRow(String label, String value) {
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
            value.length > 20 ? '${value.substring(0, 8)}...${value.substring(value.length - 4)}' : value,
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
          Container(
            height: 1,
            color: AppColors.grey100,
          ),
          const SizedBox(height: 16),
          // 地址详情
          _buildDetailRow('From', from),
          const SizedBox(height: 12),
          _buildDetailRow('To',to),
          const SizedBox(height: 16),
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
        required VoidCallback onConfirm,
        required bool isSend,

      }) {

    AppModal.show(
      context,
      title: AppLocalizations.of(context)!.profileTokenDetailPaymentDetails,
      confirmText: AppLocalizations.of(context)!.profileTokenDetailConfirm,
      onConfirm: () {
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
                      '${isSend ? '-' : '+'}1',
                      style: AppTextStyles.h1.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // 使用 profile 目录下的图标 (Use icon from profile directory)
                    Image.asset(
                      'assets/images/profile/avalanche.png',
                      width: 20,
                      height: 20,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.token, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isSend ? 'Turning out' : 'Turning in',
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
            value: '0485CF569D5f2D0f823A9c51a2ba66074481aEb89',
          ),
          const SizedBox(height: 20),

          // 接收方 (To Address)
          buildDetailItem(
            label: AppLocalizations.of(context)!.profileTokenDetailTo,
            value: 'Ox49E12A0fD33Bcd4AA5184E94Fdb0554a2d6f0F19',
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