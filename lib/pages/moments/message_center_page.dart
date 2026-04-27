import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_reply_sheet.dart';

class MessageCenterPage extends StatelessWidget {
  const MessageCenterPage({super.key});

  @override
  Widget build(BuildContext context) {

    final l10n = AppLocalizations.of(context)!;
    final items = <_MessageCenterItemData>[
      _MessageCenterItemData(
        name: 'Jessenny',
        message: l10n.translate('moments_followed_you'),
        date: '2025/04/17',
        buttonText: l10n.translate('moments_follow'),
        badgeIcon: 'assets/images/moments/center-user.png',
        isActive: true,
        isFilledButton: true,
      ),
      const _MessageCenterItemData(
        name: 'Leslie',
        message: 'Followed you',
        date: '2025/04/17',
        buttonText: 'Message',
        badgeIcon: 'assets/images/moments/center-user.png',
      ),
      const _MessageCenterItemData(
        name: 'Bell',
        message: 'Followed you',
        date: '2025/04/17',
        buttonText: 'Follow',
        badgeIcon: 'assets/images/moments/center-user.png',
        isFilledButton: true,
      ),
      const _MessageCenterItemData(
        name: 'Eleanor Pena',
        message: 'Followed you',
        date: '2025/04/17',
        buttonText: 'Message',
        badgeIcon: 'assets/images/moments/center-user.png',
      ),
      const _MessageCenterItemData(
        name: 'Simmons',
        message: 'Liked you',
        date: '2025/04/17',
        buttonText: 'Reply',
        badgeIcon: 'assets/images/moments/center-like.png',
      ),
      const _MessageCenterItemData(
        name: 'Wade Warren',
        message: 'Collected you',
        date: '2025/04/17',
        buttonText: 'Follow',
        badgeIcon: 'assets/images/moments/center-collect.png',
        isFilledButton: true,
      ),
      _MessageCenterItemData(
        name: 'Leslie',
        message: l10n.translate('moments_followed_you'),
        date: '2025/04/17',
        buttonText: l10n.translate('moments_message'),
        badgeIcon: 'assets/images/moments/center-user.png',
      ),
      _MessageCenterItemData(
        name: 'Bell',
        message: l10n.translate('moments_followed_you'),
        date: '2025/04/17',
        buttonText: l10n.translate('moments_follow'),
        badgeIcon: 'assets/images/moments/center-user.png',
        isFilledButton: true,
      ),
      _MessageCenterItemData(
        name: 'Eleanor Pena',
        message: l10n.translate('moments_followed_you'),
        date: '2025/04/17',
        buttonText: l10n.translate('moments_message'),
        badgeIcon: 'assets/images/moments/center-user.png',
      ),
      _MessageCenterItemData(
        name: 'Simmons',
        message: l10n.translate('moments_liked_you'),
        date: '2025/04/17',
        buttonText: l10n.translate('moments_reply'),
        badgeIcon: 'assets/images/moments/center-like.png',
        isFilledButton: true,
        isReplyAction: true,
      ),
      _MessageCenterItemData(
        name: 'Wade Warren',
        message: l10n.translate('moments_collected_you'),
        date: '2025/04/17',
        buttonText: l10n.translate('moments_follow'),
        badgeIcon: 'assets/images/moments/center-collect.png',
        isFilledButton: true,
      ),
      _MessageCenterItemData(
        name: 'Robert Fox',
        message: l10n.translate('moments_reply_text'),
        date: '2025/04/17',
        buttonText: l10n.translate('moments_reply'),
        badgeIcon: 'assets/images/moments/center-msg.png',
        isReplyAction: true,
      ),
    ];

    return AppPage(
      title: l10n.translate('moments_message_center_title'),
      showNavBorder: false,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 0),
        itemBuilder: (context, index) {
          return _MessageCenterListItem(item: items[index]);
        },
      ),
    );
  }
}

class _MessageCenterItemData {
  final String name;
  final String message;
  final String date;
  final String buttonText;
  final String badgeIcon;
  final bool isActive;
  final bool isFilledButton;
  final bool isReplyAction;

  const _MessageCenterItemData({
    required this.name,
    required this.message,
    required this.date,
    required this.buttonText,
    required this.badgeIcon,
    this.isActive = false,
    this.isFilledButton = false,
    this.isReplyAction = false,
  });
}

class _MessageCenterListItem extends StatelessWidget {
  final _MessageCenterItemData item;

  const _MessageCenterListItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: item.isActive ? Colors.white : Colors.transparent,
      padding: const EdgeInsets.fromLTRB(6, 16, 20, 0),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (item.isActive)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(width: 14),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/chat/avatar.png',
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: -3,
                      bottom: -3,
                      child: Image.asset(
                        item.badgeIcon,
                        width: 16,
                        height: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width:8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.grey900,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: item.message,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.grey700,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            TextSpan(
                              text: '  ${item.date}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.grey400,
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildActionButton(context),
              ],
            ),
          ),
          Positioned(
            left: 68,
            right: 0,
            bottom: 0,
            child: Container(
              height: 1,
              color: AppColors.grey200,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildActionButton(BuildContext context) {
    return _MessageCenterActionButton(
      text: item.buttonText,
      isFilled: item.isFilledButton,
      onTap: item.isReplyAction
          ? () => _showReplySheet(context)
          : null,
    );
  }

  void _showReplySheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    AppReplySheet.show<void>(
      context,
      hintText: l10n.translate('moments_reply_hint'),
      showVoiceButton: false,
      showBottomAccessoryBar: true,
    );
  }
}

class _MessageCenterActionButton extends StatelessWidget {
  final String text;
  final bool isFilled;
  final VoidCallback? onTap;

  const _MessageCenterActionButton({
    required this.text,
    required this.isFilled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 86,
        height: 30,
        decoration: BoxDecoration(
          color: isFilled ? AppColors.grey900 : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: isFilled
              ? null
              : Border.all(
                  color: AppColors.grey200,
                  width: 1.5,
                ),
        ),
        child: Center(
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: isFilled ? Colors.white : AppColors.grey900,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
