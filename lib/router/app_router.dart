import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/core/models/community_model.dart';
import 'package:paracosm/core/models/group_model.dart';
import 'package:paracosm/core/models/moment_post_model.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/call/rong_call_types.dart';
import 'package:paracosm/modules/wallet/model/token_model.dart';
import 'package:paracosm/modules/wallet/model/wallet_model.dart';
import 'package:paracosm/pages/dapp/dapp_page.dart';
import 'package:paracosm/pages/profile/add_token_manager_page.dart';
import 'package:paracosm/pages/profile/token_manager_page.dart';
import 'package:paracosm/pages/wallet/wallet_backup_mnemonic_page.dart';
import 'package:paracosm/pages/wallet/wallet_import_private_key_page.dart';
import 'package:paracosm/widgets/business/main_tab_scaffold.dart';
import 'package:paracosm/pages/chat/home/chat_page.dart';
import 'package:paracosm/pages/chat/chat_group_video_page.dart';
import 'package:paracosm/pages/chat/chat_group_voice_page.dart';
import 'package:paracosm/pages/chat/chat_combine_forward_detail_page.dart';
import 'package:paracosm/pages/chat/chat_private_video_page.dart';
import 'package:paracosm/pages/chat/chat_private_voice_page.dart';
import 'package:paracosm/pages/chat/chat_scan_page.dart';
import 'package:paracosm/pages/chat/friend_request_page.dart';
import 'package:paracosm/pages/chat/detail/chat_detail_page.dart';
import 'package:paracosm/pages/chat/chat_session_args.dart';
import 'package:paracosm/pages/chat/session_details_page.dart';
import 'package:paracosm/pages/chat/group_introduction_page.dart';
import 'package:paracosm/pages/chat/group_information_page.dart';
import 'package:paracosm/pages/chat/group_applications_page.dart';
import 'package:paracosm/pages/chat/group_join_invite_settings_page.dart';
import 'package:paracosm/pages/chat/group_qr_code_page.dart';
import 'package:paracosm/pages/chat/group_detail/group_details_page.dart';
import 'package:paracosm/pages/chat/chat_history_search_page.dart';
import 'package:paracosm/pages/chat/chat_search_page.dart';
import 'package:paracosm/pages/chat/user_profile_page.dart';
import 'package:paracosm/pages/chat/group_list_page.dart';
import 'package:paracosm/pages/moments/home/moments_page.dart';
import 'package:paracosm/pages/moments/message_center_page.dart';
import 'package:paracosm/pages/moments/moment_blocked_users_page.dart';
import 'package:paracosm/pages/moments/moment_collections_page.dart';
import 'package:paracosm/pages/moments/moment_relation_list_page.dart';
import 'package:paracosm/pages/moments/post/new_post_page.dart';
import 'package:paracosm/pages/moments/moment_post_detail_page.dart';
import 'package:paracosm/pages/moments/moment_user_profile_page.dart';
import 'package:paracosm/pages/moments/report_page.dart';
import 'package:paracosm/pages/moments/report_detail_page.dart';
import 'package:paracosm/pages/community/community_page.dart';
import 'package:paracosm/pages/community/community_detail_page.dart';
import 'package:paracosm/pages/community/create_dao_page.dart';
import 'package:paracosm/pages/community/create_club_page.dart';
import 'package:paracosm/pages/discover/discover_page.dart';
import 'package:paracosm/pages/discover/discover_list_page.dart';
import 'package:paracosm/pages/discover/discover_search_page.dart';
import 'package:paracosm/pages/profile/profile_page.dart';
import 'package:paracosm/pages/profile/profile_details_page.dart';
import 'package:paracosm/pages/profile/qr_code_page.dart';
import 'package:paracosm/pages/profile/transfer_page.dart';
import 'package:paracosm/pages/profile/transfer_details_page.dart';
import 'package:paracosm/pages/profile/wallet_manager_page.dart';
import 'package:paracosm/pages/profile/wallet_edit_page.dart';
import 'package:paracosm/pages/profile/token_detail_page.dart';
import 'package:paracosm/pages/profile/token_market_page.dart';
import 'package:paracosm/pages/profile/token_receive_page.dart';
import 'package:paracosm/pages/profile/token_network_page.dart';
import 'package:paracosm/pages/profile/language_settings_page.dart';
import 'package:paracosm/pages/profile/about_page.dart';
import 'package:paracosm/pages/profile/node_settings_page.dart';
import 'package:paracosm/pages/profile/node_detail_page.dart';
import 'package:paracosm/pages/profile/pcosm_detail_page.dart';
import 'package:paracosm/pages/wallet/wallet_start_page.dart';
import 'package:paracosm/pages/wallet/wallet_setup_page.dart';
import 'package:paracosm/pages/wallet/wallet_create_step1_page.dart';
import 'package:paracosm/pages/wallet/wallet_create_step2_page.dart';
import 'package:paracosm/pages/wallet/wallet_create_step3_page.dart';
import 'package:paracosm/pages/wallet/wallet_creating_page.dart';
import 'package:paracosm/pages/wallet/wallet_import_page.dart';
import 'package:paracosm/pages/wallet/wallet_import_password_page.dart';
import 'package:paracosm/pages/wallet/wallet_backup_tips_page.dart';
import 'package:paracosm/pages/wallet/wallet_backup_private_key_page.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../core/models/dApp_hive.dart';

/// 全局路由配置类
class AppRouter {
  // 私有构造函数，防止实例化
  AppRouter._();

  // 根路由导航 Key
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  // 路由配置对象
  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    // initialLocation: '/wallet-start',
    initialLocation: AccountManager().isLogin ? '/chat' : '/wallet-start',
    routes: [
      // 钱包启动页
      GoRoute(
        path: '/wallet-start',
        builder: (context, state) => const WalletStartPage(),
      ),
      // 钱包设置页
      GoRoute(
        path: '/wallet-setup',
        builder: (context, state) => const WalletSetupPage(),
      ),
      // 创建钱包第一步
      GoRoute(
        path: '/wallet-create-step1',
        builder: (context, state) => const WalletCreateStep1Page(),
      ),
      // 创建钱包第二步
      GoRoute(
        path: '/wallet-create-step2',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          final password = data?['password'];
          return WalletCreateStep2Page(password: password);
        },
      ),
      // 创建钱包第三步
      GoRoute(
        path: '/wallet-create-step3',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          final password = data?['password'];
          final mnemonics = data?['mnemonics'];
          return WalletCreateStep3Page(password: password, mnemonic: mnemonics);
        },
      ),
      // 代币网络页
      GoRoute(
        path: '/token-network',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const TokenNetworkPage(),
      ),
      // 正在创建钱包页
      GoRoute(
        path: '/wallet-creating',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          final password = data?['password'];
          final mnemonic = data?['mnemonics'];
          final privateKey = data?['privateKey'];
          // print('data--------$mnemonic');
          return WalletCreatingPage(
            password: password,
            mnemonics: mnemonic,
            privateKey: privateKey,
          );
        },
      ),
      // 导入钱包页
      GoRoute(
        path: '/wallet-import',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          final password = data?['password'];
          return WalletImportPage(password: password);
        },
      ),
      // 导入私钥页
      GoRoute(
        path: '/wallet-import-private-key',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          final password = data?['password'];
          final walletId = data?['walletId'];
          final chainType = data?['chainType'];
          return WalletImportPrivateKeyPage(
            password: password,
            walletId: walletId,
            chainType: chainType,
          );
        },
      ),
      // 导入设置密码页
      GoRoute(
        path: '/wallet-import-password',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          final mnemonic = data?['mnemonic'];
          final privateKey = data?['privateKey'];
          return WalletImportPasswordPage(
            mnemonic: mnemonic,
            privateKey: privateKey,
          );
        },
      ),
      // 备份提示页
      GoRoute(
        path: '/wallet-backup-tips',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          final password = data?['password'];
          final nextPath =
              state.uri.queryParameters['nextPath'] ?? '/wallet-create-step2';
          return WalletBackupTipsPage(nextPath: nextPath, password: password);
        },
      ),
      // 备份私钥页
      GoRoute(
        path: '/wallet-backup-private-key',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          final privateKey = data?['privateKey'];
          return WalletBackupPrivateKeyPage(privateKey: privateKey);
        },
      ),
      // 备份助记词页
      GoRoute(
        path: '/wallet-backup-mnemonic',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          final mnemonic = data?['mnemonic'];
          return WalletBackupMnemonicPage(mnemonic: mnemonic);
        },
      ),
      // 备份风险确认页
      // GoRoute(
      //   path: '/wallet-backup-risk',
      //   builder: (context, state) {
      //     final data = state.extra as Map<String, dynamic>?;
      //     final password = data?['password'];
      //     final nextPath = state.uri.queryParameters['nextPath'] ?? '/wallet-create-step2';
      //     return WalletBackupRiskPage(nextPath: nextPath, password: password);
      //   },
      // ),
      // 消息中心页
      GoRoute(
        path: '/message-center',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const MessageCenterPage(),
      ),
      // 新建帖子页
      GoRoute(
        path: '/new-post',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final communityId = state.extra as String?;
          return NewPostPage(
            isRetweet: state.uri.queryParameters['retweet'] == '1',
            communityId: communityId,
          );
        },
      ),
      GoRoute(
        path: '/moment-post-detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          final item = data?['item'];
          final noteId = data?['noteId']?.toString();
          if (item is MomentPostModel) {
            return MomentPostDetailPage(
              item: item,
              isFollowing: data?['isFollowing'] == true,
              isBlock: data?['isBlock'] == true,
            );
          }
          if (noteId != null && noteId.isNotEmpty) {
            return MomentPostDetailPage(noteId: noteId);
          }
          return const SizedBox();
        },
      ),

      GoRoute(
        path: '/moment-blocked-users',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const MomentBlockedUsersPage(),
      ),
      GoRoute(
        path: '/moment-collections',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const MomentCollectionsPage(),
      ),
      GoRoute(
        path: '/moment-following',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final userId = state.uri.queryParameters['userId'] ?? '';
          return MomentRelationListPage(
            type: MomentRelationListType.following,
            userId: userId,
          );
        },
      ),
      GoRoute(
        path: '/moment-followers',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final userId = state.uri.queryParameters['userId'] ?? '';
          return MomentRelationListPage(
            type: MomentRelationListType.fans,
            userId: userId,
          );
        },
      ),
      GoRoute(
        path: '/moment-user-profile',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          final mode = state.uri.queryParameters['mode'] ?? 'friend';
          var userId = '';
          var imUserId = '';
          if (extra is String) {
            userId = extra;
          } else if (extra is Map<String, dynamic>) {
            userId = extra['userId']?.toString() ?? '';
            imUserId = extra['imUserId']?.toString() ?? '';
          }
          if (userId.isEmpty && mode == 'self') {
            final account = AccountManager().currentAccount;
            userId = account?.userId.toLowerCase() ?? '';
            imUserId = account?.accountId ?? '';
          }
          return MomentUserProfilePage(
            userId: userId,
            imUserId: imUserId,
            mode: mode,
          );
        },
      ),
      GoRoute(
        path: '/moment-report',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const MomentReportPage(),
      ),
      GoRoute(
        path: '/moment-report-detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const MomentReportDetailPage(),
      ),
      // 主 Tab 路由分支配置
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // 使用 MainTabScaffold 作为 Tab 导航的外壳
          return MainTabScaffold(navigationShell: navigationShell);
        },
        branches: [
          // 分支 1: 聊天列表
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) => const ChatPage(),
              ),
            ],
          ),
          // 分支 2: 动态/朋友圈
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/moments',
                builder: (context, state) => const MomentsPage(),
              ),
            ],
          ),
          // 分支 3: 社区
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/community',
                builder: (context, state) => const CommunityPage(),
              ),
            ],
          ),
          // 分支 4: 发现
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',
                builder: (context, state) => const DiscoverPage(),
              ),
            ],
          ),
          // 分支 5: 个人中心
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),

      // 群聊详情页
      GoRoute(
        path: '/group-details',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final args = state.extra as ChatSessionArgs?;
          return GroupDetailsPage(args: args);
        },
      ),
      // 群组信息页
      GoRoute(
        path: '/group-information',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          final group = extra is GroupModel
              ? extra
              : extra is Map<String, dynamic>
              ? extra['group'] as GroupModel?
              : null;
          final isJoined = extra is Map<String, dynamic>
              ? extra['isJoined'] as bool? ?? true
              : true;
          final members = extra is Map<String, dynamic>
              ? extra['members'] as List<RCIMIWGroupMemberInfo>? ?? const []
              : const <RCIMIWGroupMemberInfo>[];
          return group == null
              ? SizedBox()
              : GroupInformationPage(
                  group: group,
                  isJoined: isJoined,
                  qrMembers: members,
                );
        },
      ),
      GoRoute(
        path: '/group-applications',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const GroupApplicationsPage(),
      ),
      GoRoute(
        path: '/group-join-invite-settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final group = state.extra as GroupModel?;
          return group == null
              ? const SizedBox()
              : GroupJoinInviteSettingsPage(group: group);
        },
      ),
      // 群二维码页
      GoRoute(
        path: '/group-qr-code',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final group = state.extra as GroupModel?;
          return group == null ? SizedBox() : GroupQrCodePage(group: group);
        },
      ),
      // 群简介编辑页
      GoRoute(
        path: '/group-introduction',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          final title = data?['title'];
          final initialIntroduction = data?['initial'];
          return GroupIntroductionPage(
            initialIntroduction: initialIntroduction,
            title: title,
          );
        },
      ),
      // 详情页：放在 StatefulShellRoute 之外，这样跳转时会隐藏底部导航栏
      GoRoute(
        path: '/chat-detail/:name',
        parentNavigatorKey: rootNavigatorKey, // 显式指定使用根导航器
        builder: (context, state) {
          final args = state.extra as ChatSessionArgs?;
          if (args == null) {
            final name = state.pathParameters['name'] ?? 'Chat';
            return ChatDetailPage.missingArgs(fallbackName: name);
          }
          return ChatDetailPage(sessionArgs: args);
        },
      ),
      GoRoute(
        path: '/chat-combine-forward-detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          final message = extra is RCIMIWCombineV2Message ? extra : null;
          return ChatCombineForwardDetailPage(message: message);
        },
      ),
      GoRoute(
        path: '/chat-private-voice/:name',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final name = state.pathParameters['name'] ?? '';
          final status = ChatCallStatus.fromRoute(
            state.uri.queryParameters['status'],
          );
          return ChatPrivateVoicePage(name: name, status: status);
        },
      ),
      GoRoute(
        path: '/chat-private-video/:name',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final name = state.pathParameters['name'] ?? '';
          final status = ChatCallStatus.fromRoute(
            state.uri.queryParameters['status'],
          );
          final cameraEnabled = state.uri.queryParameters['camera'] != 'off';
          final remoteOnBackdrop =
              state.uri.queryParameters['backdrop'] == 'remote';
          return ChatPrivateVideoPage(
            name: name,
            status: status,
            cameraEnabled: cameraEnabled,
            initialRemoteOnBackdrop: remoteOnBackdrop,
          );
        },
      ),
      GoRoute(
        path: '/chat-group-voice/:name',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final name = state.pathParameters['name'] ?? '';
          final targetId = state.uri.queryParameters['targetId'] ?? '';
          final status = ChatCallStatus.fromRoute(
            state.uri.queryParameters['status'],
          );
          return ChatGroupVoicePage(
            name: name,
            targetId: targetId,
            status: status,
          );
        },
      ),
      GoRoute(
        path: '/chat-group-video/:name',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final name = state.pathParameters['name'] ?? '';
          final targetId = state.uri.queryParameters['targetId'] ?? '';
          final status = ChatCallStatus.fromRoute(
            state.uri.queryParameters['status'],
          );
          final cameraEnabled = state.uri.queryParameters['camera'] != 'off';
          return ChatGroupVideoPage(
            name: name,
            targetId: targetId,
            status: status,
            cameraEnabled: cameraEnabled,
          );
        },
      ),
      // 会话详情页
      GoRoute(
        path: '/session-details/:name',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final name = state.pathParameters['name'] ?? 'Session';
          final extra = state.extra;
          final args = extra is ChatSessionArgs ? extra : null;
          final userId = extra is String ? extra : args?.targetId;
          return SessionDetailsPage(
            name: args?.name ?? name,
            userId: userId ?? '',
            sessionArgs: args,
          );
        },
      ),
      // 社区详情页
      GoRoute(
        path: '/community-detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final model = state.extra as CommunityModel?;
          return model == null
              ? SizedBox()
              : CommunityDetailPage(communityModel: model);
        },
      ),
      // 创建 DAO 页
      GoRoute(
        path: '/create-dao',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final data = state.extra as TokenModel?;
          return data == null ? SizedBox() : CreateDaoPage(token: data);
        },
      ),
      // 创建俱乐部页
      GoRoute(
        path: '/create-club',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CreateClubPage(),
      ),
      // 聊天搜索页
      GoRoute(
        path: '/chat-search',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final type = state.extra as ChatSearchType?;
          return ChatSearchPage(type: type ?? ChatSearchType.all);
        },
      ),
      // 会话内聊天记录搜索页
      GoRoute(
        path: '/chat-history-search',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final args = state.extra as ChatSessionArgs?;
          return args == null
              ? const SizedBox()
              : ChatHistorySearchPage(sessionArgs: args);
        },
      ),
      // 好友申请页
      GoRoute(
        path: '/friend-request',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const FriendRequestPage(),
      ),
      // 用户资料页
      GoRoute(
        path: '/user-profile',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final userId = state.extra as String?;
          return UserProfilePage(userId: userId ?? '');
        },
      ),
      // 群组列表页
      GoRoute(
        path: '/group-list',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final list = state.extra as List<RCIMIWGroupInfo>?;
          return GroupListPage(groups: list ?? []);
        },
      ),
      // 发现列表页
      GoRoute(
        path: '/discover-list/:title',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final title = state.pathParameters['title'] ?? 'Discover';
          final data = state.extra as List<DAppHive>?;
          return DiscoverListPage(title: title, dappList: data ?? []);
        },
      ),
      // 发现搜索页
      GoRoute(
        path: '/discover-search',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final data = state.extra as List<DAppHive>?;
          return DiscoverSearchPage(dapps: data ?? []);
        },
      ),
      // 通用二维码/条形码扫描页
      GoRoute(
        path: '/qr-scan',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ChatScanPage(),
      ),
      // dapp详情
      GoRoute(
        path: '/dapp',
        builder: (context, state) {
          final dApp = state.extra as DAppHive?;
          return dApp == null ? SizedBox() : DAppPage(dapp: dApp);
        },
      ),
      // 个人资料详情页
      GoRoute(
        path: '/profile-details',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ProfileDetailsPage(),
      ),
      // 二维码页
      GoRoute(
        path: '/qr-code',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final userId = state.extra as String?;
          return QrCodePage(userId: userId ?? '');
        },
      ),
      // 转账页
      GoRoute(
        path: '/transfer',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          final token = data?['token'];
          final chain = data?['chain'];
          return TransferPage(
            token: token,
            chain: chain,
            prefillAddress: data?['prefillAddress'] as String?,
            prefillAmount: data?['prefillAmount'] as String?,
          );
        },
      ),
      // 转账详情页
      GoRoute(
        path: '/transfer-details',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          final token = data?['token'];
          final tx = data?['tx'];
          return TransferDetailsPage(token: token, tx: tx);
        },
      ),
      // 钱包管理页
      GoRoute(
        path: '/wallet-manager',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const WalletManagerPage(),
      ),
      // 钱包编辑页
      GoRoute(
        path: '/wallet-edit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final wallet = state.extra as WalletModel?;
          if (wallet == null) return SizedBox();
          return WalletEditPage(wallet: wallet);
        },
      ),
      // 代币详情页
      GoRoute(
        path: '/token-detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as TokenModel?;
          return extra == null ? SizedBox() : TokenDetailPage(token: extra);
        },
      ),
      // 币种管理页
      GoRoute(
        path: '/token-manager',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          return TokenManagerPage();
        },
      ),
      // 新增币种
      GoRoute(
        path: '/add-token-manager',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          return AddTokenManagerPage();
        },
      ),
      // 代币市场/K线页
      GoRoute(
        path: '/token-market',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return TokenMarketPage(symbol: extra?['symbol'] ?? 'BTC/USDT');
        },
      ),
      // 代币收款页
      GoRoute(
        path: '/token-receive',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return TokenReceivePage(
            tokenSymbol: extra?['symbol'] ?? 'BNB',
            networkName: extra?['network'] ?? 'Binancestry(BSC)',
            walletAddress:
                extra?['address'] ??
                '0xc84sa01ua125d15uvcbv78fa98uu9daccf915uvc',
            tokenLogo: extra?['logo'] ?? '',
            chainId: extra?['chainId'] as int?,
          );
        },
      ),
      // 语言设置页
      GoRoute(
        path: '/language-settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const LanguageSettingsPage(),
      ),
      // 关于页面
      GoRoute(
        path: '/about',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AboutPage(),
      ),
      // 节点设置页
      GoRoute(
        path: '/node-settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const NodeSettingsPage(),
      ),
      // 节点详情页
      GoRoute(
        path: '/node-detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final chainName = state.extra as String? ?? 'Ethereum';
          return NodeDetailPage(chainName: chainName);
        },
      ),
      // pCOSM 详情页
      GoRoute(
        path: '/pcosm-detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PcosmDetailPage(),
      ),
    ],
  );
}
