import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/modules/im/manager/im_conversation_manager.dart';
import 'package:paracosm/modules/im/manager/im_friend_manager.dart';
import 'package:paracosm/modules/im/manager/im_group_manager.dart';
import 'package:paracosm/modules/wallet/security/wallet_security.dart';
import 'package:paracosm/pages/chat/chat_search_page.dart';
import 'package:paracosm/pages/chat/friend_request_page.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_localizations_keys.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/chat/chat_list_item.dart';
import 'package:paracosm/widgets/chat/system_notification_item.dart';
import 'package:paracosm/widgets/common/app_action_pop_menu.dart';
import 'package:paracosm/widgets/chat/select_members_modal.dart';
import 'package:paracosm/widgets/chat/quick_index_bar.dart';
import 'package:paracosm/widgets/chat/contact_item.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import '../../modules/im/manager/im_friend_applications_manager.dart';
import 'package:paracosm/widgets/common/app_empty_view.dart';

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
  int _friendApplicationUnhandledCount= 2;
  List<RCIMIWConversation> _conversations = [];
  List<RCIMIWFriendInfo> _friends = [];
  List<RCIMIWGroupInfo> _groups = [];
  final List<List<RCIMIWConversationType>> _conversationTypes = [
    RCIMIWConversationType.values,
    [RCIMIWConversationType.private,RCIMIWConversationType.group],
    [RCIMIWConversationType.system],
  ];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    await fetchFriendApplicationData();
  }

  Future<void> fetchFriendApplicationData() async {
    final manager = ImFriendApplicationsManager();
    manager.stream.listen((list) {
      print("好友申请列表更新: ${list.length}");
      setState(() {
        _friendApplicationUnhandledCount = manager.unhandledCount;
      });
    });

    setState(() {
      _friendApplicationUnhandledCount = manager.unhandledCount;
    });
  }

  Future<void> fetchConversationData() async {
    final manager = ImConversationManager();
    manager.stream.listen((map) {
      setState(() {
        _conversations = map[_selectedFilterIndex] ?? [];
      });
    });
    await manager.initAllTabs();
  }

  Future<void> fetchContactData() async {
    final manager = ImFriendManager();
    manager.stream.listen((list) {
      setState(() {
        _friends = list;
      });
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

  final List<Map<String, dynamic>> _mockChats = [
    {
      'type': 'system',
      'title': 'chat_notification_title', // 使用 key
      'subtitle': 'Linsy: The white paper of this project is a...',
      'time': '10:24',
      'unreadCount': 3,
      'icon': Icons.notifications,
      'iconBgColor': const Color(0xFFF7B500), // 黄色背景
    },
    {
      'type': 'chat',
      'title': 'John Gonzales',
      'subtitle': 'Hi, What are you doning?',
      'time': '17:48',
      'unreadCount': 4,
      'avatars': ['assets/images/chat/avatar.png'], // 暂用已有的占位图
    },
    {
      'type': 'chat',
      'title': 'PARACOSM Group',
      'subtitle': 'Linsy: Nice work,That\'s gonna be great if...',
      'time': '16:02',
      'unreadCount': 4,
      'avatars': [
        'assets/images/chat/avatar.png',
        'assets/images/chat/avatar.png',
        'assets/images/chat/avatar.png',
        'assets/images/chat/avatar.png',
      ],
    },
    {
      'type': 'chat',
      'title': 'Kristen',
      'subtitle': 'chat_image', // 使用 key
      'time': '16:00',
      'unreadCount': 0,
      'avatars': ['assets/images/chat/avatar.png'],
    },
    {
      'type': 'chat',
      'title': 'Dirac',
      'subtitle': 'You have unread about GameFi?',
      'time': '15:24',
      'unreadCount': 0,
      'isMuted': true,
      'avatars': ['assets/images/chat/avatar.png'],
    },
    {
      'type': 'chat',
      'title': 'Joey',
      'subtitle': 'That\'s right😎',
      'time': '12:09',
      'unreadCount': 0,
      'avatars': ['assets/images/chat/avatar.png'],
    },
    {
      'type': 'chat',
      'title': 'Kristen',
      'subtitle': 'Let\'s play together on the weekend ! Do you a...',
      'time': '10:49',
      'unreadCount': 0,
      'avatars': ['assets/images/chat/avatar.png'],
    },
    {
      'type': 'chat',
      'title': 'John Gonzales',
      'subtitle': 'OK',
      'time': '09:17',
      'unreadCount': 0,
      'avatars': ['assets/images/chat/avatar.png'],
    },
    {
      'type': 'chat',
      'title': 'Work project',
      'subtitle': 'Linsy: Nice work,That\'s gonna be great if...',
      'time': 'chat_yesterday', // 使用 key
      'unreadCount': 0,
      'avatars': [
        'assets/images/chat/avatar.png',
        'assets/images/chat/avatar.png',
        'assets/images/chat/avatar.png',
        'assets/images/chat/avatar.png',
      ],
    },
  ];

  final List<Map<String, dynamic>> _mockContacts = [
    {
      'initial': 'chat_group', // 使用 key
      'type': 'header',
    },
    {
      'initial': 'chat_star_friend', // 使用 key
      'contacts': [
        {'name': 'Kristen', 'avatar': 'assets/images/chat/avatar.png', 'isStar': true},
        {'name': 'John Bonzales', 'avatar': 'assets/images/chat/avatar.png', 'isStar': true},
      ]
    },
    {
      'initial': 'P',
      'contacts': [
        {'name': 'Patrick', 'avatar': 'assets/images/chat/avatar.png'},
        {'name': 'Pius', 'avatar': 'assets/images/chat/avatar.png'},
        {'name': 'Padraic', 'avatar': 'assets/images/chat/avatar.png'},
        {'name': 'Pat', 'avatar': 'assets/images/chat/avatar.png'},
        {'name': 'Philemen', 'avatar': 'assets/images/chat/avatar.png'},
      ]
    },
    {
      'initial': 'Q',
      'contacts': [
        {'name': 'Albert Flores', 'avatar': 'assets/images/chat/avatar.png'},
        {'name': 'Annette Black', 'avatar': 'assets/images/chat/avatar.png'},
      ]
    },
    {
      'initial': 'R',
      'contacts': [
        {'name': 'Ralph Edwards', 'avatar': 'assets/images/chat/avatar.png'},
      ]
    }
  ];

  final List<String> _indexLetters = [
    '★', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
  ];

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
    // 简单的过滤逻辑，为了演示切换 Tab 时的空状态效果
    // 0: All, 1: Message, 2: DAO, 3: Club, 4: Others
    final filteredChats = _mockChats.where((chat) {
      if (_selectedFilterIndex == 0) return true; // All
      if (_selectedFilterIndex == 1) return chat['type'] == 'chat' || chat['type'] == 'system'; // Message
      return false; // DAO, Club, Others 暂无数据
    }).toList();

    return Column(
      children: [
        _buildFriendRequestCard(),
        _buildFilterBar(),
        Expanded(
          child: filteredChats.isEmpty
              ? AppEmptyView(
                  text: AppLocalizations.of(context)!.chatSearchNoData,
                  bottomOffset: 50, // 调整偏移，视觉更平衡
                )
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: filteredChats.length,
                  itemBuilder: (context, index) {
                    final item = filteredChats[index];
                    if (item['type'] == 'system') {
                      return SystemNotificationItem(
                        title: item['title'] == 'chat_notification_title'
                            ? AppLocalizations.of(context)!.chatNotificationTitle
                            : item['title'],
                        subtitle: item['subtitle'],
                        time: item['time'] == 'chat_yesterday'
                            ? AppLocalizations.of(context)!.chatYesterday
                            : item['time'],
                        unreadCount: item['unreadCount'],
                        icon: item['icon'],
                        iconBgColor: item['iconBgColor'],
                        onTap: () => _navigateToDetail(item['title']),
                      );
                    } else {
                      return ChatListItem(
                        title: item['title'],
                        subtitle: item['subtitle'] == 'chat_image'
                            ? AppLocalizations.of(context)!.chatImage
                            : (item['subtitle'] == 'chat_voice'
                                ? AppLocalizations.of(context)!.chatVoice
                                : item['subtitle']),
                        time: item['time'] == 'chat_yesterday'
                            ? AppLocalizations.of(context)!.chatYesterday
                            : item['time'],
                        unreadCount: item['unreadCount'],
                        avatars: item['avatars'],
                        isMuted: item['isMuted'] ?? false,
                        onTap: () => _navigateToDetail(item['title']),
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
    if (_mockContacts.isEmpty) {
      return AppEmptyView(
        text: AppLocalizations.of(context)!.chatSearchNoData,
      );
    }
    return Stack(
      key: _contactsStackKey,
      children: [
        ListView.builder(
          controller: _contactScrollController,
          padding: EdgeInsets.zero,
          itemCount: _mockContacts.length,
          itemBuilder: (context, index) {
            final group = _mockContacts[index];
            if (group['type'] == 'header') {
              return _buildGroupHeader();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 分组首字母
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    group['initial'] == 'chat_group' 
                        ? AppLocalizations.of(context)!.chatGroup 
                        : (group['initial'] == 'chat_star_friend' 
                            ? AppLocalizations.of(context)!.chatStarFriend 
                            : group['initial']),
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.grey400,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                // 联系人列表
                ...List.generate(
                  group['contacts'].length,
                  (i) => ContactItem(
                    name: group['contacts'][i]['name'],
                    avatar: group['contacts'][i]['avatar'],
                    isStar: group['contacts'][i]['isStar'] ?? false,
                    showDivider: i != group['contacts'].length - 1,
                    onTap: () => _navigateToDetail(group['contacts'][i]['name']),
                  ),
                ),
              ],
            );
          },
        ),
        // 右侧索引栏
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
                        TextSpan(text: AppLocalizations.of(context)!.chatGroupManageCount(3)),
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

  /// 滚动到指定的首字母位置
  void _scrollToInitial(String initial) {
    int targetIndex = _mockContacts.indexWhere((group) => group['initial'] == initial);
    if (targetIndex != -1) {
      double offset = 0;
      for (int i = 0; i < targetIndex; i++) {
        final group = _mockContacts[i];
        if (group['type'] == 'header') {
          offset += 76.0; // GroupHeader 高度
        } else {
          offset += 36.0; // 分组标题高度
          offset += (group['contacts'] as List).length * 76.0; // 联系人高度
        }
      }
      _contactScrollController.jumpTo(offset); // 使用 jumpTo 实现即时跟随
    }
  }

  void _navigateToDetail(String title) {
    final encodedName = Uri.encodeComponent(title);
    context.push('/chat-detail/$encodedName');
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
      AppLocalizations.of(context)!.chatFilterAllCount(8),
      AppLocalizations.of(context)!.chatFilterMessageCount(10),
      AppLocalizations.of(context)!.chatFilterDaoCount(50),
      AppLocalizations.of(context)!.chatFilterClubCount(90),
      AppLocalizations.of(context)!.chatFilterOthers
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
