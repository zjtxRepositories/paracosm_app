import 'dart:async';

import 'package:paracosm/modules/im/manager/im_conversation_manager.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../result/im_result.dart';
import 'im_engine_manager.dart';

class ImMessageManager  {

  void initListener() {
    final engine = IMEngineManager().engine;
    engine?.onMessageReceived = (RCIMIWMessage? message, int? left, bool? offline, bool? hasPackage) {
//...
    };

    engine?.onRemoteMessageRecalled = (RCIMIWMessage? message) {
//...
    };
    engine?.onPrivateReadReceiptReceived = (String? targetId, String? channelId, int? timestamp) {
//...
    };

    engine?.onGroupMessageReadReceiptRequestReceived = (String? targetId, String? messageUId) {
//...
    };

    engine?.onGroupMessageReadReceiptResponseReceived = (String? targetId, String? messageUId, Map? respondUserIds) {
//...
    };
  }

  /// 接收消息
  void onMessageReceived(RCIMIWMessage message) {
    print("收到消息: ${message.messageId}");

  }

  /// 发送文本消息
  Future<void> sendTextMessage({
    required String targetId,
    required String content,
  }) async {

    final textMsg = RCIMIWMessage.fromJson({});
    RCIMIWSendMessageCallback? callback = RCIMIWSendMessageCallback(
        onMessageSaved: (RCIMIWMessage? message) {
//...
        }, onMessageSent: (int? code, RCIMIWMessage? message) {
//...
    });

    final code = await IMEngineManager().engine?.sendMessage(textMsg,callback: callback);
    
    if (code != 0) {
      throw Exception("发送失败: $code");
    }
    ImConversationManager().refreshAfterSend(targetId,textMsg);
  }

  /// 获取历史消息
  Future<void> getMessages({
    required RCIMIWConversationType type,
    required String targetId,
    required int sentTime,
    required RCIMIWTimeOrder order,
    required RCIMIWMessageOperationPolicy policy,
    required int count,
    String? channelId,
  }) async {

    IRCIMIWGetMessagesCallback? callback = IRCIMIWGetMessagesCallback(
        onSuccess: (List<RCIMIWMessage>? t, int? syncTimestamp, bool? hasMoreMsg) {
//...
        }, onError: (int? code) {
//...
    });

    final code = await IMEngineManager().engine?.getMessages(type, targetId, channelId, sentTime, order, policy, count,callback: callback);

    if (code != RCIMIWErrorCode.success) {
      throw Exception("发送失败: $code");
    }
  }

  /// 删除消息
  Future<bool> deleteLocalMessages({
    required List<RCIMIWMessage> messages,
  }) async {
    final code = await IMEngineManager().engine?.deleteLocalMessages(messages);
    return code == 0;
  }

  /// 撤回消息
  Future<bool> recallMessage({
    required RCIMIWMessage message,
  }) async {
    final code = await IMEngineManager().engine?.recallMessage(message);
    return code == 0;
  }

  /// =========================
  /// 根据关键字搜索
  /// =========================
  Future<ImResult<List<RCIMIWMessage>>> searchMessages({
    required RCIMIWConversationType type,
    required String targetId,
    required String keyword,
    required int startTime,
    required int count,
    String? channelId
  }) async {
    final completer =
    Completer<ImResult<List<RCIMIWMessage>>>();
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


  /// 发送已读回执
  Future<bool> sendPrivateReadReceiptMessage({
    required String targetId,
    String? channelId,
    required int timestamp
  }) async {
    final code = await IMEngineManager().engine?.sendPrivateReadReceiptMessage(targetId, channelId, timestamp);
    return code == 0;
  }

  /// 群聊消息回执
  Future<bool> sendGroupReadReceiptRequest({
    required RCIMIWMessage message,
  }) async {
    final code = await IMEngineManager().engine?.sendGroupReadReceiptRequest(message);
    return code == 0;
  }

  /// 响应回执请求
  Future<bool> sendGroupReadReceiptResponse({
    required String targetId,
    String? channelId,
    required List<RCIMIWMessage> messages,
  }) async {
    final code = await IMEngineManager().engine?.sendGroupReadReceiptResponse(targetId, channelId, messages);
    return code == 0;
  }
}