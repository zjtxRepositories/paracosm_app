import 'package:flutter/material.dart';
import 'package:paracosm/core/models/friend_model.dart';
import 'package:paracosm/core/models/group_model.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/chat/group_avatar_widget.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';
import 'package:paracosm/widgets/common/app_checkbox.dart';
import 'package:paracosm/widgets/common/app_empty_view.dart';
import 'package:paracosm/widgets/common/app_modal.dart';
import 'package:paracosm/widgets/common/app_search_input.dart';
import 'package:paracosm/widgets/common/app_toast.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

class ChatForwardTarget {
  const ChatForwardTarget({
    required this.targetId,
    required this.conversationType,
    required this.name,
    this.avatar,
    this.channelId,
  });

  final String targetId;
  final RCIMIWConversationType conversationType;
  final String name;
  final String? avatar;
  final String? channelId;

  bool get isGroup => conversationType == RCIMIWConversationType.group;
}

class ChatForwardTargetModal extends StatefulWidget {
  const ChatForwardTargetModal({
    super.key,
    required this.friends,
    required this.groups,
  });

  final List<RCIMIWFriendInfo> friends;
  final List<RCIMIWGroupInfo> groups;

  static Future<List<ChatForwardTarget>?> show(
    BuildContext context, {
    required List<RCIMIWFriendInfo> friends,
    required List<RCIMIWGroupInfo> groups,
  }) {
    return showModalBottomSheet<List<ChatForwardTarget>>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          ChatForwardTargetModal(friends: friends, groups: groups),
    );
  }

  @override
  State<ChatForwardTargetModal> createState() => _ChatForwardTargetModalState();
}

class _ChatForwardTargetModalState extends State<ChatForwardTargetModal> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedKeys = {};
  List<ChatForwardTarget> _targets = [];
  List<ChatForwardTarget> _filteredTargets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTargets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTargets() async {
    final targets = <ChatForwardTarget>[];

    for (final friend in widget.friends) {
      final userId = friend.userId;
      if (userId == null || userId.isEmpty) {
        continue;
      }

      final model = FriendModel(info: friend);
      targets.add(
        ChatForwardTarget(
          targetId: userId,
          conversationType: RCIMIWConversationType.private,
          name: model.name,
          avatar: friend.portrait,
        ),
      );
    }

    for (final group in widget.groups) {
      final groupId = group.groupId;
      if (groupId == null || groupId.isEmpty) {
        continue;
      }

      final model = GroupModel(info: group);
      final name = await model.name;
      targets.add(
        ChatForwardTarget(
          targetId: groupId,
          conversationType: RCIMIWConversationType.group,
          name: name.isNotEmpty ? name : groupId,
          avatar: group.portraitUri,
        ),
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _targets = targets;
      _filteredTargets = targets;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      title: '选择转发对象',
      confirmText: '转发 (${_selectedKeys.length})',
      cancelText: '取消',
      cancelBorder: const BorderSide(color: AppColors.grey300),
      onConfirm: _confirm,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSearchInput(
            controller: _searchController,
            hintText: '搜索好友或群聊',
            onChanged: _filter,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.46,
            child: _buildTargetList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredTargets.isEmpty) {
      return const AppEmptyView(text: '暂无可转发对象');
    }

    return ListView.builder(
      itemCount: _filteredTargets.length,
      itemBuilder: (context, index) {
        final target = _filteredTargets[index];
        final selected = _selectedKeys.contains(_targetKey(target));

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _toggleTarget(target),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              border: index == _filteredTargets.length - 1
                  ? null
                  : const Border(
                      bottom: BorderSide(color: AppColors.grey100, width: 1),
                    ),
            ),
            child: Row(
              children: [
                _buildAvatar(target),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        target.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.grey900,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        target.isGroup ? '群聊' : '好友',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.grey400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                AppCheckbox(value: selected),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(ChatForwardTarget target) {
    if (target.isGroup) {
      return GroupAvatarWidget(
        groupId: target.targetId,
        portraitUri: target.avatar,
        size: 44,
      );
    }

    return UserAvatarWidget(
      userId: target.targetId,
      avatarUrl: target.avatar,
      size: 44,
      borderRadius: BorderRadius.circular(10),
    );
  }

  void _filter(String keyword) {
    final query = keyword.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredTargets = _targets;
      } else {
        _filteredTargets = _targets
            .where(
              (target) =>
                  target.name.toLowerCase().contains(query) ||
                  target.targetId.toLowerCase().contains(query),
            )
            .toList();
      }
    });
  }

  void _toggleTarget(ChatForwardTarget target) {
    final key = _targetKey(target);

    setState(() {
      if (_selectedKeys.contains(key)) {
        _selectedKeys.remove(key);
      } else {
        _selectedKeys.add(key);
      }
    });
  }

  void _confirm() {
    if (_selectedKeys.isEmpty) {
      AppToast.show('请选择转发对象');
      return;
    }

    final selected = _targets
        .where((target) => _selectedKeys.contains(_targetKey(target)))
        .toList();

    Navigator.pop(context, selected);
  }

  String _targetKey(ChatForwardTarget target) {
    return '${target.conversationType.index}:${target.targetId}:${target.channelId ?? ''}';
  }
}
