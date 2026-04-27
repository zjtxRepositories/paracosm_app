import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/core/models/conversation_model.dart';
import 'package:paracosm/modules/im/manager/im_conversation_manager.dart';
import 'package:paracosm/modules/im/manager/im_friend_manager.dart';
import 'package:paracosm/modules/im/manager/im_group_manager.dart';
import 'package:paracosm/pages/chat/chat_session_args.dart';
import 'package:paracosm/pages/chat/chat_search_page.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/util/string_util.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/chat/chat_list_item.dart';
import 'package:paracosm/widgets/chat/system_notification_item.dart';
import 'package:paracosm/widgets/common/app_action_pop_menu.dart';
import 'package:paracosm/widgets/chat/select_members_modal.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import '../../modules/im/manager/im_connection_manager.dart';
import '../../modules/im/manager/im_friend_applications_manager.dart';
import 'package:paracosm/widgets/common/app_empty_view.dart';

import 'contacts_view.dart';

/// 聊天主列表页面
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final GlobalKey _addButtonKey = GlobalKey();
  final GlobalKey _contactsStackKey = GlobalKey();
  bool _isChatSelected = true;
  int _selectedFilterIndex = 0;
  final ScrollController _contactScrollController = ScrollController();
  int _friendApplicationUnhandledCount= 0;

  late StreamSubscription _imConnectSub;

  List<ConversationModel> _conversations = [];
  List<RCIMIWFriendInfo> _friends = [];
  List<RCIMIWGroupInfo> _groups = [];
  final List<List<RCIMIWConversationType>> _conversationTypes = [
    RCIMIWConversationType.values,
    [RCIMIWConversationType.private],
    [RCIMIWConversationType.group],
    [RCIMIWConversationType.system],
  ];
  Map<int, List<RCIMIWConversation>>? _tabCache;
  final resolver = ConversationResolver();

  @override
  void initState() {
    super.initState();
    initListener();
  }

  void initListener() {
    _imConnectSub = ImConnectionManager().eventStream.listen((event) async {
      if (event == ImEvent.connected) {
         fetchData();
      }
    });

  }
  Future<void> fetchData() async {
     fetchFriendApplicationData();
     fetchConversationData();
     fetchContactData();
     fetchGroupData();
  }

  Future<void> fetchFriendApplicationData() async {
    final manager = ImFriendApplicationsManager();
    manager.stream.listen((list) {
      print("好友申请列表更新: ${list.length}----${manager.unhandledCount}");
      setState(() {
        _friendApplicationUnhandledCount = manager.unhandledCount;
      });
    });
    manager.fetch();
  }

  Future<void> fetchConversationData() async {
    final manager = ImConversationManager();

    manager.stream.listen((map) async {
      _tabCache = manager.tabCache;
      refreshConversationData();
    });

    await manager.initAllTabs();
  }

  Future<void> refreshConversationData() async {
    final list = ImConversationManager().getTabList(_selectedFilterIndex);
    final models = list
        .map((e) => ConversationModel(info: e))
        .toList();

    setState(() {
      _conversations = models;
    });

    _resolveConversations(models);
  }

  Future<void> fetchContactData() async {
    final manager = ImFriendManager();
    manager.stream.listen((list) {
      setState(() {
        _friends = list;
      });
      debugPrint("获取好友:--- ${_friends.length}");
    });
    await manager.fetchFriends();
  }


  Future<void> fetchGroupData() async {
    final manager = ImGroupManager();
    manager.stream.listen((list) {
      setState(() {
        _groups = list;
      });
    });
    await manager.getAllJoinedGroups();
  }

  Future<void> _resolveConversations(List<ConversationModel> models) async {
    const batchSize = 10;

    for (int i = 0; i < models.length; i += batchSize) {
      final batch = models.skip(i).take(batchSize);

      await Future.wait(
        batch.map((m) => resolver.resolve(m)),
      );

      if (mounted) {
        setState(() {}); // 👉 触发局部刷新
      }
    }
  }
  // final List<Map<String, dynamic>> _mockChats = [
  //   {
  //     'type': 'system',
  //     'title': 'chat_notification_title', // 使用 key
  //     'subtitle': 'Linsy: The white paper of this project is a...',
  //     'time': '10:24',
  //     'unreadCount': 3,
  //     'icon': Icons.notifications,
  //     'iconBgColor': const Color(0xFFF7B500), // 黄色背景
  //   },
  //   {
  //     'type': 'chat',
  //     'title': 'John Gonzales',
  //     'subtitle': 'Hi, What are you doning?',
  //     'time': '17:48',
  //     'unreadCount': 4,
  //     'avatars': ['assets/images/chat/avatar.png'], // 暂用已有的占位图
  //   },
  //   {
  //     'type': 'chat',
  //     'title': 'PARACOSM Group',
  //     'subtitle': 'Linsy: Nice work,That\'s gonna be great if...',
  //     'time': '16:02',
  //     'unreadCount': 4,
  //     'avatars': [
  //       'assets/images/chat/avatar.png',
  //       'assets/images/chat/avatar.png',
  //       'assets/images/chat/avatar.png',
  //       'assets/images/chat/avatar.png',
  //     ],
  //   },
  //   {
  //     'type': 'chat',
  //     'title': 'Kristen',
  //     'subtitle': 'chat_image', // 使用 key
  //     'time': '16:00',
  //     'unreadCount': 0,
  //     'avatars': ['assets/images/chat/avatar.png'],
  //   },
  //   {
  //     'type': 'chat',
  //     'title': 'Dirac',
  //     'subtitle': 'You have unread about GameFi?',
  //     'time': '15:24',
  //     'unreadCount': 0,
  //     'isMuted': true,
  //     'avatars': ['assets/images/chat/avatar.png'],
  //   },
  //   {
  //     'type': 'chat',
  //     'title': 'Joey',
  //     'subtitle': 'That\'s right😎',
  //     'time': '12:09',
  //     'unreadCount': 0,
  //     'avatars': ['assets/images/chat/avatar.png'],
  //   },
  //   {
  //     'type': 'chat',
  //     'title': 'Kristen',
  //     'subtitle': 'Let\'s play together on the weekend ! Do you a...',
  //     'time': '10:49',
  //     'unreadCount': 0,
  //     'avatars': ['assets/images/chat/avatar.png'],
  //   },
  //   {
  //     'type': 'chat',
  //     'title': 'John Gonzales',
  //     'subtitle': 'OK',
  //     'time': '09:17',
  //     'unreadCount': 0,
  //     'avatars': ['assets/images/chat/avatar.png'],
  //   },
  //   {
  //     'type': 'chat',
  //     'title': 'Work project',
  //     'subtitle': 'Linsy: Nice work,That\'s gonna be great if...',
  //     'time': 'chat_yesterday', // 使用 key
  //     'unreadCount': 0,
  //     'avatars': [
  //       'assets/images/chat/avatar.png',
  //       'assets/images/chat/avatar.png',
  //       'assets/images/chat/avatar.png',
  //       'assets/images/chat/avatar.png',
  //     ],
  //   },
  // ];

  @override
  void dispose() {
    _contactScrollController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AppPage(
      showNav: true,
      showBack: false,
      isCustomHeader: true,
      renderCustomHeader: _buildCustomHeader(context),
      child: _isChatSelected ? _buildChatView() : _buildContactsView(),
    );
  }

  /// 构建聊天列表视图
  Widget _buildChatView() {
    // if (_conversations.isNotEmpty) {
    //   final filteredConversations = _filterConversations();
    //   return Column(
    //     children: [
    //       _buildFriendRequestCard(),
    //       _buildFilterBar(),
    //       Expanded(
    //         child: filteredConversations.isEmpty
    //             ? AppEmptyView(
    //                 text: AppLocalizations.of(context)!.chatSearchNoData,
    //                 bottomOffset: 50,
    //               )
    //             : ListView.builder(
    //                 padding: EdgeInsets.zero,
    //                 itemCount: filteredConversations.length,
    //                 itemBuilder: (context, index) {
    //                   final conversation = filteredConversations[index];
    //                   final title = _conversationTitle(conversation);
    //                   return ChatListItem(
    //                     title: title,
    //                     subtitle: _conversationSubtitle(conversation),
    //                     time: _conversationTime(conversation),
    //                     unreadCount: conversation.unreadCount ?? 0,
    //                     avatars: _conversationAvatars(conversation),
    //                     isMuted: false,
    //                     onTap: () => _navigateToConversationDetail(conversation, title),
    //                   );
    //                 },
    //               ),
    //       ),
    //     ],
    //   );
    // }

    // 简单的过滤逻辑，为了演示切换 Tab 时的空状态效果
    // 0: All, 1: Message, 2: DAO, 3: Club, 4: Others
    // final filteredChats = _conversations.where((chat) {
    //   if (_selectedFilterIndex == 0) return true; // All
    //   if (_selectedFilterIndex == 1) return chat['type'] == 'chat' || chat['type'] == 'system'; // Message
    //   return false; // DAO, Club, Others 暂无数据
    // }).toList();

    return Column(
      children: [
        _buildFriendRequestCard(),
        _buildFilterBar(),
        Expanded(
          child: _conversations.isEmpty
              ? AppEmptyView(
                  text: AppLocalizations.of(context)!.chatSearchNoData,
                  bottomOffset: 50, // 调整偏移，视觉更平衡
                )
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final item = _conversations[index];
                    if (item.info.conversationType == RCIMIWConversationType.system) {
                      return SystemNotificationItem(
                        title: AppLocalizations.of(context)!.chatNotificationTitle,
                        subtitle: 'sub',
                        time: AppLocalizations.of(context)!.chatYesterday,
                        unreadCount: 1,
                        icon: Icons.nat,
                        // iconBgColor: item['iconBgColor'],
                        // onTap: () => _navigateToDetail(item['title']),
                      );
                    } else {
                      return ChatListItem(
                        title: item.title ?? '',
                        subtitle: item.subtitle ?? '',
                        time: formatTimeAgo(item.info.operationTime ?? 0),
                        unreadCount: item.info.unreadCount ?? 0,
                        avatar: item.portraitUri ?? '',
                        isMuted: false,
                        onTap: () => _navigateToDetail(item.title ?? ''),
                      );
                    }
                  },
                ),
        ),
      ],
    );
  }

  /// 构建朋友申请卡片
  Widget _buildFriendRequestCard() {
    return _friendApplicationUnhandledCount == 0 ? SizedBox() : GestureDetector(
      onTap: () => context.push('/friend-request'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 4, 20,16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.grey200, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.chatFriendRequest,
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.grey900,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      RichText(
                        text: TextSpan(
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.grey400,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                          children: [
                            TextSpan(text: AppLocalizations.of(context)!.chatFriendRequestCount(_friendApplicationUnhandledCount)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Image.asset(
                        'assets/images/chat/go.png',
                        width: 16,
                        height: 16,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Image.asset(
              'assets/images/chat/friend-img.png',
              width: 56,
              height: 64,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建联系人列表视图
  Widget _buildContactsView() {
    return ContactsView(
      friends: _friends,
      groups: _groups,
      controller: _contactScrollController,
      buildGroupHeader: _buildGroupHeader,
      onTapContact: (userId) {
        _navigateToDetail(userId);
      },
    );
  }
  /// 构建联系人顶部的 Group 入口
  Widget _buildGroupHeader() {
    return GestureDetector(
      onTap: () => context.push('/group-list'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Group 图标 (蓝色背景)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.groupAvatarBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/chat/group-icon.png', // 暂时借用 scanner 图标，样式类似截图
                  width: 24,
                  height: 24,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 文字说明
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.chatGroup,
                    style: AppTextStyles.h2.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grey400,
                        fontSize: 12,
                      ),
                      children: [
                        TextSpan(text: AppLocalizations.of(context)!.chatGroupManageCount(_groups.length)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(String userId) {
    // final encodedName = Uri.encodeComponent(title);
    // context.push('/chat-detail/$encodedName');
  }

  void _navigateToConversationDetail(
    RCIMIWConversation conversation,
    String title,
  ) {
    final encodedName = Uri.encodeComponent(title);
    context.push(
      '/chat-detail/$encodedName',
      extra: ChatSessionArgs(
        targetId: conversation.targetId ?? '',
        conversationType:
            conversation.conversationType ?? RCIMIWConversationType.private,
        name: title,
        channelId: conversation.channelId,
        isGroup: conversation.conversationType == RCIMIWConversationType.group,
      ),
    );
  }

  /// 构建自定义导航栏
  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      color: AppColors.grey100,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 12,
      ),
      child: Row(
        children: [
          // Chat Tab
          GestureDetector(
            onTap: () {
              setState(() {
                _isChatSelected = true;
              });
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (_isChatSelected)
                  Positioned(
                    bottom: 4,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                Text(
                  AppLocalizations.of(context)!.chatTitle,
                  style: AppTextStyles.h1.copyWith(
                    fontSize: _isChatSelected ? 24 : 16,
                    color: _isChatSelected ? AppColors.grey900 : AppColors.grey400,
                    fontWeight: _isChatSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Contacts Tab
          GestureDetector(
            onTap: () {
              setState(() {
                _isChatSelected = false;
              });
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (!_isChatSelected)
                  Positioned(
                    bottom: 4,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                Text(
                  AppLocalizations.of(context)!.chatContacts,
                  style: AppTextStyles.h1.copyWith(
                    fontSize: !_isChatSelected ? 24 : 16,
                    color: !_isChatSelected ? AppColors.grey900 : AppColors.grey400,
                    fontWeight: !_isChatSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => context.push('/chat-search'),
            icon: Image.asset('assets/images/chat/search.png', width: 32, height: 32),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16), // 图标间距
          IconButton(
            key: _addButtonKey,
            onPressed: () {
              final l10n = AppLocalizations.of(context)!;
              AppActionPopMenu.show(
                context,
                buttonKey: _addButtonKey,
                rightOffset: 5,
                items: [
                  AppActionPopMenuItem(
                    icon: 'assets/images/chat/add-friend.png',
                    label: l10n.chatMenuAddFriend,
                    onTap: () {
                      // TODO: 跳转添加朋友
                      context.push('/chat-search',extra: ChatSearchType.user);
                    },
                  ),
                  AppActionPopMenuItem(
                    icon: 'assets/images/chat/create-group.png',
                    label: l10n.chatMenuCreateGroup,
                    onTap: () {
                      SelectMembersModal.show(context);
                    },
                  ),
                  AppActionPopMenuItem(
                    icon: 'assets/images/chat/scanner.png',
                    label: l10n.chatMenuScan,
                    onTap: () {
                      // TODO: 跳转扫一扫
                    },
                  ),
                ],
              );
            },
            icon: Image.asset('assets/images/chat/add.png', width: 32, height: 32),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// 构建消息分类过滤栏 (All, Message, DAO...)
  Widget _buildFilterBar() {
    final filters = [
      AppLocalizations.of(context)!
          .chatFilterAllCount(_tabCache?[0]?.length ?? 0),

      '私聊 ${_tabCache?[1]?.length ?? 0}',

      '群聊 ${_tabCache?[2]?.length ?? 0}',

      AppLocalizations.of(context)!
          .chatFilterClubCount(_tabCache?[3]?.length ?? 0),

      AppLocalizations.of(context)!
          .chatFilterDaoCount(0),
    ];
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedFilterIndex;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilterIndex = index;
              });
              refreshConversationData();
            },
            child: Container(
              margin: EdgeInsets.only(right: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min, // 确保高度自适应
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    filters[index],
                    style: isSelected
                        ? AppTextStyles.bodyMedium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey900
                          )
                        : AppTextStyles.body.copyWith(
                            color: AppColors.grey400,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                  ),
                  const SizedBox(height: 4),
                  if (isSelected)
                    Container(
                      height: 3,
                      width: 12,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )
                  else
                    const SizedBox(height: 3),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
