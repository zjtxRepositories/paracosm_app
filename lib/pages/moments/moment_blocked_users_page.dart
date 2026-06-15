import 'package:flutter/material.dart';
import 'package:paracosm/core/models/social_circle_blocked_user_model.dart';
import 'package:paracosm/core/network/api/social_circle_user_api.dart';
import 'package:paracosm/modules/im/listener/user_display_state_center.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/util/string_util.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';
import 'package:paracosm/widgets/common/app_empty_view.dart';
import 'package:paracosm/widgets/common/app_loading.dart';
import 'package:paracosm/widgets/common/app_toast.dart';

class MomentBlockedUsersPage extends StatefulWidget {
  const MomentBlockedUsersPage({super.key});

  @override
  State<MomentBlockedUsersPage> createState() => _MomentBlockedUsersPageState();
}

class _MomentBlockedUsersPageState extends State<MomentBlockedUsersPage> {
  final List<SocialCircleBlockedUserModel> _items = [];
  bool _loading = true;
  final Set<String> _unblockingIds = {};

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() {
      _loading = true;
    });

    try {
      final records =
          await SocialCircleUserApi.getSocialCircleUserBlockRecords();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(records);
        _loading = false;
      });
    } catch (e) {
      debugPrint('load blocked users failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _unblock(SocialCircleBlockedUserModel item) async {
    if (_unblockingIds.contains(item.blockUserId)) return;

    setState(() {
      _unblockingIds.add(item.blockUserId);
    });

    var success = false;
    try {
      AppLoading.show();
      success = await SocialCircleUserApi.socialCircleUserBlockToggle(
        item.blockUserId,
        false,
      );
    } catch (e) {
      debugPrint('unblock moment user failed: $e');
    } finally {
      AppLoading.dismiss();
    }

    if (!mounted) return;

    setState(() {
      _unblockingIds.remove(item.blockUserId);
      if (success) {
        _items.removeWhere((e) => e.blockUserId == item.blockUserId);
      }
    });

    if (!success) {
      AppToast.show(
        AppLocalizations.of(context)!.translate('moments_unblock_failed'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppPage(
      title: l10n.translate('moments_my_blocked'),
      backgroundColor: AppColors.white,
      navBackgroundColor: AppColors.white,
      showNavBorder: true,
      child: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return AppEmptyView(
        text: l10n.translate('moments_no_blocked_users'),
        bottomOffset: 80,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBlockedUsers,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: _items.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, color: AppColors.grey200),
        itemBuilder: (context, index) {
          final item = _items[index];
          return _BlockedUserListItem(
            item: item,
            isLoading: _unblockingIds.contains(item.blockUserId),
            onUnblock: () => _unblock(item),
          );
        },
      ),
    );
  }
}

class _BlockedUserListItem extends StatelessWidget {
  final SocialCircleBlockedUserModel item;
  final bool isLoading;
  final VoidCallback onUnblock;

  const _BlockedUserListItem({
    required this.item,
    required this.isLoading,
    required this.onUnblock,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = UserDisplayStateCenter().getDisplayModel(item.blockUserId);
    final displayName = user.name.isNotEmpty
        ? user.name
        : _shortAddress(item.blockUserId);

    return FutureBuilder(
      future: UserDisplayStateCenter().getUser(item.blockUserId),
      builder: (context, snapshot) {
        final resolved = snapshot.data ?? user;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              UserAvatarWidget(
                userId: item.blockUserId,
                avatarUrl: resolved.avatar,
                size: 44,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resolved.name.isNotEmpty ? resolved.name : displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatIMTime(item.timestamp),
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 11,
                        color: AppColors.grey400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _UnblockButton(
                label: l10n.translate('moments_unblock'),
                isLoading: isLoading,
                onTap: onUnblock,
              ),
            ],
          ),
        );
      },
    );
  }

  String _shortAddress(String value) {
    if (value.length <= 12) return value;
    return '${value.substring(0, 6)}...${value.substring(value.length - 4)}';
  }
}

class _UnblockButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const _UnblockButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isLoading ? null : onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 76),
        child: Container(
          height: 32,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.grey900,
            borderRadius: BorderRadius.circular(16),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
              : Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }
}
