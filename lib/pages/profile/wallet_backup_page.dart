import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/wallet/manager/wallet_manager.dart';
import 'package:paracosm/modules/wallet/model/wallet_model.dart';
import 'package:paracosm/modules/wallet/security/wallet_security.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_loading.dart';
import 'package:paracosm/widgets/common/app_toast.dart';
import 'package:paracosm/widgets/modals/wallet_modals.dart';

/// 备份钱包页面
class WalletBackupPage extends StatefulWidget {
  const WalletBackupPage({super.key});

  @override
  State<WalletBackupPage> createState() => _WalletBackupPageState();
}

class _WalletBackupPageState extends State<WalletBackupPage> {
  final AccountManager _accountManager = AccountManager();
  WalletModel? _wallet;

  @override
  void initState() {
    super.initState();
    _wallet = _accountManager.currentWallet;
    _accountManager.addListener(_onAccountChanged);
  }

  @override
  void dispose() {
    _accountManager.removeListener(_onAccountChanged);
    super.dispose();
  }

  void _onAccountChanged() {
    setState(() {
      _wallet = _accountManager.currentWallet;
    });
  }

  void _backupWallet(String type) {
    final wallet = _wallet;
    final loc = AppLocalizations.of(context)!;

    if (wallet == null) {
      AppToast.show(loc.commonDataError);
      return;
    }

    WalletModals.showPasswordModal(
      context: context,
      title: loc.profileTransferPassword,
      onConfirm: (password) async {
        Map<String, dynamic>? data;
        AppLoading.show();
        try {
          final isResult = await WalletSecurity.verifyPassword(password);
          if (!mounted) return;

          if (!isResult) {
            AppToast.show(loc.commonPasswordError);
            return;
          }

          data = await WalletSecurity.getWallet(
            walletId: wallet.id,
            password: password,
          );
          if (!mounted) return;
        } catch (_) {
          if (mounted) {
            AppToast.show(loc.commonDataError);
          }
          return;
        } finally {
          AppLoading.dismiss();
        }

        if (data == null) {
          return AppToast.show(loc.commonDataError);
        }

        if (type == WalletType.privateKey) {
          WalletModals.showChainSelector(
            context: context,
            wallet: wallet,
            onSelected: (chain) async {
              if (chain.address.isNotEmpty) {
                final privateKey = await WalletManager.generatePrivateKey(
                  chain,
                );
                if (!mounted) return;
                context.push(
                  '/wallet-backup-private-key',
                  extra: {'privateKey': privateKey},
                );
                return;
              }

              if (!mounted) return;
              context.push(
                '/wallet-import-private-key',
                extra: {
                  'password': password,
                  'walletId': wallet.id,
                  'chainType': chain.chainType,
                },
              );
            },
          );
          return;
        }

        final mnemonic = data['mnemonic'] as String? ?? '';
        if (mnemonic.isEmpty) {
          return AppToast.show(loc.commonDataError);
        }
        context.push('/wallet-backup-mnemonic', extra: {'mnemonic': mnemonic});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final canBackupMnemonic = _wallet?.isPrivateKey != true;

    return AppPage(
      showNav: true,
      showBack: true,
      title: loc.profileProfileDetailsBackupWallet,
      backgroundColor: AppColors.white,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildMenuItem(
              iconName: 'key.png',
              title: loc.profileProfileDetailsBackupPrivateKey,
              onTap: () => _backupWallet(WalletType.privateKey),
            ),
            if (canBackupMnemonic) ...[
              const SizedBox(height: 24),
              _buildMenuItem(
                iconName: 'back-up.png',
                title: loc.profileProfileDetailsBackupMnemonic,
                onTap: () => _backupWallet(WalletType.mnemonic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String iconName,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Image.asset(
            'assets/images/profile/user/$iconName',
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.security, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.grey900,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, size: 20, color: AppColors.grey300),
        ],
      ),
    );
  }
}
