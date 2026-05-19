import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:k_chart_plus/k_chart_plus.dart';
import 'package:paracosm/core/models/group_model.dart';
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
  /// singleton
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

  final _changeController =
  StreamController<ConversationChangeEvent>.broadcast();

  Stream<ConversationChangeEvent> get changeStream =>
      _changeController.stream;

  /// =========================
  /// debounce
  /// =========================
  Timer? _debounce;

  /// =========================
  /// cache
  /// =========================
  final Map<String, RCIMIWConversation> _allMap = {};

  /// tab -> conversation keys
  final Map<int, List<String>> _tabIds = {};

  /// tab -> conversation list
  final Map<int, List<RCIMIWConversation>> _tabCache = {};

  /// =========================
  /// tabs
  /// =========================
  final List<List<RCIMIWConversationType>> tabTypes = [
    [
      RCIMIWConversationType.private,
      RCIMIWConversationType.group,
      RCIMIWConversationType.system,
    ],

    /// private
    [
      RCIMIWConversationType.private,
    ],

    /// all group
    [
      RCIMIWConversationType.group,
    ],

    /// club
    [
      RCIMIWConversationType.group,
    ],

    /// dao
    [
      RCIMIWConversationType.group,
    ],
  ];

  bool _inited = false;
  bool _loading = false;
  bool _disposed = false;

  StreamSubscription<MessageEvent>? _messageSubscription;
  StreamSubscription<GroupEvent>? _groupEventSubscription;

  /// =========================
  /// key
  /// =========================
  String _buildKey(
      RCIMIWConversationType type,
      String targetId,
      ) {
    switch (type) {
      case RCIMIWConversationType.group:
        return 'group:${_groupBizType(targetId)}:$targetId';

      case RCIMIWConversationType.private:
        return 'private:$targetId';

      case RCIMIWConversationType.system:
        return 'system:$targetId';

      default:
        return '${type.index}:$targetId';
    }
  }

  String _groupBizType(String targetId) {
    final club = 'group_${GroupType.club.name}';
    final dao = 'group_${GroupType.dao.name}';
    if (targetId.startsWith(club)) {
      return 'club';
    }

    if (targetId.startsWith(dao)) {
      return 'dao';
    }

    return 'normal';
  }
  /// =========================
  /// group tab match
  /// =========================
  bool _matchTab(
      int tabIndex,
      RCIMIWConversationType type,
      String targetId,
      ) {
    /// 不属于当前 tab 的 sdk type
    if (!tabTypes[tabIndex].contains(type)) {
      return false;
    }
    /// 非 group
    if (type != RCIMIWConversationType.group) {
      return true;
    }

    final clubPrefix = 'group_${GroupType.club.name}';
    final daoPrefix = 'group_${GroupType.dao.name}';

    final isClub = targetId.startsWith(clubPrefix);
    final isDao = targetId.startsWith(daoPrefix);

    switch (tabIndex) {
    /// 全部
      case 0:
        return true;

    /// 普通群
      case 2:
        return !isClub && !isDao;

    /// club
      case 3:
        return isClub;

    /// dao
      case 4:
        return isDao;

      default:
        return true;
    }
  }

  /// =========================
  /// clone
  /// =========================
  RCIMIWConversation _cloneConversation(
      RCIMIWConversation source,
      ) {
    final c = RCIMIWConversation.create();
    c.conversationType = source.conversationType;
    c.targetId = source.targetId;
    c.channelId = source.channelId;
    c.firstUnreadMsgSendTime = source.firstUnreadMsgSendTime;
    c.unreadCount = source.unreadCount;
    c.lastMessage = source.lastMessage;
    c.top = source.top;
    c.operationTime = source.operationTime;
    c.notificationLevel = source.notificationLevel;
    return c;
  }

  /// =========================
  /// emit change
  /// =========================
  void _emitChange(
      ConversationChangeType type,
      String key, {
        RCIMIWConversation? conversation,
      }) {
    if (_disposed || _changeController.isClosed) return;

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
  }

  Future<void> getRemoteConversationList() async {
    await _initAllTabs();
  }

  /// =========================
  /// init tabs
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

      _sortAllTabs();

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
        print('_loadTab----${list?.length}');
        final ids = <String>[];

        for (final conv in list ?? []) {
          final type = conv.conversationType;
          final targetId = conv.targetId;

          if (type == null || targetId == null) {
            continue;
          }

          if (!_matchTab(tabIndex, type, targetId)) {
            continue;
          }

          final key = _buildKey(type, targetId);

          _allMap[key] = _cloneConversation(conv);

          if (!ids.contains(key)) {
            ids.add(key);
          }
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

    final type =
        event.conversationType ?? event.message?.conversationType;

    final msg = event.message;

    if (targetId == null || type == null || msg == null) {
      return;
    }

    final key = _buildKey(type, targetId);

    final old = _allMap[key];

    /// =========================
    /// update
    /// =========================
    if (old != null) {
      final oldMsgId = old.lastMessage?.messageId;

      if (oldMsgId == msg.messageId) {
        return;
      }

      final oldTime = old.lastMessage?.sentTime ?? 0;
      final newTime = msg.sentTime ?? 0;

      if (newTime >= oldTime) {
        old.lastMessage = msg;
      }

      if (msg.senderUserId != IMEngineManager().currentUserId) {
        old.unreadCount = (old.unreadCount ?? 0) + 1;
      }

      old.operationTime = newTime;

      _sortAllTabs();

      _rebuildAllTabCache();

      _emitChange(
        ConversationChangeType.update,
        key,
        conversation: old,
      );

      _notify();

      return;
    }

    /// =========================
    /// insert
    /// =========================
    final conv = await getConversation(
      type: type,
      targetId: targetId,
    );

    if (conv == null) {
      return;
    }

    _allMap[key] = _cloneConversation(conv);

    for (int i = 0; i < tabTypes.length; i++) {
      if (!_matchTab(i, type, targetId)) {
        continue;
      }

      _tabIds.putIfAbsent(i, () => []);

      final ids = _tabIds[i]!;

      ids.remove(key);

      ids.insert(0, key);

      print('ids----${key}');

    }

    _sortAllTabs();

    _rebuildAllTabCache();

    _emitChange(
      ConversationChangeType.insert,
      key,
      conversation: conv,
    );
    print('insert----${targetId}---$key');

    _notify();
  }

  /// =========================
  /// remove
  /// =========================
  Future<void> removeConversationByTargetId(
      String targetId,
      RCIMIWConversationType type,
      ) async {
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
  void _onReadSync(
      RCIMIWConversationType? type,
      String? targetId,
      ) {
    if (type == null || targetId == null) {
      return;
    }

    final key = _buildKey(type, targetId);

    final conv = _allMap[key];

    if (conv == null) {
      return;
    }

    conv.unreadCount = 0;

    _emitChange(
      ConversationChangeType.update,
      key,
      conversation: conv,
    );

    _notify();
  }

  /// =========================
  /// top sync
  /// =========================
  void _onTopSync(
      RCIMIWConversationType? type,
      String? targetId,
      bool? top, {
        int? operationTime,
      }) {
    if (type == null || targetId == null) {
      return;
    }

    final key = _buildKey(type, targetId);

    final conv = _allMap[key];

    if (conv == null) {
      return;
    }

    conv.top = top;

    conv.operationTime =
        operationTime ?? conv.operationTime;

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

        if (aTop && !bTop) {
          return -1;
        }

        if (!aTop && bTop) {
          return 1;
        }

        final at = max(
          A?.operationTime ?? 0,
          A?.lastMessage?.sentTime ?? 0,
        );

        final bt = max(
          B?.operationTime ?? 0,
          B?.lastMessage?.sentTime ?? 0,
        );

        return bt.compareTo(at);
      });
    }
  }

  /// =========================
  /// rebuild cache
  /// =========================
  void _rebuildAllTabCache() {
    _tabCache.clear();

    _tabIds.forEach((tab, ids) {
      _tabCache[tab] = ids
          .where((e) => _allMap[e] != null)
          .map((e) => _allMap[e]!)
          .toList();
    });
  }

  /// =========================
  /// get list
  /// =========================
  List<RCIMIWConversation> getTabList(int tabIndex) {
    return _tabCache[tabIndex] ?? [];
  }

  /// =========================
  /// notify
  /// =========================
  void _notify() {
    _debounce?.cancel();

    _debounce = Timer(
      const Duration(milliseconds: 100),
          () {
        if (_disposed || _controller.isClosed) {
          return;
        }

        _controller.add({
          for (final e in _tabCache.entries)
            e.key: List.of(e.value),
        });
      },
    );
  }

  /// =========================
  /// dispose
  /// =========================
  Future<void> dispose() async {
    _disposed = true;

    await _messageSubscription?.cancel();

    await _groupEventSubscription?.cancel();

    _debounce?.cancel();

    _allMap.clear();
    _tabIds.clear();
    _tabCache.clear();

    if (!_controller.isClosed) {
      await _controller.close();
    }

    if (!_changeController.isClosed) {
      await _changeController.close();
    }
  }

  /// =========================
  /// api
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
        onSuccess: (c) {
          completer.complete(c);
        },
        onError: (_) {
          completer.complete(null);
        },
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

    if (engine == null) {
      return false;
    }

    final completer = Completer<bool>();

    final code = await engine.changeConversationTopStatus(
      type,
      targetId,
      channelId,
      top,
      callback: IRCIMIWChangeConversationTopStatusCallback(
        onConversationTopStatusChanged: (code) {
          completer.complete(code == 0);
          _onTopSync(
            type,
            targetId,
            top,
            operationTime: DateTime.now().millisecondsSinceEpoch,
          );
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

    if (engine == null) {
      return false;
    }

    final completer = Completer<bool>();

    await engine.clearUnreadCount(
      type,
      targetId,
      channelId,
      timestamp,
      callback: IRCIMIWClearUnreadCountCallback(
        onUnreadCountCleared: (code) {
          completer.complete(code == 0);

          _onReadSync(type, targetId);
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
    final t =
        timestamp ?? DateTime.now().millisecondsSinceEpoch;

    return clearUnreadCount(
      type: type,
      targetId: targetId,
      channelId: channelId,
      timestamp: t,
    );
  }

  Future<bool> setConversationDoNotDisturb({
    required RCIMIWConversationType type,
    required String targetId,
    String? channelId,
    required bool enabled,
  }) async {
    final engine = IMEngineManager().engine;

    if (engine == null) {
      return false;
    }

    final level = enabled
        ? RCIMIWPushNotificationLevel.blocked
        : RCIMIWPushNotificationLevel.allMessage;

    final completer = Completer<bool>();

    await engine.changeConversationNotificationLevel(
      type,
      targetId,
      channelId,
      level,
      callback:
      IRCIMIWChangeConversationNotificationLevelCallback(
        onConversationNotificationLevelChanged: (code) {
          completer.complete(code == 0);
        },
      ),
    );

    return completer.future;
  }

  Future<RCIMIWPushNotificationLevel?>
  getConversationNotificationLevel({
    required RCIMIWConversationType type,
    required String targetId,
    String? channelId,
  }) async {
    final engine = IMEngineManager().engine;

    if (engine == null) {
      return null;
    }

    final completer =
    Completer<RCIMIWPushNotificationLevel?>();

    final code = await engine.getConversationNotificationLevel(
      type,
      targetId,
      channelId,
      callback:
      IRCIMIWGetConversationNotificationLevelCallback(
        onSuccess: (level) {
          completer.complete(level);
        },
        onError: (_) {
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

    if (engine == null) {
      return null;
    }

    final completer = Completer<bool?>();

    final code = await engine.getConversationTopStatus(
      type,
      targetId,
      channelId,
      callback: IRCIMIWGetConversationTopStatusCallback(
        onSuccess: (top) {
          completer.complete(top);
        },
        onError: (_) {
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