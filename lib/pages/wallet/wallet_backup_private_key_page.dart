import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/common/app_toast.dart';
import 'package:paracosm/widgets/common/app_modal.dart';

/// 备份私钥页
///
/// 展示多个链的私钥列表，支持复制并包含风险提示弹窗。
class WalletBackupPrivateKeyPage extends StatefulWidget {
  final String privateKey;
  const WalletBackupPrivateKeyPage({super.key, required this.privateKey});

  @override
  State<WalletBackupPrivateKeyPage> createState() =>
      _WalletBackupPrivateKeyPageState();
}

class _WalletBackupPrivateKeyPageState
    extends State<WalletBackupPrivateKeyPage> {
  // 模拟私钥数据
   String _privateKeyPart1 = '';
   String _privateKeyPart2 = '';

  bool _isCopied1 = false;
  bool _isCopied2 = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    final mid = (widget.privateKey.length / 2).ceil();
    _privateKeyPart1 = widget.privateKey.substring(0, mid);
    _privateKeyPart2 = widget.privateKey.substring(mid);

  }
  void _copyKey(String key, int part) {
    final loc = AppLocalizations.of(context)!;
    AppModal.show(
      context,
      title: loc.walletBackupRiskDialogTitle,
      description: loc.walletBackupRiskDialogDesc,
      confirmText: loc.walletBackupRiskDialogConfirm,
      cancelText: loc.walletBackupRiskDialogCancel,
      confirmWidth: 200,
      cancelWidth: 108,
      cancelBorder: const BorderSide(color: AppColors.grey300),
      icon: Image.asset(
        'assets/images/wallet/bell-icon.png',
        width: 120,
        height: 120,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            color: AppColors.grey100,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.notifications_active_outlined,
            size: 64,
            color: AppColors.warning,
          ),
        ),
      ),
      onConfirm: () {
        Navigator.pop(context);
        Clipboard.setData(ClipboardData(text: key.replaceAll(' ', ''))).then((_) {
          setState(() {
            if (part == 1) {
              _isCopied1 = true;
            } else {
              _isCopied2 = true;
            }
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                if (part == 1) {
                  _isCopied1 = false;
                } else {
                  _isCopied2 = false;
                }
              });
            }
          });
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AppPage(
      showNav: true,
      showBack: true,
      title: loc.walletBackupPrivTitle,
      child: Stack(
        children: [
          // 1. 全屏背景网格图
          Positioned.fill(
            child: Image.asset(
              'assets/images/wallet/grid-bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. 页面内容
          Positioned.fill(
            child: SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 顶部标题和图标部分
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          loc.walletBackupPrivTitle,
                                          style: AppTextStyles.h1.copyWith(
                                            fontSize: 14,
                                          ),
                                        ),
                                        Stack(
                                          clipBehavior: Clip.none,
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
                                              loc.walletBackupPrivShareTip,
                                              style: AppTextStyles.h1.copyWith(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      loc.walletBackupPrivSubtitle,
                                      style: AppTextStyles.body.copyWith(
                                        color: AppColors.grey400,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Image.asset(
                                'assets/images/wallet/key-icon.png',
                                width: 79,
                                height: 74,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.lock_outline,
                                  size: 40,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                        ],
                      ),
                    ),
                  ),

                  // 3. 私钥卡片列表 - 使用 SliverFillRemaining 填充剩余高度
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildKeyCard(
                            label: loc.walletBackupPrivPart1,
                            key: _privateKeyPart1,
                            isCopied: _isCopied1,
                            onCopy: () => _copyKey(_privateKeyPart1, 1),
                          ),
                          const SizedBox(height: 16),
                          _buildKeyCard(
                            label: loc.walletBackupPrivPart2,
                            key: _privateKeyPart2,
                            isCopied: _isCopied2,
                            onCopy: () => _copyKey(_privateKeyPart2, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建私钥卡片
  Widget _buildKeyCard({
    required String label,
    required String key,
    required bool isCopied,
    required VoidCallback onCopy,
  }) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.grey200,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/wallet/key.png',
                  width: 12,
                  height: 12,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.key, size: 14, color: AppColors.grey400),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12,
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              key,
              style: AppTextStyles.body.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onCopy,
              behavior: HitTestBehavior.opaque,
              child: Container(
                margin: EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/common/${isCopied ? 'copyed' : 'copy'}.png',
                      width: 16,
                      height: 16,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        isCopied ? Icons.check : Icons.copy,
                        size: 14,
                        color: isCopied
                            ? AppColors.primaryDark
                            : AppColors.grey900,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCopied ? loc.commonCopied : loc.commonCopy,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: isCopied
                            ? AppColors.primaryDark
                            : AppColors.grey900,
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
}
