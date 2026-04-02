import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/core/db/dao/wallet_dao.dart';
import 'package:paracosm/widgets/modals/wallet_switcher_modal.dart';
import '../../modules/account/model/account_model.dart';
import '../../modules/wallet/model/chain_account.dart';
import '../../modules/wallet/model/wallet_model.dart';
import '../../theme/app_colors.dart';
import '../base/app_localizations.dart';
import '../common/app_modal.dart';
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
          wallet.currentChainId = network.chainId;
          await WalletDao().updateWallet(wallet);
          onSelected(network);
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
}