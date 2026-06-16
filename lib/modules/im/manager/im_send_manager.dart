import 'dart:async';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import 'im_engine_manager.dart';
import 'im_message_manager.dart';

/// =========================
/// 发送状态
/// =========================
enum MessageSendStatus { sending, success, failed, canceled }

/// UI 更新
typedef OnMessageUpdate = void Function(RCIMIWMessage message);

/// 上传进度
typedef OnProgress = void Function(String messageId, int progress);

class ImSendManager {
  ImSendManager._();
  static final ImSendManager instance = ImSendManager._();

  RCIMIWEngine? get _engine => IMEngineManager().engine;

  /// =========================
  /// 唯一职责：发送消息（给队列调用）
  /// =========================
  Future<bool> sendMessage(
    RCIMIWMessage message, {
    void Function(int progress)? onProgress,
    bool pushSavedMessage = true,
  }) async {
    if (message is RCIMIWMediaMessage) {
      return _sendMediaMessage(
        message,
        onProgress: onProgress,
        pushSavedMessage: pushSavedMessage,
      );
    } else {
      return _sendNormalMessage(message, pushSavedMessage: pushSavedMessage);
    }
  }

  /// =========================
  /// 普通消息
  /// =========================
  Future<bool> _sendNormalMessage(
    RCIMIWMessage message, {
    required bool pushSavedMessage,
  }) async {
    final completer = Completer<bool>();
    final listener = RCIMIWSendMessageCallback(
      onMessageSaved: (msg) {
        final savedMessage = _keepClientIdentity(msg ?? message, message);
        if (!pushSavedMessage) {
          savedMessage.sentStatus =
              message.sentStatus == RCIMIWSentStatus.sending
              ? RCIMIWSentStatus.sending
              : null;
        }
        if (pushSavedMessage) {
          ImMessageManager().pushLocalMessage(savedMessage);
        } else {
          ImMessageManager().updateLocalMessage(savedMessage);
        }
      },
      onMessageSent: (code, msg) {
        final sentMessage = _keepClientIdentity(msg ?? message, message);
        if (code == 0) {
          sentMessage.sentStatus = RCIMIWSentStatus.sent;
          ImMessageManager().updateLocalMessage(sentMessage);
        }
        if (!completer.isCompleted) {
          completer.complete(code == 0);
        }
      },
    );

    final ret = await _engine?.sendMessage(message, callback: listener);

    if (ret != 0) {
      return false;
    }

    return completer.future;
  }

  /// =========================
  /// 媒体消息
  /// =========================
  Future<bool> _sendMediaMessage(
    RCIMIWMediaMessage message, {
    void Function(int progress)? onProgress,
    bool pushSavedMessage = true,
  }) async {
    final completer = Completer<bool>();
    final listener = RCIMIWSendMediaMessageListener(
      onMediaMessageSaved: (msg) {
        final savedMessage = _keepClientIdentity(
          _keepOriginalRemote(msg ?? message, message),
          message,
        );
        if (!pushSavedMessage) {
          savedMessage.sentStatus =
              message.sentStatus == RCIMIWSentStatus.sending
              ? RCIMIWSentStatus.sending
              : null;
        }
        if (pushSavedMessage) {
          ImMessageManager().pushLocalMessage(savedMessage);
        } else {
          ImMessageManager().updateLocalMessage(savedMessage);
        }
      },
      onMediaMessageSending: (message, progress) {
        final value = progress ?? 0;
        onProgress?.call(value.toInt());
      },
      onMediaMessageSent: (code, msg) {
        final sentMessage = _keepClientIdentity(
          _keepOriginalRemote(msg ?? message, message),
          message,
        );
        if (code == 0) {
          sentMessage.sentStatus = RCIMIWSentStatus.sent;
          ImMessageManager().updateLocalMessage(sentMessage);
        }
        if (!completer.isCompleted) {
          completer.complete(code == 0);
        }
      },
      onSendingMediaMessageCanceled: (_) {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );

    final ret = await _engine?.sendMediaMessage(message, listener: listener);

    if (ret != 0) {
      return false;
    }

    return completer.future;
  }

  T _keepClientIdentity<T extends RCIMIWMessage>(
    T callbackMessage,
    RCIMIWMessage originalMessage,
  ) {
    callbackMessage.conversationType ??= originalMessage.conversationType;
    callbackMessage.targetId ??= originalMessage.targetId;
    callbackMessage.sentTime = originalMessage.sentTime;
    callbackMessage.senderUserId ??= originalMessage.senderUserId;
    callbackMessage.channelId ??= originalMessage.channelId;
    return callbackMessage;
  }

  RCIMIWMediaMessage _keepOriginalRemote(
    RCIMIWMediaMessage callbackMessage,
    RCIMIWMediaMessage originalMessage,
  ) {
    final originalRemote = originalMessage.remote?.trim();
    if (originalRemote != null && originalRemote.isNotEmpty) {
      callbackMessage.remote = originalRemote;
    }
    return callbackMessage;
  }
}
