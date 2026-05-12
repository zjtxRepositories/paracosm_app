import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/core/models/conversation_model.dart';
import 'package:paracosm/core/models/group_model.dart';
import 'package:paracosm/modules/im/manager/im_conversation_manager.dart';
import 'package:paracosm/modules/im/message/send/im_sender.dart';
import 'package:paracosm/modules/scan/scan_result_handler.dart';
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
import 'package:paracosm/widgets/common/app_loading.dart';
import 'package:paracosm/widgets/common/app_toast.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import '../../../core/models/custom_message_model.dart';
import '../../../modules/im/manager/im_connection_manager.dart';
import '../../../modules/im/manager/im_engine_manager.dart';
import 'package:paracosm/widgets/common/app_empty_view.dart';

import '../../../modules/im/manager/im_group_manager.dart';
import '../../../modules/im/message/base/im_message.dart';
import '../contacts_view.dart';
import 'chat_controller.dart';

/// 聊天主列表页面
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final GlobalKey _addButtonKey = GlobalKey();
  final ScrollController _contactScrollController = ScrollController();
  late final ChatController controller;

  @override
  void initState() {
    super.initState();
    controller = ChatController();
    controller.init();
  }
  @override
  void dispose() {
    controller.dispose();
    _contactScrollController.dispose();

    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (_, __) {
        return AppPage(
          showNav: true,
          showBack: false,
          isCustomHeader: true,
          renderCustomHeader: _buildCustomHeader(context),
          child: controller.isChatSelected
              ? _buildChatView()
              : _buildContactsView(),
        );
      },
    );
  }

  /// 构建聊天列表视图
  Widget _buildChatView() {
    return Column(
      children: [
        _buildFriendRequestCard(),
        _buildFilterBar(),
        Expanded(
          child: controller.conversations.isEmpty
              ? AppEmptyView(
                  text: AppLocalizations.of(context)!.chatSearchNoData,
                  bottomOffset: 50, // 调整偏移，视觉更平衡
                )
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: controller.conversations.length,
                  itemBuilder: (context, index) {
                    final item = controller.conversations[index];
                    if (item.info.conversationType ==
                        RCIMIWConversationType.system) {
                      return SystemNotificationItem(
                        title: AppLocalizations.of(
                          context,
                        )!.chatNotificationTitle,
                        subtitle: 'sub',
                        time: AppLocalizations.of(context)!.chatYesterday,
                        unreadCount: 1,
                        icon: Icons.nat,
                        // iconBgColor: item['iconBgColor'],
                        // onTap: () => _navigateToDetail(item['title']),
                      );
                    } else {
                      return ListenableBuilder(
                        listenable: item,
                        builder: (_, __) {
                          return ChatListItem(
                            title: item.title ?? '',
                            subtitle: item.subtitle ?? '',
                            time: formatIMTime(item.time),
                            unreadCount: item.info.unreadCount ?? 0,
                            avatar: item.portraitUri ?? '',
                            targetId: item.info.targetId,
                            isGroup:
                            item.info.conversationType ==
                                RCIMIWConversationType.group,
                            isMuted: false,
                            onTap: () {
                              controller.navigateToConversationDetail(
                                context,
                                item.info,
                                item.title ?? '',
                                item.portraitUri,
                              );
                            },
                          );
                        },
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
    return controller.friendApplicationUnhandledCount == 0
        ? SizedBox()
        : GestureDetector(
            onTap: () => context.push('/friend-request'),
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 4, 20, 16),
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
                                  TextSpan(
                                    text: AppLocalizations.of(context)!
                                        .chatFriendRequestCount(
                                      controller.friendApplicationUnhandledCount,
                                        ),
                                  ),
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
      friends:controller.friends,
      groups: controller.groups,
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
      onTap: () => context.push('/group-list',extra: controller.groups),
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
                        TextSpan(
                          text: AppLocalizations.of(
                            context,
                          )!.chatGroupManageCount(controller.groups.length),
                        ),
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
    context.push('/user-profile', extra: userId);
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
              controller.switchTab(true);
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (controller.isChatSelected)
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
                    fontSize:controller.isChatSelected ? 24 : 16,
                    color: controller.isChatSelected
                        ? AppColors.grey900
                        : AppColors.grey400,
                    fontWeight: controller.isChatSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Contacts Tab
          GestureDetector(
            onTap: () {
              controller.switchTab(false);
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (!controller.isChatSelected)
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
                    fontSize: !controller.isChatSelected ? 24 : 16,
                    color: !controller.isChatSelected
                        ? AppColors.grey900
                        : AppColors.grey400,
                    fontWeight: !controller.isChatSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => context.push('/chat-search'),
            icon: Image.asset(
              'assets/images/chat/search.png',
              width: 32,
              height: 32,
            ),
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
                      context.push('/chat-search', extra: ChatSearchType.user);
                    },
                  ),
                  AppActionPopMenuItem(
                    icon: 'assets/images/chat/create-group.png',
                    label: l10n.chatMenuCreateGroup,
                    onTap: () async {
                      controller.createNormalGroup(context);
                    },
                  ),
                  AppActionPopMenuItem(
                    icon: 'assets/images/chat/scanner.png',
                    label: l10n.chatMenuScan,
                    onTap: () {
                      ScanResultHandler.scanAndHandle(context);
                    },
                  ),
                ],
              );
            },
            icon: Image.asset(
              'assets/images/chat/add.png',
              width: 32,
              height: 32,
            ),
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
      AppLocalizations.of(
        context,
      )!.chatFilterAllCount(controller.tabCache?[0]?.length ?? 0),

      '私聊 ${controller.tabCache?[1]?.length ?? 0}',

      '群聊 ${controller.tabCache?[2]?.length ?? 0}',

      AppLocalizations.of(
        context,
      )!.chatFilterClubCount(controller.tabCache?[3]?.length ?? 0),

      AppLocalizations.of(context)!.chatFilterDaoCount(0),
    ];
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final isSelected = index == controller.selectedFilterIndex;
          return GestureDetector(
            onTap: () {
              controller.switchFilter(index);
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
                            color: AppColors.grey900,
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
