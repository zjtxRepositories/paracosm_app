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
  /// Stream
  /// =========================
  final _controller =
  StreamController<Map<int, List<RCIMIWConversation>>>.broadcast();

  Stream<Map<int, List<RCIMIWConversation>>> get stream =>
      _controller.stream;

  /// =========================
  /// 多 Tab 缓存
  /// =========================
  final Map<int, List<RCIMIWConversation>> _tabCache = {};
  Map<int, List<RCIMIWConversation>> get tabCache => _tabCache;

  /// Tab 类型
  final List<List<RCIMIWConversationType>> tabTypes = [
    RCIMIWConversationType.values,
    [RCIMIWConversationType.private],
    [RCIMIWConversationType.group],
    [RCIMIWConversationType.system],
  ];

  bool _inited = false;
  bool _loaded = false;
  StreamSubscription<RCIMIWMessage>? _messageSubscription;

  /// =========================
  /// 初始化监听（只执行一次）
  /// =========================
  void initListener() {
    if (_inited) return;
    _inited = true;

    final engine = IMEngineManager().engine;

    _messageSubscription ??= ImMessageManager().messageStream.listen(
      handleIncomingMessage,
    );

    /// 会话同步完成
    engine?.onRemoteConversationListSynced = (int? code) {
      debugPrint("会话同步完成: $code");

      /// 🔥 一次性加载全部 Tab
      initAllTabs();
    };

    /// 已读同步
    engine?.onConversationReadStatusSyncMessageReceived =
        (RCIMIWConversationType? type, String? targetId, int? timestamp) {
      _onReadSync(targetId);
    };

    /// 拉远端
    getRemoteConversationList();
  }

  /// =========================
  /// 🔥 初始化全部 Tab（核心）
  /// =========================
  Future<void> initAllTabs() async {
    if (_loaded) return;
    _loaded = true;

    final futures = <Future>[];

    for (int i = 0; i < tabTypes.length; i++) {
      futures.add(
        getConversations(
          i,
          tabTypes[i],
          0,
          50,
          "",
        ),
      );
    }

    await Future.wait(futures);

    _notify();
  }

  /// =========================
  /// 拉远端
  /// =========================
  Future<void> getRemoteConversationList() async {
    IMEngineManager().engine?.getRemoteConversationList();
  }

  /// =========================
  /// 获取会话（带 Tab）
  /// =========================
  Future<void> getConversations(
      int tabIndex,
      List<RCIMIWConversationType> types,
      int startTime,
      int count,
      String? channelId,
      ) async {
    final completer = Completer<void>();

    final callback = IRCIMIWGetConversationsCallback(
      onSuccess: (list) {
        final cache = _tabCache[tabIndex] ?? [];

        if (startTime == 0) {
          cache.clear();
        }

        cache.addAll(list ?? []);

        _sort(cache);

        _tabCache[tabIndex] = cache;

        completer.complete();
      },
      onError: (code) {
        debugPrint("获取会话失败: $code");
        completer.completeError(code ?? -1);
      },
    );

    await IMEngineManager().engine?.getConversations(
      types,
      channelId,
      startTime,
      count,
      callback: callback,
    );

    return completer.future;
  }

  /// =========================
  /// 新消息处理（🔥核心）
  /// =========================
  void handleIncomingMessage(RCIMIWMessage msg) {
    bool hit = false;

    for (var entry in _tabCache.entries) {
      final list = entry.value;

      final index =
      list.indexWhere((e) => e.targetId == msg.targetId);

      if (index != -1) {
        hit = true;

        list[index].lastMessage = msg;

        list[index].unreadCount =
            (list[index].unreadCount ?? 0) + 1;
      }
    }

    /// 没命中 → 刷新全部（兜底）
    if (!hit) {
      _loaded = false;
      initAllTabs();
      return;
    }

    _sortAll();
    _notify();
  }

  /// =========================
  /// 已读同步
  /// =========================
  void _onReadSync(String? targetId) {
    if (targetId == null) return;

    for (var list in _tabCache.values) {
      final index =
      list.indexWhere((e) => e.targetId == targetId);

      if (index != -1) {
        list[index].unreadCount = 0;
      }
    }

    _notify();
  }

  /// =========================
  /// 删除会话（全局）
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
          for (var list in _tabCache.values) {
            list.removeWhere((e) => e.targetId == targetId);
          }

          _notify();
          completer.complete();
          return;
        }

        completer.completeError(code ?? -1);
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
  /// 全量排序
  /// =========================
  void _sortAll() {
    for (var list in _tabCache.values) {
      _sort(list);
    }
  }

  /// =========================
  /// 排序规则
  /// =========================
  void _sort(List<RCIMIWConversation> list) {
    list.sort((a, b) {
      final aTop = a.top ?? false;
      final bTop = b.top ?? false;

      /// 置顶优先
      if (aTop != bTop) {
        return (bTop ? 1 : 0) - (aTop ? 1 : 0);
      }

      /// 时间排序
      final aTime = a.lastMessage?.sentTime ?? 0;
      final bTime = b.lastMessage?.sentTime ?? 0;

      return bTime.compareTo(aTime);
    });
  }

  /// =========================
  /// 发送消息后刷新（推荐🔥）
  /// =========================
  void refreshAfterSend(
      String targetId,
      RCIMIWMessage message,
      ) {
    bool hit = false;

    for (var entry in _tabCache.entries) {
      final list = entry.value;

      final index =
      list.indexWhere((e) => e.targetId == targetId);

      if (index != -1) {
        hit = true;

        /// 更新最后一条消息
        list[index].lastMessage = message;

        /// 自己发的消息一般不加未读
        /// 如果你要兼容多端，可以判断 senderId

        /// 移动到顶部（关键🔥）
        final conv = list.removeAt(index);
        list.insert(0, conv);
      }
    }

    /// 没找到 → 补拉（极少情况）
    if (!hit) {
      _loaded = false;
      initAllTabs();
      return;
    }

    _sortAll();
    _notify();
  }

  /// =========================
  /// 当前 Tab 数据
  /// =========================
  List<RCIMIWConversation> getTabList(int tabIndex) {
    return _tabCache[tabIndex] ?? [];
  }

  /// =========================
  /// 通知 UI
  /// =========================
  void _notify() {
    if (!_controller.isClosed) {
      _controller.add(Map.from(_tabCache));
    }
  }

  void dispose() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _controller.close();
  }
}
