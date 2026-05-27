import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:paracosm/modules/update/app_update_service.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';

/// 关于页面
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) {
      return;
    }
    setState(() {
      _version = packageInfo.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final version = _version.isEmpty ? '-' : _version;

    return AppPage(
      title: l10n.profileAboutAbout,
      showNav: true,
      showNavBorder: true,
      navBorderColor: AppColors.grey100,
      backgroundColor: AppColors.white,
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 36),
                  // Logo 区域
                  Center(
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/profile/logo.png',
                          width: 80,
                          height: 80,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD7FF00),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.logo_dev, size: 50),
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.profileProfileParacosm,
                          style: AppTextStyles.h1.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // 列表项区域
                  _buildMenuItem(
                    icon: 'assets/images/profile/email.png',
                    title: l10n.profileAboutEmail,
                    subtitle: l10n.profileAboutLq84y0qf5woaskcom,
                    onTap: () {
                      // TODO: 复制邮箱或打开邮件客户端
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildMenuItem(
                    icon: 'assets/images/profile/update.png',
                    title: l10n.profileAboutVersionUpdate,
                    subtitle: l10n.appUpdateVersionLabel(version),
                    onTap: () {
                      AppUpdateService().checkManually(context);
                    },
                  ),
                ],
              ),
            ),
            // 底部版本号
            Positioned(
              left: 0,
              right: 0,
              bottom: 40,
              child: Center(
                child: Text(
                  l10n.appUpdateVersionLabel(version),
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    color: AppColors.grey400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建菜单项
  Widget _buildMenuItem({
    required String icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200, width: 1),
        ),
        child: Row(
          children: [
            // 图标背景
            Image.asset(
              icon,
              width: 48,
              height: 48,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.mail_outline,
                size: 48,
                color: AppColors.grey400,
              ),
            ),
            const SizedBox(width: 16),
            // 文字内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            // 右侧箭头
            const Icon(Icons.chevron_right, size: 20, color: AppColors.grey300),
          ],
        ),
      ),
    );
  }
}
