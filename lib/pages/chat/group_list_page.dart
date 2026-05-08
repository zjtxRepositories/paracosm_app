import 'dart:async';

import 'package:flutter/material.dart';
import 'package:paracosm/core/models/group_model.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_localizations_keys.dart';
import 'package:paracosm/widgets/chat/contact_item.dart';
import 'package:paracosm/widgets/chat/quick_index_bar.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../widgets/base/app_page.dart';
import '../../widgets/common/app_empty_view.dart';

/// 群组列表页面
/// 展示用户加入的所有群组，按首字母进行分类，并提供快速索引功能
class GroupListPage extends StatefulWidget {
  final List<RCIMIWGroupInfo> groups;
  const GroupListPage({super.key, required this.groups});

  @override
  State<GroupListPage> createState() => _GroupListPageState();
}

class _GroupListPageState extends State<GroupListPage> {
  final Map<String, double> _letterOffsetMap = {};

  List<String>? _cachedIndexLetters;
  List<Map<String, dynamic>> _contactGroups = [];

  final ScrollController _scrollController = ScrollController();

  /// =========================
  /// 工具：首字母规则
  /// =========================
  String _getInitial(String name) {
    if (name.isEmpty) return '#';

    final first = name[0].toUpperCase();

    if (RegExp(r'^[A-Z]$').hasMatch(first)) {
      return first;
    }

    return '#';
  }

  bool _isLetter(String s) {
    return RegExp(r'^[A-Z]$').hasMatch(s);
  }

  /// =========================
  /// 构建索引字母（缓存版）
  /// =========================
  List<String> _buildIndexLetters() {
    final Set<String> letters = {};

    for (var f in widget.groups) {
      final name =  f.groupName ?? '';

      if (name.isEmpty) continue;

      final first = name[0].toUpperCase();

      if (_isLetter(first)) {
        letters.add(first);
      } else {
        letters.add('#');
      }
    }

    final list = letters.toList();

    list.sort((a, b) {
      if (a == '#') return 1;
      if (b == '#') return -1;
      return a.compareTo(b);
    });

    return list;
  }

  List<String> get _indexLetters {
    return _cachedIndexLetters ??= _buildIndexLetters();
  }

  /// =========================
  /// 分组数据
  /// =========================
  Future<List<Map<String, dynamic>>> _buildContactGroups() async {
    final Map<String, List<GroupModel>> map = {};

    for (var f in widget.groups) {
      final name = f.groupName ?? '';
      if (name.isEmpty) continue;

      final initial = _getInitial(name);
      map.putIfAbsent(initial, () => []);
      final model = GroupModel(info: f);
      model.showName = await model.name;
      map[initial]!.add(model);
    }

    final List<Map<String, dynamic>> result = [];

    final keys = map.keys.toList();

    keys.sort((a, b) {
      if (a == '#') return 1;
      if (b == '#') return -1;
      return a.compareTo(b);
    });

    for (var key in keys) {
      result.add({
        'initial': key,
        'groups': map[key]!,
      });
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
      _scrollController.jumpTo(offset);
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
        offset += 76.0;
        continue;
      }

      final initial = group['initial'];
      map[initial] = offset;

      offset += 36.0;
      offset += (group['groups'] as List).length * 76.0;
    }

    _letterOffsetMap
      ..clear()
      ..addAll(map);
    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    _contactGroups = await _buildContactGroups();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buildOffsetMap(_contactGroups);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_contactGroups.isEmpty) {
      return AppEmptyView(
        text: AppLocalizations.of(context)!.chatSearchNoData,
      );
    }
    return AppPage(
      title: AppLocalizations.of(context)!.chatGroup,
      child: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            itemCount: _contactGroups.length,
            itemBuilder: (context, index) {
              final group = _contactGroups[index];

              final List<GroupModel> groups = group['groups'];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      _buildGroupTitle(context, group['initial']),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.grey400,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  ...List.generate(
                    groups.length,
                        (i) {
                      final group = groups[i];
                      return ContactItem(
                          name: group.showName ?? '',
                          portraitUri: group.info.portraitUri ?? '',
                          groupId: group.info.groupId ?? '',
                          isStar: false,
                          showDivider: i != groups.length - 1,
                          onTap: () {

                          }
                      );
                    },
                  ),
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
                letters: _indexLetters,
                onLetterSelected: _scrollToInitial,
              ),
            ),
          ),
        ],
      )
    );
  }
}
