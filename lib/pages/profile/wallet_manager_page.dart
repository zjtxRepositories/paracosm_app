import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/wallet/model/wallet_model.dart';
import 'package:paracosm/modules/wallet/security/wallet_security.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_localizations_keys.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_button.dart';
import 'package:paracosm/widgets/common/app_toast.dart';

import '../../core/db/dao/wallet_dao.dart';
import '../../core/util/string_util.dart';
import '../../modules/account/model/account_model.dart';
import '../../modules/wallet/chains/service/portfolio_service.dart';
import '../../modules/wallet/service/mnemonic_service.dart';
import '../../widgets/common/app_modal.dart';
import '../../widgets/common/app_network_image.dart';

/// 钱包管理页面 (Change/Add Wallet)
class WalletManagerPage extends StatefulWidget {
  const WalletManagerPage({super.key});

  @override
  State<WalletManagerPage> createState() => _WalletManagerPageState();
}

class _WalletManagerPageState extends State<WalletManagerPage> {
  bool _isBalanceVisible = true;
  List<AccountModel> _accounts = [];
  WalletModel? _walletModel;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final manager = AccountManager();
    _walletModel = manager.currentWallet;
    _accounts = manager.accounts;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppPage(
      showNav: true,
      title: l10n.profileWalletManagerWallet,
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
                  // 当前钱包卡片 (完全拷贝 profile_page.dart 的样式并移除按钮)
                  _buildCurrentWalletCard(),
                  const SizedBox(height: 32),
                  // Your wallets 标签
                  Text(
                    l10n.profileProfileDetailsYourWallets,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      color: AppColors.grey400,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 钱包列表
                  ..._accounts.map((account) {
                    return Column(
                      children: [
                        buildWalletListItem(account.id, account.avatar),
                        const SizedBox(height: 20),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
          // 底部操作按钮
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              children: [
                AppButton(
                  text: l10n.walletSetupCreateTitle,
                  backgroundColor: AppColors.white,
                  textColor: AppColors.grey900,
                  border: const BorderSide(color: AppColors.grey200, width: 1),
                  onPressed: () {
                    _showPasswordModal(0);
                  },
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: l10n.walletSetupImportTitle,
                  backgroundColor: AppColors.grey900,
                  textColor: AppColors.white,
                  onPressed: () {
                    _showPasswordModal(1);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建当前钱包卡片 (拷贝自 profile_page.dart)
  Widget _buildCurrentWalletCard() {
    final l10n = AppLocalizations.of(context)!;
    String showName = _walletModel?.name ?? '${l10n.profileProfileDetailsWallet} ${(_walletModel?.aIndex ?? 0) + 1}';
    final currentChain = _walletModel?.currentChain;
    print('currentChain----$showName');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                showName,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.grey400,
                  fontSize: 14,
                ),
              ),
              // 网络选择器样式
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppColors.grey200, width: 1),
                ),
                child: Row(
                  children: [
                    AppNetworkImage(
                      url: currentChain?.logo,
                      width: 16,
                      height: 16,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      currentChain?.name ?? '',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down, size: 12, color: AppColors.grey400),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              StreamBuilder<double>(
                stream: PortfolioService().totalUsdStream,
                builder: (context, snapshot) {
                  final total = snapshot.data ?? 0;

                  return _isBalanceVisible
                      ? Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '\$'),
                        TextSpan(text: truncateDouble(total)),
                      ],
                    ),
                  )
                      : Text('********');
                },
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                child: Image.asset(
                  _isBalanceVisible ? 'assets/images/common/eye-line.png' : 'assets/images/common/eye-off-line.png',
                  width: 20,
                  height: 20,
                  color: AppColors.grey400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建钱包列表项
  Widget buildWalletListItem(String address, String avatarPath) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<WalletModel?>(
      future: WalletDao().getWalletById(address),
      builder: (context, snapshot) {
        final wallet = snapshot.data;
        final showName = wallet?.name ?? '${l10n.profileProfileDetailsWallet} ${(wallet?.aIndex ?? 0) + 1}';

        return GestureDetector(
          onTap: () {
            context.push('/wallet-edit', extra: wallet);
          },
          behavior: HitTestBehavior.opaque,
          child: Row(
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
                      showName,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 12,
                        color: AppColors.grey400,
                      ),
                    ),
                  ],
                ),
              ),
              // 右侧图标
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.grey300,
              ),
            ],
          ),
        );
      },
    );
  }

  /// 显示密码输入弹窗
  void _showPasswordModal(int tag) {
    final passwordController = TextEditingController();
    bool isObscure = true;

    AppModal.show(
      context,
      title: AppLocalizations.of(context)!.walletStep1HintPwd,
      confirmText: AppLocalizations.of(context)!.profileTransferConfirm,
      onConfirm: () async {
        context.pop(); // 关闭密码弹窗
        // TODO: 密码验证逻辑
        final password = passwordController.text;
        final isResult = await WalletSecurity.verifyPassword(password);
        if (!isResult){
          AppToast.show('密码错误！');
          return;
        }
        if (tag == 0){
          final List<String> mnemonics = MnemonicService.generateMnemonic().split(" ");
          context.push('/wallet-creating',
            extra: {
              'password': password,
              'mnemonics':mnemonics,
            },
          );
          return;
        }
        context.push('/wallet-import',
          extra: {
            'password': password,
          },
        );
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
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: passwordController,
                        obscureText: isObscure,
                        onChanged: (value) => setModalState(() {}),
                        decoration: const InputDecoration(
                          hintText: '',
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
                    GestureDetector(
                      onTap: () => setModalState(() => isObscure = !isObscure),
                      child: Image.asset(
                        isObscure ? 'assets/images/common/eye-off-line.png' : 'assets/images/common/eye-line.png',
                        width: 24,
                        height: 24,
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
}
