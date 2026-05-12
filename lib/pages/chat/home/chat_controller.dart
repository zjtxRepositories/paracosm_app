import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../../core/models/conversation_model.dart';
import '../../../core/models/custom_message_model.dart';
import '../../../core/models/group_model.dart';
import '../../../modules/im/manager/im_connection_manager.dart';
import '../../../modules/im/manager/im_conversation_manager.dart';
import '../../../modules/im/manager/im_engine_manager.dart';
import '../../../modules/im/manager/im_group_manager.dart';
import '../../../modules/im/message/base/im_message.dart';
import '../../../modules/im/message/send/im_sender.dart';
import '../../../widgets/chat/select_members_modal.dart';
import '../../../widgets/common/app_loading.dart';
import '../../../widgets/common/app_toast.dart';
import '../chat_session_args.dart';

class ChatController extends ChangeNotifier {
  ChatController._();

  static final ChatController _instance = ChatController._();

  factory ChatController() {
    return _instance;
  }
  final IMEngineManager _engineManager = IMEngineManager();

  final List<StreamSubscription> _subs = [];

  final resolver = ConversationResolver();

  bool isChatSelected = true;

  int selectedFilterIndex = 0;

  int friendApplicationUnhandledCount = 0;

  List<ConversationModel> conversations = [];

  List<RCIMIWFriendInfo> friends = [];

  List<RCIMIWGroupInfo> groups = [];

  Map<int, List<RCIMIWConversation>>? tabCache;

  bool _inited = false;
  final Map<String, ConversationModel> _conversationMap = {};

  /// 初始化
  void init() {
    if (_inited) return;

    _inited = true;

    _listenConnection();
    _fetchConversation();
    _fetchContact();
    _fetchGroup();
    _fetchFriendApplication();
  }

  /// =========================
  /// connection
  /// =========================

  void _listenConnection() {
    final sub = _engineManager.connection.eventStream.listen((event) {
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
    _engineManager.friendApplication.fetch();
    _engineManager.friend.fetchFriends();
    _engineManager.group.getAllJoinedGroups();
    refreshConversation();
  }

  /// =========================
  /// friend request
  /// =========================

  void _fetchFriendApplication() {
    final sub = _engineManager.friendApplication.stream.listen((list) {
      friendApplicationUnhandledCount =
          _engineManager.friendApplication.unhandledCount;

      notifyListeners();
    });

    _subs.add(sub);
  }

  /// =========================
  /// conversation
  /// =========================

  void _fetchConversation() {
    final sub = _engineManager.conversation.stream.listen((map) {
      tabCache = map;

      refreshConversation();
    });

    _subs.add(sub);
  }

  Future<void> refreshConversation() async {
    final list = _engineManager.conversation.getTabList(selectedFilterIndex);

    final temp = <ConversationModel>[];

    for (final item in list) {
      final targetId = item.targetId ?? '';

      ConversationModel model;

      if (_conversationMap.containsKey(targetId)) {
        model = _conversationMap[targetId]!;

        model.updateConversation(item);
        resolve(model);
      } else {
        model = ConversationModel(info: item);
        resolve(model);
      }
      temp.add(model);
    }

    conversations = temp;

    notifyListeners();
  }

  Future<void> resolve(ConversationModel model) async {
    if (!_engineManager.connection.isConnected) return;
    await resolver.resolve(model);
    _conversationMap[model.info.targetId ?? ''] = model;
  }

  /// =========================
  /// 联系人
  /// =========================

  void _fetchContact() {
    final sub = _engineManager.friend.stream.listen((list) {
      friends = list;

      notifyListeners();
    });

    _subs.add(sub);
  }

  /// =========================
  /// 群组
  /// =========================

  void _fetchGroup() {
    final sub = _engineManager.group.stream.listen((list) {
      groups = list;

      notifyListeners();
    });

    _subs.add(sub);
  }

  /// =========================
  /// tab
  /// =========================

  void switchTab(bool isChat) {
    isChatSelected = isChat;

    notifyListeners();
  }

  void switchFilter(int index) {
    selectedFilterIndex = index;

    refreshConversation();
  }

  /// =========================
  /// event
  /// =========================
  Future<void> createNormalGroup(BuildContext context) async {
    final result = await SelectMembersModal.show(context, friends: friends);
    if (result != null) {
      AppLoading.show();
      final groupId = await ImGroupManager().create(
        inviteeUserIds: result,
        groupId: generateGroupId(GroupType.normal),
      );
      if (groupId == null) {
        AppLoading.dismiss();
        AppToast.show('创建群组失败');
        return;
      }
      final message = CustomMessage(
        targetId: groupId,
        customMessageType: CustomMessageType.groupInvited,
        conversationType: RCIMIWConversationType.group,
      );
      final isSend = await ImSender.instance.send(message: message);
      AppLoading.dismiss();
      if (!isSend) return;
      final conversation = await ImConversationManager().getConversation(
        type: RCIMIWConversationType.group,
        targetId: groupId,
      );
      if (conversation == null) return;
      final model = ConversationModel(info: conversation);
      await ConversationResolver().resolve(model);
      if (!context.mounted) return;
      navigateToConversationDetail(
        context,
        conversation,
        model.title ?? '',
        model.portraitUri,
      );
    }
  }

  void navigateToConversationDetail(
    BuildContext context,
    RCIMIWConversation conversation,
    String title,
    String? avatar,
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
        avatar: avatar,
      ),
    );
  }

  /// =========================
  /// dispose
  /// =========================

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }

    super.dispose();
  }
}
