import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/chat/group_avatar_widget.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';

/// 联系人列表项组件 (支持单聊和群聊头像)
class ContactItem extends StatelessWidget {
  final String name;
  final String portraitUri;
  final String? userId;
  final String? groupId;
  final VoidCallback? onTap;
  final bool showDivider;
  final bool isStar; // 是否显示星标

  const ContactItem({
    super.key,
    required this.name,
    required this.portraitUri,
    this.onTap,
    this.userId,
    this.groupId,
    this.showDivider = true,
    this.isStar = false,
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
          children: [
            // 头像
            Stack(
              clipBehavior: Clip.none,
              children: [
                _buildAvatar(),
                if (isStar)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Image.asset(
                      'assets/images/chat/star.png',
                      width: 16,
                      height: 16,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // 姓名和分割线
            Expanded(
              child: Container(
                height: 60,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  border: showDivider
                      ? const Border(
                          bottom: BorderSide(
                            color: AppColors.grey100,
                            width: 1,
                          ),
                        )
                      : null,
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (userId != null){
      return UserAvatarWidget(
        userId: userId,
        avatarUrl: portraitUri,
        size: 44,
        borderRadius: BorderRadius.circular(10),
      );
    }
    return GroupAvatarWidget(
      groupId: groupId ?? '',
      portraitUri: portraitUri,
      size: 44,
    );

  }
}
