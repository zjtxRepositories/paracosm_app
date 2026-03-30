import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/wallet/model/wallet_model.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_localizations_keys.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_button.dart';

import '../../modules/account/model/account_model.dart';
import '../../widgets/common/app_network_image.dart';

/// 钱包管理页面 (Change/Add Wallet)
class WalletManagerPage extends StatefulWidget {
  const WalletManagerPage({super.key});

  @override
  State<WalletManagerPage> createState() => _WalletManagerPageState();
}

class _WalletManagerPageState extends State<WalletManagerPage> {
  bool _isBalanceVisible = true;
  AccountModel? _accountModel;
  WalletModel? _walletModel;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final manager = AccountManager();
    _accountModel = manager.currentAccount;
    _walletModel = manager.currentWallet;
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
                  _buildWalletListItem(l10n.profileProfileDetailsWalletNo2, '0xF795...4aA5', 'assets/images/chat/avatar.png'),
                  const SizedBox(height: 20),
                  _buildWalletListItem(l10n.profileProfileDetailsWalletNo3, '0xF795...4aA5', 'assets/images/chat/avatar.png'),
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
                  onPressed: () {},
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: l10n.walletSetupImportTitle,
                  backgroundColor: AppColors.grey900,
                  textColor: AppColors.white,
                  onPressed: () {},
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
              _isBalanceVisible
                  ? Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '\$',
                            style: AppTextStyles.h1.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                          const WidgetSpan(child: SizedBox(width: 2)),
                          TextSpan(
                            text: '7,859,942.00',
                            style: AppTextStyles.h1.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Transform.translate(
                      offset: const Offset(0, 4),
                      child: Text(
                        '********',
                        style: AppTextStyles.h1.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
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
  Widget _buildWalletListItem(String name, String address, String avatarPath) {
    return GestureDetector(
      onTap: () {
        context.push('/wallet-edit', extra: {
          'name': name,
          'address': address,
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          // 钱包头像
          ClipOval(
            child: Image.asset(
              avatarPath,
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
                  name,
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
  }
}
