import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';

/// 全局 Toast 工具类
class AppToast {
  AppToast._();

  /// 显示普通消息（默认 show 方法）
  static void show(String message) {
    showToastWidget(
      _buildSimpleToastChild(message: message),
      duration: const Duration(seconds: 2),
      position: ToastPosition.center,
      handleTouch: true,
    );
  }

  /// 显示成功提示
  static void showSuccess(String message) {
    showToastWidget(
      _buildToastChild(
        icon: Icons.check_circle_outline,
        message: message,
      ),
      duration: const Duration(seconds: 2),
      position: ToastPosition.center,
      handleTouch: true,
    );
  }

  /// 显示警告/提示消息
  static void showInfo(String message) {
    showToastWidget(
      _buildToastChild(
        icon: Icons.info_outline,
        message: message,
      ),
      duration: const Duration(seconds: 2),
      position: ToastPosition.center,
      handleTouch: true,
    );
  }

  /// 显示复制成功提示
  static void showCopied([String message = 'Copied!']) {
    showToastWidget(
      _buildCopiedToastChild(message: message),
      duration: const Duration(seconds: 2),
      position: ToastPosition.top,
      handleTouch: true,
    );
  }

  /// 构建带图标的 Toast 内容视图
  static Widget _buildToastChild({
    required IconData icon,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建纯文本的 Toast 内容视图
  static Widget _buildSimpleToastChild({
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTextStyles.body.copyWith(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 构建复制成功提示内容视图
  static Widget _buildCopiedToastChild({
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/moments/done.png',
            width: 16,
            height: 16,
          ),
          const SizedBox(width: 4),
          Text(
            message,
            style: AppTextStyles.body.copyWith(
              color: AppColors.grey900,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
