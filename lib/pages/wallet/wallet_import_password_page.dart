import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/common/app_password_field.dart';
import 'package:paracosm/widgets/common/app_button.dart';
import 'package:go_router/go_router.dart';

import '../../modules/account/service/account_service.dart';

/// 导入钱包 - 设置密码
class WalletImportPasswordPage extends StatefulWidget {
  final String? mnemonic;
  final String? privateKey;

  const WalletImportPasswordPage({super.key, this.mnemonic,this.privateKey});

  @override
  State<WalletImportPasswordPage> createState() =>
      _WalletImportPasswordPageState();
}

class _WalletImportPasswordPageState extends State<WalletImportPasswordPage> {
  final TextEditingController _pwdController = TextEditingController();
  final TextEditingController _confirmPwdController = TextEditingController();
  bool isEnabled = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AppPage(
      showNav: true,
      showBack: true,
      title: loc.walletImportTitle,
      child: Stack(
        children: [
          // 1. 全屏背景网格图
          Positioned.fill(
            child: Image.asset(
              'assets/images/wallet/grid-bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. 页面内容
          Positioned.fill(
            child: SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 顶部标题和图标部分
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          loc.walletStep1Title.substring(
                                            0,
                                            loc.walletStep1Title.length - 2,
                                          ),
                                          style: AppTextStyles.h1.copyWith(
                                            fontSize: 14,
                                          ),
                                        ),
                                        Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Positioned(
                                              bottom: 4,
                                              left: 0,
                                              right: 0,
                                              child: Container(
                                                height: 4,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            Text(
                                              loc.walletStep1Title.substring(
                                                loc.walletStep1Title.length - 2,
                                              ),
                                              style: AppTextStyles.h1.copyWith(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      loc.walletStep1Subtitle,
                                      style: AppTextStyles.body.copyWith(
                                        color: AppColors.grey400,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 28),
                              Image.asset(
                                'assets/images/wallet/key-icon.png',
                                width: 79,
                                height: 74,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.lock_outline,
                                  size: 40,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                        ],
                      ),
                    ),
                  ),

                  // 3. 设置密码卡片 - 使用 SliverFillRemaining 填充剩余高度
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 输入密码
                          AppPasswordField(
                            controller: _pwdController,
                            labelText: loc.walletStep1LabelPwd,
                            hintText: loc.walletStep1HintPwd,
                            onChanged: (String text) {
                              setState(() {
                                isEnabled = text == _confirmPwdController.text &&
                                    text.isNotEmpty;
                              });
                            },
                          ),

                          const SizedBox(height: 24),

                          // 重新输入密码
                          AppPasswordField(
                            controller: _confirmPwdController,
                            labelText: loc.walletStep1LabelConfirmPwd,
                            hintText: loc.walletStep1HintConfirmPwd,
                            onChanged: (String text) {
                              setState(() {
                                isEnabled = text == _pwdController.text &&
                                    text.isNotEmpty;
                              });
                            },
                          ),

                          const Spacer(),

                          // 下一步按钮
                          AppButton(
                            text: loc.commonNext,
                            onPressed: !isEnabled ? null : () async {
                              // // 模拟进入创建中状态
                              // context.push('/wallet-backup-private-key');
                              context.push('/wallet-creating',
                                extra: {
                                  'password': _confirmPwdController.text,
                                  'mnemonics': widget.mnemonic?.split(" "),
                                  'privateKey': widget.privateKey,
                                },
                              );
                            },
                          ),
                           const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
