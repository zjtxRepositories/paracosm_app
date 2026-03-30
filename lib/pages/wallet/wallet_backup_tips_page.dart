import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/common/app_button.dart';
import 'package:go_router/go_router.dart';

/// 备份提示页
///
/// 展示备份助记词的重要性及风险确认。
class WalletBackupTipsPage extends StatefulWidget {
  final String nextPath; // 备份完成后跳转的路径，比如助记词页或私钥页
  final String? password;

  const WalletBackupTipsPage({
    super.key,
    this.nextPath = '/wallet-create-step2',
    this.password
  });

  @override
  State<WalletBackupTipsPage> createState() => _WalletBackupTipsPageState();
}

class _WalletBackupTipsPageState extends State<WalletBackupTipsPage> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    // 分割标题文字，以便对“拥有身份所有权”应用特殊样式
    final titleParts = loc.walletBackupTipsMnemonicIdentity.split('=');
    final firstPart = titleParts[0];
    final secondPart = titleParts.length > 1 ? titleParts[1] : '';

    return AppPage(
      showNav: true,
      showBack: true,
      title: loc.walletBackupTipsTitle,
      child: Stack(
        children: [
          // 2. 页面内容
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Column(
                  children: [
                    const SizedBox(height: 88),
                    // 中间图标
                    Image.asset(
                      'assets/images/wallet/backup-icon.png',
                      width: 240,
                      height: 240,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.security,
                        size: 240,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 标题与规则
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$firstPart=',
                          style: AppTextStyles.h2.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey900,
                          ),
                        ),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // 荧光绿背景下划线
                            Positioned(
                              bottom: 4, // 调整位置到文字下方
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 4,
                                color: AppColors.primary, // 荧光绿
                              ),
                            ),
                            Text(
                              secondPart,
                              style: AppTextStyles.h2.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.grey900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 规则列表 - 居中容器
                    Center(
                      child: IntrinsicWidth(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRuleItem(loc.walletBackupTipsMnemonicRule1),
                            const SizedBox(height: 8),
                            _buildRuleItem(loc.walletBackupTipsMnemonicRule2),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    const Spacer(),

                    // 下一步按钮
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: AppButton(
                        text: loc.commonNext,
                        onPressed: () {
                          // 跳转到风险确认页，并携带最终的下一步路径
                          // context.push(
                          //   Uri(
                          //     path: '/wallet-backup-risk',
                          //     queryParameters: {'nextPath': widget.nextPath,'password': widget.password},
                          //   ).toString(),
                          // );
                          context.push(
                            '/wallet-backup-risk',
                            extra: {
                              'password': widget.password,
                              'nextPath': widget.nextPath,
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.square,
          size: 6,
          color: AppColors.grey300,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.grey600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
