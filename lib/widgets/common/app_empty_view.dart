import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';

/// 通用空状态组件
/// 
/// 用于显示列表或搜索结果为空时的提示。
/// 自动铺满剩余空间并居中显示。
class AppEmptyView extends StatelessWidget {
  /// 提示文字
  final String text;
  
  /// 图片资源路径，默认为 'assets/images/chat/no-data.png'
  final String? imagePath;
  
  /// 图片宽度，默认为 120
  final double imageSize;
  
  /// 文字下方的占位高度，使内容视觉上更偏上一些，默认 100
  final double bottomOffset;

  const AppEmptyView({
    super.key,
    required this.text,
    this.imagePath,
    this.imageSize = 120,
    this.bottomOffset = 100,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 如果父容器提供了有限的高度，则占满高度并居中
        // 如果是无限高度（如在 ListView 中），则根据内容自适应
        final double? height = constraints.hasBoundedHeight ? constraints.maxHeight : null;
        
        return Container(
          width: double.infinity,
          height: height,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // 在有限空间内居中，在无限空间内紧凑
            children: [
              Image.asset(
                imagePath ?? 'assets/images/chat/no-data.png',
                width: imageSize,
                height: imageSize,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.grey400,
                    fontSize: 14,
                  ),
                ),
              ),
              // 占位，使内容稍微偏上一点，视觉更平衡
              SizedBox(height: bottomOffset),
            ],
          ),
        );
      },
    );
  }
}
