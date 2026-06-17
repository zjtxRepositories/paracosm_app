import 'package:flutter/material.dart';
import 'package:paracosm/core/models/friend_model.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/util/string_util.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';
import 'package:paracosm/widgets/common/app_checkbox.dart';
import 'package:paracosm/widgets/common/app_modal.dart';
import 'package:paracosm/widgets/common/app_search_input.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

/// 选择成员弹窗
class SelectMembersModal extends StatefulWidget {
  final bool showTag;
  final String confirmText;
  final bool showSelectedCount;
  final List<RCIMIWFriendInfo>? friends;
  final List<String>? defaultSelectedUserIds;
  final List<String>? initialSelectedUserIds;
  final int? minSelectedCount;
  final bool showSelectAllControl;

  const SelectMembersModal({
    super.key,
    this.showTag = true,
    this.confirmText = '',
    this.showSelectedCount = false,
    this.friends,
    this.defaultSelectedUserIds,
    this.initialSelectedUserIds,
    this.minSelectedCount,
    this.showSelectAllControl = false,
  });

  /// 显示弹窗
  static Future<List<String>?> show(
    BuildContext context, {
    bool showTag = true,
    String confirmText = '',
    bool showSelectedCount = false,
    List<RCIMIWFriendInfo>? friends,
    List<String>? defaultSelectedUserIds,
    List<String>? initialSelectedUserIds,
    int? minSelectedCount,
    bool showSelectAllControl = false,
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
        defaultSelectedUserIds: defaultSelectedUserIds,
        initialSelectedUserIds: initialSelectedUserIds,
        minSelectedCount: minSelectedCount,
        showSelectAllControl: showSelectAllControl,
      ),
    );
  }

  @override
  State<SelectMembersModal> createState() => _SelectMembersModalState();
}

class _SelectMembersModalState extends State<SelectMembersModal> {
  List<RCIMIWFriendInfo> get _members => widget.friends ?? [];
  List<String> get _defaultSelectedUserIds =>
      widget.defaultSelectedUserIds ?? [];
  List<String> get _initialSelectedUserIds =>
      widget.initialSelectedUserIds ?? [];
  final Set<String> _selectedMembers = {};
  late List<RCIMIWFriendInfo> _filterMembers;

  List<String> get _selectableUserIds => _members
      .map((member) => member.userId ?? '')
      .where(
        (userId) =>
            userId.isNotEmpty && !_defaultSelectedUserIds.contains(userId),
      )
      .toList();

  bool get _isAllSelected {
    final selectable = _selectableUserIds;
    return selectable.isNotEmpty && selectable.every(_selectedMembers.contains);
  }

  @override
  void initState() {
    super.initState();
    _filterMembers = _members;
    _selectedMembers.addAll(
      _initialSelectedUserIds.where(
        (userId) =>
            userId.isNotEmpty && !_defaultSelectedUserIds.contains(userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const double itemHeight = 72.0;
    final double listHeight = _members.length < 5
        ? _members.length * itemHeight
        : 5 * itemHeight;
    final confirm = widget.minSelectedCount == null
        ? _selectedMembers.isNotEmpty
        : (widget.minSelectedCount ?? 0) <=
              _selectedMembers.length + _defaultSelectedUserIds.length;

    final confirmText = widget.confirmText.isEmpty
        ? l10n.commonCreate
        : widget.confirmText;

    return AppModal(
      title: l10n.chatSelectMembersTitle,
      confirmText: widget.showSelectedCount
          ? '$confirmText (${_selectedMembers.length})'
          : confirmText,
      confirmColor: confirm ? AppColors.grey900 : AppColors.grey300,
      onConfirm: () {
        if (!confirm) return;
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
                        setState(() {
                          if (_selectedMembers.contains(member.userId)) {
                            _selectedMembers.remove(member.userId);
                          } else {
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
                            stops: [0.0, 0.78, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (widget.showSelectAllControl) _buildSelectAllControl(),
        ],
      ),
    );
  }

  Widget _buildSelectAllControl() {
    final l10n = AppLocalizations.of(context)!;
    final allSelected = _isAllSelected;

    return GestureDetector(
      onTap: _toggleSelectAll,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.grey100, width: 1)),
        ),
        child: Row(
          children: [
            AppCheckbox(
              value: allSelected,
              onChanged: (_) => _toggleSelectAll(),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.commonSelectAll,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey900,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSelectAll() {
    setState(() {
      if (_isAllSelected) {
        _selectedMembers.removeAll(_selectableUserIds);
      } else {
        _selectedMembers.addAll(_selectableUserIds);
      }
    });
  }

  Widget _buildMemberItem({
    required RCIMIWFriendInfo friend,
    required bool showDivider,
  }) {
    final member = FriendModel(info: friend);
    final selected =
        _selectedMembers.contains(member.info.userId) ||
        _defaultSelectedUserIds.contains(member.info.userId);
    return IgnorePointer(
      ignoring: _defaultSelectedUserIds.contains(member.info.userId),
      child: Opacity(
        opacity: _defaultSelectedUserIds.contains(member.info.userId)
            ? 0.45
            : 1,
        child: GestureDetector(
          onTap: () {
            setState(() {
              if (_selectedMembers.contains(member.info.userId)) {
                _selectedMembers.remove(member.info.userId);
              } else {
                _selectedMembers.add(member.info.userId ?? '');
              }
            });
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
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
                                ellipsisMiddle(member.info.userId ?? ''),
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
                            setState(() {
                              if (_selectedMembers.contains(
                                member.info.userId,
                              )) {
                                _selectedMembers.remove(member.info.userId);
                              } else {
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
          ),
        ),
      ),
    );
  }
}
