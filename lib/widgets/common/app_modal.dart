import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'app_button.dart';

/// 通用底部弹窗组件
class AppModal extends StatelessWidget {
  final String title;
  final Widget? titleWidget;
  final String? subtitle;
  final String? description;
  final String? confirmText;
  final String? cancelText;
  final BorderSide? cancelBorder;
  final double? confirmWidth;
  final double? cancelWidth;
  final Color? confirmColor;
  final Color? cancelColor;
  final Color? cancelTextColor;
  final Widget? icon;
  final Widget? child;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const AppModal({
    super.key,
    required this.title,
    this.titleWidget,
    this.subtitle,
    this.description,
    this.confirmText = '确定',
    this.cancelText,
    this.cancelBorder,
    this.confirmWidth,
    this.cancelWidth,
    this.confirmColor,
    this.cancelColor,
    this.cancelTextColor,
    this.icon,
    this.child,
    required this.onConfirm,
    this.onCancel,
  });

  /// 显示弹窗的静态方法
  static Future<void> show(
    BuildContext context, {
    required String title,
    Widget? titleWidget,
    String? subtitle,
    String? description,
    String? confirmText = '确定',
    String? cancelText,
    BorderSide? cancelBorder,
    double? confirmWidth,
    double? cancelWidth,
    Color? confirmColor,
    Color? cancelColor,
    Color? cancelTextColor,
    Widget? icon,
    Widget? child,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppModal(
        title: title,
        titleWidget: titleWidget,
        subtitle: subtitle,
        description: description,
        confirmText: confirmText,
        cancelText: cancelText,
        cancelBorder: cancelBorder,
        confirmWidth: confirmWidth,
        cancelWidth: cancelWidth,
        confirmColor: confirmColor,
        cancelColor: cancelColor,
        cancelTextColor: cancelTextColor,
        icon: icon,
        child: child,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 24,
          left: 20,
          right: 20,
          top: 12,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部指示条
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 20),
              // 标题栏
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  titleWidget ??
                      Text(
                        title,
                        style: AppTextStyles.h2.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey900,
                        ),
                      ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(
                      'assets/images/wallet/x.png',
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.close, color: AppColors.grey900),
                    ),
                  ),
                ],
              ),
              Container(
                height: 1,
                color: AppColors.grey100,
                margin: const EdgeInsets.only(top: 16, bottom: 24),
              ),
              // 内容区域
              if (child != null)
                child!
              else ...[
                // 默认的风险提示布局
                icon ??
                    Image.asset(
                      'assets/images/wallet/no-photo.png',
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
                          Icons.no_photography_outlined,
                          size: 64,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                const SizedBox(height: 16),
                if (subtitle != null) ...[
                  Center(
                    child: Text(
                      subtitle!,
                      style: AppTextStyles.h1.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (description != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      description!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.black,
                      ),
                    ),
                  ),
              ],
              // 按钮
              if (confirmText != null || cancelText != null)
                const SizedBox(height: 36),
              if (cancelText != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppButton(
                      text: cancelText!,
                      width: cancelWidth,
                      backgroundColor: cancelColor ?? AppColors.white,
                      textColor: cancelTextColor ?? AppColors.grey900,
                      border: cancelBorder,
                      onPressed: () {
                        if (onCancel != null) {
                          onCancel!();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    if (confirmText != null) ...[
                      const SizedBox(width: 12),
                      AppButton(
                        text: confirmText!,
                        width: confirmWidth,
                        backgroundColor: confirmColor,
                        onPressed: () {
                          onConfirm();
                        },
                      ),
                    ],
                  ],
                )
              else if (confirmText != null)
                AppButton(
                  text: confirmText!,
                  backgroundColor: confirmColor,
                  onPressed: () {
                    onConfirm();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
