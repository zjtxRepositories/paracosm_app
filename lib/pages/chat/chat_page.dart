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
import '../../modules/im/manager/im_engine_manager.dart';
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
  bool _isChatSelected = true;
  int _selectedFilterIndex = 0;
  final ScrollController _contactScrollController = ScrollController();
  int _friendApplicationUnhandledCount = 0;

  /// =========================
  /// Stream 管理（避免泄漏）
  /// =========================
  final List<StreamSubscription> _subs = [];

  IMEngineManager _engineManager = IMEngineManager();
  List<ConversationModel> _conversations = [];
  List<RCIMIWFriendInfo> _friends = [];
  List<RCIMIWGroupInfo> _groups = [];
  Map<int, List<RCIMIWConversation>>? _tabCache;

  final resolver = ConversationResolver();

  bool _inited = false;

  @override
  void initState() {
    super.initState();
    initListener();
  }

  void initListener() {
    if (_inited) return;
    _inited = true;

    final sub = _engineManager.connection
        .eventStream
        .listen((event) {
      if (event == ImEvent.connected) {
        fetchData();
      }
    });

    _subs.add(sub);
  }

  /// =========================
  /// 数据入口
  /// =========================
  void fetchData() {
    _fetchFriendApplication();
    _fetchConversation();
    _fetchContact();
    _fetchGroup();
  }

  /// =========================
  /// 好友申请（防重复监听）
  /// =========================
  void _fetchFriendApplication() {
    final sub = _engineManager.friendApplication.stream.listen((list) {
      if (!mounted) return;

      setState(() {
        _friendApplicationUnhandledCount =
            _engineManager.friendApplication.unhandledCount;
      });
    });

    _subs.add(sub);

    _engineManager.friendApplication.fetch();
  }

  /// =========================
  /// 会话（核心优化）
  /// =========================
  void _fetchConversation() {
    final sub = _engineManager.conversation.stream.listen((map) {
      if (!mounted) return;

      _tabCache = map;
      _refreshConversation();
    });

    _subs.add(sub);
    // _engineManager.conversation.initAllTabs();
  }

  /// =========================
  /// 刷新会话（减少 rebuild）
  /// =========================
  void _refreshConversation() {
    final list =
    _engineManager.conversation.getTabList(_selectedFilterIndex);

    _conversations =
        list.map((e) => ConversationModel(info: e)).toList();

    if (mounted) {
      setState(() {});
    }

    _resolveConversation(_conversations);
  }

  /// =========================
  /// 联系人
  /// =========================
  void _fetchContact() {
    final sub = _engineManager.friend.stream.listen((list) {
      if (!mounted) return;

      setState(() {
        _friends = list;
      });
    });

    _subs.add(sub);

    _engineManager.friend.fetchFriends();
  }

  /// =========================
  /// 群组
  /// =========================
  void _fetchGroup() {
    final sub = _engineManager.group.stream.listen((list) {
      if (!mounted) return;

      setState(() {
        _groups = list;
      });
    });

    _subs.add(sub);

    _engineManager.group.getAllJoinedGroups();
  }

  /// =========================
  /// 分批解析（防卡顿优化）
  /// =========================
  Future<void> _resolveConversation(
      List<ConversationModel> models,
      ) async {
    const batchSize = 10;

    for (int i = 0; i < models.length; i += batchSize) {
      final batch = models.skip(i).take(batchSize);

      await Future.wait(
        batch.map((m) => resolver.resolve(m)),
      );

      if (!mounted) return;

      setState(() {}); // 局部刷新
    }
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }

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
                  userId: item.info.targetId,
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
              _refreshConversation();
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
