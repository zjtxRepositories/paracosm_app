import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';

/// 勾选框类型
enum AppCheckboxType {
  /// 复选 - 未选中
  uncheck,
  /// 复选 - 选中
  checked,
  /// 单选 - 选中
  radioChecked,
}

/// 通用勾选框组件
class AppCheckbox extends StatelessWidget {
  /// 是否选中
  final bool value;
  /// 点击回调
  final ValueChanged<bool>? onChanged;
  /// 尺寸
  final double size;
  /// 是否为单选模式
  final bool isRadio;

  const AppCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 20,
    this.isRadio = false,
  });

  @override
  Widget build(BuildContext context) {
    String iconName;
    if (isRadio) {
      iconName = value ? 'radio-checked' : 'uncheck';
    } else {
      iconName = value ? 'checked' : 'uncheck';
    }

    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: Image.asset(
        'assets/images/common/$iconName.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        // 增加错误处理，防止图片缺失导致布局崩溃
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: isRadio ? BoxShape.circle : BoxShape.rectangle,
              border: Border.all(color: AppColors.grey300),
            ),
            child: value ? Icon(Icons.check, size: size * 0.8, color: AppColors.primary) : null,
          );
        },
      ),
    );
  }
}
