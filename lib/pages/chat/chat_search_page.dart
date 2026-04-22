import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/modules/im/manager/im_group_manager.dart';
import 'package:paracosm/modules/im/manager/im_message_manager.dart';
import 'package:paracosm/modules/im/manager/im_user_manager.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_localizations_keys.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_search_input.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import 'package:paracosm/widgets/common/app_empty_view.dart';

enum ChatSearchType {
  all,
  user,
  group,
  message,
}

/// 聊天搜索页面
class ChatSearchPage extends StatefulWidget {
  final ChatSearchType type;

  const ChatSearchPage({
    super.key,
    this.type = ChatSearchType.all,
  });
  @override
  State<ChatSearchPage> createState() => _ChatSearchPageState();
}

class _ChatSearchPageState extends State<ChatSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool get _isSearching => _searchQuery.isNotEmpty;
  ChatSearchType get _type => widget.type;

  // 模拟搜索结果数据
  final List<Map<String, dynamic>> _mockUsers = [
    {
      'name': 'John Bonzales',
      'subtitle': 'Hi, What are you doning?',
      'avatar': 'assets/images/chat/avatar.png',
    },
    {
      'name': 'Kristen',
      'subtitle': 'Hi, What are you doning?',
      'avatar': 'assets/images/chat/avatar.png',
    },
  ];

  final List<Map<String, dynamic>> _mockGroups = [
    {
      'name': 'PARACOSM Group - B',
      'id': '',
      'avatars': List.filled(4, 'assets/images/chat/avatar.png'),
    },
    {
      'name': 'PARACOSM Group - B',
      'id': '24Block902ad2',
      'avatars': List.filled(4, 'assets/images/chat/avatar.png'),
    },
  ];

  final List<Map<String, dynamic>> _mockMessages = [
    {
      'name': 'John Gonzales',
      'subtitle': 'Hi, Baby-What are you doning?',
      'avatar': 'assets/images/chat/avatar.png',
    },
    {
      'name': 'Kristen',
      'subtitle': 'Hi, Baby-What are you doning?',
      'avatar': 'assets/images/chat/avatar.png',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> searchUserData(String keyword) async {
    final users = await ImUserManager().getUserProfiles([keyword]);
    setState(() {

    });
  }

  Future<void> searchGroupData(String keyword) async {
    final groups = await ImGroupManager().searchJoinedGroups(keyword: keyword);
    setState(() {

    });
  }

  Future<void> searchMessageData(String keyword) async {
    final messages = await ImMessageManager().searchMessages(
        type: RCIMIWConversationType.private, targetId: '', keyword: keyword, startTime: 0, count: 50);
    setState(() {

    });
  }
  @override
  Widget build(BuildContext context) {
    return AppPage(
      showNav: true,
      isCustomHeader: true,
      renderCustomHeader: _buildCustomHeader(),
      child: _isSearching || _type != ChatSearchType.all ? _buildResultView() : _buildInitialView(),
    );
  }

  /// 构建自定义导航栏内容
  Widget _buildCustomHeader() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: AppSearchInput(
              controller: _searchController,
              autofocus: true,
              hintText: AppLocalizations.of(context)!.chatSearchHint,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.chatSearchCancel,
              style: AppTextStyles.body.copyWith(
                color: AppColors.primaryLight,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建初始状态视图（分类入口 + 搜索历史）
  Widget _buildInitialView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              AppLocalizations.of(context)!.chatSearchSpecific,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.grey700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(
            color: AppColors.grey100,
            height: 1,
            indent: 20,
            endIndent: 20,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCategoryItem(AppLocalizations.of(context)!.chatSearchUser),
                _buildCategoryItem(AppLocalizations.of(context)!.chatSearchGroup),
                _buildCategoryItem(AppLocalizations.of(context)!.chatSearchMessage),
                _buildCategoryItem(AppLocalizations.of(context)!.chatSearchBrowser),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              AppLocalizations.of(context)!.chatSearchHistory,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.grey400,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 1),
          const Divider(
            color: AppColors.grey100,
            height: 1,
            indent: 20,
            endIndent: 20,
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              AppLocalizations.of(context)!.chatSearchNoRecent,
              style: const TextStyle(color: AppColors.grey400, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建搜索结果视图
  Widget _buildResultView() {
    final filteredUsers = _mockUsers
        .where((u) => u['name'].toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
    final filteredGroups = _mockGroups
        .where((g) => g['name'].toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
    final filteredMessages = _mockMessages
        .where((m) =>
            m['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
            m['subtitle'].toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    if (filteredUsers.isEmpty &&
        filteredGroups.isEmpty &&
        filteredMessages.isEmpty) {
      return _buildEmptyView();
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (filteredUsers.isNotEmpty) _buildSectionHeader(AppLocalizations.of(context)!.chatSearchUser),
        ...filteredUsers.map((user) => _buildUserItem(user)),
        if (filteredGroups.isNotEmpty) _buildSectionHeader(AppLocalizations.of(context)!.chatSearchGroup),
        ...filteredGroups.map((group) => _buildGroupItem(group)),
        if (filteredMessages.isNotEmpty) _buildSectionHeader(AppLocalizations.of(context)!.chatSearchMessage),
        ...filteredMessages.map((msg) => _buildMessageItem(msg)),
      ],
    );
  }

  /// 构建空状态视图
  Widget _buildEmptyView() {
    return AppEmptyView(
      text: AppLocalizations.of(context)!.chatSearchNoData,
    );
  }

  /// 构建分类入口项
  Widget _buildCategoryItem(String label) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: AppColors.primaryLight,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 构建区块标题
  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.grey400,
          fontSize: 14,
        ),
      ),
    );
  }

  /// 构建用户搜索项
  Widget _buildUserItem(Map<String, dynamic> user) {
    return GestureDetector(
      onTap: () {
        final encodedName = Uri.encodeComponent(user['name']);
        context.push('/user-profile/$encodedName');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.white,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: AssetImage(user['avatar']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.grey100, width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHighlightText(
                      user['name'],
                      _searchQuery,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.grey900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user['subtitle'],
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grey700,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建群聊搜索项
  Widget _buildGroupItem(Map<String, dynamic> group) {
    return GestureDetector(
      onTap: () {
        final encodedName = Uri.encodeComponent(group['name']);
        context.push('/group-details/$encodedName');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.white,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _buildGroupAvatar(group['avatars']),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.grey100, width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHighlightText(
                      group['name'],
                      _searchQuery,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.grey900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (group['id'].isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _buildHighlightText(
                        'ID : ${group['id']}',
                        _searchQuery,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.grey400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建消息搜索项
  Widget _buildMessageItem(Map<String, dynamic> msg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.white,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: AssetImage(msg['avatar']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.grey100, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg['name'],
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.grey900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildHighlightText(
                    msg['subtitle'],
                    _searchQuery,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.grey400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建群聊 4-grid 头像
  Widget _buildGroupAvatar(List<String> avatars) {
    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        children: avatars
            .take(4)
            .map(
              (avatar) => ClipRRect(
                borderRadius: BorderRadius.circular(1),
                child: Image.asset(avatar, fit: BoxFit.cover),
              ),
            )
            .toList(),
      ),
    );
  }

  /// 构建带高亮显示的文本
  Widget _buildHighlightText(
    String text,
    String highlight, {
    required TextStyle style,
  }) {
    if (highlight.isEmpty ||
        !text.toLowerCase().contains(highlight.toLowerCase())) {
      return Text(text, style: style);
    }

    final List<TextSpan> spans = [];
    final String lowerText = text.toLowerCase();
    final String lowerHighlight = highlight.toLowerCase();
    int start = 0;
    int indexOfHighlight;

    while ((indexOfHighlight = lowerText.indexOf(lowerHighlight, start)) !=
        -1) {
      if (indexOfHighlight > start) {
        spans.add(TextSpan(text: text.substring(start, indexOfHighlight)));
      }
      spans.add(
        TextSpan(
          text: text.substring(
            indexOfHighlight,
            indexOfHighlight + highlight.length,
          ),
          style: const TextStyle(color: AppColors.primaryLight),
        ),
      );
      start = indexOfHighlight + highlight.length;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      text: TextSpan(style: style, children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
