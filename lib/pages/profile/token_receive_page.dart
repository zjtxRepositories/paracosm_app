import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_network_image.dart';
import 'package:paracosm/widgets/common/app_toast.dart';
import 'package:screenshot/screenshot.dart';

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

  /// 代币图标
  final String tokenLogo;

  final ScreenshotController _cardScreenshotController = ScreenshotController();

  TokenReceivePage({
    super.key,
    this.tokenSymbol = 'BNB',
    this.networkName = 'Binancestry(BSC)',
    this.walletAddress = '0xc84sa01ua125d15uvcbv78fa98uu9daccf915uvc',
    this.tokenLogo = '',
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    print('wallet---$walletAddress');
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
                      Screenshot(
                        controller: _cardScreenshotController,
                        child: Container(
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
                                    AppNetworkImage(
                                      url: tokenLogo,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.contain,
                                      borderRadius: BorderRadius.circular(12),
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
                      ),
                      const SizedBox(height: 12),
                      // 底部操作栏 (白色背景)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
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
                            // 下载按钮
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _saveReceiveCard(context),
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
                                      l10n.profileTokenReceiveSave,
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
                                        l10n.profileTokenReceiveCopiedToClipboard,
                                      ),
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

  Future<void> _saveReceiveCard(BuildContext context) async {
    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        if (!context.mounted) return;
        AppToast.show(AppLocalizations.of(context)!.commonDownloadFailed);
        return;
      }

      final Uint8List? image = await _cardScreenshotController.capture(
        pixelRatio: 3,
      );
      if (!context.mounted) return;

      if (image == null) {
        AppToast.show(AppLocalizations.of(context)!.commonDownloadFailed);
        return;
      }

      await PhotoManager.editor.saveImage(
        image,
        filename:
            'paracosm_receive_${tokenSymbol}_${DateTime.now().millisecondsSinceEpoch}.png',
        title: '$tokenSymbol Receive',
      );

      if (!context.mounted) return;
      AppToast.show(AppLocalizations.of(context)!.commonSavedToAlbum);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(AppLocalizations.of(context)!.commonDownloadFailed);
      debugPrint('save receive card error => $e');
    }
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
}

/// 绘制圆弧缺口的边框
class _NotchBorderPainter extends CustomPainter {
  final bool isLeftNotch;

  _NotchBorderPainter({required this.isLeftNotch});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors
          .grey200 // 与容器边框颜色一致
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
