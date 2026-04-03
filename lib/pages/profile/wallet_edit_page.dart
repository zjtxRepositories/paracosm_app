import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/wallet/model/wallet_model.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_button.dart';
import 'package:paracosm/widgets/common/app_modal.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/modals/wallet_modals.dart';

import '../../modules/wallet/manager/wallet_manager.dart';
import '../../modules/wallet/security/wallet_security.dart';
import '../../widgets/common/app_loading.dart';
import '../../widgets/common/app_toast.dart';

/// 钱包编辑/管理页面 (Manage Wallet)
class WalletEditPage extends StatefulWidget {
  final WalletModel wallet;

  const WalletEditPage({
    super.key,
    required this.wallet,
  });

  @override
  State<WalletEditPage> createState() => _WalletEditPageState();
}

class _WalletEditPageState extends State<WalletEditPage> {
  late String _currentWalletName;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final l10n = AppLocalizations.of(context)!;

      setState(() {
        _currentWalletName = widget.wallet.name ??
            '${l10n.profileProfileDetailsWallet} ${widget.wallet.aIndex + 1}';
      });
    });
  }

  ///备份
  void _backupMnemonic(String type){
    WalletModals.showPasswordModal(
        context: context,
        title: AppLocalizations.of(context)!
            .profileTransferPassword,
        onConfirm: (password) async {
          AppLoading.show();
          final isResult =
          await WalletSecurity.verifyPassword(password);
          AppLoading.dismiss();
          if (!isResult) {
            return AppToast.show('密码错误！');
          }
          final data = await WalletSecurity.getWallet(walletId: widget.wallet.id, password: password);
          if (data == null) {
            return AppToast.show('数据错误！');
          }
          if (type == WalletType.privateKey){
            WalletModals.showChainSelector(
                context: context,
                wallet: widget.wallet,
                onSelected: (chain) async {
                  if (chain.address.isNotEmpty){
                    final privateKey = await WalletManager.generatePrivateKey(chain);
                    context.push('/wallet-backup-private-key',
                      extra: {
                        'privateKey': privateKey,
                      },
                    );
                    return;
                  }
                  context.push('/wallet-import-private-key',
                    extra: {
                      'password': password,
                      'walletId': widget.wallet.id,
                      'chainType': chain.chainType,
                    },
                  );
                }
            );
            return;
          }
          final mnemonic = data['mnemonic'];
          context.push('/wallet-backup-mnemonic',
            extra: {
              'mnemonic': mnemonic,
            },
          );
        });
  }

  /// 显示重命名钱包弹窗 (参考 transfer_page.dart 的 _showPasswordModal)
  void _showRenameModal() {
    final nameController = TextEditingController(text: _currentWalletName);
    AppModal.show(
      context,
      title: AppLocalizations.of(context)!.profileWalletEditRenameThisWallet,
      confirmText: AppLocalizations.of(context)!.profileWalletEditSave,
      onConfirm: () async {
        if (nameController.text.isNotEmpty) {
          await WalletManager.changeWalletName(widget.wallet.id, nameController.text);
          setState(() {
            _currentWalletName = nameController.text;
          });
          context.pop();
        }
      },
      child: StatefulBuilder(
        builder: (context, setModalState) {
          final isEmpty = nameController.text.isEmpty;
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
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: nameController,
                        onChanged: (value) => setModalState(() {}),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.profileWalletEditEnterWalletName,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: AppTextStyles.body.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.grey900,
                        ),
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

  @override
  Widget build(BuildContext context) {
    return AppPage(
      showNav: true,
      title: AppLocalizations.of(context)!.profileWalletEditManageWallet,
      backgroundColor: AppColors.white,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Your wallets 标签
                  Text(
                    AppLocalizations.of(context)!.profileWalletEditYourWallets,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 12,
                      color: AppColors.grey400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 钱包详情区域
                  _buildWalletDetailHeader(),
                  const SizedBox(height: 24),
                  const Divider(color: AppColors.grey100, height: 1),
                  const SizedBox(height: 24),
                  // 菜单列表
                  widget.wallet.isPrivateKey == false ?  _buildMenuItem(
                    icon: 'learn.png',
                    title: AppLocalizations.of(context)!.profileWalletEditBackupMnemonics,
                    onTap: () {
                      _backupMnemonic(WalletType.mnemonic);
                    },
                  ):SizedBox(),
                  const SizedBox(height: 24),
                  _buildMenuItem(
                    icon: 'security.png',
                    title: AppLocalizations.of(context)!.profileWalletEditBackingUpPrivate,
                    onTap: () {
                      _backupMnemonic(WalletType.privateKey);
                    },
                  )
                ],
              ),
            ),
          ),
          // 底部警示和删除按钮
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Image.asset(
                        'assets/images/common/tips-error-icon.png',
                        width: 16,
                        height: 16,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.profileWalletEditBackupWarning,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 12,
                          color: AppColors.error,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: AppLocalizations.of(context)!.profileWalletEditDelete,
                  backgroundColor: AppColors.error,
                  textColor: Colors.white,
                  onPressed: () async {
                    // TODO: 删除钱包逻辑
                    await AccountManager().deleteAccount(widget.wallet.id);
                    context.pop();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建钱包详情头部 (头像、名称、地址、编辑图标)
  Widget _buildWalletDetailHeader() {
    return Row(
      children: [
        // 钱包头像
        ClipOval(
          child: Image.asset(
            'assets/images/chat/avatar.png',
            width: 44,
            height: 44,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        // 钱包信息
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentWalletName,
                style: AppTextStyles.h1.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Image.asset(
                    'assets/images/common/copy-grey.png',
                    width: 16,
                    height: 16,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      widget.wallet.id,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 12,
                        color: AppColors.grey400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // 编辑图标
        GestureDetector(
          onTap: _showRenameModal,
          child: Image.asset(
            'assets/images/profile/user/edit.png',
            width: 20,
            height: 20,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.edit_outlined,
              size: 24,
              color: AppColors.grey900,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建菜单项
  Widget _buildMenuItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Image.asset(
            'assets/images/profile/user/$icon',
            width: 24,
            height: 24,
            errorBuilder: (_, __, ___) => const Icon(Icons.security, size: 24),
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
