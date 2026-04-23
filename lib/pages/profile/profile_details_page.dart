import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/modules/wallet/manager/wallet_manager.dart';
import 'package:paracosm/modules/wallet/security/wallet_security.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';
import 'package:paracosm/widgets/common/app_button.dart';
import 'package:paracosm/widgets/common/app_checkbox.dart';
import 'package:paracosm/widgets/common/app_modal.dart';
import 'package:paracosm/widgets/common/app_network_selector.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/common/app_toast.dart';
import 'package:paracosm/widgets/modals/wallet_modals.dart';

import '../../core/db/dao/wallet_dao.dart';
import '../../core/util/string_util.dart';
import '../../modules/account/manager/account_manager.dart';
import '../../modules/account/model/account_model.dart';
import '../../modules/wallet/chains/service/portfolio_service.dart';
import '../../modules/wallet/model/chain_account.dart';
import '../../modules/wallet/model/wallet_model.dart';
import '../../widgets/common/app_loading.dart';
import '../../widgets/common/app_network_image.dart';

/// 个人资料详情页面
class ProfileDetailsPage extends StatefulWidget {
  const ProfileDetailsPage({super.key});

  @override
  State<ProfileDetailsPage> createState() => _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends State<ProfileDetailsPage> {
  List<AccountModel> _accounts = [];
  WalletModel? _walletModel;
  AccountModel? _account;
  Map<String, WalletModel>? _walletMap;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchData();
    fetchWalletData();
  }

  Future<void> fetchData() async {
    final manager = AccountManager();
    _walletModel = manager.currentWallet;
    _accounts = manager.accounts;
    _account = manager.currentAccount;
    setState(() {});
  }

  Future<void> fetchWalletData() async {
    final futures = _accounts.map((account) {
      return WalletDao().getWalletById(account.id);
    }).toList();

    final results = await Future.wait(futures);

    final map = <String, WalletModel>{};
    for (int i = 0; i < _accounts.length; i++) {
      final wallet = results[i];
      if (wallet != null) {
        map[_accounts[i].id] = wallet;
      }
    }
    _walletMap = map;

  }

  /// 显示密码输入弹窗
  void _showPasswordModal() {
    WalletModals.showPasswordModal(
      title: '输入当前密码',
      context: context,
      onConfirm: (oldPassword) async {

        AppLoading.show();

        final isResult =
        await WalletSecurity.verifyPassword(oldPassword);

        AppLoading.dismiss();

        if (!isResult) {
          return AppToast.show('密码错误！');
        }
        await Future.delayed(const Duration(milliseconds: 150));

        WalletModals.showPasswordModal(
          title: '输入新密码',
          context: context,
          onConfirm: (newPassword) async {

            if (newPassword.length < 6) {
              return AppToast.show('密码至少6位');
            }
            AppLoading.show();

            await WalletSecurity.changePassword(
              oldPassword: oldPassword,
              newPassword: newPassword,
            );
            AppLoading.dismiss();

            AppToast.show('修改成功');
          },
        );
      },
    );
  }

  /// 显示钱包切换弹窗
  void _showWalletSwitcher() {
    if (_walletModel == null || _walletMap == null) return;
    WalletModals.showWalletSwitcher(context,
        accounts: _accounts,
        walletMap: _walletMap!,
        currentWalletId: _walletModel!.id,
        onSwitch: (address) async {
          await AccountManager().switchAccount(address);
          await fetchData();
        },
        onAddWallet: (){
          context.push('/wallet-manager'); // 跳转到钱包管理页
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
          final data = await WalletSecurity.getWallet(walletId: _walletModel?.id ?? '', password: password);
          if (data == null) {
            return AppToast.show('数据错误！');
          }
          if (type == WalletType.privateKey){
            WalletModals.showChainSelector(
                context: context,
                wallet: _walletModel!,
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
                      'walletId': _walletModel!.id,
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


  @override
  Widget build(BuildContext context) {
    return AppPage(
      showNav: true,
      title: '',
      backgroundColor: AppColors.white,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            _buildUserInfo(context),
            const SizedBox(height: 18),
            _buildActionCards(),
            const SizedBox(height: 32),
            _buildMenuList(context),
            const SizedBox(height: 32),
            _buildLogoutButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// 构建用户信息区域 (头像、名称、地址、二维码)
  Widget _buildUserInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          // 用户头像
          UserAvatarWidget(
            userId: _account?.accountId,
            avatarUrl: _account?.avatar,
            size: 44,
            borderRadius: BorderRadius.circular(11),
          ),
          const SizedBox(width: 12),
          // 用户信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _account?.name ?? '',
                  style: AppTextStyles.h1.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Image.asset(
                      'assets/images/common/copy-grey.png',
                      width: 16,
                      height: 16,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(width: 2),
                    SizedBox(
                      width: 128,
                      child: Text(
                        _account?.accountId ?? '',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 12,
                          color: AppColors.grey400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
          // 二维码图标
          GestureDetector(
            onTap: () {
              context.push('/qr-code');
            },
            child: Image.asset(
              'assets/images/profile/user/qrcode.png',
              width: 20,
              height: 20,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.qr_code_scanner, color: AppColors.grey900),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建备份钱包和邀请好友两个卡片
  Widget _buildActionCards() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildSingleCard(
              title: AppLocalizations.of(context)!.profileProfileDetailsBackupWallet,
              desc: AppLocalizations.of(context)!.profileProfileDetailsBackupDesc,
              iconPath: 'assets/images/profile/user/wallet.png',
              bgColor: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSingleCard(
              title: AppLocalizations.of(context)!.profileProfileDetailsInviteFriends,
              desc: AppLocalizations.of(context)!.profileProfileDetailsInviteDesc,
              iconPath: 'assets/images/profile/user/invite.png',
              bgColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单个动作卡片
  Widget _buildSingleCard({
    required String title,
    required String desc,
    required String iconPath,
    required Color bgColor,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 卡片主体
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 22), // 为上方溢出的图标留出空间
          padding: const EdgeInsets.fromLTRB(12, 40, 12, 12), // 顶部留出更多间距，避免遮挡标题
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grey200, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: AppTextStyles.body.copyWith(
                  fontSize: 10,
                  color: AppColors.grey400,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        // 溢出图标
        Positioned(
          top: 0,
          left: 12,
          child: Image.asset(iconPath, width: 68, height: 60),
        ),
      ],
    );
  }

  /// 构建功能列表
  Widget _buildMenuList(BuildContext context) {
    final menuItems = [
      {
        'title': AppLocalizations.of(context)!.profileProfileDetailsChangeAddWallet,
        'icon': 'add-wallet.png',
        'onTap': _showWalletSwitcher
      },
      {
        'title': AppLocalizations.of(context)!.profileProfileDetailsBackupPrivateKey,
        'icon': 'key.png',
        'onTap': () => _backupMnemonic(WalletType.privateKey),
      },
      if (_walletModel?.isPrivateKey == false)
        {
          'title': AppLocalizations.of(context)!.profileProfileDetailsBackupMnemonic,
          'icon': 'back-up.png',
          'onTap': () => _backupMnemonic(WalletType.mnemonic),
        },
      // {
      //   'title': AppLocalizations.of(context)!.profileProfileDetailsChangeCurrency,
      //   'icon': 'change-currency.png',
      //   'onTap': _showWalletSwitcher
      // },
      // {
      //   'title': AppLocalizations.of(context)!.profileProfileDetailsPcosm,
      //   'icon': 'pcosm.png',
      //   'route': '/pcosm-detail'
      // },
      {
        'title': AppLocalizations.of(context)!.profileProfileDetailsChangePassword,
        'icon': 'change-password.png',
        'onTap': _showPasswordModal
      },
      // {
      //   'title': AppLocalizations.of(context)!.profileNodeSettingsNodeSettings,
      //   'icon': 'node-setting.png',
      //   'route': '/node-settings'
      // },
      // {
      //   'title': AppLocalizations.of(context)!.profileProfileDetailsMessagesNotifications,
      //   'icon': 'message.png'
      // },
      {
        'title': AppLocalizations.of(context)!.profileLanguageSettingsChangeLanguage,
        'icon': 'change-language.png',
        'route': '/language-settings'
      },
      {
        'title': AppLocalizations.of(context)!.profileAboutAbout,
        'icon': 'about.png',
        'route': '/about'
      },
    ];

    return Column(
      children: menuItems
          .map(
            (item) => _buildMenuItem(
              context: context,
              title: item['title'] as String,
              iconName: item['icon'] as String,
              route: item['route'] as String?,
              onTap: item['onTap'] as VoidCallback?,
            ),
          )
          .toList(),
    );
  }

  /// 构建单个列表项
  Widget _buildMenuItem({
    required BuildContext context,
    required String title,
    required String iconName,
    String? route,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap();
        } else if (route != null) {
          context.push(route);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Image.asset(
              'assets/images/profile/user/$iconName',
              width: 24,
              height: 24,
              errorBuilder: (_, __, ___) => const Icon(Icons.settings, size: 24),
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
      ),
    );
  }

  /// 构建退出登录按钮
  Widget _buildLogoutButton() {
    return AppButton(
      text: AppLocalizations.of(context)!.profileProfileDetailsLogout,
      backgroundColor: Colors.white,
      textColor: AppColors.error,
      border: BorderSide(
        color: AppColors.error.withValues(alpha: 0.2),
        width: 1.5,
      ),
      onPressed: () {
        // TODO: 退出登录逻辑
      },
    );
  }
}
