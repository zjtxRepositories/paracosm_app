import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../modules/im/manager/im_group_member_manager.dart';

class GroupAvatarWidget extends StatefulWidget {
  final RCIMIWGroupInfo group;
  final double size;

  const GroupAvatarWidget({
    super.key,
    required this.group,
    this.size = 44,
  });

  @override
  State<GroupAvatarWidget> createState() => _GroupAvatarWidgetState();
}

class _GroupAvatarWidgetState extends State<GroupAvatarWidget> {
  List<String> _memberAvatars = [];
  bool _loading = true;

  String get _groupId => widget.group.groupId ?? '';

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  /// =========================
  /// 拉取群成员头像
  /// =========================
  Future<void> _loadMembers() async {
    try {
      /// ⚠️ 只有没有群头像才拉成员
      final hasGroupAvatar =
          (widget.group.portraitUri ?? '').isNotEmpty;

      if (hasGroupAvatar) {
        setState(() {
          _loading = false;
        });
        return;
      }

      final result =
      await ImGroupMemberManager().getGroupMembers(_groupId);

      final members = result ?? [];

      _memberAvatars = members
          .map((e) => e.portraitUri ?? '')
          .where((e) => e.isNotEmpty)
          .toList();

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      print('❌ GroupAvatarWidget error: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildLoading();
    }

    /// =========================
    /// 1. 群头像优先
    /// =========================
    final groupAvatar = widget.group.portraitUri;
    if (groupAvatar != null && groupAvatar.isNotEmpty) {
      return _buildSingle(groupAvatar);
    }

    /// =========================
    /// 2. 成员拼图头像
    /// =========================
    return _buildGrid();
  }

  /// 单头像
  Widget _buildSingle(String url) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// 3x3成员头像（最多9个）
  Widget _buildGrid() {
    final avatars = _memberAvatars.take(9).toList();

    return Container(
      width: widget.size,
      height: widget.size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: GridView.builder(
        itemCount: avatars.length,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
        ),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Image.network(
              avatars[index],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: Colors.grey[300]),
            ),
          );
        },
      ),
    );
  }

  /// loading
  Widget _buildLoading() {
    return Container(
      width: widget.size,
      height: widget.size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}