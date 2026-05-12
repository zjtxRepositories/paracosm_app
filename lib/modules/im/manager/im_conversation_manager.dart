import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import 'im_message_manager.dart';
import 'im_engine_manager.dart';

class ImConversationManager {
  /// =========================
  /// 单例
  /// =========================
  static final ImConversationManager _instance =
      ImConversationManager._internal();

  factory ImConversationManager() => _instance;

  ImConversationManager._internal();

  /// =========================
  /// Stream（节流）
  /// =========================
  final _controller =
      StreamController<Map<int, List<RCIMIWConversation>>>.broadcast();

  Stream<Map<int, List<RCIMIWConversation>>> get stream => _controller.stream;

  Timer? _debounce;

  /// =========================
  /// 核心数据（唯一源）
  /// =========================
  final Map<String, RCIMIWConversation> _allMap = {};

  /// Tab -> targetId 列表
  final Map<int, List<String>> _tabIds = {};

  /// =========================
  /// Tab 类型
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

  StreamSubscription<RCIMIWMessage>? _messageSubscription;

  /// =========================
  /// 初始化
  /// =========================
  void initListener() {
    if (_inited) return;
    _inited = true;

    final engine = IMEngineManager().engine;

    _messageSubscription ??= ImMessageManager().messageStream.listen(
      _onMessage,
    );

    /// 已读同步
    engine?.onConversationReadStatusSyncMessageReceived =
        (type, targetId, timestamp) {
          _onReadSync(targetId);
        };

    getRemoteConversationList();
  }

  Future<void> initAll() async {
    await _initAllTabs();
  }

  /// =========================
  /// 拉远端
  /// =========================
  Future<void> getRemoteConversationList() async {
    await _initAllTabs();
  }

  /// =========================
  /// 初始化全部 Tab
  /// =========================
  Future<void> _initAllTabs() async {
    if (_loading) return;
    _loading = true;

    try {
      _allMap.clear();
      _tabIds.clear();

      final futures = <Future>[];

      for (int i = 0; i < tabTypes.length; i++) {
        futures.add(_loadTab(i));
      }

      await Future.wait(futures);
      _notify();
    } finally {
      _loading = false;
    }
  }

  /// =========================
  /// 加载单个 Tab
  /// =========================
  Future<void> _loadTab(int tabIndex) async {
    final completer = Completer<void>();

    final callback = IRCIMIWGetConversationsCallback(
      onSuccess: (list) {
        final ids = <String>[];

        for (var conv in list ?? []) {
          final id = conv.targetId;
          if (id == null) continue;

          _allMap[id] = conv;
          ids.add(id);
        }

        _sortIds(ids);
        _tabIds[tabIndex] = ids;

        completer.complete();
      },
      onError: (code) {
        debugPrint("获取会话失败: $code");
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
    debugPrint("获取会话成功: ");

    return completer.future;
  }

  /// =========================
  /// 获取单个会话
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
          debugPrint("获取会话成功: $conversation");
          completer.complete(conversation);
        },
        onError: (code) {
          debugPrint("获取会话失败: $code");
          completer.completeError(code ?? -1);
        },
      ),
    );

    return completer.future;
  }

  /// =========================
  /// 新消息
  /// =========================
  void _onMessage(RCIMIWMessage msg) {
    final targetId = msg.targetId;
    if (targetId == null) return;

    final conv = _allMap[targetId];

    /// 已存在
    if (conv != null) {
      conv.lastMessage = msg;
      if (msg.senderUserId != IMEngineManager().currentUserId) {
        conv.unreadCount = (conv.unreadCount ?? 0) + 1;
      }

      _sortAllTabs();
    } else {
      /// 新会话
      _insertNewConversation(msg);
      _sortAllTabs();
    }

    _notify();
  }

  /// =========================
  /// 插入新会话
  /// =========================
  void _insertNewConversation(RCIMIWMessage msg) {
    final conv = RCIMIWConversation.create();
    conv.targetId = msg.targetId;
    conv.conversationType = msg.conversationType;
    conv.lastMessage = msg;
    if (msg.senderUserId != IMEngineManager().currentUserId) {
      conv.unreadCount = 1;
    }

    final id = msg.targetId!;
    _allMap[id] = conv;

    for (int i = 0; i < tabTypes.length; i++) {
      if (tabTypes[i].contains(conv.conversationType)) {
        _tabIds.putIfAbsent(i, () => []);
        _tabIds[i]!.insert(0, id);
      }
    }
  }

  /// =========================
  /// 已读同步
  /// =========================
  void _onReadSync(String? targetId) {
    if (targetId == null) return;
    final conv = _allMap[targetId];
    if (conv != null) {
      conv.unreadCount = 0;
      _notify();
    }
  }

  Future<bool> markConversationRead({
    required RCIMIWConversationType type,
    required String targetId,
    String? channelId,
    int? timestamp,
  }) async {
    final readTime = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    final cleared = await clearUnreadCount(
      type: type,
      targetId: targetId,
      channelId: channelId,
      timestamp: readTime,
    );

    if (cleared && type == RCIMIWConversationType.private) {
      await syncConversationReadStatus(
        type: type,
        targetId: targetId,
        channelId: channelId,
        timestamp: readTime,
      );
    }

    return cleared;
  }

  Future<bool> clearUnreadCount({
    required RCIMIWConversationType type,
    required String targetId,
    String? channelId,
    required int timestamp,
  }) async {
    final completer = Completer<bool>();

    final code = await IMEngineManager().engine?.clearUnreadCount(
      type,
      targetId,
      channelId,
      timestamp,
      callback: IRCIMIWClearUnreadCountCallback(
        onUnreadCountCleared: (code) {
          if (code == 0) {
            _clearLocalUnreadCount(targetId);
            completer.complete(true);
          } else {
            debugPrint("清除会话未读数失败: $code");
            completer.complete(false);
          }
        },
      ),
    );

    if (code != 0 && !completer.isCompleted) {
      debugPrint("清除会话未读数调用失败: $code");
      completer.complete(false);
    }

    return completer.future;
  }

  Future<bool> syncConversationReadStatus({
    required RCIMIWConversationType type,
    required String targetId,
    String? channelId,
    required int timestamp,
  }) async {
    final completer = Completer<bool>();

    final code = await IMEngineManager().engine?.syncConversationReadStatus(
      type,
      targetId,
      channelId,
      timestamp,
      callback: IRCIMIWSyncConversationReadStatusCallback(
        onConversationReadStatusSynced: (code) {
          if (code == 0) {
            completer.complete(true);
          } else {
            debugPrint("同步会话已读状态失败: $code");
            completer.complete(false);
          }
        },
      ),
    );

    if (code != 0 && !completer.isCompleted) {
      debugPrint("同步会话已读状态调用失败: $code");
      completer.complete(false);
    }

    return completer.future;
  }

  Future<RCIMIWPushNotificationLevel?> getConversationNotificationLevel({
    required RCIMIWConversationType type,
    required String targetId,
    String? channelId,
  }) async {
    final engine = IMEngineManager().engine;
    if (engine == null) {
      debugPrint("获取会话通知级别失败: engine is null");
      return null;
    }

    final completer = Completer<RCIMIWPushNotificationLevel?>();
    final code = await engine.getConversationNotificationLevel(
      type,
      targetId,
      channelId,
      callback: IRCIMIWGetConversationNotificationLevelCallback(
        onSuccess: (level) {
          _updateLocalNotificationLevel(targetId, level);
          completer.complete(level);
        },
        onError: (code) {
          debugPrint("获取会话通知级别失败: $code");
          completer.complete(null);
        },
      ),
    );

    if (code != 0 && !completer.isCompleted) {
      debugPrint("获取会话通知级别调用失败: $code");
      completer.complete(null);
    }

    return completer.future;
  }

  Future<bool> setConversationDoNotDisturb({
    required RCIMIWConversationType type,
    required String targetId,
    String? channelId,
    required bool enabled,
  }) async {
    final engine = IMEngineManager().engine;
    if (engine == null) {
      debugPrint("设置会话免打扰失败: engine is null");
      return false;
    }

    final level = enabled
        ? RCIMIWPushNotificationLevel.blocked
        : RCIMIWPushNotificationLevel.allMessage;
    final completer = Completer<bool>();
    final code = await engine.changeConversationNotificationLevel(
      type,
      targetId,
      channelId,
      level,
      callback: IRCIMIWChangeConversationNotificationLevelCallback(
        onConversationNotificationLevelChanged: (code) {
          if (code == 0) {
            _updateLocalNotificationLevel(targetId, level);
            completer.complete(true);
          } else {
            debugPrint("设置会话免打扰失败: $code");
            completer.complete(false);
          }
        },
      ),
    );

    if (code != 0 && !completer.isCompleted) {
      debugPrint("设置会话免打扰调用失败: $code");
      completer.complete(false);
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
      debugPrint("获取会话置顶状态失败: engine is null");
      return null;
    }

    final completer = Completer<bool?>();
    final code = await engine.getConversationTopStatus(
      type,
      targetId,
      channelId,
      callback: IRCIMIWGetConversationTopStatusCallback(
        onSuccess: (top) {
          _updateLocalTopStatus(targetId, top ?? false);
          completer.complete(top);
        },
        onError: (code) {
          debugPrint("获取会话置顶状态失败: $code");
          completer.complete(null);
        },
      ),
    );

    if (code != 0 && !completer.isCompleted) {
      debugPrint("获取会话置顶状态调用失败: $code");
      completer.complete(null);
    }

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
      debugPrint("设置会话置顶失败: engine is null");
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
          if (code == 0) {
            _updateLocalTopStatus(targetId, top);
            completer.complete(true);
          } else {
            debugPrint("设置会话置顶失败: $code");
            completer.complete(false);
          }
        },
      ),
    );

    if (code != 0 && !completer.isCompleted) {
      debugPrint("设置会话置顶调用失败: $code");
      completer.complete(false);
    }

    return completer.future;
  }

  void _clearLocalUnreadCount(String targetId) {
    final conv = _allMap[targetId];
    if (conv == null || conv.unreadCount == 0) return;

    conv.unreadCount = 0;
    _notify();
  }

  void _updateLocalNotificationLevel(
    String targetId,
    RCIMIWPushNotificationLevel? level,
  ) {
    final conv = _allMap[targetId];
    if (conv == null) return;

    conv.notificationLevel = level;
    _notify();
  }

  void _updateLocalTopStatus(String targetId, bool top) {
    final conv = _allMap[targetId];
    if (conv == null) return;

    conv.top = top;
    _sortAllTabs();
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

    final callback = IRCIMIWRemoveConversationCallback(
      onConversationRemoved: (int? code) {
        if (code == 0) {
          _allMap.remove(targetId);

          for (var list in _tabIds.values) {
            list.remove(targetId);
          }

          _notify();
          completer.complete();
        } else {
          completer.completeError(code ?? -1);
        }
      },
    );

    await IMEngineManager().engine?.removeConversation(
      type,
      targetId,
      channelId,
      callback: callback,
    );

    return completer.future;
  }

  /// =========================
  /// 刷新
  /// =========================
  void onNewMessage(String targetId, RCIMIWMessage message) {
    final conv = _allMap[targetId];

    if (conv != null) {
      conv.lastMessage = message;
      _sortAllTabs();
    } else {
      _insertNewConversation(message);
      _sortAllTabs();
    }

    _notify();
  }

  void _sortAllTabs() {
    for (final ids in _tabIds.values) {
      _sortIds(ids);
    }
  }

  /// =========================
  /// 排序（仅初始化用）
  /// =========================
  void _sortIds(List<String> ids) {
    ids.sort((a, b) {
      final convA = _allMap[a];
      final convB = _allMap[b];

      final aTop = convA?.top ?? false;
      final bTop = convB?.top ?? false;

      if (aTop != bTop) {
        return (bTop ? 1 : 0) - (aTop ? 1 : 0);
      }

      final aTime = convA?.lastMessage?.sentTime ?? 0;
      final bTime = convB?.lastMessage?.sentTime ?? 0;

      return bTime.compareTo(aTime);
    });
  }

  /// =========================
  /// 获取 Tab 数据
  /// =========================
  List<RCIMIWConversation> getTabList(int tabIndex) {
    final ids = _tabIds[tabIndex] ?? [];
    return ids.map((e) => _allMap[e]!).toList();
  }

  /// =========================
  /// 通知 UI（节流）
  /// =========================
  void _notify() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 100), () {
      if (!_controller.isClosed) {
        final map = <int, List<RCIMIWConversation>>{};
        _tabIds.forEach((key, value) {
          map[key] = value.map((e) => _allMap[e]!).toList();
        });
        _controller.add(map);
      }
    });
  }

  /// =========================
  /// 销毁
  /// =========================
  void dispose() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _debounce?.cancel();
    _controller.close();
  }
}
