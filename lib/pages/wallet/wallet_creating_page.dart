
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/modules/account/service/account_service.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';

import '../../widgets/common/app_toast.dart';

/// 创建钱包 - 正在创建中
class WalletCreatingPage extends StatefulWidget {
  final List<String>? mnemonics;
  final String? password;
  final String? privateKey;
  const WalletCreatingPage({super.key, this.mnemonics, this.password, this.privateKey});

  @override
  State<WalletCreatingPage> createState() => _WalletCreatingPageState();
}

class _WalletCreatingPageState extends State<WalletCreatingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _creating();
    });
  }
  Future _creating() async {
    if (widget.mnemonics != null || widget.privateKey != null){
      try {
        await Future.delayed(Duration(seconds: 2));
        await AccountService.creating(
          mnemonic: widget.mnemonics?.join(' '),
          privateKey: widget.privateKey,
          password: widget.password!,
        );
        AppToast.showSuccess(AppLocalizations.of(context)!.walletCreateSuccess);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            // 跳转到主页 Chat 页
            context.go('/chat');
          }
        });
      }catch(e){
        print('创建钱包错误：$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AppPage(
      showNav: true,
      showBack: true,
      title: loc.walletCreatingStarNetwork,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 中间图标 - network-icon
            Image.asset(
              'assets/images/wallet/network-icon.png',
              width: 240.w, // 使用适配尺寸
              height: 240.w,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.cloud_sync,
                size: 100.w,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 24.h),
            // 正在创建钱包...
            Text(
              loc.walletCreatingTitle,
              style: AppTextStyles.h2.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
            ),
            SizedBox(height: 12.h),
            // 助记词需妥善放置安全处，防止丢失
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Text(
                loc.walletCreatingTip,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.grey400,
                ),
              ),
            ),
            // 为了视觉平衡，下方留出一段空间
            SizedBox(height: 100.h),
          ],
        ),
      ),
    );
  }
}
