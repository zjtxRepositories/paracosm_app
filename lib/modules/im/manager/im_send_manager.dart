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
      return _sendNormalMessage(message);
    }
  }

  /// =========================
  /// 普通消息
  /// =========================
  Future<bool> _sendNormalMessage(RCIMIWMessage message) async {
    final completer = Completer<bool>();

    final listener = RCIMIWSendMessageCallback(
      onMessageSaved: (msg) {
        ImMessageManager().pushLocalMessage(msg ?? message);
      },
      onMessageSent: (code, msg) {
        ImMessageManager().updateLocalMessage(msg ?? message);
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
        if (pushSavedMessage) {
          ImMessageManager().pushLocalMessage(
            _keepOriginalRemote(msg ?? message, message),
          );
        }
      },
      onMediaMessageSending: (message, progress) {
        final value = progress ?? 0;
        onProgress?.call(value.toInt());
      },
      onMediaMessageSent: (code, msg) {
        ImMessageManager().updateLocalMessage(
          _keepOriginalRemote(msg ?? message, message),
        );
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
