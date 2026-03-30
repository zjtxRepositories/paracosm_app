import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/common/app_checkbox.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/widgets/common/app_toast.dart';

import '../../core/network/config/config_service.dart';

/// 钱包设置/选择页
///
/// 提供创建钱包和导入钱包两个选项。
class WalletSetupPage extends StatefulWidget {
  const WalletSetupPage({super.key});

  @override
  State<WalletSetupPage> createState() => _WalletSetupPageState();
}

class _WalletSetupPageState extends State<WalletSetupPage> {
  bool _isAgreed = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    ConfigService().init();
  }
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AppPage(
      showNav: false,
      child: Stack(
        children: [
          // 1. 全屏背景网格图
          Positioned.fill(
            child: Image.asset(
              'assets/images/wallet/grid-bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. 页面主要内容 - 使用 Positioned.fill 确保获得确定的布局约束
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // 顶部标题和全球图标
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded( // 包裹 Expanded 防止文字过长导致横向溢出
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.walletStartWelcome,
                                style: AppTextStyles.h1.copyWith(fontSize: 40),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    loc.walletStartTo,
                                    style: AppTextStyles.h1.copyWith(fontSize: 24),
                                  ),
                                  Stack(
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
                                        'PARACOSM',
                                        style: AppTextStyles.h1.copyWith(
                                          fontSize: 24,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    ' ${loc.walletStartWorld}',
                                    style: AppTextStyles.h1.copyWith(fontSize: 24),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          child: Image.asset(
                            'assets/images/wallet/global.png',
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(), // 在有固定高度约束的 Column 中可以使用 Spacer

                    // 3. 创建钱包卡片
                    _buildOptionCard(
                      title: loc.walletSetupCreateTitle,
                      subtitle: loc.walletSetupCreateSubtitle,
                      iconPath: 'assets/images/wallet/create-icon.png',
                      onTap: () {
                        if (!_isAgreed){
                          AppToast.show('请仔细阅读服务条款和隐私政策');
                          return;
                        }
                        context.push('/wallet-create-step1');
                      },
                    ),

                    const SizedBox(height: 16),

                    // 4. 导入钱包卡片
                    _buildOptionCard(
                      title: loc.walletSetupImportTitle,
                      subtitle: loc.walletSetupImportSubtitle,
                      iconPath: 'assets/images/wallet/import-icon.png',
                      onTap: () {
                        if (!_isAgreed){
                          AppToast.show('请仔细阅读服务条款和隐私政策');
                          return;
                        }
                        context.push('/wallet-import');
                      },
                    ),

                    const SizedBox(height: 16),

                    // 5. 服务条款勾选
                    Row(
                      children: [
                        AppCheckbox(
                          value: _isAgreed,
                          size: 20, // 恢复显式尺寸
                          onChanged: (val) => setState(() => _isAgreed = val),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: loc.walletSetupAgree,
                              style: AppTextStyles.caption.copyWith(),
                              children: [
                                TextSpan(
                                  text: loc.walletSetupTerms,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primaryLight,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                TextSpan(text: loc.walletSetupAnd),
                                TextSpan(
                                  text: loc.walletSetupPrivacy,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primaryLight,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required String iconPath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.h2.copyWith()),
                  const SizedBox(height: 8),
                  Text(subtitle, style: AppTextStyles.body.copyWith(color: AppColors.grey500)),
                  const SizedBox(height: 16),
                  // 跳转图标（参考修改后的，不加额外容器）
                  Image.asset(
                    'assets/images/wallet/next-icon.png',
                    width: 32,
                    height: 32,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Image.asset(iconPath, width: 100, height: 100, fit: BoxFit.contain),
          ],
        ),
      ),
    );
  }
}
