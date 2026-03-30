import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:paracosm/pages/wallet/wallet_create_step2_page.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/common/app_password_field.dart';
import 'package:paracosm/widgets/common/app_button.dart';
import 'package:go_router/go_router.dart';

/// 创建钱包 - 第一步：设置密码
class WalletCreateStep1Page extends StatefulWidget {
  const WalletCreateStep1Page({super.key});

  @override
  State<WalletCreateStep1Page> createState() => _WalletCreateStep1PageState();
}

class _WalletCreateStep1PageState extends State<WalletCreateStep1Page> {
  final TextEditingController _pwdController = TextEditingController();
  final TextEditingController _confirmPwdController = TextEditingController();
  bool isEnabled = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AppPage(
      showNav: true,
      showBack: true,
      title: '', // UI 顶部没有标题文字，只有返回按钮
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                // 顶部标题 - 创建新钱包 (仅“新钱包”有下划线)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      loc.walletCreateTitle,
                                      style: AppTextStyles.h1.copyWith(fontSize: 24),
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
                                          loc.walletCreateNew,
                                          style: AppTextStyles.h1.copyWith(fontSize: 24),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // Step 信息
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text.rich(
                                      TextSpan(
                                        text: 'Step 1',
                                        style: AppTextStyles.body.copyWith(
                                          fontSize: 14,
                                          color: AppColors.grey900,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '/3',
                                            style: AppTextStyles.body.copyWith(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.grey400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // 步骤指示条
                                    _buildStepIndicator(1),
                                  ],
                                ),
                              ],
                            ),

                            // 3. 设置密码卡片
                            Padding(
                              padding: const EdgeInsets.only(top: 40, bottom: 20),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
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
                                    Text(loc.walletStep1Title, style: AppTextStyles.h2.copyWith()),
                                    const SizedBox(height: 8),
                                    Text(
                                      loc.walletStep1Subtitle,
                                      style: AppTextStyles.body.copyWith(),
                                    ),
                                    const SizedBox(height: 36),

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

                                    const SizedBox(height: 36),

                                    // 下一步按钮
                                    AppButton(
                                      text: loc.commonNext,
                                      onPressed: !isEnabled ? null : () {
                                        context.push(
                                          '/wallet-create-step2',
                                          extra: {
                                            'password': _pwdController.text,
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建步骤指示器
  Widget _buildStepIndicator(int currentStep) {
    return Row(
      children: List.generate(3, (index) {
        final isActive = index + 1 <= currentStep;
        return Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.grey900 : AppColors.grey200,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
