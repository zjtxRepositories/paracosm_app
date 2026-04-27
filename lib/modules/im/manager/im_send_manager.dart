import 'dart:async';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import 'im_engine_manager.dart';

/// =========================
/// 发送状态
/// =========================
enum MessageSendStatus {
  sending,
  success,
  failed,
  canceled,
}

/// UI 更新
typedef OnMessageUpdate = void Function(RCIMIWMessage message);

/// 上传进度
typedef OnProgress = void Function(String messageId, int progress);

class ImSendManager {
  ImSendManager._();
  static final ImSendManager instance = ImSendManager._();

  /// ⚠️ 动态获取，避免空或失效
  RCIMIWEngine? get _engine => IMEngineManager().engine;

  /// =========================
  /// 本地状态缓存
  /// =========================
  final Map<String, MessageSendStatus> _statusMap = {};

  MessageSendStatus? getStatus(String messageId) {
    return _statusMap[messageId];
  }

  /// =========================
  /// 统一发送入口（返回最终结果）
  /// =========================
  Future<bool> send({
    required RCIMIWMessage message,
    OnMessageUpdate? onUpdate,
    OnProgress? onProgress,
  }) async {
    if (message is RCIMIWMediaMessage) {
      return sendMediaMessage(
        message: message,
        onUpdate: onUpdate,
        onProgress: onProgress,
      );
    } else if (message is RCIMIWTextMessage) {
      return sendTextMessage(
        message: message,
        onUpdate: onUpdate,
      );
    } else if (message is RCIMIWCustomMessage) {
      return sendCustomMessage(
        message: message,
        onUpdate: onUpdate,
      );
    } else {
      _updateStatus(message, MessageSendStatus.failed, onUpdate);
      return false;
    }
  }

  /// =========================
  /// 发送文本消息
  /// =========================
  Future<bool> sendTextMessage({
    required RCIMIWTextMessage message,
    OnMessageUpdate? onUpdate,
  }) async {
    final completer = Completer<bool>();

    final listener = RCIMIWSendMessageCallback(
      onMessageSaved: (msg) {
        _updateStatus(msg, MessageSendStatus.sending, onUpdate);
      },
      onMessageSent: (code, msg) {
        if (!completer.isCompleted) {
          if (code == 0) {
            _updateStatus(msg, MessageSendStatus.success, onUpdate);
            completer.complete(true);
          } else {
            _updateStatus(msg, MessageSendStatus.failed, onUpdate);
            completer.complete(false);
          }
        }
      },
    );

    final ret = await _engine?.sendMessage(message, callback: listener);

    // ❌ SDK调用失败（直接返回 false）
    if (ret != 0) {
      _updateStatus(message, MessageSendStatus.failed, onUpdate);
      return false;
    }

    return completer.future;
  }

  /// =========================
  /// 发送媒体消息
  /// =========================
  Future<bool> sendMediaMessage({
    required RCIMIWMediaMessage message,
    OnMessageUpdate? onUpdate,
    OnProgress? onProgress,
  }) async {
    final completer = Completer<bool>();

    final listener = RCIMIWSendMediaMessageListener(
      onMediaMessageSaved: (msg) {
        _updateStatus(msg, MessageSendStatus.sending, onUpdate);
      },
      onMediaMessageSending: (msg, progress) {
        final messageId = msg?.messageId?.toString() ?? '';
        if (messageId.isNotEmpty && progress != null) {
          onProgress?.call(messageId, progress);
        }
      },
      onMediaMessageSent: (code, msg) {
        if (!completer.isCompleted) {
          if (code == 0) {
            _updateStatus(msg, MessageSendStatus.success, onUpdate);
            completer.complete(true);
          } else {
            _updateStatus(msg, MessageSendStatus.failed, onUpdate);
            completer.complete(false);
          }
        }
      },
      onSendingMediaMessageCanceled: (msg) {
        if (!completer.isCompleted) {
          _updateStatus(msg, MessageSendStatus.canceled, onUpdate);
          completer.complete(false);
        }
      },
    );

    final ret = await _engine?.sendMediaMessage(
      message,
      listener: listener,
    );

    if (ret != 0) {
      _updateStatus(message, MessageSendStatus.failed, onUpdate);
      return false;
    }

    return completer.future;
  }

  /// =========================
  /// 发送自定义消息
  /// =========================
  Future<bool> sendCustomMessage({
    required RCIMIWCustomMessage message,
    OnMessageUpdate? onUpdate,
  }) async {
    final completer = Completer<bool>();

    final callback = RCIMIWSendMessageCallback(
      onMessageSaved: (m) {
        _updateStatus(m, MessageSendStatus.sending, onUpdate);
      },
      onMessageSent: (code, m) {
        if (!completer.isCompleted) {
          if (code == 0) {
            _updateStatus(m, MessageSendStatus.success, onUpdate);
            completer.complete(true);
          } else {
            _updateStatus(m, MessageSendStatus.failed, onUpdate);
            completer.complete(false);
          }
        }
      },
    );

    final ret = await _engine?.sendMessage(
      message,
      callback: callback,
    );

    if (ret != 0) {
      _updateStatus(message, MessageSendStatus.failed, onUpdate);
      return false;
    }

    return completer.future;
  }

  /// =========================
  /// 重发消息
  /// =========================
  Future<bool> resend({
    required RCIMIWMessage message,
    OnMessageUpdate? onUpdate,
    OnProgress? onProgress,
  }) async {
    return send(
      message: message,
      onUpdate: onUpdate,
      onProgress: onProgress,
    );
  }

  /// =========================
  /// 内部状态更新
  /// =========================
  void _updateStatus(
      RCIMIWMessage? message,
      MessageSendStatus status,
      OnMessageUpdate? onUpdate,
      ) {
    if (message == null) return;

    final messageId = message.messageId?.toString() ?? '';
    if (messageId.isNotEmpty) {
      _statusMap[messageId] = status;
    }

    onUpdate?.call(message);
  }
}