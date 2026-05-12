import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import 'im_engine_manager.dart';
import 'im_group_manager.dart';
import 'im_message_manager.dart';

class ImConversationManager {
  /// =========================
  /// 单例
  /// =========================
  static final ImConversationManager _instance =
  ImConversationManager._internal();

  factory ImConversationManager() => _instance;

  ImConversationManager._internal();

  /// =========================
  /// stream
  /// =========================
  final _controller =
  StreamController<Map<int, List<RCIMIWConversation>>>.broadcast();

  Stream<Map<int, List<RCIMIWConversation>>> get stream =>
      _controller.stream;

  Timer? _debounce;

  bool _notifying = false;

  /// =========================
  /// 会话缓存
  /// key:
  /// ${type.index}_$targetId
  /// =========================
  final Map<String, RCIMIWConversation> _allMap = {};

  /// tab -> keys
  final Map<int, List<String>> _tabIds = {};

  /// tab cache
  final Map<int, List<RCIMIWConversation>> _tabCache = {};

  /// =========================
  /// tab 类型
  /// =========================
  final List<List<RCIMIWConversationType>> tabTypes = [
    [
      RCIMIWConversationType.private,
      RCIMIWConversationType.group,
      RCIMIWConversationType.system,
    ],

    [RCIMIWConversationType.private],

    [RCIMIWConversationType.group],

    [RCIMIWConversationType.system],
  ];

  bool _inited = false;

  bool _loading = false;

  StreamSubscription<MessageEvent>? _messageSubscription;

  StreamSubscription<GroupEvent>? _groupEventSubscription;

  /// =========================
  /// key
  /// =========================
  String _buildKey(
      RCIMIWConversationType type,
      String targetId,
      ) {
    return '${type.index}_$targetId';
  }

  /// =========================
  /// 初始化
  /// =========================
  void initListener() {
    if (_inited) return;

    _inited = true;

    final engine = IMEngineManager().engine;

    /// 消息监听
    _messageSubscription ??=
        ImMessageManager().messageStream.listen(
          _onMessageEvent,
        );

    /// 群事件
    _groupEventSubscription ??=
        GroupEventBus.instance.stream.listen(
          _onGroupEvent,
        );

    /// 已读同步
    engine?.onConversationReadStatusSyncMessageReceived =
        (
        type,
        targetId,
        timestamp,
        ) {
      _onReadSync(
        type,
        targetId,
      );
    };

    /// 置顶同步
    engine?.onConversationTopStatusSynced =
        (
        type,
        targetId,
        channelId,
        top,
        ) {
      _onTopSync(
        type,
        targetId,
        top,
      );
    };

    getRemoteConversationList();
  }

  Future<void> initAll() async {
    await _initAllTabs();
  }

  /// =========================
  /// 拉取远端会话
  /// =========================
  Future<void> getRemoteConversationList() async {
    await _initAllTabs();
  }

  /// =========================
  /// 初始化全部 tab
  /// =========================
  Future<void> _initAllTabs() async {
    if (_loading) return;

    _loading = true;

    try {
      _allMap.clear();

      _tabIds.clear();

      _tabCache.clear();

      final futures = <Future>[];

      for (int i = 0; i < tabTypes.length; i++) {
        futures.add(_loadTab(i));
      }

      await Future.wait(futures);

      _rebuildAllTabCache();

      _notify();
    } finally {
      _loading = false;
    }
  }

  /// =========================
  /// 加载 tab
  /// =========================
  Future<void> _loadTab(int tabIndex) async {
    final completer = Completer<void>();

    final callback = IRCIMIWGetConversationsCallback(
      onSuccess: (list) {
        final ids = <String>[];

        for (final conv in list ?? []) {
          final targetId = conv.targetId;

          final type = conv.conversationType;

          if (targetId == null || type == null) {
            continue;
          }

          final key = _buildKey(
            type,
            targetId,
          );

          _allMap.putIfAbsent(
            key,
                () => conv,
          );

          ids.add(key);
        }

        _sortIds(ids);

        _tabIds[tabIndex] = ids;

        completer.complete();
      },
      onError: (code) {
        debugPrint('获取会话失败: $code');

        completer.completeError(code ?? -1);
      },
    );

    await IMEngineManager().engine?.getConversations(
      tabTypes[tabIndex],
      null,
      0,
      50,
      callback: callback,
    );

    return completer.future;
  }

  /// =========================
  /// 获取会话
  /// =========================
  Future<RCIMIWConversation?> getConversation({
    required RCIMIWConversationType type,
    required String targetId,
    String? channelId,
  }) {
    final completer = Completer<RCIMIWConversation?>();

    IMEngineManager().engine?.getConversation(
      type,
      targetId,
      channelId,
      callback: IRCIMIWGetConversationCallback(
        onSuccess: (conversation) {
          completer.complete(conversation);
        },
        onError: (code) {
          completer.completeError(code ?? -1);
        },
      ),
    );

    return completer.future;
  }

  /// =========================
  /// 消息事件
  /// =========================
  void _onMessageEvent(MessageEvent event) async {
    final targetId =
        event.targetId ?? event.message?.targetId;

    final conversationType =
        event.conversationType ??
            event.message?.conversationType;

    final message = event.message;

    if (targetId == null ||
        conversationType == null ||
        message == null) {
      return;
    }

    final key = _buildKey(
      conversationType,
      targetId,
    );

    try {
      final oldConversation = _allMap[key];

      /// =========================
      /// 本地已有会话
      /// =========================
      if (oldConversation != null) {
        final oldMsgId =
            oldConversation.lastMessage?.messageId;

        final newMsgId = message.messageId;

        /// 同一条消息
        if (oldMsgId == newMsgId) {
          return;
        }

        oldConversation.lastMessage = message;

        /// 自己发送不增加未读
        if (message.senderUserId !=
            IMEngineManager().currentUserId) {
          oldConversation.unreadCount =
              (oldConversation.unreadCount ?? 0) + 1;
        }

        _moveToTop(key);

        _rebuildAllTabCache();

        _notify();

        return;
      }

      /// =========================
      /// 本地不存在
      /// 从 SDK 拉取完整会话
      /// =========================
      final conversation =
      await getConversation(
        type: conversationType,
        targetId: targetId,
      );

      if (conversation == null) {
        return;
      }

      _allMap[key] = conversation;

      for (int i = 0; i < tabTypes.length; i++) {
        if (!tabTypes[i].contains(
          conversationType,
        )) {
          continue;
        }

        _tabIds.putIfAbsent(i, () => []);

        final ids = _tabIds[i]!;

        if (!ids.contains(key)) {
          ids.insert(0, key);
        }
      }

      _moveToTop(key);

      _rebuildAllTabCache();

      _notify();
    } catch (e) {
      debugPrint('刷新会话失败: $e');
    }
  }

  /// =========================
  /// 群事件
  /// =========================
  void _onGroupEvent(GroupEvent event) {
    switch (event.type) {
    /// 退群
      case GroupEventType.quit:

      /// 解散
      case GroupEventType.dismissed:
        _removeConversationByGroup(
          event.groupId,
        );
        break;

      default:
        break;
    }
  }

  /// =========================
  /// 删除群会话
  /// =========================
  Future<void> _removeConversationByGroup(
      String targetId,
      ) async {
    final key = _buildKey(
      RCIMIWConversationType.group,
      targetId,
    );

    try {
      await IMEngineManager()
          .engine
          ?.removeConversation(
        RCIMIWConversationType.group,
        targetId,
        null,
      );
    } catch (_) {}

    _removeLocalConversation(key);
  }

  /// =========================
  /// 删除本地会话
  /// =========================
  void _removeLocalConversation(String key) {
    _allMap.remove(key);

    for (final ids in _tabIds.values) {
      ids.remove(key);
    }

    _rebuildAllTabCache();

    _notify();
  }

  /// =========================
  /// 已读同步
  /// =========================
  void _onReadSync(
      RCIMIWConversationType? type,
      String? targetId,
      ) {
    if (type == null || targetId == null) {
      return;
    }

    final key = _buildKey(
      type,
      targetId,
    );

    final conv = _allMap[key];

    if (conv == null) {
      return;
    }

    conv.unreadCount = 0;

    _rebuildAllTabCache();

    _notify();
  }

  /// =========================
  /// 置顶同步
  /// =========================
  void _onTopSync(
      RCIMIWConversationType? type,
      String? targetId,
      bool? top,
      ) {
    if (type == null || targetId == null) {
      return;
    }

    final key = _buildKey(
      type,
      targetId,
    );

    final conv = _allMap[key];

    if (conv == null) {
      return;
    }

    conv.top = top;

    for (final ids in _tabIds.values) {
      _sortIds(ids);
    }

    _rebuildAllTabCache();

    _notify();
  }

  /// =========================
  /// 删除会话
  /// =========================
  Future<void> removeConversation(
      RCIMIWConversationType type,
      String? channelId,
      String targetId,
      ) async {
    final completer = Completer<void>();

    final key = _buildKey(
      type,
      targetId,
    );

    final callback =
    IRCIMIWRemoveConversationCallback(
      onConversationRemoved: (code) {
        if (code == 0) {
          _removeLocalConversation(key);

          completer.complete();
        } else {
          completer.completeError(code ?? -1);
        }
      },
    );

    await IMEngineManager()
        .engine
        ?.removeConversation(
      type,
      targetId,
      channelId,
      callback: callback,
    );

    return completer.future;
  }

  /// =========================
  /// 设置置顶
  /// =========================
  Future<bool> changeConversationTopStatus({
    required RCIMIWConversationType type,
    required String targetId,
    String? channelId,
    required bool top,
  }) {
    final completer = Completer<bool>();

    IMEngineManager()
        .engine
        ?.changeConversationTopStatus(
      type,
      targetId,
      channelId,
      top,
      callback:
      IRCIMIWChangeConversationTopStatusCallback(
        onConversationTopStatusChanged:
            (code) {
          completer.complete(code == 0);
        },
      ),
    );

    return completer.future;
  }

  /// =========================
  /// 新消息
  /// =========================
  void onNewMessage(
      String targetId,
      RCIMIWMessage message,
      ) {
    final type = message.conversationType;

    if (type == null) return;

    final key = _buildKey(
      type,
      targetId,
    );

    final conv = _allMap[key];

    if (conv != null) {
      final oldMsgId =
          conv.lastMessage?.messageId;

      if (oldMsgId == message.messageId) {
        return;
      }

      conv.lastMessage = message;

      _moveToTop(key);
    }

    _rebuildAllTabCache();

    _notify();
  }

  /// =========================
  /// 移动顶部
  /// =========================
  void _moveToTop(String key) {
    for (final list in _tabIds.values) {
      final index = list.indexOf(key);

      if (index <= 0) continue;

      list.removeAt(index);

      final conv = _allMap[key];

      final isTop = conv?.top ?? false;

      /// 置顶
      if (isTop) {
        list.insert(0, key);

        continue;
      }

      /// 插入非置顶首位
      int insertIndex = list.length;

      for (int i = 0; i < list.length; i++) {
        final item = _allMap[list[i]];

        if (!(item?.top ?? false)) {
          insertIndex = i;

          break;
        }
      }

      list.insert(insertIndex, key);
    }
  }

  /// =========================
  /// 排序
  /// =========================
  void _sortIds(List<String> ids) {
    ids.sort((a, b) {
      final convA = _allMap[a];

      final convB = _allMap[b];

      final aTop = convA?.top ?? false;

      final bTop = convB?.top ?? false;

      if (aTop != bTop) {
        return (bTop ? 1 : 0) -
            (aTop ? 1 : 0);
      }

      final aTime =
          convA?.lastMessage?.sentTime ?? 0;

      final bTime =
          convB?.lastMessage?.sentTime ?? 0;

      return bTime.compareTo(aTime);
    });
  }

  /// =========================
  /// 重建 tab cache
  /// =========================
  void _rebuildAllTabCache() {
    _tabCache.clear();

    _tabIds.forEach((tab, ids) {
      _tabCache[tab] =
          ids
              .where(
                (e) => _allMap[e] != null,
          )
              .map((e) => _allMap[e]!)
              .toList();
    });
  }

  /// =========================
  /// 获取 tab 数据
  /// =========================
  List<RCIMIWConversation> getTabList(
      int tabIndex,
      ) {
    return _tabCache[tabIndex] ?? [];
  }

  /// =========================
  /// notify
  /// =========================
  void _notify() {
    if (_notifying) return;

    _notifying = true;

    _debounce?.cancel();

    _debounce = Timer(
      const Duration(milliseconds: 100),
          () {
        _notifying = false;

        if (_controller.isClosed) {
          return;
        }

        _controller.add(
          Map.from(_tabCache),
        );
      },
    );
  }

  /// =========================
  /// dispose
  /// =========================
  void dispose() {
    _messageSubscription?.cancel();

    _messageSubscription = null;

    _groupEventSubscription?.cancel();

    _groupEventSubscription = null;

    _debounce?.cancel();

    /// 单例不要 close
    /// 否则无法再次监听
  }
}