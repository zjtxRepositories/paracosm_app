import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/common/app_checkbox.dart';
import 'package:paracosm/widgets/common/app_button.dart';
import 'package:go_router/go_router.dart';

/// 备份风险确认页
///
/// 展示备份助记词的风险确认项。
class WalletBackupRiskPage extends StatefulWidget {
  final String nextPath; // 备份完成后跳转的路径，比如助记词页或私钥页
  final String? password;

  const WalletBackupRiskPage({
    super.key,
    this.nextPath = '/wallet-create-step2',
    this.password
  });

  @override
  State<WalletBackupRiskPage> createState() => _WalletBackupRiskPageState();
}

class _WalletBackupRiskPageState extends State<WalletBackupRiskPage> {
  final List<bool> _checks = [false, false, false];

  bool get _isAllChecked => _checks.every((e) => e);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // 分割标题文字，以便对重点部分应用特殊字重
    final titleParts = loc.walletBackupRiskTitle.split('=');
    final firstPart = titleParts.isNotEmpty ? titleParts[0] : '';
    final secondPart = titleParts.length > 1 ? titleParts[1] : '';
    final thirdPart = titleParts.length > 2 ? titleParts[2] : '';

    return AppPage(
      showNav: true,
      showBack: true,
      title: loc.walletBackupTipsTitle,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      // 中间图标
                      Image.asset(
                        'assets/images/wallet/backup-icon.png',
                        width: 180,
                        height: 180,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.security,
                          size: 180,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 标题
                      RichText(
                        textAlign: TextAlign.left,
                        text: TextSpan(
                          style: AppTextStyles.h2.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.grey900,
                            height: 1.5,
                          ),
                          children: [
                            TextSpan(text: firstPart),
                            if (secondPart.isNotEmpty)
                              TextSpan(
                                text: secondPart,
                                style: AppTextStyles.h2.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.grey900,
                                ),
                              ),
                            if (thirdPart.isNotEmpty) TextSpan(text: thirdPart),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 分割线
                      const Divider(color: AppColors.grey200, height: 1),
                      const SizedBox(height:16),

                      // 规则列表
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRuleItem(loc.walletBackupTipsMnemonicRule1),
                          const SizedBox(height: 8),
                          _buildRuleItem(loc.walletBackupTipsMnemonicRule2),
                        ],
                      ),
                      const SizedBox(height: 34),

                      // 风险确认勾选项
                      _buildCheckItem(0, loc.walletBackupTipsRisk1),
                      const SizedBox(height: 12),
                      _buildCheckItem(1, loc.walletBackupTipsRisk2),
                      const SizedBox(height: 12),
                      _buildCheckItem(2, loc.walletBackupTipsRisk3),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // 下一步按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(36, 0, 36, 20),
              child: AppButton(
                text: loc.commonNext,
                onPressed: _isAllChecked
                    ? () =>
                    context.push(
                      widget.nextPath,
                      extra: {
                        'password': widget.password,
                      },
                    )
                  //   context.push(widget.nextPath,
                  // queryParameters: {'nextPath': widget.nextPath,'password': widget.password},)
                    : null,
              ),
            ),
          ],
        ),
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

  Widget _buildCheckItem(int index, String text) {
    return GestureDetector(
      onTap: () => setState(() => _checks[index] = !_checks[index]),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.grey200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.body.copyWith(
                  fontSize: 14,
                  color: AppColors.grey900,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 16),
            AppCheckbox(
              value: _checks[index],
              onChanged: (val) => setState(() => _checks[index] = val),
            ),
          ],
        ),
      ),
    );
  }
}
