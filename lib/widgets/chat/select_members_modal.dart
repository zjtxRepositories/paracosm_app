import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/common/app_modal.dart';
import 'package:paracosm/widgets/common/app_search_input.dart';
import 'package:paracosm/widgets/common/app_checkbox.dart';

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
  const SelectMembersModal({super.key});

  /// 显示弹窗的静态方法
  static Future<List<Member>?> show(BuildContext context) {
    return showModalBottomSheet<List<Member>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SelectMembersModal(),
    );
  }

  @override
  State<SelectMembersModal> createState() => _SelectMembersModalState();
}

class _SelectMembersModalState extends State<SelectMembersModal> {
  // 模拟数据
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

  @override
  Widget build(BuildContext context) {
    // 计算列表区域的高度逻辑
    // 如果数据小于 5，则自适应高度；否则设置固定高度或限制最大高度
    const double itemHeight = 72.0;
    final double listHeight = _members.length < 5 
        ? _members.length * itemHeight 
        : 5 * itemHeight;

    return AppModal(
      title: 'Select Members',
      confirmText: 'Create',
      onConfirm: () {
        final selected = _members.where((m) => m.isSelected).toList();
        Navigator.pop(context, selected);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 搜索框
          const AppSearchInput(),
          const SizedBox(height: 12),
          // 成员列表
          SizedBox(
            height: listHeight,
            child: ListView.builder(
              itemCount: _members.length,
              itemExtent: itemHeight,
              itemBuilder: (context, index) {
                final member = _members[index];
                return _buildMemberItem(member, index != _members.length - 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberItem(Member member, bool showDivider) {
    return Container(
      height: 76,
      child: Row(
        children: [
          // 头像
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
          // 名称和地址
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
                  // 标签
                  Text(
                    member.tag,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.grey700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 复选框
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
