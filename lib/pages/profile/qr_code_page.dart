import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';

/// 二维码页面
class QrCodePage extends StatelessWidget {
  const QrCodePage({super.key});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    return AppPage(
      showNav: true,
      title: AppLocalizations.of(context)!.profileQrCodeQrCode,
      headerActions: [
        GestureDetector(
          onTap: () {
            // TODO: 分享逻辑
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Image.asset(
              'assets/images/profile/user/share.png',
              width: 24,
              height: 24,
            ),
          ),
        ),
      ],
      child: Stack(
        children: [
          // 背景网格图
          Positioned.fill(
            child: Image.asset(
              'assets/images/wallet/grid-bg.png',
              fit: BoxFit.cover,
            ),
          ),
          // 页面主要内容
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // 顶部插图
                Center(
                  child: Image.asset(
                    'assets/images/profile/user/code-bg.png',
                    width: 335,
                    height: 207,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                // 二维码卡片容器
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 用户信息行
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/images/chat/avatar.png',
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Jane Cooper',
                                      style: AppTextStyles.h2.copyWith(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.grey900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      AppLocalizations.of(context)!.profileQrCodeScanToAdd,
                                      style: AppTextStyles.body.copyWith(
                                        fontSize: 12,
                                        color: AppColors.grey400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  // TODO: 下载逻辑
                                },
                                child: Image.asset(
                                  'assets/images/profile/user/download.png',
                                  width: 24,
                                  height: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 带圆弧缺口的虚线分割线
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // 虚线
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: List.generate(
                                  30,
                                  (index) => Expanded(
                                    child: Container(
                                      height: 1,
                                      margin: const EdgeInsets.symmetric(horizontal: 2),
                                      color: AppColors.grey200,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // 两侧圆弧缺口
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // 左侧缺口
                                Transform.translate(
                                  offset: const Offset(-10, 0),
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: AppColors.grey100, // 与背景色保持一致
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                // 右侧缺口
                                Transform.translate(
                                  offset: const Offset(10, 0),
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: AppColors.grey100, // 与背景色保持一致
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // 二维码区域
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(0),
                              ),
                              child: Image.asset(
                                'assets/images/profile/user/test-code.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
