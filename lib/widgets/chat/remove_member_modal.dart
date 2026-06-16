import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/util/string_util.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/common/app_checkbox.dart';
import 'package:paracosm/widgets/common/app_modal.dart';
import 'package:paracosm/widgets/common/app_search_input.dart';

import '../../core/models/group_member_model.dart';

/// 选择成员弹窗
class RemoveMemberModal extends StatefulWidget {
  final List<GroupMemberModel>? members;
  final String? title;
  final List<String>? defaultSelectedUserIds;
  final bool singleSelection;

  const RemoveMemberModal({
    super.key,
    this.members,
    this.title,
    this.defaultSelectedUserIds,
    this.singleSelection = false,
  });

  /// 显示弹窗
  static Future<List<String>?> show(
    BuildContext context, {
    List<GroupMemberModel>? members,
    String? title,
    List<String>? defaultSelectedUserIds,
    bool singleSelection = false,
  }) {
    return showModalBottomSheet<List<String>>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RemoveMemberModal(
        members: members,
        title: title,
        defaultSelectedUserIds: defaultSelectedUserIds,
        singleSelection: singleSelection,
      ),
    );
  }

  @override
  State<RemoveMemberModal> createState() => _RemoveMemberModalState();
}

class _RemoveMemberModalState extends State<RemoveMemberModal> {
  List<GroupMemberModel> get _members => widget.members ?? [];
  final Set<String> _selectedMembers = {};
  late List<GroupMemberModel> _filterMembers;
  @override
  void initState() {
    super.initState();
    _filterMembers = _members;
    _selectedMembers.addAll(widget.defaultSelectedUserIds ?? []);
  }

  @override
  Widget build(BuildContext context) {
    const double itemHeight = 72.0;
    final double listHeight = _members.length < 5
        ? _members.length * itemHeight
        : 5 * itemHeight;

    return AppModal(
      title: widget.title ?? AppLocalizations.of(context)!.chatRemoveMembers,
      confirmText: widget.singleSelection
          ? AppLocalizations.of(context)!.commonDone
          : _selectedMembers.isNotEmpty
          ? AppLocalizations.of(
              context,
            )!.commonDoneCount(_selectedMembers.length)
          : AppLocalizations.of(context)!.commonDone,
      confirmColor: _selectedMembers.isNotEmpty
          ? AppColors.grey900
          : AppColors.grey300,
      onConfirm: () {
        Navigator.pop(context, _selectedMembers.toList());
      },
      contentPadding: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsetsGeometry.symmetric(horizontal: 20),
            child: AppSearchInput(
              onChanged: (t) {
                setState(() {
                  if (t.isEmpty) {
                    _filterMembers = _members;
                  } else {
                    _filterMembers = _members.where((e) {
                      final name =  e.name;
                      final address = e.item.userId ?? '';

                      final keyword = t.toLowerCase();

                      return name.toLowerCase().contains(keyword) ||
                          address.toLowerCase().contains(keyword);
                    }).toList();
                  }
                });
              },
            ),
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
                      onTap: () {
                        _toggleMember(member.item.userId);
                      },
                      child: _buildMemberItem(
                        member: member,
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
                            stops: [0.0, 0.78, 1.0],
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
    required GroupMemberModel member,
    required bool showDivider,
  }) {
    final selected = _selectedMembers.contains(member.item.userId);
    return IgnorePointer(
      ignoring: false,
      child: Opacity(
        opacity: 1,
        child: GestureDetector(
          onTap: () {
            _toggleMember(member.item.userId);
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            height: 76,
            child: Row(
              children: [
                UserAvatarWidget(
                  userId: member.item.userId,
                  avatarUrl: member.item.portraitUri,
                  size: 44,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: showDivider
                          ? const Border(
                              bottom: BorderSide(
                                color: AppColors.grey100,
                                width: 1,
                              ),
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
                                ellipsisMiddle(member.item.userId ?? ''),
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
                          value: selected,
                          onChanged: (val) {
                            _toggleMember(member.item.userId);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleMember(String? userId) {
    if (userId == null || userId.isEmpty) return;
    setState(() {
      if (_selectedMembers.contains(userId)) {
        _selectedMembers.remove(userId);
        return;
      }
      if (widget.singleSelection) {
        _selectedMembers
          ..clear()
          ..add(userId);
        return;
      }
      _selectedMembers.add(userId);
    });
  }
}
