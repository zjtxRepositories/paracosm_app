import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../common/app_modal.dart';
import '../common/app_toast.dart';

/// =========================
/// Share Modals
/// =========================
class ShareModals {
  static Future<void> show(
      BuildContext context, {
        List<ShareContactData>? contacts,
        List<ShareActionData>? actions,
      }) {
    return AppModal.show(
      context,
      title: '分享',
      confirmText: null,
      onConfirm: () {},
      child: _ShareModalContent(
        contacts: contacts,
        actions: actions,
      ),
    );
  }
}

/// =========================
/// Content
/// =========================
class _ShareModalContent extends StatelessWidget {
  final List<ShareContactData>? contacts;
  final List<ShareActionData>? actions;

  const _ShareModalContent({
    this.contacts,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final shareContacts = contacts ??
        const [
          ShareContactData(name: 'Kristen', avatar: 'assets/images/chat/avatar.png'),
          ShareContactData(name: 'Kristen', avatar: 'assets/images/chat/avatar.png'),
          ShareContactData(name: 'Kristen', avatar: 'assets/images/chat/avatar.png'),
        ];

    final shareActions = actions ??
        [
          const ShareActionData(icon: 'assets/images/moments/friends.png', label: 'Friends'),
          const ShareActionData(icon: 'assets/images/moments/save.png', label: 'Save'),
          ShareActionData(
            icon: 'assets/images/moments/link.png',
            label: 'Copy link',
            onTap: AppToast.showCopied,
          ),
        ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// 联系人横向列表
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: shareContacts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 20),
                itemBuilder: (_, i) {
                  return _ShareContactItem(contact: shareContacts[i]);
                },
              ),
            ),

            const SizedBox(height: 16),

            /// 分割线
            Container(height: 1, color: AppColors.grey100),

            const SizedBox(height: 16),

            /// 操作区
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: shareActions
                  .map((e) => _ShareActionItem(action: e))
                  .toList(),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// =========================
/// Data Models
/// =========================

class ShareContactData {
  final String name;
  final String avatar;

  const ShareContactData({
    required this.name,
    required this.avatar,
  });
}

class ShareActionData {
  final String icon;
  final String label;
  final VoidCallback? onTap;

  const ShareActionData({
    required this.icon,
    required this.label,
    this.onTap,
  });
}

/// =========================
/// Contact Item
/// =========================
class _ShareContactItem extends StatelessWidget {
  final ShareContactData contact;

  const _ShareContactItem({required this.contact});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              contact.avatar,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            contact.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              fontSize: 12,
              color: AppColors.grey900,
            ),
          ),
        ],
      ),
    );
  }
}

/// =========================
/// Action Item
/// =========================
class _ShareActionItem extends StatelessWidget {
  final ShareActionData action;

  const _ShareActionItem({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: action.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              action.icon,
              width: 20,
              height: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            action.label,
            style: AppTextStyles.body.copyWith(
              fontSize: 12,
              color: AppColors.grey800,
            ),
          ),
        ],
      ),
    );
  }
}