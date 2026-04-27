import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';

/// 全局通用搜索框组件
class AppSearchInput extends StatelessWidget {
  /// 控制器
  final TextEditingController? controller;
  /// 占位文本
  final String? hintText;
  /// 输入改变回调
  final ValueChanged<String>? onChanged;
  /// 提交回调
  final ValueChanged<String>? onSubmitted;
  /// 自动获取焦点
  final bool autofocus;
  /// 内边距
  final EdgeInsetsGeometry? padding;

  const AppSearchInput({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.topBg, // 使用背景色
        borderRadius: BorderRadius.circular(28), // 圆角
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/common/search.png',
            width: 24,
            height: 24,
            color: AppColors.grey900,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Center(
              child: TextField(
                controller: controller,
                autofocus: autofocus,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                textAlignVertical: TextAlignVertical.center,
                cursorHeight: 18, // 限制光标高度，防止撑开
                style: AppTextStyles.body.copyWith(
                  color: AppColors.grey900,
                  fontSize: 14,
                  height: 1.2, // 调整行高
                ),
                decoration: InputDecoration(
                  hintText: hintText ?? 'Search by alias, name, or address',
                  hintStyle: AppTextStyles.body.copyWith(
                    color: AppColors.grey400,
                    fontSize: 14,
                    height: 1.2,
                  ),
                  border: InputBorder.none,
                  isCollapsed: true, // 使用 collapsed 减少默认内边距干扰
                  contentPadding: const EdgeInsets.symmetric(vertical: 4), // 手动控制垂直内边距
                  suffixIconConstraints: const BoxConstraints(
                    minHeight: 24,
                    minWidth: 24,
                  ),
                  suffixIcon: controller != null
                      ? ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller!,
                    builder: (context, value, child) {
                      if (value.text.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return GestureDetector(
                        onTap: () {
                          controller!.clear();
                          onChanged?.call('');
                        },
                        child: const Icon(
                          Icons.close,
                          color: AppColors.grey400,
                          size: 20,
                        ),
                      );
                    },
                  )
                      : null,
                ),
              ),
            )
          ),
        ],
      ),
    );
  }
}
