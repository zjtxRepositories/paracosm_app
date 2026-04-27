import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';

/// 底部动作表项
class AppActionSheetItem {
  final String label;
  final VoidCallback onTap;

  const AppActionSheetItem({
    required this.label,
    required this.onTap,
  });
}

/// 底部动作表
class AppActionSheet extends StatelessWidget {
  final List<AppActionSheetItem> items;
  final String cancelText;

  const AppActionSheet({
    super.key,
    required this.items,
    this.cancelText = '取消',
  });

  static Future<void> show(
    BuildContext context, {
    required List<AppActionSheetItem> items,
    String cancelText = '取消',
    bool useRootNavigator = true,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: useRootNavigator,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AppActionSheet(
          items: items,
          cancelText: cancelText,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      color: AppColors.grey100,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Container(
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: items.asMap().entries.expand((entry) {
                    final index = entry.key;
                    final item = entry.value;

                    return [
                      _buildActionItem(
                        context,
                        label: item.label,
                        onTap: item.onTap,
                      ),
                      if (index != items.length - 1)
                        const Divider(
                          height: 1,
                          // thickness: 0.5,
                          color: AppColors.grey200,
                        ),
                    ];
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionItem(
                    context,
                    label: cancelText,
                    onTap: () {},
                    isCancel: true,
                  ),
                  SizedBox(height: bottomInset),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
    bool isCancel = false,
  }) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
      child: Container(
        width: double.infinity,
        height: 56,
        alignment: Alignment.center,
        color: Colors.white,
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.grey900,
          ),
        ),
      ),
    );
  }
}
