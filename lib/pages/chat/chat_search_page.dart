import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:k_chart_plus/k_chart_plus.dart';
import 'package:paracosm/core/models/user_model.dart';
import 'package:paracosm/modules/im/manager/im_group_manager.dart';
import 'package:paracosm/modules/im/manager/im_message_manager.dart';
import 'package:paracosm/modules/im/manager/im_user_manager.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_localizations_keys.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/chat/group_avatar_widget.dart';
import 'package:paracosm/widgets/common/app_search_input.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import 'package:paracosm/widgets/common/app_empty_view.dart';

import '../../modules/im/result/im_result.dart';
import '../../util/string_util.dart';
import '../../widgets/chat/user_avatar_widget.dart';
import '../../widgets/common/app_network_image.dart';

enum ChatSearchType {
  all,
  user,
  group,
  message,
  browser,
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
  final TextEditingController _searchController = TextEditingController(text: '0xe6590a740a45bc2b4d4996a85ab4a2ad371fbb6b');

  Timer? _debounce;

  String _searchQuery = '';
  bool get _isSearching => _searchQuery.isNotEmpty;
  ChatSearchType get _type => widget.type;

  List<RCIMIWUserProfile> _users = [];
  List<RCIMIWGroupInfo> _groups = [];
  List<RCIMIWMessage> _messages = [];

  String _getHintText() {
    final l10n = AppLocalizations.of(context)!;

    switch (_type) {
      case ChatSearchType.all:
        return l10n.chatSearchHint; // 默认：搜索
      case ChatSearchType.user:
        return l10n.chatSearchUser; // 搜索用户
      case ChatSearchType.group:
        return l10n.chatSearchGroup; // 搜索群聊
      case ChatSearchType.message:
        return l10n.chatSearchMessage; // 搜索消息
      case ChatSearchType.browser:
        return l10n.chatSearchBrowser; // 搜索网页
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch(String keyword) async {
    if (keyword.isEmpty) {
      setState(() {
        _users = [];
        _groups = [];
        _messages = [];
      });
      return;
    }
    try {
      List<RCIMIWUserProfile> users = [];
      List<RCIMIWGroupInfo> groups = [];
      List<RCIMIWMessage> messages = [];
      print('get======$keyword');
      switch (_type) {
        case ChatSearchType.all:
          final results = await Future.wait([
            ImUserManager().getUserProfiles([keyword]),
            ImGroupManager().searchJoinedGroups(keyword: keyword),
            ImMessageManager().searchMessages(
              type: RCIMIWConversationType.private,
              targetId: '',
              keyword: keyword,
              startTime: 0,
              count: 50,
            ),
          ]);

          users = (results[0] as List<RCIMIWUserProfile>? ?? []);
          final groupResult = results[1] as RCIMIWPagingQueryResult<RCIMIWGroupInfo>?;
          groups = groupResult?.data ?? [];
          final messageResult = results[2] as ImResult<List<RCIMIWMessage>>;
          messages = messageResult.data ?? [];

          break;

        case ChatSearchType.user:
          users = await ImUserManager().getUserProfiles([keyword]) ?? [];
          break;

        case ChatSearchType.group:
          final result =
          await ImGroupManager().searchJoinedGroups(keyword: keyword);
          groups = result?.data ?? [];
          break;

        case ChatSearchType.message:
          final result  = await ImMessageManager().searchMessages(
            type: RCIMIWConversationType.private,
            targetId: '',
            keyword: keyword,
            startTime: 0,
            count: 50,
          );
          messages = result.data ?? [];
          break;

        case ChatSearchType.browser:
          break;
      }

      setState(() {
        _users = users;
        _groups = groups;
        _messages = messages;
      });
    } catch (e) {
      setState(() {
        _users = [];
        _groups = [];
        _messages = [];
      });
    }
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
              hintText: _getHintText(),
              onChanged: (value) {
                _debounce?.cancel();

                _debounce = Timer(const Duration(milliseconds: 300), () {
                  setState(() {
                    _searchQuery = value;
                  });

                  _handleSearch(value.toLowerCase());
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
                _buildCategoryItem(AppLocalizations.of(context)!.chatSearchUser,ChatSearchType.user),
                _buildCategoryItem(AppLocalizations.of(context)!.chatSearchGroup,ChatSearchType.group),
                _buildCategoryItem(AppLocalizations.of(context)!.chatSearchMessage,ChatSearchType.message),
                _buildCategoryItem(AppLocalizations.of(context)!.chatSearchBrowser,ChatSearchType.browser),
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
    if (_users.isEmpty &&
        _groups.isEmpty &&
        _messages.isEmpty) {
      return _buildEmptyView();
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (_users.isNotEmpty) _buildSectionHeader(AppLocalizations.of(context)!.chatSearchUser),
        ..._users.map((user) => _buildUserItem(user)),
        if (_groups.isNotEmpty) _buildSectionHeader(AppLocalizations.of(context)!.chatSearchGroup),
        ..._groups.map((group) => _buildGroupItem(group)),
        if (_messages.isNotEmpty) _buildSectionHeader(AppLocalizations.of(context)!.chatSearchMessage),
        ..._messages.map((msg) => _buildMessageItem(msg)),
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
  Widget _buildCategoryItem(String label,ChatSearchType type) {
    return GestureDetector(
      onTap: (){
        context.push('/chat-search',extra: type);
      },
      child: Column(
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
      ),
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
  Widget _buildUserItem(RCIMIWUserProfile user) {
    final userModel = UserModel(profile: user);
    return GestureDetector(
      onTap: () {
        context.push('/user-profile',extra: user.userId);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.white,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: UserAvatarWidget(
                userId: user.userId,
                avatarUrl: user.portraitUri,
                size: 48,
                borderRadius: BorderRadius.circular(10),
              )
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
                      userModel.name,
                      _searchQuery,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.grey900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ellipsisMiddle(user.userId ?? ''),
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
  Widget _buildGroupItem(RCIMIWGroupInfo group) {
    return GestureDetector(
      onTap: () {
        // final encodedName = Uri.encodeComponent(group['name']);
        // context.push('/group-details/$encodedName');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.white,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _buildGroupAvatar(group),
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
                      group.groupName ?? '',
                      _searchQuery,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.grey900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (group.groupId != null) ...[
                      const SizedBox(height: 4),
                      _buildHighlightText(
                        'ID : ${group.groupId}',
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
  Widget _buildMessageItem(RCIMIWMessage msg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.white,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child:AppNetworkImage(
                url: msg.userInfo?.portrait ?? '',
                width: 48,
                height: 48,
                fit: BoxFit.contain,
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
                    msg.userInfo?.name ?? '',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.grey900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildHighlightText(
                    'content',
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
  Widget _buildGroupAvatar(RCIMIWGroupInfo group) {
    return GroupAvatarWidget(groupId: group.groupId ?? '', portraitUri: group.portraitUri,);
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
