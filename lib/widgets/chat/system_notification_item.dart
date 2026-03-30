import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';

/// 系统通知列表项组件
class SystemNotificationItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final int unreadCount;
  final IconData icon;
  final Color iconBgColor;
  final VoidCallback? onTap;

  const SystemNotificationItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
    this.unreadCount = 0,
    required this.icon,
    this.iconBgColor = AppColors.notificationBg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.only(left: 20, top: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图标部分
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Image.asset('assets/images/chat/notification.png', width: 28, height: 28),
              ),
            ),
            const SizedBox(width: 12),
            // 内容部分
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(right: 20, bottom: 16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.grey100,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.h2.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          time,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.grey400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subtitle,
                            style: AppTextStyles.caption.copyWith(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            constraints: const BoxConstraints(minWidth: 18),
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: AppTextStyles.overline.copyWith(
                                color: AppColors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
