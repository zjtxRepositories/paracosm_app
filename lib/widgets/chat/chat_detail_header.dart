import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';

import 'group_avatar_widget.dart';

class ChatDetailHeader extends StatelessWidget {
  const ChatDetailHeader({
    super.key,
    required this.name,
    required this.isGroup,
    required this.avatar,
    required this.targetId,
    required this.memberCount,
    required this.isOnline,
    required this.onMoreTap,
    this.onAvatarTap,
  });

  final String name;
  final bool isGroup;
  final String avatar;
  final String targetId;
  final int memberCount;
  final bool isOnline;
  final VoidCallback onMoreTap;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kToolbarHeight + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: const BoxDecoration(
        color: Colors.transparent,
        border: Border(bottom: BorderSide(color: AppColors.grey200)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 4),
          IconButton(
            icon: Image.asset(
              'assets/images/common/back-icon.png',
              width: 32,
              height: 32,
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/chat');
              }
            },
          ),
          GestureDetector(onTap: onAvatarTap, child: _buildAvatar()),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h2.copyWith(fontSize: 16),
                    ),
                    Text(
                      '($memberCount)',
                      style: AppTextStyles.h2.copyWith(fontSize: 16),
                    ),
                  ],
                ),
                Row(
                  children: [
                    isGroup
                        ? SizedBox()
                        : Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? AppColors.onlineBg
                                  : AppColors.grey400,
                              shape: BoxShape.circle,
                            ),
                          ),
                    isGroup ? SizedBox() : const SizedBox(width: 4),
                    isGroup
                        ? SizedBox()
                        : Text(
                            isOnline
                                ? AppLocalizations.of(context)!.chatDetailActive
                                : AppLocalizations.of(
                                    context,
                                  )!.chatHeaderOffline,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.grey400,
                              fontSize: 12,
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Image.asset(
              'assets/images/chat/more.png',
              width: 32,
              height: 32,
            ),
            onPressed: onMoreTap,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (!isGroup) {
      return UserAvatarWidget(
        userId: targetId,
        avatarUrl: avatar,
        size: 44,
        borderRadius: BorderRadius.circular(10),
      );
    }
    return GroupAvatarWidget(groupId: targetId, portraitUri: avatar, size: 44);
  }
}
