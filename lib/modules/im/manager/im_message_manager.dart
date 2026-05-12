import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../call/rong_call_summary_parser.dart';
import '../result/im_result.dart';
import 'im_engine_manager.dart';

/// =========================
/// 消息来源
/// =========================
enum MessageSource {
  remote,
  local,
  history,
}

/// =========================
/// 消息事件类型
/// =========================
enum MessageEventType {
  add,
  delete,
  recall,
  clear,
  update,
}

/// =========================
/// 消息事件
/// =========================
class MessageEvent {
  final MessageEventType type;

  final RCIMIWMessage? message;
  final List<RCIMIWMessage>? messages;

  final RCIMIWConversationType? conversationType;

  final String? targetId;
  final String? channelId;

  final int? timestamp;

  const MessageEvent({
    required this.type,
    this.message,
    this.messages,
    this.conversationType,
    this.targetId,
    this.channelId,
    this.timestamp,
  });
}

/// =========================
/// ImMessageManager
/// =========================
class ImMessageManager {
  static final ImMessageManager _instance =
  ImMessageManager._internal();

  factory ImMessageManager() => _instance;

  ImMessageManager._internal();

  /// =========================
  /// 消息事件流
  /// =========================
  final _messageController =
  StreamController<MessageEvent>.broadcast();

  Stream<MessageEvent> get messageStream =>
      _messageController.stream;

  bool _inited = false;

  bool _disposed = false;

  /// =========================
  /// 去重缓存（LRU）
  /// =========================
  final Map<String, int> _messageCache = {};

  final int _maxCacheSize = 2000;

  /// =========================
  /// buffer（防乱序）
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

    /// 收到消息
    engine?.onMessageReceived =
        (
        RCIMIWMessage? message,
        int? left,
        bool? offline,
        bool? hasPackage,
        ) {
      if (message == null) return;

      onMessageReceived(message);
    };

    /// 消息撤回
    engine?.onRemoteMessageRecalled =
        (RCIMIWMessage? message) {
      if (message == null) return;

      onMessageRecalled(message);
    };

    /// 单聊已读
    engine?.onPrivateReadReceiptReceived =
        (
        String? targetId,
        String? channelId,
        int? timestamp,
        ) {
      onPrivateReadReceipt(
        targetId,
        channelId,
        timestamp,
      );
    };

    /// 群已读请求
    engine?.onGroupMessageReadReceiptRequestReceived =
        (
        String? targetId,
        String? messageUId,
        ) {
      onGroupReadRequest(
        targetId,
        messageUId,
      );
    };

    /// 群已读响应
    engine?.onGroupMessageReadReceiptResponseReceived =
        (
        String? targetId,
        String? messageUId,
        Map? respondUserIds,
        ) {
      onGroupReadResponse(
        targetId,
        messageUId,
        respondUserIds,
      );
    };
  }

  /// =========================
  /// 收到消息
  /// =========================
  void onMessageReceived(RCIMIWMessage message) {
    if (_disposed) return;

    _debugLogMessage('收到消息', message);

    _dispatchMessage(
      message,
      source: MessageSource.remote,
    );
  }

  /// =========================
  /// 消息撤回
  /// =========================
  void onMessageRecalled(RCIMIWMessage message) {
    if (_disposed) return;

    _messageController.add(
      MessageEvent(
        type: MessageEventType.recall,
        message: message,
      ),
    );
  }

  /// =========================
  /// 单聊已读
  /// =========================
  void onPrivateReadReceipt(
      String? targetId,
      String? channelId,
      int? timestamp,
      ) {}

  /// =========================
  /// 群已读请求
  /// =========================
  void onGroupReadRequest(
      String? targetId,
      String? messageUId,
      ) {}

  /// =========================
  /// 群已读响应
  /// =========================
  void onGroupReadResponse(
      String? targetId,
      String? messageUId,
      Map? respondUserIds,
      ) {}

  /// =========================
  /// 获取历史消息
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
    final completer =
    Completer<List<RCIMIWMessage>>();

    IRCIMIWGetMessagesCallback? callback =
    IRCIMIWGetMessagesCallback(
      onSuccess: (
          List<RCIMIWMessage>? t,
          ) {
        final list = t ?? [];

        if (kDebugMode) {
          debugPrint(
            '历史消息返回: count=${list.length}',
          );

          for (final msg in list) {
            _debugLogMessage(
              '历史消息',
              msg,
            );
          }
        }

        /// 历史消息统一走 dispatch
        for (final msg in list) {
          _dispatchMessage(
            msg,
            source: MessageSource.history,
          );
        }

        completer.complete(list);
      },
      onError: (int? code) {
        completer.completeError(
          Exception("获取历史消息: $code"),
        );
      },
    );

    final code =
    await IMEngineManager().engine?.getMessages(
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
      throw Exception("获取历史消息失败: $code");
    }

    return completer.future;
  }

  /// =========================
  /// 删除本地消息
  /// =========================
  Future<bool> deleteLocalMessages({
    required List<RCIMIWMessage> messages,
  }) async {
    final code =
    await IMEngineManager()
        .engine
        ?.deleteLocalMessages(messages);

    final success = code == 0;

    if (success) {
      /// 删除缓存
      for (final msg in messages) {
        final key = _messageCacheKey(msg);

        if (key != null) {
          _messageCache.remove(key);
        }
      }

      /// 通知 UI
      _messageController.add(
        MessageEvent(
          type: MessageEventType.delete,
          messages: messages,
        ),
      );
    }

    return success;
  }

  /// =========================
  /// 清空消息
  /// =========================
  Future<bool> clearMessages({
    required RCIMIWConversationType type,
    required String targetId,
    String? channelId,
    required int timestamp,
    RCIMIWMessageOperationPolicy policy =
        RCIMIWMessageOperationPolicy.localRemote,
  }) async {
    final code =
    await IMEngineManager().engine?.clearMessages(
      type,
      targetId,
      channelId,
      timestamp,
      policy,
    );

    final success = code == 0;

    if (success) {
      /// 清除缓存
      _messageCache.removeWhere((key, value) {
        return key.contains(targetId);
      });

      /// 通知 UI
      _messageController.add(
        MessageEvent(
          type: MessageEventType.clear,
          conversationType: type,
          targetId: targetId,
          channelId: channelId,
          timestamp: timestamp,
        ),
      );
    }

    return success;
  }

  /// =========================
  /// 撤回消息
  /// =========================
  Future<bool> recallMessage({
    required RCIMIWMessage message,
  }) async {
    final code =
    await IMEngineManager()
        .engine
        ?.recallMessage(message);

    return code == 0;
  }

  /// =========================
  /// 搜索消息
  /// =========================
  Future<ImResult<List<RCIMIWMessage>>>
  searchMessages({
    required RCIMIWConversationType type,
    required String targetId,
    required String keyword,
    required int startTime,
    required int count,
    String? channelId,
  }) async {
    final completer =
    Completer<ImResult<List<RCIMIWMessage>>>();

    final ret =
    await IMEngineManager().engine?.searchMessages(
      type,
      targetId,
      channelId,
      keyword,
      startTime,
      count,
      callback: IRCIMIWSearchMessagesCallback(
        onSuccess: (
            List<RCIMIWMessage>? t,
            ) {
          completer.complete(
            ImResult.success(data: t),
          );
        },
        onError: (code) {
          completer.complete(
            ImResult.error(
              code: code ?? -1,
            ),
          );
        },
      ),
    );

    if (ret != null && ret != 0) {
      return ImResult.error(code: ret);
    }

    return completer.future;
  }

  /// =========================
  /// 单聊已读回执
  /// =========================
  Future<bool>
  sendPrivateReadReceiptMessage({
    required String targetId,
    String? channelId,
    required int timestamp,
  }) async {
    final code =
    await IMEngineManager()
        .engine
        ?.sendPrivateReadReceiptMessage(
      targetId,
      channelId,
      timestamp,
    );

    return code == 0;
  }

  /// =========================
  /// 群已读请求
  /// =========================
  Future<bool> sendGroupReadReceiptRequest({
    required RCIMIWMessage message,
  }) async {
    final code =
    await IMEngineManager()
        .engine
        ?.sendGroupReadReceiptRequest(message);

    return code == 0;
  }

  /// =========================
  /// 群已读响应
  /// =========================
  Future<bool> sendGroupReadReceiptResponse({
    required String targetId,
    String? channelId,
    required List<RCIMIWMessage> messages,
  }) async {
    final code =
    await IMEngineManager()
        .engine
        ?.sendGroupReadReceiptResponse(
      targetId,
      channelId,
      messages,
    );

    return code == 0;
  }

  /// =========================
  /// 本地推送消息
  /// =========================
  void pushLocalMessage(RCIMIWMessage message) {
    if (_disposed) return;

    _dispatchMessage(
      message,
      source: MessageSource.local,
    );
  }

  /// =========================
  /// 核心 dispatch
  /// =========================
  void _dispatchMessage(
      RCIMIWMessage message, {
        required MessageSource source,
      }) {
    if (_disposed) return;

    final id = _messageCacheKey(message);

    if (id == null) return;

    /// 去重
    if (_messageCache.containsKey(id)) {
      return;
    }

    /// LRU
    if (_messageCache.length > _maxCacheSize) {
      _messageCache.remove(
        _messageCache.keys.first,
      );
    }

    _messageCache[id] =
        DateTime.now().millisecondsSinceEpoch;

    /// buffer
    _buffer.add(message);

    _scheduleFlush();

    if (kDebugMode) {
      debugPrint(
        "刷新消息: "
            "${message.messageId} "
            "key=$id "
            "source=$source",
      );
    }
  }

  /// =========================
  /// 生成唯一 key
  /// =========================
  String? _messageCacheKey(
      RCIMIWMessage message,
      ) {
    final callSummaryKey =
    RongCallSummaryParser.stableMessageKey(
      message,
    );

    if (callSummaryKey != null) {
      return callSummaryKey;
    }

    final messageUId = message.messageUId;

    if (messageUId != null &&
        messageUId.isNotEmpty) {
      return 'uid:$messageUId';
    }

    final messageId = message.messageId;

    if (messageId != null && messageId > 0) {
      return 'id:$messageId';
    }

    final timestamp =
        message.sentTime ?? message.receivedTime;

    final targetId = message.targetId;

    if (timestamp == null ||
        targetId == null ||
        targetId.isEmpty) {
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

  /// =========================
  /// flush
  /// =========================
  void _scheduleFlush() {
    _flushTimer?.cancel();

    _flushTimer = Timer(
      const Duration(milliseconds: 10),
          () {
        if (_disposed) return;

        for (final msg in _buffer) {
          _messageController.add(
            MessageEvent(
              type: MessageEventType.add,
              message: msg,
            ),
          );
        }

        _buffer.clear();
      },
    );
  }

  /// =========================
  /// debug
  /// =========================
  void _debugLogMessage(
      String prefix,
      RCIMIWMessage message,
      ) {
    if (!kDebugMode) return;

    debugPrint(
      '$prefix: '
          'id=${message.messageId} '
          'uid=${message.messageUId} '
          'type=${message.messageType} '
          'object=${_messageObjectName(message)} '
          'hasRawData=${_hasRawData(message)} '
          'hasFields=${_hasFields(message)}',
    );
  }

  String? _messageObjectName(
      RCIMIWMessage message,
      ) {
    if (message is RCIMIWUnknownMessage) {
      return message.objectName;
    }

    if (message is RCIMIWNativeCustomMessage) {
      return message.messageIdentifier;
    }

    if (message is RCIMIWCustomMessage) {
      return message.identifier;
    }

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