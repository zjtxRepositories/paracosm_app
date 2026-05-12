import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../call/rong_call_summary_parser.dart';
import '../result/im_result.dart';
import 'im_engine_manager.dart';

/// =========================
/// 消息来源（新增，不影响原逻辑）
/// =========================
enum MessageSource { remote, local, history }

/// =========================
/// ImMessageManager（增强版）
/// =========================
class ImMessageManager {
  static final ImMessageManager _instance = ImMessageManager._internal();
  factory ImMessageManager() => _instance;
  ImMessageManager._internal();

  /// =========================
  /// 原始消息流（全局）
  /// =========================
  final _messageController = StreamController<RCIMIWMessage>.broadcast();

  Stream<RCIMIWMessage> get messageStream => _messageController.stream;

  bool _inited = false;
  bool _disposed = false;

  /// =========================
  /// 🔥 去重（LRU 防止内存爆炸）
  /// =========================
  final Map<String, int> _messageCache = {};
  final int _maxCacheSize = 2000;

  /// =========================
  /// 🔥 排序缓冲（防乱序扩展点）
  /// =========================
  final List<RCIMIWMessage> _buffer = [];

  Timer? _flushTimer;

  /// =========================
  /// 初始化监听
  /// =========================
  void initListener() {
    if (_inited) return;
    _inited = true;

    final engine = IMEngineManager().engine;

    engine?.onMessageReceived =
        (RCIMIWMessage? message, int? left, bool? offline, bool? hasPackage) {
          if (message == null) return;
          onMessageReceived(message);
        };

    engine?.onRemoteMessageRecalled = (RCIMIWMessage? message) {
      if (message == null) return;
      onMessageRecalled(message);
    };

    engine?.onPrivateReadReceiptReceived =
        (String? targetId, String? channelId, int? timestamp) {
          onPrivateReadReceipt(targetId, channelId, timestamp);
        };

    engine?.onGroupMessageReadReceiptRequestReceived =
        (String? targetId, String? messageUId) {
          onGroupReadRequest(targetId, messageUId);
        };

    engine?.onGroupMessageReadReceiptResponseReceived =
        (String? targetId, String? messageUId, Map? respondUserIds) {
          onGroupReadResponse(targetId, messageUId, respondUserIds);
        };
  }

  /// =========================
  /// 🔥 消息接收（核心）
  /// =========================
  void onMessageReceived(RCIMIWMessage message) {
    if (_disposed) return;

    _debugLogMessage('收到消息', message);
    _dispatchMessage(message, source: MessageSource.remote);
  }

  /// =========================
  /// 撤回消息
  /// =========================
  void onMessageRecalled(RCIMIWMessage message) {
    if (_disposed) return;

    // 保留扩展点（后续可更新 UI 状态）
  }

  void onPrivateReadReceipt(
    String? targetId,
    String? channelId,
    int? timestamp,
  ) {}

  void onGroupReadRequest(String? targetId, String? messageUId) {}

  void onGroupReadResponse(
    String? targetId,
    String? messageUId,
    Map? respondUserIds,
  ) {}

  /// =========================
  /// 获取历史消息（原样保留）
  /// =========================
  Future<List<RCIMIWMessage>> getMessages({
    required RCIMIWConversationType type,
    required String targetId,
    required int sentTime,
    required RCIMIWTimeOrder order,
    required RCIMIWMessageOperationPolicy policy,
    int count = 15,
    String? channelId,
  }) async {
    final completer = Completer<List<RCIMIWMessage>>();

    IRCIMIWGetMessagesCallback? callback = IRCIMIWGetMessagesCallback(
      onSuccess: (List<RCIMIWMessage>? t) {
        final list = t ?? [];
        if (kDebugMode) {
          debugPrint('历史消息返回: count=${list.length}');
          for (final msg in list) {
            _debugLogMessage('历史消息', msg);
          }
        }

        /// 🔥 历史消息统一走 dispatch（保证一致性）
        for (final msg in list) {
          _dispatchMessage(msg, source: MessageSource.history);
        }

        completer.complete(list);
      },
      onError: (int? code) {
        completer.completeError(Exception("获取历史消息1: $code"));
      },
    );

    final code = await IMEngineManager().engine?.getMessages(
      type,
      targetId,
      channelId,
      sentTime,
      order,
      policy,
      count,
      callback: callback,
    );

    if (code != 0) {
      throw Exception("获取历史消息2: $code");
    }

    return completer.future;
  }

  /// =========================
  /// 删除消息（原样）
  /// =========================
  Future<bool> deleteLocalMessages({
    required List<RCIMIWMessage> messages,
  }) async {
    final code = await IMEngineManager().engine?.deleteLocalMessages(messages);
    return code == 0;
  }

  /// =========================
  /// 撤回消息（原样）
  /// =========================
  Future<bool> recallMessage({required RCIMIWMessage message}) async {
    final code = await IMEngineManager().engine?.recallMessage(message);
    return code == 0;
  }

  /// =========================
  /// 搜索消息（原样）
  /// =========================
  Future<ImResult<List<RCIMIWMessage>>> searchMessages({
    required RCIMIWConversationType type,
    required String targetId,
    required String keyword,
    required int startTime,
    required int count,
    String? channelId,
  }) async {
    final completer = Completer<ImResult<List<RCIMIWMessage>>>();

    final ret = await IMEngineManager().engine?.searchMessages(
      type,
      targetId,
      channelId,
      keyword,
      startTime,
      count,
      callback: IRCIMIWSearchMessagesCallback(
        onSuccess: (List<RCIMIWMessage>? t) {
          completer.complete(ImResult.success(data: t));
        },
        onError: (code) {
          completer.complete(ImResult.error(code: code ?? -1));
        },
      ),
    );

    if (ret == null) {
      return ImResult.error(code: -1);
    }

    if (ret != 0) {
      return ImResult.error(code: ret);
    }

    return completer.future;
  }

  Future<ImResult<List<RCIMIWMessage>>> getMessagesAroundTime({
    required RCIMIWConversationType type,
    required String targetId,
    required int sentTime,
    int beforeCount = 10,
    int afterCount = 10,
    String? channelId,
  }) async {
    final completer = Completer<ImResult<List<RCIMIWMessage>>>();

    final ret = await IMEngineManager().engine?.getMessagesAroundTime(
      type,
      targetId,
      channelId,
      sentTime,
      beforeCount,
      afterCount,
      callback: IRCIMIWGetMessagesAroundTimeCallback(
        onSuccess: (List<RCIMIWMessage>? t) {
          completer.complete(ImResult.success(data: t ?? []));
        },
        onError: (code) {
          completer.complete(ImResult.error(code: code ?? -1));
        },
      ),
    );

    if (ret == null) {
      return ImResult.error(code: -1);
    }

    if (ret != 0) {
      return ImResult.error(code: ret);
    }

    return completer.future;
  }

  /// =========================
  /// 已读回执（原样）
  /// =========================
  Future<bool> sendPrivateReadReceiptMessage({
    required String targetId,
    String? channelId,
    required int timestamp,
  }) async {
    final code = await IMEngineManager().engine?.sendPrivateReadReceiptMessage(
      targetId,
      channelId,
      timestamp,
    );
    return code == 0;
  }

  /// =========================
  /// 群已读请求（原样）
  /// =========================
  Future<bool> sendGroupReadReceiptRequest({
    required RCIMIWMessage message,
  }) async {
    final code = await IMEngineManager().engine?.sendGroupReadReceiptRequest(
      message,
    );
    return code == 0;
  }

  /// =========================
  /// 群已读响应（原样）
  /// =========================
  Future<bool> sendGroupReadReceiptResponse({
    required String targetId,
    String? channelId,
    required List<RCIMIWMessage> messages,
  }) async {
    final code = await IMEngineManager().engine?.sendGroupReadReceiptResponse(
      targetId,
      channelId,
      messages,
    );
    return code == 0;
  }

  /// =========================
  /// 🆕 UI主动推送（发送消息后立刻刷新）
  /// =========================
  void pushLocalMessage(RCIMIWMessage message) {
    if (_disposed) return;
    _dispatchMessage(message, source: MessageSource.local);
  }

  /// =========================
  /// 🔥 核心 dispatch（增强版）
  /// =========================
  void _dispatchMessage(
    RCIMIWMessage message, {
    required MessageSource source,
  }) {
    if (_disposed) return;

    final id = _messageCacheKey(message);
    if (id == null) return;

    /// =========================
    /// 去重（LRU）
    /// =========================
    if (_messageCache.containsKey(id)) return;

    if (_messageCache.length > _maxCacheSize) {
      _messageCache.remove(_messageCache.keys.first);
    }

    _messageCache[id] = DateTime.now().millisecondsSinceEpoch;

    /// =========================
    /// buffer（扩展排序能力）
    /// =========================
    _buffer.add(message);

    _scheduleFlush();

    if (kDebugMode) {
      debugPrint("刷新消息: ${message.messageId} key=$id source=$source");
    }
  }

  String? _messageCacheKey(RCIMIWMessage message) {
    final callSummaryKey = RongCallSummaryParser.stableMessageKey(message);
    if (callSummaryKey != null) return callSummaryKey;

    final messageId = message.messageId;
    if (messageId != null && messageId > 0) {
      return 'id:$messageId';
    }

    final messageUId = message.messageUId;
    if (messageUId != null && messageUId.isNotEmpty) {
      return 'uid:$messageUId';
    }

    final timestamp = message.sentTime ?? message.receivedTime;
    final targetId = message.targetId;
    if (timestamp == null || targetId == null || targetId.isEmpty) {
      return null;
    }

    return [
      'fallback',
      message.conversationType?.index ?? -1,
      targetId,
      message.channelId ?? '',
      message.senderUserId ?? '',
      timestamp,
      message.messageType?.index ?? -1,
      _messageObjectName(message) ?? '',
    ].join(':');
  }

  void _debugLogMessage(String prefix, RCIMIWMessage message) {
    if (!kDebugMode) return;

    debugPrint(
      '$prefix: id=${message.messageId} uid=${message.messageUId} '
      'type=${message.messageType} object=${_messageObjectName(message)} '
      'hasRawData=${_hasRawData(message)} hasFields=${_hasFields(message)}',
    );
  }

  String? _messageObjectName(RCIMIWMessage message) {
    if (message is RCIMIWUnknownMessage) return message.objectName;
    if (message is RCIMIWNativeCustomMessage) return message.messageIdentifier;
    if (message is RCIMIWCustomMessage) return message.identifier;
    return null;
  }

  bool _hasRawData(RCIMIWMessage message) {
    return message is RCIMIWUnknownMessage &&
        (message.rawData?.isNotEmpty ?? false);
  }

  bool _hasFields(RCIMIWMessage message) {
    if (message is RCIMIWNativeCustomMessage) {
      return message.fields?.isNotEmpty ?? false;
    }
    if (message is RCIMIWCustomMessage) {
      return message.fields?.isNotEmpty ?? false;
    }
    return false;
  }

  /// =========================
  /// 批量 flush（可扩展排序）
  /// =========================
  void _scheduleFlush() {
    _flushTimer?.cancel();

    _flushTimer = Timer(const Duration(milliseconds: 10), () {
      if (_disposed) return;

      for (final msg in _buffer) {
        _messageController.add(msg);
      }
      _buffer.clear();
    });
  }

  /// =========================
  /// dispose
  /// =========================
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    _flushTimer?.cancel();
    _messageController.close();
    _messageCache.clear();
    _buffer.clear();
  }
}
