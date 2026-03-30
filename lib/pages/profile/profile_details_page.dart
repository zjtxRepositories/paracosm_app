import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_button.dart';
import 'package:paracosm/widgets/common/app_checkbox.dart';
import 'package:paracosm/widgets/common/app_modal.dart';
import 'package:paracosm/widgets/common/app_network_selector.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';

import '../../modules/account/manager/account_manager.dart';
import '../../modules/wallet/model/chain_account.dart';
import '../../widgets/common/app_network_image.dart';

/// 个人资料详情页面
class ProfileDetailsPage extends StatefulWidget {
  const ProfileDetailsPage({super.key});

  @override
  State<ProfileDetailsPage> createState() => _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends State<ProfileDetailsPage> {
  bool _isBalanceVisible = true; // 控制余额显示/隐藏的状态
  ChainAccount? _selectedNetwork;

  /// 显示网络选择弹窗
  void _showNetworkSelector({VoidCallback? onSelected}) {
    final wallet = AccountManager().currentWallet;
    AppModal.show(
      context,
      title: AppLocalizations.of(context)!.profileProfileDetailsChooseNetwork,
      confirmText: null, // 移除底部确认按钮，改为点击项即选择并关闭
      onConfirm: () {},
      child: AppNetworkSelector(
        initialNetwork: wallet!.currentChain ?? wallet.chains.first,
        networks: wallet.chains,
        onSelected: (network) {
          setState(() {
            _selectedNetwork = network;
          });
          onSelected?.call();
          context.pop();
        },
      ),
    );
  }

  /// 显示密码输入弹窗
  void _showPasswordModal() {
    final passwordController = TextEditingController();
    bool isObscure = true;

    AppModal.show(
      context,
      title: AppLocalizations.of(context)!.profileProfileDetailsNewPassword,
      confirmText: AppLocalizations.of(context)!.profileProfileDetailsConfirm,
      onConfirm: () {
        context.pop(); // 关闭密码弹窗
        // TODO: 密码验证逻辑
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
                        isObscure
                            ? 'assets/images/common/eye-off-line.png'
                            : 'assets/images/common/eye-line.png',
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

  /// 显示钱包切换弹窗
  void _showWalletSwitcher() {
    AppModal.show(
      context,
      title: AppLocalizations.of(context)!.profileProfileDetailsWallet,
      confirmText: null, // 移除底部确认按钮，改为点击项即选择并关闭
      onConfirm: () {},
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildWalletCard(
                showActions: false,
                margin: EdgeInsets.zero,
                onEyeTap: () => setModalState(() {
                  setState(() {
                    _isBalanceVisible = !_isBalanceVisible;
                  });
                }),
                onNetworkTap: () => _showNetworkSelector(
                  onSelected: () => setModalState(() {}),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                AppLocalizations.of(context)!.profileProfileDetailsYourWallets,
                style: AppTextStyles.body.copyWith(
                  fontSize: 14,
                  color: AppColors.grey400,
                ),
              ),
              const SizedBox(height: 20),
              _buildModalWalletItem(
                  AppLocalizations.of(context)!.profileProfileDetailsWalletNo2,
                  '0xF795...4aA5',
                  true),
              const SizedBox(height: 16),
              _buildModalWalletItem(
                  AppLocalizations.of(context)!.profileProfileDetailsWalletNo3,
                  '0xF795...4aA5',
                  false),
              const SizedBox(height: 16),
              _buildModalWalletItem(
                  AppLocalizations.of(context)!.profileProfileDetailsWalletNo4,
                  '0xF795...4aA5',
                  false),
              const SizedBox(height: 32),
              // Add wallet 按钮
              AppButton(
                text: AppLocalizations.of(context)!.profileProfileDetailsAddWallet,
                backgroundColor: AppColors.grey900,
                textColor: AppColors.white,
                onPressed: () {
                  context.pop(); // 先关闭当前弹窗
                  context.push('/wallet-manager'); // 跳转到钱包管理页
                },
              ),
            ],
          );
        },
      ),
    );
  }

  /// 构建弹窗中的钱包列表项
  Widget _buildModalWalletItem(String name, String address, bool isSelected) {
    return Row(
      children: [
        // 钱包头像 (随便用一个图替代)
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
                name,
                style: AppTextStyles.body.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey900,
                ),
              ),
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
        // 选中状态图标 (使用 AppCheckbox 组件)
        AppCheckbox(
          value: isSelected,
          isRadio: false,
          size: 24,
        ),
      ],
    );
  }

  /// 复制自 ProfilePage 的钱包卡片构建方法
  Widget _buildWalletCard({
    bool showActions = true,
    EdgeInsetsGeometry margin = const EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 24),
    VoidCallback? onEyeTap,
    VoidCallback? onNetworkTap,
  }) {
    return Container(
      margin: margin,
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
              // 钱包名称
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.profileProfileDetailsWalletNo1,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.grey400,
                      fontSize: 14,
                    ),
                  ),
                  if (showActions) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.grey400),
                  ],
                ],
              ),
              // 网络选择 (BNB 下拉)
              GestureDetector(
                onTap: onNetworkTap ?? _showNetworkSelector,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.grey200, width: 1),
                  ),
                  child: Row(
                    children: [
                      AppNetworkImage(
                        url: _selectedNetwork?.logo,
                        width: 16,
                        height: 16,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _selectedNetwork?.symbol ?? '',
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
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 余额数值及显隐切换按钮
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
                onTap: () {
                  setState(() => _isBalanceVisible = !_isBalanceVisible);
                  onEyeTap?.call();
                },
                child: Image.asset(
                  _isBalanceVisible ? 'assets/images/common/eye-line.png' : 'assets/images/common/eye-off-line.png',
                  width: 20,
                  height: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.asset(
              'assets/images/chat/avatar.png',
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          // 用户信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jenny Wilson',
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
                    Expanded(
                      child: Text(
                        '0X5E4F3A2689B11EE4...',
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
        'route': '/wallet-manager'
      },
      {
        'title': AppLocalizations.of(context)!.profileProfileDetailsBackupPrivateKey,
        'icon': 'key.png'
      },
      {
        'title': AppLocalizations.of(context)!.profileProfileDetailsBackupMnemonic,
        'icon': 'back-up.png'
      },
      {
        'title': AppLocalizations.of(context)!.profileProfileDetailsChangeCurrency,
        'icon': 'change-currency.png',
        'onTap': _showWalletSwitcher
      },
      {
        'title': AppLocalizations.of(context)!.profileProfileDetailsPcosm,
        'icon': 'pcosm.png',
        'route': '/pcosm-detail'
      },
      {
        'title': AppLocalizations.of(context)!.profileProfileDetailsChangePassword,
        'icon': 'change-password.png',
        'onTap': _showPasswordModal
      },
      {
        'title': AppLocalizations.of(context)!.profileNodeSettingsNodeSettings,
        'icon': 'node-setting.png',
        'route': '/node-settings'
      },
      {
        'title': AppLocalizations.of(context)!.profileProfileDetailsMessagesNotifications,
        'icon': 'message.png'
      },
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
