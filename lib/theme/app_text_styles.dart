import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';

/// 全局字体样式配置
/// 采用 Poppins 和 Inter 字体，提供多层级文本规范
class AppTextStyles {
  AppTextStyles._();

  // 一级标题
  static const TextStyle h1 = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.grey900,
    height: 1.3,
  );

  // 二级标题/列表项标题
  static const TextStyle h2 = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.grey900,
    height: 26 / 18,
  );

  // 标准正文 (14px)
  static const TextStyle body = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.grey400,
    height: 1.5,
  );

  // 强调正文 (14px, Medium)
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.black,
    height: 22 / 14,
  );

  // 辅助/次要文本 (12px)
  static const TextStyle caption = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.grey700,
    height: 1.5,
  );

  // 微型标签文本 (10px)
  static const TextStyle overline = TextStyle(
    fontFamily: 'Inter',
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.white,
    height: 12 / 10,
  );
}
