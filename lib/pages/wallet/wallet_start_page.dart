import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// 钱包启动页
///
/// 展示欢迎界面，背景包含网格图，中间有启动图标，底部有下一步按钮。
class WalletStartPage extends StatelessWidget {
  const WalletStartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AppPage(
      showNav: false, // 全屏展示，不显示导航栏
      child: Stack(
        children: [
          // 1. 全屏背景网格图
          Positioned.fill(
            child: Image.asset(
              'assets/images/wallet/grid-bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. 页面主要内容
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 70),
                  // 中间的启动图标
                  Center(
                    child: Image.asset(
                      'assets/images/wallet/start-icon.png',
                      width: MediaQuery.of(context).size.width,
                      height: 300,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const Spacer(),

                  // 欢迎文字
                  Text(
                    loc.walletStartWelcome,
                    style: AppTextStyles.h1.copyWith(
                      fontSize: 36,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 带下划线的 PARACOSM 文字
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        loc.walletStartTo,
                        style: AppTextStyles.h1.copyWith(
                          fontSize: 36,
                         
                        ),
                      ),
                      Stack(
                        children: [
                          // 下划线
                          Positioned(
                            bottom: 8,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 6,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'PARACOSM',
                            style: AppTextStyles.h1.copyWith(
                              fontSize: 34,
                             
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Text(
                    loc.walletStartWorld,
                    style: AppTextStyles.h1.copyWith(
                      fontSize: 36,
                     
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 底部下一步按钮 (黑色圆形图标)
                  Align(
                    alignment: Alignment.centerRight,// 底部留出40px的间距
                    child: GestureDetector(
                      onTap: () {
                      context.push('/wallet-setup');
                    },
                      child: Container(
                        margin: const EdgeInsets.only(right: 28),
                        child: Image.asset(
                        'assets/images/wallet/next-icon.png',
                        width: 64,
                        height: 64,
                      ),
                      )
                    ),
                  ),
                   const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
