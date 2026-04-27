import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_localizations_keys.dart';
import 'package:paracosm/widgets/chat/contact_item.dart';
import 'package:paracosm/widgets/chat/quick_index_bar.dart';
import 'package:paracosm/widgets/base/app_page.dart';

/// 群组列表页面
/// 展示用户加入的所有群组，按首字母进行分类，并提供快速索引功能
class GroupListPage extends StatefulWidget {
  const GroupListPage({super.key});

  @override
  State<GroupListPage> createState() => _GroupListPageState();
}

class _GroupListPageState extends State<GroupListPage> {
  final ScrollController _scrollController = ScrollController();
  
  /// 模拟群组数据，按首字母分组
  final List<Map<String, dynamic>> _groupData = [
    {
      'initial': 'A',
      'groups': [
        {
          'name': 'Work group',
          'avatars': [
            'assets/images/chat/avatar.png',
            'assets/images/chat/avatar.png',
            'assets/images/chat/avatar.png',
            'assets/images/chat/avatar.png',
          ]
        },
        {
          'name': 'Work group',
          'avatars': [
            'assets/images/chat/avatar.png',
            'assets/images/chat/avatar.png',
            'assets/images/chat/avatar.png',
            'assets/images/chat/avatar.png',
          ]
        },
      ]
    },
    {
      'initial': 'B',
      'groups': [
        {
          'name': 'Work group',
          'avatars': [
            'assets/images/chat/avatar.png',
            'assets/images/chat/avatar.png',
            'assets/images/chat/avatar.png',
            'assets/images/chat/avatar.png',
          ]
        },
        {
          'name': 'Work group',
          'avatars': [
            'assets/images/chat/avatar.png',
            'assets/images/chat/avatar.png',
            'assets/images/chat/avatar.png',
            'assets/images/chat/avatar.png',
          ]
        },
        {
          'name': 'Work group',
          'avatars': [
            'assets/images/chat/avatar.png',
            'assets/images/chat/avatar.png',
            'assets/images/chat/avatar.png',
            'assets/images/chat/avatar.png',
          ]
        },
        {
          'name': 'Work group',
          'avatars': [
            'assets/images/chat/avatar.png',
            'assets/images/chat/avatar.png',
            'assets/images/chat/avatar.png',
            'assets/images/chat/avatar.png',
          ]
        },
        {
          'name': 'Work group',
          'avatars': [
            'assets/images/chat/avatar.png',
            'assets/images/chat/avatar.png',
            'assets/images/chat/avatar.png',
            'assets/images/chat/avatar.png',
          ]
        },
      ]
    },
  ];

  /// 快速索引字母列表
  final List<String> _indexLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');

  /// 滚动到指定的首字母分组位置
  void _scrollToInitial(String initial) {
    int targetIndex = _groupData.indexWhere((item) => item['initial'] == initial);
    if (targetIndex != -1) {
      double offset = 0;
      for (int i = 0; i < targetIndex; i++) {
        // 分组头部高度 28 + 每个群组项高度 64
        offset += 28 + (_groupData[i]['groups'] as List).length * 64;
      }
      _scrollController.jumpTo(offset);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: AppLocalizations.of(context)!.chatGroup,
      child: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            itemCount: _groupData.length,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              final group = _groupData[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 分组首字母标题
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    color: AppColors.grey100,
                    child: Text(
                      group['initial'],
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.grey400,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  // 该字母下的群组列表
                  // ...List.generate(
                  //   group['groups'].length,
                  //   (i) => ContactItem(
                  //     name: group['groups'][i]['name'],
                  //     avatar: group['groups'][i]['avatars'],
                  //     showDivider: i != group['groups'].length - 1,
                  //     onTap: () {
                  //       // TODO: 跳转群组聊天详情
                  //     },
                  //   ),
                  // ),
                ],
              );
            },
          ),
          // 右侧快速索引栏
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
      ),
    );
  }

  /// 构建字母分组头部
  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      color: AppColors.grey100,
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.grey500,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
