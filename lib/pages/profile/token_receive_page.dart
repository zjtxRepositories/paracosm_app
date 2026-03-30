import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_localizations_keys.dart';
import 'package:paracosm/widgets/base/app_page.dart';

/// 代币收款页面
///
/// 用于展示指定代币的收款二维码和钱包地址，并提供分享和复制功能。
class TokenReceivePage extends StatelessWidget {
  /// 代币符号 (例如: BNB, BTC)
  final String tokenSymbol;

  /// 网络名称 (例如: Binancestry(BSC))
  final String networkName;

  /// 钱包地址
  final String walletAddress;

  const TokenReceivePage({
    super.key,
    this.tokenSymbol = 'BNB',
    this.networkName = 'Binancestry(BSC)',
    this.walletAddress = '0xc84sa01ua125d15uvcbv78fa98uu9daccf915uvc',
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppPage(
      showNav: true,
      title: l10n.profileTokenReceiveQrCodePayment,
      child: Stack(
        children: [
          // 1. 背景网格图
          Positioned.fill(
            child: Image.asset(
              'assets/images/wallet/grid-bg.png',
              fit: BoxFit.cover,
            ),
          ),
          // 2. 页面主要内容
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      // 收款卡片容器
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.grey200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. 用户信息展示行 (头像 + 名称 + 扫码提示)
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tokenSymbol,
                                          style: AppTextStyles.h2.copyWith(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.grey900,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          l10n.profileTokenReceiveScanQrToPay,
                                          style: AppTextStyles.body.copyWith(
                                            fontSize: 12,
                                            color: AppColors.grey400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 2. 带圆弧缺口的虚线分割线
                            _buildTicketSeparator(context),

                            // 3. 二维码展示区域
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 24,
                                bottom: 16,
                                left: 24,
                                right: 24,
                              ),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Image.asset(
                                  'assets/images/profile/user/test-code.png', // 指定的测试二维码路径
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),

                            // 4. 虚线分割线 (无缺口)
                            _buildDashedLine(),

                            // 5. 钱包地址展示区域
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 16,
                                left: 20,
                                right: 20,
                                bottom: 20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.profileTokenReceiveWalletAddress,
                                    style: AppTextStyles.body.copyWith(
                                      fontSize: 14,
                                      color: AppColors.grey700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    walletAddress,
                                    style: AppTextStyles.body.copyWith(
                                      fontSize: 14,
                                      color: AppColors.grey800,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 底部操作栏 (白色背景)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.grey200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // 分享按钮
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _showShareDialog(context),
                                behavior: HitTestBehavior.opaque,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      'assets/images/common/share.png',
                                      width: 20,
                                      height: 20,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      l10n.profileTokenReceiveShare,
                                      style: AppTextStyles.body.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.grey800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // 垂直分割线
                            Container(
                              width: 1,
                              height: 30,
                              color: AppColors.grey200,
                            ),
                            // 复制按钮
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(text: walletAddress),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          l10n.profileTokenReceiveCopiedToClipboard),
                                    ),
                                  );
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      'assets/images/common/copy-black.png',
                                      width: 20,
                                      height: 20,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      l10n.profileTokenReceiveCopy,
                                      style: AppTextStyles.body.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.grey800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建带圆弧缺口的虚线分割线
  Widget _buildTicketSeparator(BuildContext context, {Color? bgColor}) {
    final effectiveBgColor = bgColor ?? AppColors.grey100;
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildDashedLine(),
        // 两侧圆弧缺口
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 左侧缺口
            Transform.translate(
              offset: const Offset(-10, 0),
              child: Stack(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: effectiveBgColor, // 背景色，匹配底层背景
                      shape: BoxShape.circle,
                    ),
                  ),
                  CustomPaint(
                    size: const Size(20, 20),
                    painter: _NotchBorderPainter(isLeftNotch: true),
                  ),
                ],
              ),
            ),
            // 右侧缺口
            Transform.translate(
              offset: const Offset(10, 0),
              child: Stack(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: effectiveBgColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  CustomPaint(
                    size: const Size(20, 20),
                    painter: _NotchBorderPainter(isLeftNotch: false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建纯虚线
  Widget _buildDashedLine() {
    return Padding(
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
    );
  }

  /// 显示分享弹窗
  void _showShareDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ShareDialog',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 335,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. 上半部分：主内容区域 (带特殊切边的容器)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipPath(
                        clipper: _ShareClipper(),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 欢迎文字
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 48,
                                  left: 20,
                                  right: 50, // 给右上角的绳子留点空间
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.walletStartWelcome,
                                      style: AppTextStyles.h1.copyWith(
                                        fontSize: 38.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.grey900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          l10n.walletStartTo,
                                          style: AppTextStyles.h1.copyWith(
                                            fontSize: 22.sp,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.grey900,
                                          ),
                                        ),
                                        Text(
                                          'PARACOSM',
                                          style: AppTextStyles.h1.copyWith(
                                            fontSize: 22.sp,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.grey900, // 主色
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: AppColors.primary,
                                            decorationThickness: 2,
                                          ),
                                        ),
                                        Text(
                                          l10n.walletStartWorld,
                                          style: AppTextStyles.h1.copyWith(
                                            fontSize: 22.sp,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.grey900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // 中间插画图片
                              Image.asset(
                                'assets/images/profile/user/share-bg.png',
                                width: double.infinity,
                                height: 292,
                                fit: BoxFit.contain,
                              ),
                              // 分割线 (带圆弧缺口)
                              _buildTicketSeparator(context,
                                  bgColor: Colors.black.withOpacity(0.5)),
                              // 底部邀请信息
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n.profileProfileDetailsInviteFriends,
                                            style: AppTextStyles.h2.copyWith(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.grey900,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            l10n.profileQrCodeScanToAdd,
                                            style: AppTextStyles.body.copyWith(
                                              fontSize: 12,
                                              color: AppColors.grey400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Image.asset(
                                      'assets/images/profile/user/test-code.png',
                                      width: 48,
                                      height: 48,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // 右上角绳子图标
                      Positioned(
                        top: -12,
                        right: 8,
                        child: Image.asset(
                          'assets/images/profile/user/rope.png',
                          width: 48,
                          height: 70,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 2. 下半部分：操作按钮区域
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        // Download
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              // TODO: 下载功能
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/profile/user/share-download.png',
                                  width: 20,
                                  height: 20,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Download',
                                  style: AppTextStyles.body.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.grey800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // 垂直分割线
                        Container(
                          width: 1,
                          height: 30,
                          color: AppColors.grey200,
                        ),
                        // Copy
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Clipboard.setData(
                                const ClipboardData(
                                    text: 'PARACOSM World Invite'),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('已复制邀请链接')),
                              );
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/common/copy-black.png',
                                  width: 20,
                                  height: 20,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Copy',
                                  style: AppTextStyles.body.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.grey800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 自定义弹窗顶部特殊切边
class _ShareClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const radius = 16.0;
    const curveRadius = 80.0; // 右上角特殊的圆角半径

    // 从左上角开始
    path.moveTo(radius, 0);
    // 顶部边缘
    path.lineTo(size.width - curveRadius, 0);
    // 右上角特殊的圆弧
    path.arcToPoint(
      Offset(size.width, curveRadius),
      radius: const Radius.circular(curveRadius),
      clockwise: true,
    );
    // 右侧边缘
    path.lineTo(size.width, size.height - radius);
    // 右下角圆角
    path.arcToPoint(
      Offset(size.width - radius, size.height),
      radius: const Radius.circular(radius),
      clockwise: true,
    );
    // 底部边缘
    path.lineTo(radius, size.height);
    // 左下角圆角
    path.arcToPoint(
      Offset(0, size.height - radius),
      radius: const Radius.circular(radius),
      clockwise: true,
    );
    // 左侧边缘
    path.lineTo(0, radius);
    // 左上角圆角
    path.arcToPoint(
      Offset(radius, 0),
      radius: const Radius.circular(radius),
      clockwise: true,
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// 绘制圆弧缺口的边框
class _NotchBorderPainter extends CustomPainter {
  final bool isLeftNotch;

  _NotchBorderPainter({required this.isLeftNotch});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.grey200 // 与容器边框颜色一致
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    if (isLeftNotch) {
      // 左侧缺口：绘制圆弧的右侧（即进入容器内部的曲线部分）
      canvas.drawArc(
        Rect.fromLTWH(0, 0, size.width, size.height),
        -1.57, // 从顶部开始 (-90度)
        3.14, // 顺时针旋转180度，到底部 (90度)
        false,
        paint,
      );
    } else {
      // 右侧缺口：绘制圆弧的左侧（即进入容器内部的曲线部分）
      canvas.drawArc(
        Rect.fromLTWH(0, 0, size.width, size.height),
        1.57, // 从底部开始 (90度)
        3.14, // 顺时针旋转180度，到顶部 (270度)
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
