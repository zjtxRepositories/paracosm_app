import 'package:flutter/material.dart';
import 'package:paracosm/core/models/friend_model.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/util/string_util.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';
import 'package:paracosm/widgets/common/app_checkbox.dart';
import 'package:paracosm/widgets/common/app_modal.dart';
import 'package:paracosm/widgets/common/app_search_input.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

/// 成员模型
class Member {
  final String id;
  final String name;
  final String address;
  final String avatar;
  final String tag;
  bool isSelected;

  Member({
    required this.id,
    required this.name,
    required this.address,
    required this.avatar,
    required this.tag,
    this.isSelected = false,
  });
}

/// 选择成员弹窗
class SelectMembersModal extends StatefulWidget {
  final bool showTag;
  final String confirmText;
  final bool showSelectedCount;
  final List<RCIMIWFriendInfo>? friends;

  const SelectMembersModal({
    super.key,
    this.showTag = true,
    this.confirmText = 'Create',
    this.showSelectedCount = false,
    this.friends,
  });

  /// 显示弹窗
  static Future<List<String>?> show(
      BuildContext context, {
        bool showTag = true,
        String confirmText = 'Create',
        bool showSelectedCount = false,
        List<RCIMIWFriendInfo>? friends,
  }) {
    return showModalBottomSheet<List<String>>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SelectMembersModal(
        showTag: showTag,
        confirmText: confirmText,
        showSelectedCount: showSelectedCount,
        friends: friends,
      ),
    );
  }

  @override
  State<SelectMembersModal> createState() => _SelectMembersModalState();
}

class _SelectMembersModalState extends State<SelectMembersModal> {

  List<RCIMIWFriendInfo> get _members => widget.friends ?? [];
  final Set<String> _selectedMembers = {};
  late List<RCIMIWFriendInfo> _filterMembers;
  @override
  void initState() {
    super.initState();
    _filterMembers = _members;
  }
  @override
  Widget build(BuildContext context) {
    const double itemHeight = 72.0;
    final double listHeight =
        _members.length < 5 ? _members.length * itemHeight : 5 * itemHeight;

    return AppModal(
      title: 'Select Members',
      confirmText: widget.showSelectedCount
          ? '${widget.confirmText} (${_selectedMembers.length})'
          : widget.confirmText,
      onConfirm: () {
        Navigator.pop(context, _selectedMembers.toList());
        },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSearchInput(
            onChanged: (t) {
              setState(() {
                if (t.isEmpty) {
                  _filterMembers = _members;
                } else {
                  _filterMembers = _members.where((e) {
                    final name = e.name ?? '';
                    final address = e.userId ?? '';

                    final keyword = t.toLowerCase();

                    return name.toLowerCase().contains(keyword) ||
                        address.toLowerCase().contains(keyword);
                  }).toList();
                }
              });
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: listHeight,
            child: Stack(
              children: [
                ListView.builder(
                  itemCount: _filterMembers.length,
                  itemExtent: itemHeight,
                  itemBuilder: (context, index) {
                    final member = _filterMembers[index];
                    return GestureDetector(
                      onTap: (){
                        setState(() {
                          if (_selectedMembers.contains(member.userId)){
                            _selectedMembers.remove(member.userId);
                          }else{
                            _selectedMembers.add(member.userId ?? '');
                          }
                        });
                      },
                      child: _buildMemberItem(
                        friend: member,
                        showDivider: index != _filterMembers.length - 1,
                      ),
                    );
                  },
                ),
                if (_filterMembers.length > 5)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        height: 44,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x00FFFFFF),
                              Color(0xCCFFFFFF),
                              Color(0xFFFFFFFF),
                            ],
                            stops: [
                              0.0,
                              0.78,
                              1.0,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberItem({
    required RCIMIWFriendInfo friend,
    required bool showDivider,
  }) {
    final member = FriendModel(info: friend);
    return SizedBox(
      height: 76,
      child: Row(
        children: [
          UserAvatarWidget(
            userId: member.info.userId,
            avatarUrl: member.info.portrait,
            size: 44,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: showDivider
                    ? const Border(
                        bottom: BorderSide(color: AppColors.grey100, width: 1),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          member.name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey900,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                         ellipsisMiddle( member.info.userId ?? ''),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.grey700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // if (widget.showTag) ...[
                  //   Text(
                  //     member.name,
                  //     style: AppTextStyles.caption.copyWith(
                  //       color: AppColors.grey700,
                  //       fontSize: 12,
                  //     ),
                  //   ),
                  //   const SizedBox(width: 8),
                  // ],
                  AppCheckbox(
                    value: _selectedMembers.contains(member.info.userId),
                    onChanged: (val) {
                      setState(() {
                        if (_selectedMembers.contains(member.info.userId)){
                          _selectedMembers.remove(member.info.userId);
                        }else{
                          _selectedMembers.add(member.info.userId ?? '');
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
