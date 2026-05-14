import 'dart:async';

import 'package:flutter/material.dart';
import 'package:paracosm/modules/im/listener/group_state_center.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../modules/im/listener/im_data_center.dart';
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
  State<GroupAvatarWidget> createState() =>
      _GroupAvatarWidgetState();
}

class _GroupAvatarWidgetState extends State<GroupAvatarWidget> {
  List<RCIMIWGroupMemberInfo> _memberAvatars = [];

  bool _loading = true;
  StreamSubscription? _sub;


  String get _groupId => widget.groupId;

  @override
  void initState() {
    super.initState();
    final groupAvatar = widget.portraitUri;

    /// =========================
    /// 有群头像直接显示
    /// =========================
    if (groupAvatar != null && groupAvatar.isNotEmpty) {
      _loading = false;
      return;
    }

    /// 监听群成员变化
    _sub = ImDataCenter().groupInfoStream.listen((groupIds) {
      if (!mounted) return;

      if (groupIds.contains(_groupId)) {
        final list = ImDataCenter().getGroupMembers(
          _groupId,
        );

        setState(() {
          _memberAvatars = list;
          _loading = false;
        });
      }
    });

    /// 拉取成员
    /// =========================
    _loadMembers();
  }
  /// 拉取成员
  Future<void> _loadMembers() async {
    try {
      final members = await GroupStateCenter().getGroupMembers(
        _groupId,
      );
      if (!mounted) return;

      setState(() {
        _memberAvatars = members;
        _loading = false;
      });
    } catch (e) {
      debugPrint(
        'GroupAvatarWidget error: $e',
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupAvatar = widget.portraitUri;

    /// =========================
    /// 群头像优先
    /// =========================
    if (groupAvatar != null && groupAvatar.isNotEmpty) {
      return _buildSingle(groupAvatar);
    }

    /// =========================
    /// loading
    /// =========================
    if (_loading) {
      return _buildLoading();
    }

    /// =========================
    /// 拼图头像
    /// =========================
    return _buildGrid();
  }

  /// =========================
  /// 单头像
  /// =========================
  Widget _buildSingle(String url) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius:
        BorderRadius.circular(10),
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// =========================
  /// 拼图头像
  /// =========================
  Widget _buildGrid() {
    final members =
    _memberAvatars.take(9).toList();

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
        borderRadius:
        BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (
            context,
            constraints,
            ) {
          final maxWidth =
              constraints.maxWidth;

          int crossAxisCount = 3;

          if (count <= 1) {
            crossAxisCount = 1;
          } else if (count <= 4) {
            crossAxisCount = 2;
          }

          const spacing = 1.5;

          final itemSize =
              (maxWidth -
                  spacing *
                      (crossAxisCount -
                          1)) /
                  crossAxisCount;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            alignment:
            WrapAlignment.center,
            runAlignment:
            WrapAlignment.center,
            children: _buildChildren(
              members,
              itemSize,
            ),
          );
        },
      ),
    );
  }

  /// =========================
  /// 子布局
  /// =========================
  List<Widget> _buildChildren(
      List<RCIMIWGroupMemberInfo>
      members,
      double itemSize,
      ) {
    /// 微信 3 人布局
    if (members.length == 3) {
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
        _buildItem(
          members[1],
          itemSize,
        ),
        _buildItem(
          members[2],
          itemSize,
        ),
      ];
    }

    return members
        .map(
          (e) => _buildItem(
        e,
        itemSize,
      ),
    )
        .toList();
  }

  /// =========================
  /// 单个成员
  /// =========================
  Widget _buildItem(
      RCIMIWGroupMemberInfo member,
      double size,
      ) {
    return UserAvatarWidget(
      userId: member.userId,
      avatarUrl: member.portraitUri,
      size: size,
      borderRadius:
      BorderRadius.circular(4),
    );
  }

  /// =========================
  /// empty
  /// =========================
  Widget _buildEmpty() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius:
        BorderRadius.circular(10),
      ),
      child: const Icon(Icons.group),
    );
  }

  /// =========================
  /// loading
  /// =========================
  Widget _buildLoading() {
    return Container(
      width: widget.size,
      height: widget.size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius:
        BorderRadius.circular(10),
      ),
      child: const SizedBox(
        width: 12,
        height: 12,
        child:
        CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }
}