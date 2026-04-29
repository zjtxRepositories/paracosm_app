import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:paracosm/modules/im/manager/im_conversation_manager.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../result/im_result.dart';
import 'im_engine_manager.dart';

class ImMessageManager {
  static final ImMessageManager _instance =
  ImMessageManager._internal();
  factory ImMessageManager() => _instance;
  ImMessageManager._internal();

  /// =========================
  /// 原始消息流（全局）
  /// =========================
  final _messageController =
  StreamController<RCIMIWMessage>.broadcast();

  Stream<RCIMIWMessage> get messageStream =>
      _messageController.stream;

  bool _inited = false;
  bool _disposed = false;

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

    engine?.onRemoteMessageRecalled =
        (RCIMIWMessage? message) {
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

    debugPrint("收到消息: ${message.messageId}");
    _dispatchMessage(message);

  }

  /// =========================
  /// 撤回消息
  /// =========================
  void onMessageRecalled(RCIMIWMessage message) {
    if (_disposed) return;

  }

  void onPrivateReadReceipt(
      String? targetId, String? channelId, int? timestamp) {}

  void onGroupReadRequest(String? targetId, String? messageUId) {}

  void onGroupReadResponse(
      String? targetId, String? messageUId, Map? respondUserIds) {}

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

    IRCIMIWGetMessagesCallback? callback =
    IRCIMIWGetMessagesCallback(
      onSuccess: (List<RCIMIWMessage>? t, int? syncTimestamp,
          bool? hasMoreMsg) {
        completer.complete(t ?? []);
      },
      onError: (int? code) {
        completer.completeError(
          Exception("获取历史消息1: $code"),
        );
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
        callback: callback);

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
    final code = await IMEngineManager()
        .engine
        ?.deleteLocalMessages(messages);
    return code == 0;
  }

  /// =========================
  /// 撤回消息（原样）
  /// =========================
  Future<bool> recallMessage({
    required RCIMIWMessage message,
  }) async {
    final code = await IMEngineManager()
        .engine
        ?.recallMessage(message);
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
    final completer =
    Completer<ImResult<List<RCIMIWMessage>>>();

    final ret = await IMEngineManager()
        .engine
        ?.searchMessages(
      type,
      targetId,
      channelId,
      keyword,
      startTime,
      count,
      callback: IRCIMIWSearchMessagesCallback(
        onSuccess: (List<RCIMIWMessage>? t) {
          completer
              .complete(ImResult.success(data: t));
        },
        onError: (code) {
          completer.complete(
            ImResult.error(code: code ?? -1),
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
  /// 已读回执（原样）
  /// =========================
  Future<bool> sendPrivateReadReceiptMessage({
    required String targetId,
    String? channelId,
    required int timestamp,
  }) async {
    final code = await IMEngineManager()
        .engine
        ?.sendPrivateReadReceiptMessage(
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
    final code = await IMEngineManager()
        .engine
        ?.sendGroupReadReceiptRequest(message);
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
    final code = await IMEngineManager()
        .engine
        ?.sendGroupReadReceiptResponse(
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
    _dispatchMessage(message);

  }

  void _dispatchMessage(RCIMIWMessage message) {
    if (_disposed) return;

    /// 1️⃣ 全局流
    _messageController.add(message);
    debugPrint("刷新消息: ${message.messageId}");

    // /// 2️⃣ 会话分发（关键）
    // final targetId = message.targetId;
    // if (targetId != null) {
    //   ImConversationManager().onNewMessage(targetId, message);
    // }
  }
  /// =========================
  /// dispose（优化版）
  /// =========================
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    _messageController.close();

  }
}