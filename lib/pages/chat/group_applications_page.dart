import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/modules/im/listener/group_state_center.dart';
import 'package:paracosm/modules/im/listener/user_display_state_center.dart';
import 'package:paracosm/modules/im/manager/im_group_applications_manager.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';
import 'package:paracosm/widgets/common/app_empty_view.dart';
import 'package:paracosm/widgets/common/app_loading.dart';
import 'package:paracosm/widgets/common/app_modal.dart';
import 'package:paracosm/widgets/common/app_toast.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

class GroupApplicationsPage extends StatefulWidget {
  const GroupApplicationsPage({super.key});

  @override
  State<GroupApplicationsPage> createState() => _GroupApplicationsPageState();
}

class _GroupApplicationsPageState extends State<GroupApplicationsPage> {
  final _manager = ImGroupApplicationsManager();
  StreamSubscription<List<RCIMIWGroupApplicationInfo>>? _sub;

  List<RCIMIWGroupApplicationInfo> _joinUnhandled = [];
  List<RCIMIWGroupApplicationInfo> _joinProcessed = [];
  List<RCIMIWGroupApplicationInfo> _inviteUnhandled = [];
  List<RCIMIWGroupApplicationInfo> _inviteProcessed = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _sub = _manager.stream.listen(_splitList);
    _fetch();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      await _manager.fetch(
        directions: const [
          RCIMIWGroupApplicationDirection.applicationreceived,
          RCIMIWGroupApplicationDirection.invitationreceived,
        ],
        statuses: const [
          RCIMIWGroupApplicationStatus.managerunhandled,
          RCIMIWGroupApplicationStatus.managerrefused,
          RCIMIWGroupApplicationStatus.inviteeunhandled,
          RCIMIWGroupApplicationStatus.inviteerefused,
          RCIMIWGroupApplicationStatus.joined,
          RCIMIWGroupApplicationStatus.expired,
        ],
      );
    } catch (e) {
      if (mounted) {
        AppToast.show(AppLocalizations.of(context)!.chatRequestFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _splitList(List<RCIMIWGroupApplicationInfo> list) {
    final joinUnhandled = <RCIMIWGroupApplicationInfo>[];
    final joinProcessed = <RCIMIWGroupApplicationInfo>[];
    final inviteUnhandled = <RCIMIWGroupApplicationInfo>[];
    final inviteProcessed = <RCIMIWGroupApplicationInfo>[];

    for (final item in list) {
      if (item.direction ==
          RCIMIWGroupApplicationDirection.applicationreceived) {
        if (item.status == RCIMIWGroupApplicationStatus.managerunhandled) {
          joinUnhandled.add(item);
        } else {
          joinProcessed.add(item);
        }
      } else if (item.direction ==
          RCIMIWGroupApplicationDirection.invitationreceived) {
        if (item.status == RCIMIWGroupApplicationStatus.inviteeunhandled) {
          inviteUnhandled.add(item);
        } else {
          inviteProcessed.add(item);
        }
      }
    }

    _prefetchUsers(list);
    _prefetchGroups(list);
    if (!mounted) return;
    setState(() {
      _joinUnhandled = joinUnhandled;
      _joinProcessed = joinProcessed;
      _inviteUnhandled = inviteUnhandled;
      _inviteProcessed = inviteProcessed;
    });
  }

  void _prefetchUsers(List<RCIMIWGroupApplicationInfo> list) {
    final userIds = <String>{};
    for (final item in list) {
      final applicantId = item.joinMemberInfo?.userId;
      final inviterId = item.inviterInfo?.userId;
      if (applicantId != null && applicantId.isNotEmpty) {
        userIds.add(applicantId);
      }
      if (inviterId != null && inviterId.isNotEmpty) {
        userIds.add(inviterId);
      }
    }
    for (final userId in userIds) {
      unawaited(
        UserDisplayStateCenter().getUser(userId).then((_) {
          if (mounted) setState(() {});
        }),
      );
    }
  }

  void _prefetchGroups(List<RCIMIWGroupApplicationInfo> list) {
    final groupIds = <String>{};
    for (final item in list) {
      final groupId = item.groupId;
      if (groupId != null && groupId.isNotEmpty) {
        groupIds.add(groupId);
      }
    }
    for (final groupId in groupIds) {
      unawaited(
        GroupStateCenter().getGroup(groupId, forceRefresh: true).then((_) {
          if (mounted) setState(() {});
        }),
      );
    }
  }

  Future<void> _acceptApplication(RCIMIWGroupApplicationInfo item) async {
    final groupId = item.groupId ?? '';
    final applicantId = item.joinMemberInfo?.userId ?? '';
    final inviterId = item.inviterInfo?.userId ?? '';
    if (groupId.isEmpty || applicantId.isEmpty) return;

    AppLoading.show();
    final result = await _manager.acceptGroupApplication(
      groupId: groupId,
      inviterId: inviterId,
      applicantId: applicantId,
    );
    AppLoading.dismiss();
    if (!mounted) return;
    if (result.status == GroupApplicationActionStatus.waitingInviteeConfirm) {
      AppToast.show(
        AppLocalizations.of(context)!.chatGroupApplicationWaitInvitee,
      );
      return;
    }
    if (!result.isSuccess) {
      AppToast.show(AppLocalizations.of(context)!.chatRequestFailed);
    }
  }

  Future<void> _acceptInvite(RCIMIWGroupApplicationInfo item) async {
    final groupId = item.groupId ?? '';
    final inviterId = item.inviterInfo?.userId ?? '';
    if (groupId.isEmpty || inviterId.isEmpty) return;

    AppLoading.show();
    final isOk = await _manager.acceptGroupInvite(
      groupId: groupId,
      inviterId: inviterId,
    );
    AppLoading.dismiss();
    if (!mounted) return;
    if (!isOk) {
      AppToast.show(AppLocalizations.of(context)!.chatRequestFailed);
    }
  }

  void _showRejectModal(RCIMIWGroupApplicationInfo item) {
    AppModal.show(
      context,
      title: AppLocalizations.of(context)!.chatRequestHint,
      description: AppLocalizations.of(context)!.chatRequestRejectConfirm,
      confirmText: AppLocalizations.of(context)!.chatRequestSure,
      cancelText: AppLocalizations.of(context)!.chatRequestCancel,
      confirmWidth: 161,
      cancelWidth: 161,
      cancelBorder: const BorderSide(color: AppColors.grey300),
      icon: Image.asset(
        'assets/images/wallet/bell-icon.png',
        width: 120,
        height: 120,
        fit: BoxFit.contain,
      ),
      onConfirm: () async {
        context.pop();
        final isInvite =
            item.direction ==
            RCIMIWGroupApplicationDirection.invitationreceived;
        final groupId = item.groupId ?? '';
        final inviterId = item.inviterInfo?.userId ?? '';
        final applicantId = item.joinMemberInfo?.userId ?? '';
        if (groupId.isEmpty) return;

        AppLoading.show();
        final isOk = isInvite
            ? await _manager.refuseGroupInvite(
                groupId: groupId,
                inviterId: inviterId,
              )
            : await _manager.refuseGroupApplication(
                groupId: groupId,
                inviterId: inviterId,
                applicantId: applicantId,
              );
        AppLoading.dismiss();
        if (!mounted) return;
        if (!isOk) {
          AppToast.show(AppLocalizations.of(context)!.chatRequestFailed);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final empty =
        !_loading &&
        _joinUnhandled.isEmpty &&
        _joinProcessed.isEmpty &&
        _inviteUnhandled.isEmpty &&
        _inviteProcessed.isEmpty;

    return AppPage(
      title: l10n.chatGroupApplications,
      showNavBorder: true,
      backgroundColor: Colors.white,
      child: RefreshIndicator(
        onRefresh: _fetch,
        child: empty
            ? ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  AppEmptyView(text: l10n.chatGroupApplicationEmpty),
                ],
              )
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 16),
                  _buildGroup(
                    l10n.chatGroupJoinApplications,
                    _joinUnhandled,
                    _joinProcessed,
                    isInvite: false,
                  ),
                  _buildGroup(
                    l10n.chatGroupInviteConfirmations,
                    _inviteUnhandled,
                    _inviteProcessed,
                    isInvite: true,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
      ),
    );
  }

  Widget _buildGroup(
    String title,
    List<RCIMIWGroupApplicationInfo> unhandled,
    List<RCIMIWGroupApplicationInfo> processed, {
    required bool isInvite,
  }) {
    if (unhandled.isEmpty && processed.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        if (unhandled.isNotEmpty) ...[
          _buildSubTitle(AppLocalizations.of(context)!.chatRequestNew),
          ...unhandled.map((item) => _buildItem(item, isInvite: isInvite)),
          const SizedBox(height: 16),
        ],
        if (processed.isNotEmpty) ...[
          _buildSubTitle(AppLocalizations.of(context)!.chatRequestProcessed),
          ...processed.map((item) => _buildProcessedItem(item)),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: AppTextStyles.body.copyWith(
          color: AppColors.grey900,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSubTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.grey400,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildItem(RCIMIWGroupApplicationInfo item, {required bool isInvite}) {
    final member = item.joinMemberInfo;
    final userId = member?.userId ?? '';
    final avatar = _avatar(userId, member?.portraitUri);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          UserAvatarWidget(
            userId: userId,
            avatarUrl: avatar,
            size: 44,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(bottom: 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.grey100, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildInfo(item)),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _showRejectModal(item),
                    child: Image.asset(
                      'assets/images/chat/refuse.png',
                      width: 40,
                      height: 26,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => isInvite
                        ? _acceptInvite(item)
                        : _acceptApplication(item),
                    child: Image.asset(
                      'assets/images/chat/agree.png',
                      width: 40,
                      height: 26,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessedItem(RCIMIWGroupApplicationInfo item) {
    final member = item.joinMemberInfo;
    final userId = member?.userId ?? '';
    final avatar = _avatar(userId, member?.portraitUri);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          UserAvatarWidget(
            userId: userId,
            avatarUrl: avatar,
            size: 44,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(bottom: 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.grey100, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildInfo(item)),
                  const SizedBox(width: 8),
                  Text(
                    _statusText(item.status),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.grey400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo(RCIMIWGroupApplicationInfo item) {
    final member = item.joinMemberInfo;
    final userId = member?.userId ?? '';
    final name = _name(userId, fallback: member?.nickname ?? member?.name);
    final groupName = _groupName(item.groupId ?? '');
    final groupText = groupName.isEmpty
        ? ''
        : '${AppLocalizations.of(context)!.chatGroup}：$groupName';
    final timeText = _formatTime(item.operationTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: AppTextStyles.body.copyWith(
            color: AppColors.grey900,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (groupText.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            groupText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.grey400,
              fontSize: 12,
            ),
          ),
        ],
        if (timeText.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            timeText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.grey400,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  String _name(String userId, {String? fallback}) {
    final display = UserDisplayStateCenter().getDisplayModel(userId);
    final name = display.name;
    if (name.isNotEmpty && name != userId) return name;
    final fallbackName = fallback?.trim() ?? '';
    if (fallbackName.isNotEmpty) return fallbackName;
    if (userId.length > 8) return userId.substring(userId.length - 8);
    return userId;
  }

  String _avatar(String userId, String? fallback) {
    final display = UserDisplayStateCenter().getDisplayModel(userId);
    if (display.avatar.isNotEmpty) return display.avatar;
    return fallback ?? '';
  }

  String _groupName(String groupId) {
    if (groupId.isEmpty) return '';
    final group = GroupStateCenter().getCachedGroup(groupId);
    final name = group?.groupName?.trim() ?? '';
    if (name.isNotEmpty) return name;
    if (groupId.length > 8) return groupId.substring(groupId.length - 8);
    return groupId;
  }

  String _statusText(RCIMIWGroupApplicationStatus? status) {
    final l10n = AppLocalizations.of(context)!;
    return switch (status) {
      RCIMIWGroupApplicationStatus.managerunhandled => l10n.chatRequestNew,
      RCIMIWGroupApplicationStatus.inviteeunhandled =>
        l10n.chatGroupApplicationWaitInvitee,
      RCIMIWGroupApplicationStatus.managerrefused ||
      RCIMIWGroupApplicationStatus.inviteerefused =>
        l10n.chatRequestStatusRejected,
      RCIMIWGroupApplicationStatus.joined => l10n.chatRequestStatusAdded,
      RCIMIWGroupApplicationStatus.expired => l10n.chatRequestStatusExpired,
      null => '',
    };
  }

  String _formatTime(int? time) {
    if (time == null || time <= 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(time);
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$month-$day $hour:$minute';
  }
}
