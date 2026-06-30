import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/invite/model/invite_models.dart';
import 'package:paracosm/modules/invite/service/invite_service.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_button.dart';
import 'package:paracosm/widgets/common/app_network_image.dart';
import 'package:paracosm/widgets/common/app_toast.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:screenshot/screenshot.dart';

class InvitePage extends StatefulWidget {
  const InvitePage({super.key, this.inviteCode});

  final String? inviteCode;

  @override
  State<InvitePage> createState() => _InvitePageState();
}

class _InvitePageState extends State<InvitePage> {
  final _service = InviteService();
  final _screenshotController = ScreenshotController();

  InviteProfile? _profile;
  InviteResolveResult? _resolvedInvite;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final routeCode = widget.inviteCode?.trim() ?? '';
      if (routeCode.isNotEmpty) {
        if (AccountManager().isLogin &&
            await _stopIfInviteShouldBeSkipped(routeCode)) {
          final profile = await _service.getProfile();
          if (!mounted) return;
          setState(() {
            _profile = profile;
            _isLoading = false;
          });
          return;
        }

        _resolvedInvite = await _service.captureInviteCode(routeCode);
        if (AccountManager().isLogin) {
          final didBind = await _service.tryBindPendingInviteIfNeeded();
          if (didBind) {
            AppToast.show(AppLocalizations.currentText('invite_bind_success'));
          }
        }
      }
      if (_resolvedInvite != null && !AccountManager().isLogin) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final profile = await _service.getProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<bool> _stopIfInviteShouldBeSkipped(String code) async {
    try {
      final reason = await _service.getInviteSkipReason(code);
      if (reason != InviteSkipReason.none) {
        await _service.clearPendingInvite();
        AppToast.show(_inviteSkipMessage(reason));
        return true;
      }
      return false;
    } catch (_) {
      AppToast.show(AppLocalizations.currentText('invite_load_failed'));
      return true;
    }
  }

  String _inviteSkipMessage(InviteSkipReason reason) {
    return AppLocalizations.currentText(switch (reason) {
      InviteSkipReason.alreadyHasParent => 'invite_already_has_parent',
      InviteSkipReason.selfInviteCode => 'invite_self_code_not_allowed',
      InviteSkipReason.none => 'invite_code_invalid',
    });
  }

  Future<void> _copy(String text, {String? message}) async {
    if (text.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    AppToast.showCopied(message);
  }

  Future<void> _saveQrCard() async {
    final profile = _profile;
    if (profile == null || profile.inviteLink.isEmpty) return;

    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        AppToast.show(AppLocalizations.currentText('common_permission_denied'));
        return;
      }

      final Uint8List? image = await _screenshotController.capture(
        pixelRatio: 3,
      );
      if (image == null) {
        AppToast.show(AppLocalizations.currentText('common_download_failed'));
        return;
      }

      await PhotoManager.editor.saveImage(
        image,
        filename: 'paracosm_invite_${profile.inviteCode}.png',
        title: 'Paracosm Invite',
      );
      AppToast.show(AppLocalizations.currentText('common_saved_to_album'));
    } catch (_) {
      AppToast.show(AppLocalizations.currentText('common_download_failed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      showNav: true,
      title: AppLocalizations.currentText('invite_title'),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/wallet/grid-bg.png',
              fit: BoxFit.cover,
            ),
          ),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _InviteErrorView(onRetry: _load);
    }

    final profile = _profile;
    if (_resolvedInvite != null && !AccountManager().isLogin) {
      return _buildResolvedInvite(_resolvedInvite!);
    }
    if (profile == null) {
      return _InviteErrorView(onRetry: _load);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          children: [
            _buildInviteCard(profile),
            const SizedBox(height: 12),
            _buildActions(profile),
            const SizedBox(height: 12),
            _buildParentCard(profile.parent),
            const SizedBox(height: 12),
            _buildChildrenEntry(profile),
          ],
        ),
      ),
    );
  }

  Widget _buildResolvedInvite(InviteResolveResult invite) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/profile/user/invite.png',
                  width: 76,
                  height: 68,
                ),
                const SizedBox(height: 16),
                Text(
                  invite.isValid
                      ? AppLocalizations.currentText('invite_join_from', {
                          'name': invite.inviterName.isNotEmpty
                              ? invite.inviterName
                              : invite.inviterUserId,
                        })
                      : AppLocalizations.currentText('invite_code_invalid'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h2.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  invite.inviteCode,
                  style: AppTextStyles.h1.copyWith(
                    fontSize: 28,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(
                  text: AppLocalizations.currentText('invite_continue_wallet'),
                  onPressed: () => context.push('/wallet-start'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCard(InviteProfile profile) {
    return Screenshot(
      controller: _screenshotController,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/images/profile/user/invite.png',
                  width: 64,
                  height: 56,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.currentText('invite_title'),
                        style: AppTextStyles.h2.copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.currentText('invite_subtitle'),
                        style: AppTextStyles.body.copyWith(
                          fontSize: 12,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    AppLocalizations.currentText('invite_my_code'),
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.grey500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    profile.inviteCode.isEmpty ? '--' : profile.inviteCode,
                    style: AppTextStyles.h1.copyWith(
                      fontSize: 28,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 208,
              height: 208,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.grey200),
              ),
              child: profile.inviteLink.isEmpty
                  ? const SizedBox()
                  : PrettyQrView.data(
                      data: profile.inviteLink,
                      decoration: const PrettyQrDecoration(
                        shape: PrettyQrSmoothSymbol(),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.currentText('invite_children_count', {
                'count': profile.childrenCount,
              }),
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 14,
                color: AppColors.grey800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(InviteProfile profile) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          _InviteAction(
            icon: Icons.confirmation_number_outlined,
            label: AppLocalizations.currentText('invite_copy_code'),
            onTap: () => _copy(profile.inviteCode),
          ),
          _InviteAction(
            icon: Icons.link,
            label: AppLocalizations.currentText('invite_copy_link'),
            onTap: () => _copy(
              profile.inviteLink,
              message: AppLocalizations.currentText(
                'profile_invite_link_copied',
              ),
            ),
          ),
          _InviteAction(
            icon: Icons.download_outlined,
            label: AppLocalizations.currentText('invite_save_qr'),
            onTap: _saveQrCard,
          ),
          _InviteAction(
            icon: Icons.ios_share,
            label: AppLocalizations.currentText('invite_share'),
            onTap: () => _copy(
              profile.inviteLink,
              message: AppLocalizations.currentText('invite_share_link_copied'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentCard(InviteUser? parent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.currentText('invite_parent_title'),
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 16,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 12),
          if (parent == null)
            Text(
              AppLocalizations.currentText('invite_no_parent'),
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                color: AppColors.grey500,
              ),
            )
          else
            Row(
              children: [
                AppNetworkImage(
                  url: parent.avatar,
                  width: 44,
                  height: 44,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parent.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        parent.boundAt,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.grey400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildChildrenEntry(InviteProfile profile) {
    return AppButton(
      text: AppLocalizations.currentText('invite_view_children'),
      onPressed: () => context.push('/invite-children'),
      backgroundColor: AppColors.grey900,
      textColor: AppColors.white,
    );
  }
}

class _InviteAction extends StatelessWidget {
  const _InviteAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: AppColors.grey900),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: AppColors.grey700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteErrorView extends StatelessWidget {
  const _InviteErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.currentText('invite_load_failed'),
              style: AppTextStyles.bodyMedium.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 16),
            AppButton(
              text: AppLocalizations.currentText('common_retry'),
              onPressed: onRetry,
              width: 140,
              height: 44,
              fontSize: 14,
            ),
          ],
        ),
      ),
    );
  }
}
