import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../../core/models/conversation_model.dart';
import '../../../core/models/custom_message_model.dart';
import '../../../core/models/group_model.dart';
import '../../../modules/im/listener/im_data_center.dart';
import '../../../modules/im/manager/im_connection_manager.dart';
import '../../../modules/im/manager/im_conversation_manager.dart';
import '../../../modules/im/manager/im_engine_manager.dart';
import '../../../modules/im/manager/im_group_manager.dart';
import '../../../modules/im/message/base/im_message.dart';
import '../../../modules/im/message/send/im_sender.dart';
import '../../../widgets/chat/select_members_modal.dart';
import '../../../widgets/base/app_localizations.dart';
import '../../../widgets/common/app_loading.dart';
import '../../../widgets/common/app_toast.dart';
import '../chat_session_args.dart';

class ChatController extends ChangeNotifier {
  ChatController._();

  static final ChatController _instance = ChatController._();

  factory ChatController() => _instance;

  final IMEngineManager _engineManager = IMEngineManager();

  final List<StreamSubscription> _subs = [];

  final Set<String> _resolvingIds = {};

  Timer? _notifyDebounce;

  bool isChatSelected = true;
  int selectedFilterIndex = 0;

  int friendApplicationUnhandledCount = 0;

  /// =========================
  /// conversations
  /// =========================
  final List<ConversationModel> conversations = [];

  final Map<String, ConversationModel> _conversationMap = {};

  List<RCIMIWFriendInfo> friends = [];
  List<RCIMIWGroupInfo> groups = [];

  Map<int, List<RCIMIWConversation>>? tabCache;

  bool isConversationLoadingMore = false;
  bool hasMoreConversations = true;

  bool _inited = false;

  /// 会话变更订阅
  StreamSubscription? _conversationChangeSub;

  final ImDataCenter _dataCenter = ImDataCenter();

  /// =========================
  /// init
  /// =========================
  void init() {
    if (_inited) return;
    _inited = true;

    _listenConnection();
    _listenConversation();
    _listenFriendList();
    _listenGroupList();
    _listenFriendApplication();
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

    if (_engineManager.connection.isConnected) {
      fetchData();
    }
  }

  /// =========================
  /// 数据入口（只做初始化触发）
  /// =========================
  void fetchData() {
    _engineManager.conversation.getRemoteConversationList();
    _engineManager.friendApplication.fetch();
    _engineManager.friend.fetchFriends();
    _engineManager.group.getAllJoinedGroups();
  }

  /// =========================
  /// conversation stream（关键新增）
  /// =========================
  void _listenConversation() {
    final sub = _engineManager.conversation.stream.listen((map) {
      // print('conversation.stream-${map.length}');
      tabCache = map;
      _syncConversationPageState();
      _buildConversationList();
    });

    _subs.add(sub);

    _conversationChangeSub = _engineManager.conversation.changeStream.listen(
      _onConversationChange,
    );

    _subs.add(_conversationChangeSub!);

    _dataCenter.profileStream.listen((userIds) {
      for (var userId in userIds) {
        final model = _conversationMap[userId];
        if (model != null) {
          ConversationResolver().resolve(model);
        }
      }
    });

    _dataCenter.groupInfoStream.listen((groupIds) {
      // print('groupInfoStream----$groupIds');
      for (var groupId in groupIds) {
        final model = _conversationMap[groupId];
        if (model != null) {
          ConversationResolver().resolve(model);
        }
      }
    });
  }

  /// =========================
  /// 核心：增量构建列表（替代 refreshConversation）
  /// =========================
  void _buildConversationList() {
    final list = _engineManager.conversation.getTabList(selectedFilterIndex);

    final ids = <String>{};

    final newList = <ConversationModel>[];

    for (final item in list) {
      final targetId = item.targetId ?? '';
      if (targetId.isEmpty) continue;

      ids.add(targetId);

      final existing = _conversationMap[targetId];

      if (existing != null) {
        existing.updateConversation(item);
        newList.add(existing);
        _resolveSafe(existing);
      } else {
        final model = ConversationModel(info: item);
        _conversationMap[targetId] = model;
        newList.add(model);
        _resolveSafe(model);
      }
    }

    /// 删除不存在的会话
    final removeKeys = _conversationMap.keys
        .where((e) => !ids.contains(e))
        .toList();

    for (final key in removeKeys) {
      _conversationMap.remove(key);
    }

    conversations
      ..clear()
      ..addAll(newList);

    _notify();
  }

  /// =========================
  /// 会话变更处理（🔥核心）
  /// =========================
  void _onConversationChange(ConversationChangeEvent event) {
    final conv = event.conversation;
    final targetId = conv?.targetId ?? '';
    if (targetId.isEmpty && event.type != ConversationChangeType.delete) {
      return;
    }

    switch (event.type) {
      case ConversationChangeType.insert:
        _handleInsert(conv!);
        break;

      case ConversationChangeType.update:
        _handleUpdate(conv!);
        break;

      case ConversationChangeType.delete:
        _handleDelete(targetId);
        break;
    }

    _notify();
  }

  /// =========================
  /// insert
  /// =========================
  void _handleInsert(RCIMIWConversation conv) {
    final targetId = conv.targetId ?? '';
    if (targetId.isEmpty) return;

    final model = _conversationMap[targetId];
    if (model != null) {
      model.updateConversation(conv);
      ConversationResolver().resolve(model);
    } else {
      final newModel = ConversationModel(info: conv);
      ConversationResolver().resolve(newModel);
      _conversationMap[targetId] = newModel;
      conversations.insert(0, newModel);
    }
  }

  /// =========================
  /// update
  /// =========================
  void _handleUpdate(RCIMIWConversation conv) {
    final targetId = conv.targetId ?? '';
    if (targetId.isEmpty) return;

    final model = _conversationMap[targetId];
    if (model == null) return;

    model.updateConversation(conv);
    ConversationResolver().resolve(model);
  }

  /// =========================
  /// delete
  /// =========================
  void _handleDelete(String targetId) {
    final model = _conversationMap.remove(targetId);
    if (model == null) return;
    conversations.remove(model);
  }

  /// =========================
  /// resolve
  /// =========================
  Future<void> _resolveSafe(ConversationModel model) async {
    final id = model.info.targetId ?? '';
    if (id.isEmpty) return;

    if (_resolvingIds.contains(id)) return;

    _resolvingIds.add(id);

    try {
      if (!_engineManager.connection.isConnected) return;

      ConversationResolver().resolve(model);

      _notify();
    } finally {
      _resolvingIds.remove(id);
    }
  }

  /// =========================
  /// friend / group
  /// =========================
  void _listenFriendApplication() {
    final sub = _engineManager.friendApplication.stream.listen((list) {
      friendApplicationUnhandledCount =
          _engineManager.friendApplication.unhandledCount;
      _notify();
    });

    _subs.add(sub);
  }

  void _listenFriendList() {
    final sub = _dataCenter.friendListStream.listen((list) {
      friends = list;
      _notify();
    });
    _subs.add(sub);
  }

  void _listenGroupList() {
    final sub = _dataCenter.groupListStream.listen((list) {
      groups = list;
      _notify();
    });
    _subs.add(sub);
  }

  /// =========================
  /// tab switch
  /// =========================
  void switchFilter(int index) {
    if (selectedFilterIndex == index) return;

    selectedFilterIndex = index;
    _syncConversationPageState();

    /// ❗ 不再 refreshConversation，全量由 stream 驱动
    _buildConversationList();

    if (conversations.isEmpty && hasMoreConversations) {
      Future.microtask(loadMoreConversations);
    }
  }

  Future<void> loadMoreConversations() async {
    if (isConversationLoadingMore || !hasMoreConversations) {
      return;
    }

    isConversationLoadingMore = true;
    _notify();

    try {
      await _engineManager.conversation.loadMoreConversations(
        selectedFilterIndex,
      );
    } finally {
      isConversationLoadingMore = false;
      _syncConversationPageState();
      _notify();
    }
  }

  void _syncConversationPageState() {
    hasMoreConversations = _engineManager.conversation.hasMore(
      selectedFilterIndex,
    );
    isConversationLoadingMore = _engineManager.conversation.isTabLoading(
      selectedFilterIndex,
    );
  }

  /// =========================
  /// create group
  /// =========================
  Future<void> createNormalGroup(BuildContext context) async {
    final result = await SelectMembersModal.show(context, friends: friends);

    if (result == null || result.isEmpty) return;

    AppLoading.show();

    try {
      final groupId = await ImGroupManager().create(
        inviteeUserIds: result,
        groupId: generateGroupId(GroupType.normal),
      );

      if (groupId == null) {
        AppLoading.dismiss();
        AppToast.show(
          AppLocalizations.currentText('common_create_group_failed'),
        );
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
    } catch (e) {
      AppLoading.dismiss();
      AppToast.show(AppLocalizations.currentText('common_create_group_failed'));
    }
  }

  /// =========================
  /// top
  /// =========================
  Future<void> toggleConversationTop(ConversationModel model) async {
    final info = model.info;

    final targetId = info.targetId;
    final type = info.conversationType;

    if (targetId == null || type == null) return;

    final top = !(info.top ?? false);

    await _engineManager.conversation.setConversationTopStatus(
      type: type,
      targetId: targetId,
      channelId: info.channelId,
      top: top,
    );
  }

  /// =========================
  /// delete
  /// =========================
  Future<void> removeConversation(ConversationModel model) async {
    final info = model.info;

    final targetId = info.targetId;
    final type = info.conversationType;

    if (targetId == null || type == null) return;

    final backup = model;
    final index = conversations.indexOf(model);

    conversations.remove(model);
    _conversationMap.remove(targetId);

    _notify();

    try {
      await _engineManager.conversation.removeConversation(
        type,
        info.channelId,
        targetId,
      );

      AppToast.show(AppLocalizations.currentText('common_delete_success'));
    } catch (_) {
      conversations.insert(index, backup);
      _conversationMap[targetId] = backup;
      _notify();

      AppToast.show(AppLocalizations.currentText('chat_detail_delete_failed'));
    }
  }

  /// =========================
  /// notify
  /// =========================
  void _notify() {
    _notifyDebounce?.cancel();

    _notifyDebounce = Timer(const Duration(milliseconds: 16), notifyListeners);
  }

  /// =========================
  /// navigate
  /// =========================
  void navigateToConversationDetail(
    BuildContext context,
    RCIMIWConversation conversation,
    String title,
    String? avatar,
  ) {
    context.push(
      '/chat-detail/${Uri.encodeComponent(title)}',
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
  /// switchTab
  /// =========================
  void switchTab(bool isChat) {
    if (isChatSelected == isChat) return;

    isChatSelected = isChat;

    _notify();
  }

  /// =========================
  /// dispose
  /// =========================
  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }

    _notifyDebounce?.cancel();
    _conversationChangeSub?.cancel();

    super.dispose();
  }
}
