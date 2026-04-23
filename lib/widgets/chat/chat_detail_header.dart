import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';

class ChatDetailHeader extends StatelessWidget {
  const ChatDetailHeader({
    super.key,
    required this.name,
    required this.isGroup,
    required this.avatars,
    required this.onMoreTap,
  });

  final String name;
  final bool isGroup;
  final List<String> avatars;
  final VoidCallback onMoreTap;

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
            onPressed: () => Navigator.pop(context),
          ),
          GestureDetector(
            onTap: () {
              final encodedName = Uri.encodeComponent(name);
              context.push('/session-details/$encodedName');
            },
            child: _HeaderAvatar(
              isGroup: isGroup,
              avatars: avatars,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: AppTextStyles.h2.copyWith(fontSize: 16),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.onlineBg,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.chatDetailActive,
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
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({
    required this.isGroup,
    required this.avatars,
  });

  final bool isGroup;
  final List<String> avatars;

  @override
  Widget build(BuildContext context) {
    if (!isGroup || avatars.isEmpty) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: const DecorationImage(
            image: AssetImage('assets/images/chat/avatar.png'),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
        ),
        itemCount: avatars.length > 4 ? 4 : avatars.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Image.asset(
              avatars[index],
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}
