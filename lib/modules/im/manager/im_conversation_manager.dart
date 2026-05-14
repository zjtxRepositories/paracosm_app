import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import 'im_engine_manager.dart';
import 'im_group_manager.dart';
import 'im_message_manager.dart';

/// =========================
/// 会话变更类型
/// =========================
enum ConversationChangeType {
  insert,
  update,
  delete,
}

/// =========================
/// 会话变更事件
/// =========================
class ConversationChangeEvent {
  final ConversationChangeType type;
  final String key;
  final RCIMIWConversation? conversation;

  ConversationChangeEvent({
    required this.type,
    required this.key,
    this.conversation,
  });
}

class ImConversationManager {
  /// =========================
  /// 单例
  /// =========================
  static final ImConversationManager _instance =
  ImConversationManager._internal();

  factory ImConversationManager() => _instance;

  ImConversationManager._internal();

  /// =========================
  /// 全量 tab stream
  /// =========================
  final _controller =
  StreamController<Map<int, List<RCIMIWConversation>>>.broadcast();

  Stream<Map<int, List<RCIMIWConversation>>> get stream =>
      _controller.stream;

  /// =========================
  /// 变化 stream
  /// =========================
  final _changeController =
  StreamController<ConversationChangeEvent>.broadcast();

  Stream<ConversationChangeEvent> get changeStream =>
      _changeController.stream;

  Timer? _debounce;

  /// =========================
  /// cache
  /// =========================
  final Map<String, RCIMIWConversation> _allMap = {};
  final Map<int, List<String>> _tabIds = {};
  final Map<int, List<RCIMIWConversation>> _tabCache = {};

  final Map<String, ValueNotifier<RCIMIWConversation>>
  _conversationNotifiers = {};

  /// =========================
  /// tab types
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
  String _buildKey(RCIMIWConversationType type, String targetId) {
    return '${type.index}_$targetId';
  }

  /// =========================
  /// emit change
  /// =========================
  void _emitChange(
      ConversationChangeType type,
      String key, {
        RCIMIWConversation? conversation,
      }) {
    if (_changeController.isClosed) return;

    _changeController.add(
      ConversationChangeEvent(
        type: type,
        key: key,
        conversation: conversation,
      ),
    );
  }

  /// =========================
  /// init
  /// =========================
  void initListener() {
    if (_inited) return;
    _inited = true;

    final engine = IMEngineManager().engine;

    _messageSubscription ??=
        ImMessageManager().messageStream.listen(_onMessageEvent);


    engine?.onConversationReadStatusSyncMessageReceived =
        (type, targetId, timestamp) {
      _onReadSync(type, targetId);
    };

    engine?.onConversationTopStatusSynced =
        (type, targetId, channelId, top) {
      _onTopSync(type, targetId, top);
    };

    getRemoteConversationList();
  }

  Future<void> getRemoteConversationList() async {
    await _initAllTabs();
  }

  /// =========================
  /// 初始化 tab
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

  Future<void> _loadTab(int tabIndex) async {
    final completer = Completer<void>();

    final callback = IRCIMIWGetConversationsCallback(
      onSuccess: (list) {
        final ids = <String>[];

        for (final conv in list ?? []) {
          final type = conv.conversationType;
          final targetId = conv.targetId;

          if (type == null || targetId == null) continue;

          final key = _buildKey(type, targetId);

          _allMap[key] = conv;
          ids.add(key);
        }

        _tabIds[tabIndex] = ids;
        completer.complete();
      },
      onError: (code) {
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
  /// message event
  /// =========================
  void _onMessageEvent(MessageEvent event) async {
    final targetId = event.targetId ?? event.message?.targetId;
    final type = event.conversationType ?? event.message?.conversationType;
    final msg = event.message;

    if (targetId == null || type == null || msg == null) return;

    final key = _buildKey(type, targetId);

    final old = _allMap[key];

    /// =========================
    /// update
    /// =========================
    if (old != null) {
      final oldMsgId = old.lastMessage?.messageId;

      if (oldMsgId == msg.messageId) return;

      old.lastMessage = msg;

      if (msg.senderUserId != IMEngineManager().currentUserId) {
        old.unreadCount = (old.unreadCount ?? 0) + 1;
      }

      _sortAllTabs();
      _rebuildAllTabCache();

      _emitChange(
        ConversationChangeType.update,
        key,
        conversation: old,
      );

      return;
    }

    /// =========================
    /// insert
    /// =========================
    final conv = await getConversation(
      type: type,
      targetId: targetId,
    );

    if (conv == null) return;

    _allMap[key] = conv;

    for (int i = 0; i < tabTypes.length; i++) {
      if (!tabTypes[i].contains(type)) continue;

      _tabIds.putIfAbsent(i, () => []);
      _tabIds[i]!.insert(0, key);
    }

    _sortAllTabs();
    _rebuildAllTabCache();

    _emitChange(
      ConversationChangeType.insert,
      key,
      conversation: conv,
    );

    _notify();
  }

  Future<void> removeConversationByTargetId(String targetId,RCIMIWConversationType type) async {
    final key = _buildKey(type, targetId);

    try {
      await IMEngineManager().engine?.removeConversation(
        type,
        targetId,
        null,
      );
    } catch (_) {}

    _removeLocalConversation(key);
  }

  void _removeLocalConversation(String key) {
    final conv = _allMap.remove(key);

    _conversationNotifiers.remove(key)?.dispose();

    for (final ids in _tabIds.values) {
      ids.remove(key);
    }

    _rebuildAllTabCache();

    _emitChange(
      ConversationChangeType.delete,
      key,
      conversation: conv,
    );

    _notify();
  }

  /// =========================
  /// read sync
  /// =========================
  void _onReadSync(RCIMIWConversationType? type, String? targetId) {
    if (type == null || targetId == null) return;

    final key = _buildKey(type, targetId);
    final conv = _allMap[key];

    if (conv == null) return;

    conv.unreadCount = 0;

    _emitChange(
      ConversationChangeType.update,
      key,
      conversation: conv,
    );
  }

  /// =========================
  /// top sync
  /// =========================
  void _onTopSync(
      RCIMIWConversationType? type,
      String? targetId,
      bool? top,
  {int? operationTime}
      ) {
    if (type == null || targetId == null) return;

    final key = _buildKey(type, targetId);
    final conv = _allMap[key];

    if (conv == null) return;

    conv.top = top;
    conv.operationTime = operationTime ?? conv.operationTime;
    _sortAllTabs();
    _rebuildAllTabCache();

    _emitChange(
      ConversationChangeType.update,
      key,
      conversation: conv,
    );

    _notify();
  }

  /// =========================
  /// sort
  /// =========================
  void _sortAllTabs() {
    for (final ids in _tabIds.values) {
      ids.sort((a, b) {
        final A = _allMap[a];
        final B = _allMap[b];

        final aTop = A?.top ?? false;
        final bTop = B?.top ?? false;

        if (aTop != bTop) return bTop ? 1 : -1;

        final at = A?.operationTime ?? A?.lastMessage?.sentTime ?? 0;
        final bt = B?.operationTime ?? B?.lastMessage?.sentTime ?? 0;

        return bt.compareTo(at);
      });
    }
  }

  void _rebuildAllTabCache() {
    _tabCache.clear();

    _tabIds.forEach((k, v) {
      _tabCache[k] =
          v.where((e) => _allMap[e] != null).map((e) => _allMap[e]!).toList();
    });
  }

  List<RCIMIWConversation> getTabList(int tabIndex) {
    return _tabCache[tabIndex] ?? [];
  }

  void _notify() {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 100), () {
      if (_controller.isClosed) return;

      _controller.add(Map.from(_tabCache));
    });
  }

  void dispose() {
    _messageSubscription?.cancel();
    _groupEventSubscription?.cancel();
    _debounce?.cancel();

    for (final n in _conversationNotifiers.values) {
      n.dispose();
    }

    _conversationNotifiers.clear();
  }

  /// =========================
  /// ⭐ 业务 API（完整恢复）
  /// =========================

  Future<RCIMIWConversation?> getConversation({
    required RCIMIWConversationType type,
    required String targetId,
    String? channelId,
  }) async {
    final completer = Completer<RCIMIWConversation?>();

    IMEngineManager().engine?.getConversation(
      type,
      targetId,
      channelId,
      callback: IRCIMIWGetConversationCallback(
        onSuccess: (c) => completer.complete(c),
        onError: (_) => completer.complete(null),
      ),
    );

    return completer.future;
  }

  Future<void> removeConversation(
      RCIMIWConversationType type,
      String? channelId,
      String targetId,
      ) async {
    final completer = Completer<void>();

    await IMEngineManager().engine?.removeConversation(
      type,
      targetId,
      channelId,
      callback: IRCIMIWRemoveConversationCallback(
        onConversationRemoved: (code) {
          if (code == 0) {
            final key = _buildKey(type, targetId);
            _removeLocalConversation(key);
            completer.complete();
          } else {
            completer.completeError(code ?? -1);
          }
        },
      ),
    );

    return completer.future;
  }

  Future<bool> setConversationTopStatus({
    required RCIMIWConversationType type,
    required String targetId,
    String? channelId,
    required bool top,
  }) async {
    final engine = IMEngineManager().engine;
    if (engine == null) return false;

    final completer = Completer<bool>();

    final code = await engine.changeConversationTopStatus(
      type,
      targetId,
      channelId,
      top,
      callback: IRCIMIWChangeConversationTopStatusCallback(
        onConversationTopStatusChanged: (code) {
          completer.complete(code == 0);
          _onTopSync(type, targetId, top, operationTime: DateTime.now().millisecondsSinceEpoch);
        },
      ),
    );

    if (code != 0 && !completer.isCompleted) {
      completer.complete(false);
    }

    return completer.future;
  }

  Future<bool> clearUnreadCount({
    required RCIMIWConversationType type,
    required String targetId,
    String? channelId,
    required int timestamp,
  }) async {
    final engine = IMEngineManager().engine;
    if (engine == null) return false;

    final completer = Completer<bool>();

    await engine.clearUnreadCount(
      type,
      targetId,
      channelId,
      timestamp,
      callback: IRCIMIWClearUnreadCountCallback(
        onUnreadCountCleared: (code) {
          completer.complete(code == 0);
        },
      ),
    );

    return completer.future;
  }

  Future<bool> markConversationRead({
    required RCIMIWConversationType type,
    required String targetId,
    String? channelId,
    int? timestamp,
  }) async {
    final t = timestamp ?? DateTime.now().millisecondsSinceEpoch;

    final ok = await clearUnreadCount(
      type: type,
      targetId: targetId,
      channelId: channelId,
      timestamp: t,
    );

    return ok;
  }

  Future<bool> setConversationDoNotDisturb({
    required RCIMIWConversationType type,
    required String targetId,
    String? channelId,
    required bool enabled,
  }) async {
    final engine = IMEngineManager().engine;
    if (engine == null) return false;

    final level = enabled
        ? RCIMIWPushNotificationLevel.blocked
        : RCIMIWPushNotificationLevel.allMessage;

    final completer = Completer<bool>();

    await engine.changeConversationNotificationLevel(
      type,
      targetId,
      channelId,
      level,
      callback: IRCIMIWChangeConversationNotificationLevelCallback(
        onConversationNotificationLevelChanged: (code) {
          completer.complete(code == 0);
        },
      ),
    );

    return completer.future;
  }

  Future<RCIMIWPushNotificationLevel?> getConversationNotificationLevel({
    required RCIMIWConversationType type,
    required String targetId,
    String? channelId,
  }) async {
    final engine = IMEngineManager().engine;
    if (engine == null) return null;

    final completer = Completer<RCIMIWPushNotificationLevel?>();

    final code = await engine.getConversationNotificationLevel(
      type,
      targetId,
      channelId,
      callback: IRCIMIWGetConversationNotificationLevelCallback(
        onSuccess: (level) {
          completer.complete(level);
        },
        onError: (code) {
          completer.complete(null);
        },
      ),
    );

    if (code != 0 && !completer.isCompleted) {
      completer.complete(null);
    }

    return completer.future;
  }

  Future<bool?> getConversationTopStatus({
    required RCIMIWConversationType type,
    required String targetId,
    String? channelId,
  }) async {
    final engine = IMEngineManager().engine;
    if (engine == null) return null;

    final completer = Completer<bool?>();

    final code = await engine.getConversationTopStatus(
      type,
      targetId,
      channelId,
      callback: IRCIMIWGetConversationTopStatusCallback(
        onSuccess: (top) {
          completer.complete(top);
        },
        onError: (code) {
          completer.complete(null);
        },
      ),
    );

    if (code != 0 && !completer.isCompleted) {
      completer.complete(null);
    }

    return completer.future;
  }
}