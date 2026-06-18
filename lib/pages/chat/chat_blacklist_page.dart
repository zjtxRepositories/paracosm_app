import 'package:flutter/material.dart';
import 'package:paracosm/core/models/user_display_model.dart';
import 'package:paracosm/modules/im/listener/user_display_state_center.dart';
import 'package:paracosm/modules/im/manager/im_friend_manager.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';
import 'package:paracosm/widgets/common/app_empty_view.dart';
import 'package:paracosm/widgets/common/app_toast.dart';

class ChatBlacklistPage extends StatefulWidget {
  const ChatBlacklistPage({super.key});

  @override
  State<ChatBlacklistPage> createState() => _ChatBlacklistPageState();
}

class _ChatBlacklistPageState extends State<ChatBlacklistPage> {
  final List<String> _userIds = [];
  final Set<String> _blacklistedIds = {};
  final Set<String> _switchingIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBlacklist();
  }

  Future<void> _loadBlacklist() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final result = await ImFriendManager().getBlacklist();
      if (!mounted) return;

      if (!result.success) {
        AppToast.show(result.message);
      }

      setState(() {
        _userIds
          ..clear()
          ..addAll(result.data ?? []);
        _blacklistedIds
          ..clear()
          ..addAll(result.data ?? []);
        _loading = false;
      });
    } catch (e) {
      debugPrint('load chat blacklist failed: $e');
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
      AppToast.show(AppLocalizations.of(context)!.chatBlacklistRemoveFailed);
    }
  }

  Future<void> _removeFromBlacklist(String userId) async {
    if (_switchingIds.contains(userId)) return;

    setState(() {
      _switchingIds.add(userId);
    });

    try {
      final result = await ImFriendManager().removeFromBlacklist(userId);
      if (!mounted) return;

      if (result.success) {
        setState(() {
          _switchingIds.remove(userId);
          _blacklistedIds.remove(userId);
        });
        AppToast.showSuccess(
          AppLocalizations.of(context)!.chatBlacklistRemoveSuccess,
        );
        return;
      }

      setState(() {
        _switchingIds.remove(userId);
      });
      AppToast.show(result.message);
    } catch (e) {
      debugPrint('remove from chat blacklist failed: $e');
      if (!mounted) return;

      setState(() {
        _switchingIds.remove(userId);
      });
      AppToast.show(AppLocalizations.of(context)!.chatBlacklistRemoveFailed);
    }
  }

  Future<void> _addToBlacklist(String userId) async {
    if (_switchingIds.contains(userId)) return;

    setState(() {
      _switchingIds.add(userId);
    });

    try {
      final result = await ImFriendManager().addToBlacklist(userId);
      if (!mounted) return;

      if (result.success) {
        setState(() {
          _switchingIds.remove(userId);
          _blacklistedIds.add(userId);
        });
        AppToast.showSuccess(
          AppLocalizations.of(context)!.chatBlacklistAddSuccess,
        );
        return;
      }

      setState(() {
        _switchingIds.remove(userId);
      });
      AppToast.show(result.message);
    } catch (e) {
      debugPrint('add to chat blacklist failed: $e');
      if (!mounted) return;

      setState(() {
        _switchingIds.remove(userId);
      });
      AppToast.show(AppLocalizations.of(context)!.chatBlacklistAddFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppPage(
      title: l10n.chatBlacklist,
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

    if (_userIds.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadBlacklist,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: AppEmptyView(
                text: l10n.chatBlacklistEmpty,
                bottomOffset: 80,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBlacklist,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: _userIds.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, color: AppColors.grey200),
        itemBuilder: (context, index) {
          final userId = _userIds[index];
          return _BlacklistUserItem(
            key: ValueKey(userId),
            userId: userId,
            isBlacklisted: _blacklistedIds.contains(userId),
            isSwitching: _switchingIds.contains(userId),
            onToggle: () {
              if (_blacklistedIds.contains(userId)) {
                _removeFromBlacklist(userId);
                return;
              }
              _addToBlacklist(userId);
            },
          );
        },
      ),
    );
  }
}

class _BlacklistUserItem extends StatelessWidget {
  const _BlacklistUserItem({
    super.key,
    required this.userId,
    required this.isBlacklisted,
    required this.isSwitching,
    required this.onToggle,
  });

  final String userId;
  final bool isBlacklisted;
  final bool isSwitching;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cached = UserDisplayStateCenter().getDisplayModel(userId);

    return FutureBuilder<UserDisplayModel?>(
      future: UserDisplayStateCenter().getUser(userId),
      builder: (context, snapshot) {
        final user = snapshot.data ?? cached;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              UserAvatarWidget(
                userId: userId,
                avatarUrl: user.avatar,
                size: 44,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  user.name.isNotEmpty ? user.name : _shortUserId(userId),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.grey900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _BlacklistActionButton(
                isBlacklisted: isBlacklisted,
                isLoading: isSwitching,
                onTap: onToggle,
              ),
            ],
          ),
        );
      },
    );
  }

  String _shortUserId(String value) {
    if (value.length <= 12) return value;
    return '${value.substring(0, 6)}...${value.substring(value.length - 4)}';
  }
}

class _BlacklistActionButton extends StatelessWidget {
  const _BlacklistActionButton({
    required this.isBlacklisted,
    required this.isLoading,
    required this.onTap,
  });

  final bool isBlacklisted;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isLoading ? null : onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 72),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isBlacklisted ? AppColors.grey900 : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isBlacklisted ? AppColors.grey900 : AppColors.grey300,
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isBlacklisted ? AppColors.white : AppColors.grey900,
                  ),
                )
              : Text(
                  isBlacklisted
                      ? l10n.chatBlacklistRemove
                      : l10n.chatBlacklistAdd,
                  style: AppTextStyles.caption.copyWith(
                    color: isBlacklisted ? AppColors.white : AppColors.grey900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }
}
