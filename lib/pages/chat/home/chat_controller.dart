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

  static final ChatController _instance =
  ChatController._();

  factory ChatController() {
    return _instance;
  }

  final IMEngineManager _engineManager =
  IMEngineManager();

  final List<StreamSubscription> _subs = [];

  final resolver = ConversationResolver();

  /// 防重复 resolve
  final Set<String> _resolvingIds = {};

  /// notify 节流
  Timer? _notifyDebounce;

  bool isChatSelected = true;

  int selectedFilterIndex = 0;

  int friendApplicationUnhandledCount = 0;

  /// 固定引用（不要重新赋值）
  final List<ConversationModel>
  conversations = [];

  List<RCIMIWFriendInfo> friends = [];

  List<RCIMIWGroupInfo> groups = [];

  Map<int, List<RCIMIWConversation>>?
  tabCache;

  bool _inited = false;

  /// targetId -> model
  final Map<String, ConversationModel>
  _conversationMap = {};

  /// =========================
  /// 初始化
  /// =========================
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
    final sub = _engineManager
        .connection
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
    _engineManager.friendApplication.fetch();

    _engineManager.friend.fetchFriends();

    _engineManager.group.getAllJoinedGroups();

    refreshConversation();
  }

  /// =========================
  /// friend request
  /// =========================
  void _fetchFriendApplication() {
    final sub = _engineManager
        .friendApplication
        .stream
        .listen((list) {
      friendApplicationUnhandledCount =
          _engineManager
              .friendApplication
              .unhandledCount;

      _notify();
    });

    _subs.add(sub);
  }

  /// =========================
  /// conversation
  /// =========================
  void _fetchConversation() {
    final sub = _engineManager
        .conversation
        .stream
        .listen((map) {
      tabCache = map;

      refreshConversation();
    });

    _subs.add(sub);
  }

  /// =========================
  /// conversation refresh
  /// =========================
  Future<void>
  refreshConversation() async {
    final list = _engineManager
        .conversation
        .getTabList(
      selectedFilterIndex,
    );

    final ids = <String>{};

    final newList = <ConversationModel>[];

    for (final item in list) {
      final targetId =
          item.targetId ?? '';

      if (targetId.isEmpty) {
        continue;
      }

      ids.add(targetId);

      ConversationModel model;

      /// 已存在
      if (_conversationMap.containsKey(
        targetId,
      )) {
        model =
        _conversationMap[targetId]!;

        /// 更新 conversation
        model.updateConversation(item);

        /// 后台 resolve
        _resolveSafe(model);
      } else {
        /// 新会话
        model = ConversationModel(
          info: item,
        );

        _conversationMap[targetId] =
            model;

        /// 异步解析
        _resolveSafe(model);
      }

      newList.add(model);
    }

    /// 删除不存在会话
    final removeKeys =
    _conversationMap.keys
        .where(
          (e) => !ids.contains(e),
    )
        .toList();

    for (final key in removeKeys) {
      _conversationMap.remove(key);
    }

    /// 保持 list 引用不变
    conversations
      ..clear()
      ..addAll(newList);

    _notify();
  }

  /// =========================
  /// 安全 resolve
  /// =========================
  Future<void> _resolveSafe(
      ConversationModel model,
      ) async {
    final id =
        model.info.targetId ?? '';

    if (id.isEmpty) {
      return;
    }

    /// 防重复
    if (_resolvingIds.contains(id)) {
      return;
    }

    _resolvingIds.add(id);

    try {
      if (!_engineManager
          .connection
          .isConnected) {
        return;
      }

      await resolver.resolve(model);

      _notify();
    } catch (e) {
      debugPrint(
        'resolve conversation error: $e',
      );
    } finally {
      _resolvingIds.remove(id);
    }
  }

  /// =========================
  /// 联系人
  /// =========================
  void _fetchContact() {
    final sub = _engineManager
        .friend
        .stream
        .listen((list) {
      friends = list;

      _notify();
    });

    _subs.add(sub);
  }

  /// =========================
  /// 群组
  /// =========================
  void _fetchGroup() {
    final sub = _engineManager.group.stream
        .listen((list) {
      groups = list;

      _notify();
    });

    _subs.add(sub);
  }

  /// =========================
  /// tab
  /// =========================
  void switchTab(bool isChat) {
    if (isChatSelected == isChat) {
      return;
    }

    isChatSelected = isChat;

    _notify();
  }

  void switchFilter(int index) {
    if (selectedFilterIndex == index) {
      return;
    }

    selectedFilterIndex = index;

    refreshConversation();
  }

  /// =========================
  /// create group
  /// =========================
  Future<void> createNormalGroup(
      BuildContext context,
      ) async {
    final result =
    await SelectMembersModal.show(
      context,
      friends: friends,
    );

    if (result == null ||
        result.isEmpty) {
      return;
    }

    AppLoading.show();

    try {
      final groupId =
      await ImGroupManager().create(
        inviteeUserIds: result,
        groupId: generateGroupId(
          GroupType.normal,
        ),
      );

      if (groupId == null) {
        AppLoading.dismiss();

        AppToast.show('创建群组失败');

        return;
      }

      final message = CustomMessage(
        targetId: groupId,
        customMessageType:
        CustomMessageType
            .groupInvited,
        conversationType:
        RCIMIWConversationType.group,
      );

      final isSend =
      await ImSender.instance.send(
        message: message,
      );

      AppLoading.dismiss();

      if (!isSend) {
        return;
      }

      final conversation =
      await ImConversationManager()
          .getConversation(
        type:
        RCIMIWConversationType.group,
        targetId: groupId,
      );

      if (conversation == null) {
        return;
      }

      final model = ConversationModel(
        info: conversation,
      );

      await resolver.resolve(model);

      if (!context.mounted) {
        return;
      }

      navigateToConversationDetail(
        context,
        conversation,
        model.title ?? '',
        model.portraitUri,
      );
    } catch (e) {
      AppLoading.dismiss();

      AppToast.show('创建群组失败');

      debugPrint(
        'create group error: $e',
      );
    }
  }

  /// =========================
  /// 会话置顶
  /// =========================
  Future<void>
  toggleConversationTop(
      ConversationModel model,
      ) async {
    final info = model.info;

    final targetId = info.targetId;

    final type =
        info.conversationType;

    if (targetId == null ||
        type == null) {
      return;
    }

    final top = !(info.top ?? false);

    /// 乐观更新
    info.top = top;

    model.updateConversation(info);

    /// 本地排序
    _sortConversationList();

    _notify();

    try {
      final success =
      await _engineManager
          .conversation
          .setConversationTopStatus(
        type: type,
        targetId: targetId,
        channelId: info.channelId,
        top: top,
      );

      if (!success) {
        /// 回滚
        info.top = !top;

        model.updateConversation(info);

        _sortConversationList();

        _notify();

        AppToast.show(
          top
              ? '置顶失败'
              : '取消置顶失败',
        );
      }
    } catch (e) {
      /// 回滚
      info.top = !top;

      model.updateConversation(info);

      _sortConversationList();

      _notify();

      debugPrint(
        'toggleConversationTop error: $e',
      );
    }
  }

  /// =========================
  /// 删除会话
  /// =========================
  Future<void> removeConversation(
      ConversationModel model,
      ) async {
    final info = model.info;

    final targetId = info.targetId;

    final type =
        info.conversationType;

    if (targetId == null ||
        type == null) {
      return;
    }

    /// 先缓存
    final backupIndex =
    conversations.indexOf(model);

    final backupModel = model;

    /// 乐观删除
    conversations.remove(model);

    _conversationMap.remove(
      targetId,
    );

    _notify();

    try {
      await _engineManager.conversation
          .removeConversation(
        type,
        info.channelId,
        targetId,
      );

      AppToast.show('删除成功');
    } catch (e) {
      /// 回滚
      conversations.insert(
        backupIndex,
        backupModel,
      );

      _conversationMap[targetId] =
          backupModel;

      _sortConversationList();

      _notify();

      AppToast.show('删除失败');

      debugPrint(
        'removeConversation error: $e',
      );
    }
  }

  /// =========================
  /// 本地排序
  /// =========================
  void _sortConversationList() {
    conversations.sort((a, b) {
      final aTop =
          a.info.top ?? false;

      final bTop =
          b.info.top ?? false;

      /// 置顶优先
      if (aTop != bTop) {
        return (bTop ? 1 : 0) -
            (aTop ? 1 : 0);
      }

      final aTime =
          a.info.lastMessage?.sentTime ??
              0;

      final bTime =
          b.info.lastMessage?.sentTime ??
              0;

      return bTime.compareTo(aTime);
    });
  }

  /// =========================
  /// chat detail
  /// =========================
  void navigateToConversationDetail(
      BuildContext context,
      RCIMIWConversation conversation,
      String title,
      String? avatar,
      ) {
    final encodedName =
    Uri.encodeComponent(title);

    context.push(
      '/chat-detail/$encodedName',
      extra: ChatSessionArgs(
        targetId:
        conversation.targetId ?? '',
        conversationType:
        conversation
            .conversationType ??
            RCIMIWConversationType
                .private,
        name: title,
        channelId:
        conversation.channelId,
        isGroup:
        conversation
            .conversationType ==
            RCIMIWConversationType
                .group,
        avatar: avatar,
      ),
    );
  }

  /// =========================
  /// notify
  /// =========================
  void _notify() {
    _notifyDebounce?.cancel();

    _notifyDebounce = Timer(
      const Duration(
        milliseconds: 16,
      ),
          () {
        notifyListeners();
      },
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

    _notifyDebounce?.cancel();

    super.dispose();
  }
}