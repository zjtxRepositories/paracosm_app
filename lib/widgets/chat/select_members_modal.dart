import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/common/app_checkbox.dart';
import 'package:paracosm/widgets/common/app_modal.dart';
import 'package:paracosm/widgets/common/app_search_input.dart';

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

  const SelectMembersModal({
    super.key,
    this.showTag = true,
    this.confirmText = 'Create',
    this.showSelectedCount = false,
  });

  /// 显示弹窗
  static Future<List<Member>?> show(
    BuildContext context, {
    bool showTag = true,
    String confirmText = 'Create',
    bool showSelectedCount = false,
  }) {
    return showModalBottomSheet<List<Member>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SelectMembersModal(
        showTag: showTag,
        confirmText: confirmText,
        showSelectedCount: showSelectedCount,
      ),
    );
  }

  @override
  State<SelectMembersModal> createState() => _SelectMembersModalState();
}

class _SelectMembersModalState extends State<SelectMembersModal> {
  /// 模拟数据
  final List<Member> _members = [
    Member(
      id: '1',
      name: 'Jesseny',
      address: '0x83644..7ae078a',
      avatar: 'assets/images/chat/avatar.png',
      tag: 'Recent Chat',
      isSelected: true,
    ),
    Member(
      id: '2',
      name: 'Jerome Bell',
      address: '0x83644..7ae078a',
      avatar: 'assets/images/chat/avatar.png',
      tag: 'My Following',
      isSelected: true,
    ),
    Member(
      id: '3',
      name: 'Floyd Miles',
      address: '0x83644..7ae078a',
      avatar: 'assets/images/chat/avatar.png',
      tag: 'My Following',
      isSelected: true,
    ),
    Member(
      id: '4',
      name: 'Theresa Webb',
      address: '0x83644..7ae078a',
      avatar: 'assets/images/chat/avatar.png',
      tag: 'My Following',
    ),
    Member(
      id: '5',
      name: 'Cody Fisher',
      address: '0x83644..7ae078a',
      avatar: 'assets/images/chat/avatar.png',
      tag: 'My Following',
    ),
    Member(
      id: '6',
      name: 'Jacob Jones',
      address: '0x83644..7ae078a',
      avatar: 'assets/images/chat/avatar.png',
      tag: 'My Following',
    ),
  ];

  int get _selectedCount => _members.where((member) => member.isSelected).length;

  List<Member> get _selectedMembers =>
      _members.where((member) => member.isSelected).toList(growable: false);

  @override
  Widget build(BuildContext context) {
    const double itemHeight = 72.0;
    final double listHeight =
        _members.length < 5 ? _members.length * itemHeight : 5 * itemHeight;

    return AppModal(
      title: 'Select Members',
      confirmText: widget.showSelectedCount
          ? '${widget.confirmText} ($_selectedCount)'
          : widget.confirmText,
      onConfirm: () {
        Navigator.pop(context, _selectedMembers);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSearchInput(),
          const SizedBox(height: 12),
          SizedBox(
            height: listHeight,
            child: ListView.builder(
              itemCount: _members.length,
              itemExtent: itemHeight,
              itemBuilder: (context, index) {
                final member = _members[index];
                return _buildMemberItem(
                  member: member,
                  showDivider: index != _members.length - 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberItem({
    required Member member,
    required bool showDivider,
  }) {
    return SizedBox(
      height: 76,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              member.avatar,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
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
                          member.address,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.grey700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.showTag) ...[
                    Text(
                      member.tag,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grey700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  AppCheckbox(
                    value: member.isSelected,
                    onChanged: (val) {
                      setState(() {
                        member.isSelected = val;
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
