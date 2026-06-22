import 'package:flutter/material.dart';
import 'package:paracosm/core/models/friend_model.dart';
import 'package:paracosm/modules/contact/contact_indexer.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/chat/contact_item.dart';
import 'package:paracosm/widgets/chat/quick_index_bar.dart';
import 'package:paracosm/widgets/common/app_empty_view.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

class ContactsView extends StatefulWidget {
  final List<RCIMIWFriendInfo> friends;
  final List<RCIMIWGroupInfo> groups;
  final ScrollController controller;
  final Function(String) onTapContact;
  final Widget Function() buildGroupHeader;

  const ContactsView({
    super.key,
    required this.friends,
    required this.groups,
    required this.controller,
    required this.onTapContact,
    required this.buildGroupHeader,
  });

  @override
  State<ContactsView> createState() => _ContactsViewState();
}

class _ContactsViewState extends State<ContactsView> {
  final Map<String, double> _letterOffsetMap = {};

  /// =========================
  /// 分组数据
  /// =========================
  List<Map<String, dynamic>> _buildContactGroups() {
    final List<Map<String, dynamic>> result = [];

    result.add({'type': 'header'});

    final groups = buildContactIndexGroups(
      widget.friends,
      (friendInfo) => FriendModel(info: friendInfo).name,
    );

    for (final group in groups) {
      result.add({'initial': group.initial, 'contacts': group.contacts});
    }

    return result;
  }

  /// =========================
  /// 标题
  /// =========================
  String _buildGroupTitle(BuildContext context, String initial) {
    if (initial == 'chat_group') {
      return AppLocalizations.of(context)!.chatGroup;
    }
    if (initial == 'chat_star_friend') {
      return AppLocalizations.of(context)!.chatStarFriend;
    }
    return initial;
  }

  /// =========================
  /// 滚动
  /// =========================
  void _scrollToInitial(String initial) {
    final offset = _letterOffsetMap[initial];
    if (offset != null) {
      widget.controller.jumpTo(offset);
    }
  }

  /// =========================
  /// offset 计算（postFrame 更稳定）
  /// =========================
  void _buildOffsetMap(List<Map<String, dynamic>> groups) {
    final map = <String, double>{};
    double offset = 0;

    for (var group in groups) {
      if (group['type'] == 'header') {
        offset += 152.0;
        continue;
      }

      final initial = group['initial'];
      map[initial] = offset;

      offset += 36.0;
      offset += (group['contacts'] as List).length * 76.0;
    }

    _letterOffsetMap
      ..clear()
      ..addAll(map);
  }

  @override
  Widget build(BuildContext context) {
    final contactGroups = _buildContactGroups();
    final indexLetters = contactGroups
        .where((group) => group['type'] != 'header')
        .map((group) => group['initial'] as String)
        .toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buildOffsetMap(contactGroups);
    });

    if (contactGroups.isEmpty) {
      return AppEmptyView(text: AppLocalizations.of(context)!.chatSearchNoData);
    }

    return Stack(
      children: [
        ListView.builder(
          controller: widget.controller,
          itemCount: contactGroups.length,
          itemBuilder: (context, index) {
            final group = contactGroups[index];

            if (group['type'] == 'header') {
              return widget.buildGroupHeader();
            }

            final List<RCIMIWFriendInfo> contacts = group['contacts'];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(
                    _buildGroupTitle(context, group['initial']),
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.grey400,
                      fontSize: 14,
                    ),
                  ),
                ),
                ...List.generate(contacts.length, (i) {
                  final friend = FriendModel(info: contacts[i]);

                  return ContactItem(
                    name: friend.name,
                    portraitUri: friend.info.portrait ?? '',
                    userId: friend.info.userId ?? '',
                    isStar: false,
                    showDivider: i != contacts.length - 1,
                    onTap: () => widget.onTapContact(friend.info.userId ?? ''),
                  );
                }),
              ],
            );
          },
        ),

        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: Center(
            child: QuickIndexBar(
              letters: indexLetters,
              onLetterSelected: _scrollToInitial,
            ),
          ),
        ),
      ],
    );
  }
}
