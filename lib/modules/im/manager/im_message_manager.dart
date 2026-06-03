import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../call/rong_call_summary_parser.dart';
import '../result/im_result.dart';
import 'im_burn_after_reading_manager.dart';
import 'im_engine_manager.dart';

/// =========================
/// 消息来源
/// =========================
enum MessageSource { remote, local, history }

/// =========================
/// 消息事件类型
/// =========================
enum MessageEventType {
  add,
  delete,
  recall,
  clear,
  update,
  privateReadReceipt,
  groupReadReceiptRequest,
  groupReadReceiptResponse,
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

  final String? messageUId;

  final Map? respondUserIds;

  const MessageEvent({
    required this.type,
    this.message,
    this.messages,
    this.conversationType,
    this.targetId,
    this.channelId,
    this.timestamp,
    this.messageUId,
    this.respondUserIds,
  });
}

/// =========================
/// ImMessageManager
/// =========================
class ImMessageManager {
  static final ImMessageManager _instance = ImMessageManager._internal();

  factory ImMessageManager() => _instance;

  ImMessageManager._internal();

  /// =========================
  /// 消息事件流
  /// =========================
  final _messageController = StreamController<MessageEvent>.broadcast();

  Stream<MessageEvent> get messageStream => _messageController.stream;

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

  final ImBurnAfterReadingManager _burnAfterReadingManager =
      ImBurnAfterReadingManager();

  final Map<String, RCIMIWMessage> _burnAfterReadingMessages = {};

  final Map<String, Timer> _burnAfterReadingTimers = {};

  final Set<String> _burnAfterReadingDeletingKeys = {};

  /// =========================
  /// 初始化监听
  /// =========================
  void initListener() {
    if (_inited) return;

    _inited = true;

    final engine = IMEngineManager().engine;

    /// 收到消息
    engine?.onMessageReceived =
        (RCIMIWMessage? message, int? left, bool? offline, bool? hasPackage) {
          if (message == null) return;

          onMessageReceived(message);
        };

    /// 消息撤回
    engine?.onRemoteMessageRecalled = (RCIMIWMessage? message) {
      if (kDebugMode) {
        debugPrint('消息撤回----------$message');
      }
      if (message == null) return;

      onMessageRecalled(message);
    };

    /// 单聊已读
    engine?.onPrivateReadReceiptReceived =
        (String? targetId, String? channelId, int? timestamp) {
          if (kDebugMode) {
            debugPrint('单聊已读----------$timestamp--$targetId');
          }
          onPrivateReadReceipt(targetId, channelId, timestamp);
        };

    /// 群已读请求
    engine?.onGroupMessageReadReceiptRequestReceived =
        (String? targetId, String? messageUId) {
          onGroupReadRequest(targetId, messageUId);
        };

    /// 群已读响应
    engine?.onGroupMessageReadReceiptResponseReceived =
        (String? targetId, String? messageUId, Map? respondUserIds) {
          onGroupReadResponse(targetId, messageUId, respondUserIds);
        };

    /// 本地消息删除（包含 SDK 自动焚烧删除回调）
    // ignore: deprecated_member_use
    engine?.onLocalMessagesDeleted =
        (int? code, List<RCIMIWMessage>? messages) {
          if (code != 0 || messages == null || messages.isEmpty) return;

          onMessagesDeleted(messages: messages);
        };

    /// 远端消息删除（包含 SDK 自动焚烧删除回调）
    // ignore: deprecated_member_use
    engine?.onMessagesDeleted =
        (
          int? code,
          RCIMIWConversationType? type,
          String? targetId,
          String? channelId,
          List<RCIMIWMessage>? messages,
        ) {
          if (code != 0 || messages == null || messages.isEmpty) return;

          onMessagesDeleted(
            messages: messages,
            conversationType: type,
            targetId: targetId,
            channelId: channelId,
          );
        };
  }

  /// =========================
  /// 收到消息
  /// =========================
  void onMessageReceived(RCIMIWMessage message) {
    if (_disposed) return;

    if (_isRecallMessage(message)) {
      onMessageRecalled(message);
      return;
    }

    _debugLogMessage('收到消息', message);

    _dispatchMessage(message, source: MessageSource.remote);
  }

  /// =========================
  /// 消息撤回
  /// =========================
  void onMessageRecalled(RCIMIWMessage message) {
    if (_disposed) return;

    _messageController.add(
      MessageEvent(type: MessageEventType.recall, message: message),
    );
  }

  /// =========================
  /// 单聊已读
  /// =========================
  void onPrivateReadReceipt(
    String? targetId,
    String? channelId,
    int? timestamp,
  ) {
    if (_disposed || targetId == null || timestamp == null) return;

    unawaited(
      _startSentMessagesBurnAfterReading(
        targetId: targetId,
        channelId: channelId,
        readReceiptTime: timestamp,
      ),
    );

    _messageController.add(
      MessageEvent(
        type: MessageEventType.privateReadReceipt,
        conversationType: RCIMIWConversationType.private,
        targetId: targetId,
        channelId: channelId,
        timestamp: timestamp,
      ),
    );
  }

  /// =========================
  /// 群已读请求
  /// =========================
  void onGroupReadRequest(String? targetId, String? messageUId) {
    if (_disposed ||
        targetId == null ||
        messageUId == null ||
        messageUId.isEmpty) {
      return;
    }

    _messageController.add(
      MessageEvent(
        type: MessageEventType.groupReadReceiptRequest,
        conversationType: RCIMIWConversationType.group,
        targetId: targetId,
        messageUId: messageUId,
      ),
    );
  }

  /// =========================
  /// 群已读响应
  /// =========================
  void onGroupReadResponse(
    String? targetId,
    String? messageUId,
    Map? respondUserIds,
  ) {
    if (_disposed ||
        targetId == null ||
        messageUId == null ||
        messageUId.isEmpty) {
      return;
    }

    _messageController.add(
      MessageEvent(
        type: MessageEventType.groupReadReceiptResponse,
        conversationType: RCIMIWConversationType.group,
        targetId: targetId,
        messageUId: messageUId,
        respondUserIds: respondUserIds,
      ),
    );
  }

  void onMessagesDeleted({
    required List<RCIMIWMessage> messages,
    RCIMIWConversationType? conversationType,
    String? targetId,
    String? channelId,
  }) {
    if (_disposed) return;

    _clearBurnAfterReadingStateForMessages(messages);

    final fallbackMessage = _firstMessageWithConversationIdentity(messages);
    final eventConversationType =
        conversationType ?? fallbackMessage?.conversationType;
    final eventTargetId = targetId ?? fallbackMessage?.targetId;
    final eventChannelId = channelId ?? fallbackMessage?.channelId;

    for (final msg in messages) {
      final key = _messageCacheKey(msg);

      if (key != null) {
        _messageCache.remove(key);
      }
    }

    _messageController.add(
      MessageEvent(
        type: MessageEventType.delete,
        messages: messages,
        conversationType: eventConversationType,
        targetId: eventTargetId,
        channelId: eventChannelId,
      ),
    );
  }

  bool _hasConversationIdentity(RCIMIWMessage message) {
    return message.conversationType != null ||
        (message.targetId?.isNotEmpty ?? false) ||
        (message.channelId?.isNotEmpty ?? false);
  }

  RCIMIWMessage? _firstMessageWithConversationIdentity(
    List<RCIMIWMessage> messages,
  ) {
    for (final message in messages) {
      if (_hasConversationIdentity(message)) {
        return message;
      }
    }
    return null;
  }

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
    final completer = Completer<List<RCIMIWMessage>>();

    final callback = IRCIMIWGetMessagesCallback(
      onSuccess: (List<RCIMIWMessage>? t) {
        final list = t ?? [];

        if (kDebugMode) {
          debugPrint('历史消息返回: count=${list.length}');

          for (final msg in list) {
            _debugLogMessage('历史消息', msg);
          }
        }

        /// 历史消息统一走 dispatch
        for (final msg in list) {
          _dispatchMessage(msg, source: MessageSource.history);
        }

        completer.complete(list);
      },
      onError: (int? code) {
        completer.completeError(Exception("获取历史消息失败: $code"));
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
    final code = await IMEngineManager().engine?.deleteLocalMessages(messages);

    final success = code == 0;

    if (success) {
      _clearBurnAfterReadingStateForMessages(messages);

      /// 删除缓存
      for (final msg in messages) {
        final key = _messageCacheKey(msg);

        if (key != null) {
          _messageCache.remove(key);
        }
      }

      /// 通知 UI
      _messageController.add(
        MessageEvent(type: MessageEventType.delete, messages: messages),
      );
    }

    return success;
  }

  Future<bool> deleteRemoteMessages({
    required RCIMIWConversationType type,
    required String targetId,
    String? channelId,
    required List<RCIMIWMessage> messages,
  }) async {
    if (messages.isEmpty) return true;

    final engine = IMEngineManager().engine;
    if (engine == null) return false;

    final completer = Completer<bool>();
    final code = await engine.deleteMessages(
      type,
      targetId,
      channelId,
      messages,
      callback: IRCIMIWDeleteMessagesCallback(
        onMessagesDeleted: (int? code, List<RCIMIWMessage>? deletedMessages) {
          final success = code == 0;
          if (success) {
            onMessagesDeleted(
              messages: deletedMessages ?? messages,
              conversationType: type,
              targetId: targetId,
              channelId: channelId,
            );
          }

          if (!completer.isCompleted) {
            completer.complete(success);
          }
        },
      ),
    );

    if (code != 0) {
      return false;
    }

    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => false,
    );
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
    final code = await IMEngineManager().engine?.clearMessages(
      type,
      targetId,
      channelId,
      timestamp,
      policy,
    );

    final success = code == 0;

    if (success) {
      _clearBurnAfterReadingStateForConversation(
        type: type,
        targetId: targetId,
        channelId: channelId,
        timestamp: timestamp,
      );

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
  Future<bool> recallMessage({required RCIMIWMessage message}) async {
    final engine = IMEngineManager().engine;
    if (engine == null) return false;

    final completer = Completer<bool>();

    final code = await engine.recallMessage(
      message,
      callback: IRCIMIWRecallMessageCallback(
        onMessageRecalled: (code, recallMessage) {
          final success = code == 0 && recallMessage != null;

          if (success) {
            onMessageRecalled(recallMessage);
          }

          if (!completer.isCompleted) {
            completer.complete(success);
          }
        },
      ),
    );

    if (code != 0) {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
      return false;
    }

    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => false,
    );
  }

  bool _isRecallMessage(RCIMIWMessage message) {
    return message is RCIMIWRecallNotificationMessage ||
        message.messageType == RCIMIWMessageType.recall;
  }

  /// =========================
  /// 搜索消息
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

  Future<bool> sendReadReceiptMessage({
    required RCIMIWConversationType type,
    required String targetId,
    String? channelId,
    int? timestamp,
  }) async {
    final t = timestamp ?? DateTime.now().millisecondsSinceEpoch;

    if (type == RCIMIWConversationType.private) {
      return sendPrivateReadReceiptMessage(
        targetId: targetId,
        channelId: channelId,
        timestamp: t,
      );
    }

    return false;
  }

  Future<void> markMessagesReadForBurnAfterReading({
    required List<RCIMIWMessage> messages,
    int? readTime,
  }) async {
    if (_disposed || messages.isEmpty) return;

    final currentUserId = IMEngineManager().currentUserId;
    final startTime = readTime ?? DateTime.now().millisecondsSinceEpoch;

    for (final message in messages) {
      if (message.senderUserId == currentUserId) {
        continue;
      }

      await _startBurnAfterReadingCountdown(message, startTime: startTime);
    }
  }

  /// =========================
  /// 单聊已读回执
  /// =========================
  Future<bool> sendPrivateReadReceiptMessage({
    required String targetId,
    String? channelId,
    required int timestamp,
  }) async {
    final engine = IMEngineManager().engine;
    if (engine == null) return false;

    final completer = Completer<bool>();
    final code = await engine.sendPrivateReadReceiptMessage(
      targetId,
      channelId,
      timestamp,
      callback: IRCIMIWSendPrivateReadReceiptMessageCallback(
        onPrivateReadReceiptMessageSent: (int? code) {
          if (!completer.isCompleted) {
            completer.complete(code == 0);
          }
        },
      ),
    );

    if (code != 0) {
      return false;
    }

    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => false,
    );
  }

  /// =========================
  /// 群已读请求
  /// =========================
  Future<bool> sendGroupReadReceiptRequest({
    required RCIMIWMessage message,
  }) async {
    final engine = IMEngineManager().engine;
    if (engine == null) return false;

    final completer = Completer<bool>();
    final code = await engine.sendGroupReadReceiptRequest(
      message,
      callback: IRCIMIWSendGroupReadReceiptRequestCallback(
        onGroupReadReceiptRequestSent: (int? code, RCIMIWMessage? message) {
          final success = code == 0;
          if (success && message != null) {
            updateLocalMessage(message);
          }

          if (!completer.isCompleted) {
            completer.complete(success);
          }
        },
      ),
    );

    if (code != 0) {
      return false;
    }

    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => false,
    );
  }

  /// =========================
  /// 群已读响应
  /// =========================
  Future<bool> sendGroupReadReceiptResponse({
    required String targetId,
    String? channelId,
    required List<RCIMIWMessage> messages,
  }) async {
    if (messages.isEmpty) return true;

    final engine = IMEngineManager().engine;
    if (engine == null) return false;

    final completer = Completer<bool>();
    final code = await engine.sendGroupReadReceiptResponse(
      targetId,
      channelId,
      messages,
      callback: IRCIMIWSendGroupReadReceiptResponseCallback(
        onGroupReadReceiptResponseSent:
            (int? code, List<RCIMIWMessage>? messages) {
              final success = code == 0;
              if (success && messages != null) {
                for (final message in messages) {
                  updateLocalMessage(message);
                }
              }

              if (!completer.isCompleted) {
                completer.complete(success);
              }
            },
      ),
    );

    if (code != 0) {
      return false;
    }

    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => false,
    );
  }

  /// =========================
  /// 本地推送消息
  /// =========================
  void pushLocalMessage(RCIMIWMessage message) {
    if (_disposed) return;

    _dispatchMessage(message, source: MessageSource.local);
  }

  void updateLocalMessage(RCIMIWMessage message) {
    if (_disposed) return;

    _registerBurnAfterReadingCandidate(message);

    final id = _messageCacheKey(message);
    if (id != null) {
      if (_messageCache.length >= _maxCacheSize) {
        _messageCache.remove(_messageCache.keys.first);
      }
      _messageCache[id] = DateTime.now().millisecondsSinceEpoch;
    }

    _messageController.add(
      MessageEvent(type: MessageEventType.update, message: message),
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
    if (_messageCache.length >= _maxCacheSize) {
      _messageCache.remove(_messageCache.keys.first);
    }

    _messageCache[id] = DateTime.now().millisecondsSinceEpoch;

    _registerBurnAfterReadingCandidate(message);

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
  String? _messageCacheKey(RCIMIWMessage message) {
    /// 通话消息稳定 key
    final callSummaryKey = RongCallSummaryParser.stableMessageKey(message);

    if (callSummaryKey != null) {
      return callSummaryKey;
    }

    final mediaKey = _mediaMessageCacheKey(message);
    if (mediaKey != null) {
      return mediaKey;
    }

    /// messageUId 优先
    final messageUId = message.messageUId;

    if (messageUId != null && messageUId.isNotEmpty) {
      return 'uid:$messageUId';
    }

    /// messageId 次之
    final messageId = message.messageId;

    if (messageId != null && messageId > 0) {
      return 'id:$messageId';
    }

    /// fallback
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

  String? _mediaMessageCacheKey(RCIMIWMessage message) {
    if (message is! RCIMIWMediaMessage) {
      return null;
    }

    final local = message.local?.trim();
    final remote = message.remote?.trim();
    final mediaPath = (local != null && local.isNotEmpty) ? local : remote;
    if (mediaPath == null || mediaPath.isEmpty) {
      return null;
    }

    return [
      'media',
      message.conversationType?.index ?? -1,
      message.targetId ?? '',
      message.channelId ?? '',
      message.senderUserId ?? '',
      message.messageType?.index ?? -1,
      mediaPath,
    ].join(':');
  }

  /// =========================
  /// flush
  /// =========================
  void _scheduleFlush() {
    _flushTimer?.cancel();

    _flushTimer = Timer(const Duration(milliseconds: 10), () {
      if (_disposed) return;

      final messages = List<RCIMIWMessage>.from(_buffer);

      _buffer.clear();

      for (final msg in messages) {
        _messageController.add(
          MessageEvent(type: MessageEventType.add, message: msg),
        );
      }
    });
  }

  bool _isBurnAfterReadingCandidate(RCIMIWMessage message) {
    final duration = message.destructDuration ?? 0;
    final targetId = message.targetId;
    return duration > 0 &&
        message.conversationType == RCIMIWConversationType.private &&
        targetId != null &&
        targetId.isNotEmpty &&
        _burnAfterReadingMessageKey(message) != null;
  }

  void _registerBurnAfterReadingCandidate(RCIMIWMessage message) {
    if (!_isBurnAfterReadingCandidate(message)) {
      return;
    }

    final key = _burnAfterReadingMessageKey(message);
    if (key == null) {
      return;
    }

    _burnAfterReadingMessages[key] = message;
    unawaited(_scheduleExistingBurnAfterReadingIfNeeded(key, message));
  }

  Future<void> _scheduleExistingBurnAfterReadingIfNeeded(
    String key,
    RCIMIWMessage message,
  ) async {
    final expireTime = await _burnAfterReadingManager.getMessageExpireTime(key);
    if (_disposed || expireTime == null) {
      return;
    }

    if (!_burnAfterReadingMessages.containsKey(key)) {
      return;
    }

    _scheduleBurnAfterReadingDeletion(key, message, expireTime);
  }

  Future<void> _startSentMessagesBurnAfterReading({
    required String targetId,
    String? channelId,
    required int readReceiptTime,
  }) async {
    if (_disposed) return;

    final currentUserId = IMEngineManager().currentUserId;
    final readTime = DateTime.now().millisecondsSinceEpoch;
    final messages = _burnAfterReadingMessages.values.toList();

    for (final message in messages) {
      if (message.senderUserId != currentUserId) {
        continue;
      }

      if (message.targetId != targetId ||
          message.conversationType != RCIMIWConversationType.private ||
          !_isSameChannel(message.channelId, channelId)) {
        continue;
      }

      final sentTime = message.sentTime;
      if (sentTime == null || sentTime > readReceiptTime) {
        continue;
      }

      await _startBurnAfterReadingCountdown(message, startTime: readTime);
    }
  }

  Future<void> _startBurnAfterReadingCountdown(
    RCIMIWMessage message, {
    required int startTime,
  }) async {
    if (!_isBurnAfterReadingCandidate(message)) {
      return;
    }

    final key = _burnAfterReadingMessageKey(message);
    final duration = message.destructDuration ?? 0;
    if (key == null || duration <= 0) {
      return;
    }

    _burnAfterReadingMessages[key] = message;

    final expireTime = await _burnAfterReadingManager.ensureMessageExpireTime(
      messageKey: key,
      startTime: startTime,
      durationSeconds: duration,
    );

    if (_disposed || expireTime == null) {
      return;
    }

    _scheduleBurnAfterReadingDeletion(key, message, expireTime);
  }

  void _scheduleBurnAfterReadingDeletion(
    String key,
    RCIMIWMessage message,
    int expireTime,
  ) {
    if (_disposed || _burnAfterReadingDeletingKeys.contains(key)) {
      return;
    }

    _burnAfterReadingTimers.remove(key)?.cancel();

    final now = DateTime.now().millisecondsSinceEpoch;
    final delayMilliseconds = expireTime - now;
    if (delayMilliseconds <= 0) {
      unawaited(_deleteBurnAfterReadingMessage(key, message));
      return;
    }

    _burnAfterReadingTimers[key] = Timer(
      Duration(milliseconds: delayMilliseconds),
      () => unawaited(_deleteBurnAfterReadingMessage(key, message)),
    );
  }

  Future<void> _deleteBurnAfterReadingMessage(
    String key,
    RCIMIWMessage message,
  ) async {
    if (_disposed || _burnAfterReadingDeletingKeys.contains(key)) {
      return;
    }

    final latestMessage = _burnAfterReadingMessages[key] ?? message;
    final type = latestMessage.conversationType;
    final targetId = latestMessage.targetId;
    if (type == null || targetId == null || targetId.isEmpty) {
      _clearBurnAfterReadingState(key);
      return;
    }

    _burnAfterReadingDeletingKeys.add(key);
    final remoteDeleted = await deleteRemoteMessages(
      type: type,
      targetId: targetId,
      channelId: latestMessage.channelId,
      messages: [latestMessage],
    );

    if (!remoteDeleted && !_disposed) {
      await deleteLocalMessages(messages: [latestMessage]);
    }

    if (!remoteDeleted) {
      _clearBurnAfterReadingState(key);
    }
  }

  void _clearBurnAfterReadingStateForMessages(List<RCIMIWMessage> messages) {
    for (final message in messages) {
      final key = _burnAfterReadingMessageKey(message);
      if (key != null) {
        _clearBurnAfterReadingState(key);
      }
    }
  }

  void _clearBurnAfterReadingStateForConversation({
    required RCIMIWConversationType type,
    required String targetId,
    String? channelId,
    required int timestamp,
  }) {
    final keys = <String>[];
    for (final entry in _burnAfterReadingMessages.entries) {
      final message = entry.value;
      if (message.conversationType != type ||
          message.targetId != targetId ||
          !_isSameChannel(message.channelId, channelId)) {
        continue;
      }

      final messageTime = message.sentTime ?? message.receivedTime ?? 0;
      if (messageTime <= timestamp) {
        keys.add(entry.key);
      }
    }

    for (final key in keys) {
      _clearBurnAfterReadingState(key);
    }
  }

  void _clearBurnAfterReadingState(String key) {
    _burnAfterReadingTimers.remove(key)?.cancel();
    _burnAfterReadingMessages.remove(key);
    _burnAfterReadingDeletingKeys.remove(key);
    unawaited(_burnAfterReadingManager.clearMessageExpireTime(key));
  }

  Future<int?> getBurnAfterReadingExpireTime(RCIMIWMessage message) async {
    final key = _burnAfterReadingMessageKey(message);
    if (key == null) {
      return null;
    }

    return _burnAfterReadingManager.getMessageExpireTime(key);
  }

  bool _isSameChannel(String? left, String? right) {
    return (left ?? '').trim() == (right ?? '').trim();
  }

  String? _burnAfterReadingMessageKey(RCIMIWMessage message) {
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

  /// =========================
  /// debug
  /// =========================
  void _debugLogMessage(String prefix, RCIMIWMessage message) {
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

  String? _messageObjectName(RCIMIWMessage message) {
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

    for (final timer in _burnAfterReadingTimers.values) {
      timer.cancel();
    }

    _messageCache.clear();

    _buffer.clear();

    _burnAfterReadingTimers.clear();

    _burnAfterReadingMessages.clear();

    _burnAfterReadingDeletingKeys.clear();

    _messageController.close();
  }
}
