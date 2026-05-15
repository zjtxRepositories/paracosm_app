import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/widgets/common/app_modal.dart';

import '../base/app_localizations.dart';

class AppConfirmDialog {
  AppConfirmDialog._();

  /// =========================
  /// 通用确认弹窗
  /// =========================
  static Future<void> show(
      BuildContext context, {
        required String description,
        String? title,
        /// 确认按钮
        String? confirmText,
        /// 取消按钮
        String? cancelText,
        /// 图标
        Widget? icon,
        /// 是否危险操作
        bool danger = false,
        /// 点击确认
        Future<void> Function()? onConfirm,

        /// 点击取消
        VoidCallback? onCancel,

        /// 是否自动关闭
        bool autoPop = true,
      }) async {
    await AppModal.show(
        context,
        title: title ?? AppLocalizations.of(context)!.chatRequestHint,
        description: description,
        confirmText: confirmText ?? AppLocalizations.of(context)!.chatRequestSure,
        cancelText: cancelText ?? AppLocalizations.of(context)!.chatRequestCancel,
        confirmWidth: 161,
        cancelWidth: 161,
        cancelBorder: const BorderSide(color: AppColors.grey300),
        icon: Image.asset(
          'assets/images/wallet/bell-icon.png',
          width: 120,
          height: 120,
          fit: BoxFit.contain,
        ),
        onConfirm: ()=> onConfirm?.call()
    );
  }

}