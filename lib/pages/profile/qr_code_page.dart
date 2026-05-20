import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:paracosm/core/models/user_display_model.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/im/listener/user_display_state_center.dart';
import 'package:paracosm/modules/im/manager/im_user_manager.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';
import 'package:paracosm/widgets/common/app_toast.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import 'package:screenshot/screenshot.dart';

/// 二维码页面
class QrCodePage extends StatefulWidget {
  final String userId;

  const QrCodePage({super.key, required this.userId});

  @override
  State<QrCodePage> createState() => _QrCodePageState();
}

class _QrCodePageState extends State<QrCodePage> {
  UserDisplayModel? _user;

  final ScreenshotController _screenshotController = ScreenshotController();

  /// 截图时隐藏下载按钮
  bool _hideDownloadButton = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  /// =========================
  /// 加载用户
  /// =========================
  Future<void> _loadUser() async {
    final profile = await UserDisplayStateCenter().getUser(widget.userId);
    if (profile == null) return;

    if (!mounted) return;

    setState(() {
      _user = profile;
    });
  }

  /// =========================
  /// 二维码内容
  /// =========================
  String get _qrContent {
    return 'paracosm://user?userId=${widget.userId}';
  }

  /// =========================
  /// 保存二维码
  /// =========================
  Future<void> _saveQrCode() async {
    try {
      /// 隐藏下载按钮
      setState(() {
        _hideDownloadButton = true;
      });

      /// 等待界面刷新
      await Future.delayed(const Duration(milliseconds: 50));

      final permission = await PhotoManager.requestPermissionExtend();

      if (!permission.isAuth) {
        setState(() {
          _hideDownloadButton = false;
        });
        return;
      }

      final Uint8List? image = await _screenshotController.capture(
        pixelRatio: 3,
      );

      /// 恢复按钮
      if (mounted) {
        setState(() {
          _hideDownloadButton = false;
        });
      }

      if (image == null) {
        AppToast.show(AppLocalizations.of(context)!.commonDownloadFailed);
        return;
      }

      await PhotoManager.editor.saveImage(
        image,
        filename: 'paracosm_qr_${widget.userId}.png',
        title: _user?.name ?? 'QR Code',
      );

      AppToast.show(AppLocalizations.of(context)!.commonSavedToAlbum);
    } catch (e) {
      if (mounted) {
        setState(() {
          _hideDownloadButton = false;
        });
      }

      AppToast.show(AppLocalizations.of(context)!.commonDownloadFailed);

      debugPrint('save qr error => $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      showNav: true,
      title: AppLocalizations.of(context)!.profileQrCodeQrCode,

      child: Stack(
        children: [
          /// 背景
          Positioned.fill(
            child: Image.asset(
              'assets/images/wallet/grid-bg.png',
              fit: BoxFit.cover,
            ),
          ),

          /// 内容
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),

            child: Column(
              children: [
                const SizedBox(height: 16),

                /// 顶部背景图
                Center(
                  child: Image.asset(
                    'assets/images/profile/user/code-bg.png',
                    width: 335,
                    height: 207,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 16),

                /// 二维码卡片
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),

                  child: Screenshot(
                    controller: _screenshotController,

                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),

                      child: Column(
                        mainAxisSize: MainAxisSize.min,

                        children: [
                          /// 用户信息
                          Padding(
                            padding: const EdgeInsets.all(20),

                            child: Row(
                              children: [
                                UserAvatarWidget(
                                  userId: _user?.userId,

                                  avatarUrl: _user?.avatar,

                                  size: 48,

                                  borderRadius: BorderRadius.circular(12),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,

                                    children: [
                                      Text(
                                        _user?.name ?? '',

                                        style: AppTextStyles.h2.copyWith(
                                          fontSize: 20,

                                          fontWeight: FontWeight.w600,

                                          color: AppColors.grey900,
                                        ),
                                      ),

                                      const SizedBox(height: 2),

                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.profileQrCodeScanToAdd,

                                        style: AppTextStyles.body.copyWith(
                                          fontSize: 12,

                                          color: AppColors.grey400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                /// 下载按钮
                                if (!_hideDownloadButton)
                                  GestureDetector(
                                    onTap: _saveQrCode,

                                    child: Image.asset(
                                      'assets/images/profile/user/download.png',
                                      width: 24,
                                      height: 24,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          /// 虚线分割
                          Stack(
                            alignment: Alignment.center,

                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),

                                child: Row(
                                  children: List.generate(
                                    30,
                                    (index) => Expanded(
                                      child: Container(
                                        height: 1,

                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 2,
                                        ),

                                        color: AppColors.grey200,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,

                                children: [
                                  /// 左缺口
                                  Transform.translate(
                                    offset: const Offset(-10, 0),

                                    child: Container(
                                      width: 20,
                                      height: 20,

                                      decoration: BoxDecoration(
                                        color: AppColors.grey100,

                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),

                                  /// 右缺口
                                  Transform.translate(
                                    offset: const Offset(10, 0),

                                    child: Container(
                                      width: 20,
                                      height: 20,

                                      decoration: BoxDecoration(
                                        color: AppColors.grey100,

                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          /// 二维码区域
                          Padding(
                            padding: const EdgeInsets.all(24),

                            child: AspectRatio(
                              aspectRatio: 1,

                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,

                                  borderRadius: BorderRadius.circular(12),
                                ),

                                padding: const EdgeInsets.all(12),

                                child: PrettyQrView.data(
                                  data: _qrContent,

                                  decoration: PrettyQrDecoration(
                                    shape: const PrettyQrSmoothSymbol(),

                                    image: _user?.avatar != null
                                        ? PrettyQrDecorationImage(
                                            image: NetworkImage(_user!.avatar),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
