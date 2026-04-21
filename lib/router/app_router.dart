import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/core/network/models/dApp_hive.dart';
import 'package:paracosm/core/network/models/social_Invitation_model.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/wallet/model/token_model.dart';
import 'package:paracosm/modules/wallet/model/wallet_model.dart';
import 'package:paracosm/pages/dapp/dapp_page.dart';
import 'package:paracosm/pages/profile/add_token_manager_page.dart';
import 'package:paracosm/pages/profile/token_manager_page.dart';
import 'package:paracosm/pages/wallet/wallet_backup_mnemonic_page.dart';
import 'package:paracosm/pages/wallet/wallet_import_private_key_page.dart';
import 'package:paracosm/widgets/business/main_tab_scaffold.dart';
import 'package:paracosm/pages/chat/chat_page.dart';
import 'package:paracosm/pages/chat/friend_request_page.dart';
import 'package:paracosm/pages/chat/chat_detail_page.dart';
import 'package:paracosm/pages/chat/session_details_page.dart';
import 'package:paracosm/pages/chat/group_introduction_page.dart';
import 'package:paracosm/pages/chat/group_information_page.dart';
import 'package:paracosm/pages/chat/group_details_page.dart';
import 'package:paracosm/pages/chat/chat_search_page.dart';
import 'package:paracosm/pages/chat/user_profile_page.dart';
import 'package:paracosm/pages/chat/group_list_page.dart';
import 'package:paracosm/pages/moments/home/moments_page.dart';
import 'package:paracosm/pages/moments/message_center_page.dart';
import 'package:paracosm/pages/moments/new_post_page.dart';
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
import 'package:paracosm/pages/wallet/wallet_backup_risk_page.dart';

/// 全局路由配置类
class AppRouter {
  // 私有构造函数，防止实例化
  AppRouter._();

  // 根路由导航 Key
  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

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
          return WalletCreateStep3Page(password: password,mnemonic: mnemonics);
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
          return WalletCreatingPage(password: password,mnemonics: mnemonic,privateKey: privateKey,);
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
          return WalletImportPrivateKeyPage(password: password, walletId: walletId, chainType: chainType,);
        },
      ),
      // 导入设置密码页
      GoRoute(
        path: '/wallet-import-password',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          final mnemonic = data?['mnemonic'];
          final privateKey = data?['privateKey'];
          return WalletImportPasswordPage(mnemonic: mnemonic,privateKey: privateKey);
        },
      ),
      // 备份提示页
      GoRoute(
        path: '/wallet-backup-tips',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          final password = data?['password'];
          final nextPath = state.uri.queryParameters['nextPath'] ?? '/wallet-create-step2';
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
      GoRoute(
        path: '/wallet-backup-risk',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          final password = data?['password'];
          final nextPath = state.uri.queryParameters['nextPath'] ?? '/wallet-create-step2';
          return WalletBackupRiskPage(nextPath: nextPath, password: password);
        },
      ),
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
        builder: (context, state) => NewPostPage(
          isRetweet: state.uri.queryParameters['retweet'] == '1',
        ),
      ),
      GoRoute(
        path: '/moment-post-detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          final item = data?['item'];
          final isFollowing = data?['isFollowing'];
          final isBlock = data?['isBlock'];
          return data == null ? SizedBox() : MomentPostDetailPage(item: item, isFollowing: isFollowing, isBlock: isBlock,);
        },
      ),
      
      GoRoute(
        path: '/moment-user-profile',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const MomentUserProfilePage(),
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
        path: '/group-details/:name',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final name = state.pathParameters['name'] ?? 'Group';
          return GroupDetailsPage(groupName: name);
        },
      ),
      // 群组信息页
      GoRoute(
        path: '/group-information/:name',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final name = state.pathParameters['name'] ?? 'Group';
          return GroupInformationPage(groupName: name);
        },
      ),
      // 群简介编辑页
      GoRoute(
        path: '/group-introduction',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final initialIntroduction = state.uri.queryParameters['initialIntroduction'] ?? '';
          return GroupIntroductionPage(initialIntroduction: initialIntroduction);
        },
      ),
      // 详情页：放在 StatefulShellRoute 之外，这样跳转时会隐藏底部导航栏
      GoRoute(
        path: '/chat-detail/:name',
        parentNavigatorKey: rootNavigatorKey, // 显式指定使用根导航器
        builder: (context, state) {
          final name = state.pathParameters['name'] ?? 'Chat';
          return ChatDetailPage(name: name);
        },
      ),
      // 会话详情页
      GoRoute(
        path: '/session-details/:name',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final name = state.pathParameters['name'] ?? 'Session';
          return SessionDetailsPage(name: name);
        },
      ),
      // 社区详情页
      GoRoute(
        path: '/community-detail/:name',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final name = state.pathParameters['name'] ?? 'BKOK持仓群';
          return CommunityDetailPage(communityName: name);
        },
      ),
      // 创建 DAO 页
      GoRoute(
        path: '/create-dao',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CreateDaoPage(),
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
        builder: (context, state) => const ChatSearchPage(),
      ),
      // 好友申请页
      GoRoute(
        path: '/friend-request',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const FriendRequestPage(),
      ),
      // 用户资料页
      GoRoute(
        path: '/user-profile/:name',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final name = state.pathParameters['name'] ?? 'User';
          return UserProfilePage(
            name: name,
            avatarPath: 'assets/images/chat/avatar.png', // 这里暂时写死，后续可以从 state 传参
          );
        },
      ),
      // 群组列表页
      GoRoute(
        path: '/group-list',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const GroupListPage(),
      ),
      // 发现列表页
      GoRoute(
        path: '/discover-list/:title',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final title = state.pathParameters['title'] ?? 'Discover';
          final data = state.extra as List<DAppHive>?;
          return DiscoverListPage(title: title, dappList: data ?? [],);
        },
      ),
      // dapp详情
      GoRoute(
        path: '/dapp',
        builder: (context, state) {
          final dApp = state.extra as DAppHive?;
          // print('data--------$mnemonic');
          return dApp == null ? SizedBox() : DAppPage(dapp: dApp,);
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
        builder: (context, state) => const QrCodePage(),
      ),
      // 转账页
      GoRoute(
        path: '/transfer',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          final token = data?['token'];
          final chain = data?['chain'];
          return TransferPage(token: token, chain: chain);
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
          return WalletEditPage(
            wallet: wallet,
          );
        },
      ),
      // 代币详情页
      GoRoute(
        path: '/token-detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as TokenModel?;
          return extra == null ? SizedBox():TokenDetailPage(
            token: extra,
          );
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
          return TokenMarketPage(
            symbol: extra?['symbol'] ?? 'BTC/USDT',
          );
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
            walletAddress: extra?['address'] ?? '0xc84sa01ua125d15uvcbv78fa98uu9daccf915uvc',
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
