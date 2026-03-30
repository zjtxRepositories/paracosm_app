import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';

/// 通用密码输入框组件
/// 
/// 支持显隐切换，集成自定义 eye 图标。
class AppPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;

  const AppPasswordField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.onChanged,
    this.validator,
    this.textInputAction,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscureText = true;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 12),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: _obscureText,
          onChanged: widget.onChanged,
          validator: widget.validator,
          textInputAction: widget.textInputAction,
          cursorColor: AppColors.grey900,
          style: AppTextStyles.body.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.grey900,
            letterSpacing: _obscureText ? 4.0 : 0.0,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: AppTextStyles.body.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.grey400,
              letterSpacing: 0,
            ),
            filled: true,
            fillColor: _focusNode.hasFocus ? AppColors.white : AppColors.grey100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            // 边框处理
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.grey900, width: 1,),
            ),
            // 右侧显隐切换图标
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscureText = !_obscureText),
              icon: Image.asset(
                'assets/images/common/${_obscureText ? 'eye-off-line' : 'eye-line'}.png',
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) {
                  // 容错处理：如果图标不存在，使用 Material 图标
                  return Icon(
                    _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.grey400,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
