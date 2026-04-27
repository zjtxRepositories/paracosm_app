import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_button.dart';
import 'package:paracosm/widgets/common/app_modal.dart';

/// 群聊详情页面
/// 完全参考 [session_details_page.dart] 进行样式重构
class GroupDetailsPage extends StatefulWidget {
  final String groupName;
  final int memberCount;

  const GroupDetailsPage({
    super.key,
    required this.groupName,
    this.memberCount = 13,
  });

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  bool _isPinned = false;
  bool _isMuted = false;

  /// 测试数据里同时放好友、星标好友和陌生人，方便点头像后验证资料页状态分支。
  final List<Map<String, dynamic>> _members = [
    {
      'name': 'Mari..',
      'avatar': 'assets/images/chat/avatar.png',
      'mode': 'friend',
    },
    {
      'name': 'Jane..',
      'avatar': 'assets/images/chat/avatar.png',
      'mode': 'stranger',
    },
    {
      'name': 'Wad..',
      'avatar': 'assets/images/chat/avatar.png',
      'mode': 'friend',
    },
    {
      'name': 'Broo..',
      'avatar': 'assets/images/chat/avatar.png',
      'mode': 'stranger',
    },
    {
      'name': 'Jenn..',
      'avatar': 'assets/images/chat/avatar.png',
      'mode': 'star',
      'isStar': true,
    },
    {
      'name': 'Guy ..',
      'avatar': 'assets/images/chat/avatar.png',
      'mode': 'friend',
    },
    {
      'name': 'Jaco..',
      'avatar': 'assets/images/chat/avatar.png',
      'mode': 'friend',
    },
    {
      'name': 'Robe..',
      'avatar': 'assets/images/chat/avatar.png',
      'mode': 'stranger',
    },
    {
      'name': 'Darle..',
      'avatar': 'assets/images/chat/avatar.png',
      'mode': 'friend',
    },
    {
      'name': 'Dian..',
      'avatar': 'assets/images/chat/avatar.png',
      'mode': 'friend',
    },
    {
      'name': 'Dian..',
      'avatar': 'assets/images/chat/avatar.png',
      'mode': 'star',
      'isStar': true,
    },
    {
      'name': 'Devo..',
      'avatar': 'assets/images/chat/avatar.png',
      'mode': 'stranger',
    },
    {
      'name': 'Floyd..',
      'avatar': 'assets/images/chat/avatar.png',
      'mode': 'friend',
    },
  ];

  /// 显示清空记录确认弹窗
  void _showClearHistoryModal() {
    AppModal.show(
      context,
      title: AppLocalizations.of(context)!.commonRiskTips,
      description: AppLocalizations.of(context)!.chatSettingClearConfirm,
      confirmText: AppLocalizations.of(context)!.commonConfirm,
      cancelText: AppLocalizations.of(context)!.chatRequestCancel,
      confirmWidth: 161,
      cancelWidth: 161,
      cancelBorder: const BorderSide(color: AppColors.grey300),
      icon: Image.asset(
        'assets/images/wallet/bell-icon.png',
        width: 120,
        height: 120,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            color: AppColors.grey100,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.notifications_active_outlined,
            size: 64,
            color: AppColors.warning,
          ),
        ),
      ),
      onConfirm: () {
        Navigator.pop(context);
        // TODO: 处理清空逻辑
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: AppLocalizations.of(context)!.chatSettingTitle,
      backgroundColor: Colors.white,
      showNavBorder: true,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                _buildMemberGrid(),
                _buildViewMore(),
                const SizedBox(height: 12),
                _buildOptionItem(
                  AppLocalizations.of(context)!.chatSettingGroupInfo,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildGroupAvatars(),
                      const SizedBox(width: 8),
                      Image.asset(
                        'assets/images/common/next.png',
                        width: 20,
                        height: 20,
                      ),
                    ],
                  ),
                  onTap: () {
                    final encodedName = Uri.encodeComponent(widget.groupName);
                    context.push('/group-information/$encodedName');
                  },
                ),
                _buildOptionItem(
                  AppLocalizations.of(context)!.chatSettingIntroduction,
                  subtitle: AppLocalizations.of(context)!.chatSettingIntroEmpty,
                  onTap: () {
                    context.push('/group-introduction');
                  },
                ),
                _buildOptionItem(
                  AppLocalizations.of(context)!.chatSettingNotice,
                  subtitle: AppLocalizations.of(context)!.chatSettingIntroEmpty,
                  isFullBorder: true,
                  onTap: () {},
                ),
                Container(
                  height: 10,
                  decoration: const BoxDecoration(color: AppColors.grey100),
                ),
                _buildOptionItem(
                  AppLocalizations.of(context)!.chatSettingSearchHistory,
                  isFullBorder: true,
                  onTap: () {},
                ),
                Container(
                  height: 10,
                  decoration: const BoxDecoration(color: AppColors.grey100),
                ),
                _buildOptionItem(
                  AppLocalizations.of(context)!.chatSettingPin,
                  trailing: GestureDetector(
                    onTap: () => setState(() => _isPinned = !_isPinned),
                    child: Image.asset(
                      _isPinned
                          ? 'assets/images/common/switch-active.png'
                          : 'assets/images/common/switch-default.png',
                      width: 52,
                      height: 28,
                    ),
                  ),
                ),
                _buildOptionItem(
                  AppLocalizations.of(context)!.chatSettingMuteAll,
                  isFullBorder: true,
                  trailing: GestureDetector(
                    onTap: () => setState(() => _isMuted = !_isMuted),
                    child: Image.asset(
                      _isMuted
                          ? 'assets/images/common/switch-active.png'
                          : 'assets/images/common/switch-default.png',
                      width: 52,
                      height: 28,
                    ),
                  ),
                ),
                Container(
                  height: 10,
                  decoration: const BoxDecoration(color: AppColors.grey100),
                ),
                _buildOptionItem(
                  AppLocalizations.of(context)!.chatSettingDisband,
                  isFullBorder: true,
                  onTap: () {},
                ),
                Container(
                  height: 10,
                  decoration: const BoxDecoration(color: AppColors.grey100),
                ),
                _buildOptionItem(
                  AppLocalizations.of(context)!.chatSettingClearHistory,
                  isFullBorder: true,
                  onTap: _showClearHistoryModal,
                ),
                Container(
                  height: 10,
                  decoration: const BoxDecoration(color: AppColors.grey100),
                ),
                _buildOptionItem(
                  AppLocalizations.of(context)!.sessionDetailsReport,
                  isFullBorder: true,
                  onTap: () {},
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          _buildLeaveButton(),
        ],
      ),
    );
  }

  /// 构建成员网格 (参考 session_details_page.dart 的 Wrap 结构)
  Widget _buildMemberGrid() {
    final visibleMembers = _members
        .take(widget.memberCount.clamp(0, _members.length))
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Wrap(
            spacing: 28,
            runSpacing: 12,
            children: [
              ...visibleMembers.map((member) => _buildMemberItem(member)),
              _buildActionMemberItem('assets/images/common/add-member.png'),
              _buildActionMemberItem('assets/images/common/remove-member.png'),
            ],
          ),
        ],
      ),
    );
  }

  /// 单个成员项 (参考 session_details_page.dart)
  Widget _buildMemberItem(Map<String, dynamic> member) {
    final String name = member['name'] as String? ?? 'User';
    final String avatarPath =
        member['avatar'] as String? ?? 'assets/images/chat/avatar.png';
    final String mode = member['mode'] as String? ?? 'friend';
    final bool isStar = member['isStar'] == true;

    return GestureDetector(
      onTap: () {
        final encodedName = Uri.encodeComponent(name);
        context.push(
          '/user-profile/$encodedName?mode=$mode${isStar ? '&star=1' : ''}',
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: AssetImage(avatarPath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name.length > 5 ? '${name.substring(0, 4)}..' : name,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.grey900,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  /// 添加/删除成员按钮 (参考 session_details_page.dart)
  Widget _buildActionMemberItem(String iconPath) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(iconPath, width: 44, height: 44, color: AppColors.grey900),
        const SizedBox(height: 4),
        const Text('', style: TextStyle(fontSize: 14)),
      ],
    );
  }

  /// 查看更多 (参考 session_details_page.dart 风格适配)
  Widget _buildViewMore() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)!.commonViewMore(2),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.grey400,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Image.asset(
            'assets/images/common/next.png',
            width: 16,
            height: 16,
            color: AppColors.grey400,
          ),
        ],
      ),
    );
  }

  /// 群组头像预览 (适配 session 风格)
  Widget _buildGroupAvatars() {
    return Container(
      width: 36,
      height: 36,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
          4,
          (index) => ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: Image.asset(
              'assets/images/chat/avatar.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  /// 通用选项行 (完全参考 session_details_page.dart 的 Stack 结构)
  Widget _buildOptionItem(
    String title, {
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isFullBorder = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        color: Colors.white,
        child: Stack(
          children: [
            Positioned(
              left: isFullBorder ? 0 : 20,
              right: isFullBorder ? 0 : 20,
              bottom: 0,
              child: Container(height: 0.5, color: AppColors.grey200),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.grey900,
                            fontSize: 14,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.grey400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  trailing ??
                      Image.asset(
                        'assets/images/common/next.png',
                        width: 20,
                        height: 20,
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 退出按钮 (复用 AppButton)
  Widget _buildLeaveButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: AppButton(
        text: AppLocalizations.of(context)!.commonLeave,
        textColor: Colors.white,
        backgroundColor: const Color(0xFFF04438),
        onPressed: () {},
      ),
    );
  }
}
