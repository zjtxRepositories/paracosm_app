import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import '../../modules/im/manager/im_group_member_manager.dart';

class GroupAvatarWidget extends StatefulWidget {
  final String groupId;
  final String? portraitUri;
  final double size;

  const GroupAvatarWidget({
    super.key,
    required this.groupId,
    this.portraitUri,
    this.size = 44,
  });

  @override
  State<GroupAvatarWidget> createState() => _GroupAvatarWidgetState();
}

class _GroupAvatarWidgetState extends State<GroupAvatarWidget> {
  List<RCIMIWGroupMemberInfo> _memberAvatars = [];
  bool _loading = true;

  String get _groupId => widget.groupId;

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
          (widget.portraitUri ?? '').isNotEmpty;
      if (hasGroupAvatar) {
        setState(() {
          _loading = false;
        });
        return;
      }

      final result =
      await ImGroupMemberManager().getGroupMembers(_groupId);

      final members = result ?? [];

      _memberAvatars = members;
      print('hasGroupAvatar-----$hasGroupAvatar---${widget.portraitUri}--$_memberAvatars');

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
    final groupAvatar = widget.portraitUri;
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
    final members = _memberAvatars.take(9).toList();

    final count = members.length;
    if (count == 0) {
      return _buildEmpty();
    }

    return Container(
      width: widget.size,
      height: widget.size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;

          int crossAxisCount = 3;

          if (count <= 1) {
            crossAxisCount = 1;
          } else if (count <= 4) {
            crossAxisCount = 2;
          } else {
            crossAxisCount = 3;
          }

          final spacing = 1.5;

          final itemSize =
              (maxWidth - spacing * (crossAxisCount - 1)) /
                  crossAxisCount;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            children: _buildChildren(
              members,
              itemSize,
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildChildren(
      List<RCIMIWGroupMemberInfo> members,
      double itemSize,
      ) {
    final count = members.length;

    /// =========================
    /// 微信3人特殊布局
    /// =========================
    if (count == 3) {
      return [
        SizedBox(
          width: itemSize * 2 + 1.5,
          child: Center(
            child: _buildItem(
              members[0],
              itemSize,
            ),
          ),
        ),
        _buildItem(members[1], itemSize),
        _buildItem(members[2], itemSize),
      ];
    }

    return members.map((e) {
      return _buildItem(e, itemSize);
    }).toList();
  }

  Widget _buildEmpty() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.group),
    );
  }

  Widget _buildItem(
      RCIMIWGroupMemberInfo member,
      double size,
      ) {
    return UserAvatarWidget(
      userId: member.userId,
      avatarUrl: member.portraitUri,
      size: size,
      borderRadius: BorderRadius.circular(4),
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