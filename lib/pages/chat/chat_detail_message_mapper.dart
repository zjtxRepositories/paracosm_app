import 'package:paracosm/modules/call/rong_call_summary_parser.dart';
import 'package:paracosm/modules/im/manager/im_engine_manager.dart';
import 'package:paracosm/pages/chat/chat_detail_message.dart';
import 'package:paracosm/util/string_util.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../core/models/message_model.dart';

class ChatDetailMessageMapper {
  ChatDetailMessageMapper._();

  static Future<List<ChatDetailMessage>> mapMessages(
    List<RCIMIWMessage> messages,
  ) async {
    final result = <ChatDetailMessage>[];
    int? previousTimestamp;
    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      final timestamp = message.sentTime ?? message.receivedTime;
      if (_shouldInsertTimestamp(i, previousTimestamp, timestamp)) {
        result.add(
          ChatDetailMessage(
            messageId: '${messageKeyFor(message)}:timestamp',
            kind: ChatDetailMessageKind.timestamp,
            text: _formatTimestamp(timestamp!),
            sentTime: timestamp,
          ),
        );
      }

      result.add(await mapMessage(message));
      previousTimestamp = timestamp;
    }

    return result;
  }

  static Future<ChatDetailMessage> mapMessage(RCIMIWMessage message) async {
    final isMe = message.senderUserId == IMEngineManager().currentUserId;
    final sentTime = message.sentTime ?? message.receivedTime;
    final messageKey = messageKeyFor(message);

    if (_isRecallMessage(message)) {
      return ChatDetailMessage(
        messageId: messageKey,
        kind: ChatDetailMessageKind.withdrawnNotice,
        sentTime: sentTime,
        extra: message,
      );
    }

    if (message is RCIMIWCombineV2Message) {
      final summaries = message.summaryList ?? const <String>[];
      return ChatDetailMessage(
        messageId: messageKey,
        kind: ChatDetailMessageKind.combineForward,
        isMe: isMe,
        text: '聊天记录',
        combineSummaries: summaries,
        sentTime: sentTime,
        extra: message,
      );
    }

    if (message.messageType == RCIMIWMessageType.combineV2) {
      return ChatDetailMessage(
        messageId: messageKey,
        kind: ChatDetailMessageKind.combineForward,
        isMe: isMe,
        text: '聊天记录',
        sentTime: sentTime,
        extra: message,
      );
    }

    if (message is RCIMIWReferenceMessage) {
      final referenceMessage = message.referenceMessage;
      return ChatDetailMessage(
        messageId: messageKey,
        kind: ChatDetailMessageKind.text,
        isMe: isMe,
        text: (message.text?.isNotEmpty ?? false) ? message.text : '[空消息]',
        quoteText: await quoteSummaryForMessage(referenceMessage),
        quoteMessageId: referenceMessage == null
            ? null
            : messageKeyFor(referenceMessage),
        quoteSentTime:
            referenceMessage?.sentTime ?? referenceMessage?.receivedTime,
        quoteMessageUId: referenceMessage?.messageUId,
        quoteRawMessageId: referenceMessage?.messageId,
        quoteSenderUserId: referenceMessage?.senderUserId,
        quoteMessageType: referenceMessage?.messageType?.index,
        sentTime: sentTime,
        extra: message,
      );
    }

    final callSummary = RongCallSummaryParser.tryParse(message);
    if (callSummary != null) {
      return ChatDetailMessage(
        messageId: messageKey,
        kind: ChatDetailMessageKind.call,
        isMe: isMe,
        sentTime: sentTime,
        isVideo: callSummary.isVideo,
        text: callSummary.text,
        extra: message,
      );
    }

    if (message is RCIMIWTextMessage) {
      return ChatDetailMessage(
        messageId: messageKey,
        kind: ChatDetailMessageKind.text,
        isMe: isMe,
        text: (message.text?.isNotEmpty ?? false) ? message.text : '[空消息]',
        sentTime: sentTime,
        extra: message,
      );
    }

    if (message is RCIMIWImageMessage) {
      return ChatDetailMessage(
        messageId: messageKey,
        kind: ChatDetailMessageKind.image,
        isMe: isMe,
        sentTime: sentTime,
        imagePath: message.local,
        remote: message.remote,
        thumbnailBase64String: message.thumbnailBase64String,
        extra: message,
      );
    }

    if (message is RCIMIWSightMessage) {
      // print('video----${message.duration}---${message.thumbnailBase64String}');
      return ChatDetailMessage(
        messageId: messageKey,
        kind: ChatDetailMessageKind.video,
        isMe: isMe,
        sentTime: sentTime,
        thumbnailBase64String: message.thumbnailBase64String,
        path: message.local,
        duration: formatDurationFromMs(message.duration ?? 0),
        extra: message,
      );
    }
    if (message is RCIMIWVoiceMessage) {
      return ChatDetailMessage(
        messageId: messageKey,
        kind: ChatDetailMessageKind.voice,
        isMe: isMe,
        sentTime: sentTime,
        path: message.local,
        remote: message.remote,
        duration: formatDurationFromMs(message.duration ?? 0),
        extra: message,
      );
    }
    if (message is RCIMIWFileMessage) {
      return ChatDetailMessage(
        messageId: messageKey,
        kind: ChatDetailMessageKind.file,
        isMe: isMe,
        sentTime: sentTime,
        fileName: message.name,
        fileSize: formatFileSize(message.size ?? 0),
        path: message.local,
        extra: message,
      );
    }

    if (message.messageType == RCIMIWMessageType.custom) {
      MessageModel model = MessageModel(item: message);
      final content = await model.formatCustomContent();
      return ChatDetailMessage(
        messageId: messageKey,
        kind: ChatDetailMessageKind.fm,
        sentTime: sentTime,
        text: content,
        extra: message,
      );
    }

    return ChatDetailMessage(
      messageId: messageKey,
      kind: ChatDetailMessageKind.text,
      isMe: isMe,
      text: '[暂不支持的消息类型]',
      sentTime: sentTime,
      extra: message,
    );
  }

  static bool _shouldInsertTimestamp(int index, int? previous, int? current) {
    if (index == 0) return false;

    if (previous == null || current == null) return false;
    return current - previous >= const Duration(minutes: 5).inMilliseconds;
  }

  static String _formatTimestamp(int timestamp) {
    return formatIMTime(timestamp);
  }

  static bool _isRecallMessage(RCIMIWMessage message) {
    return message is RCIMIWRecallNotificationMessage ||
        message.messageType == RCIMIWMessageType.recall;
  }

  static Future<String> quoteSummaryForMessage(RCIMIWMessage? message) async {
    if (message == null || _isRecallMessage(message)) {
      return '[消息]';
    }

    final callSummary = RongCallSummaryParser.tryParse(message);
    if (callSummary != null) {
      return callSummary.text;
    }

    if (message is RCIMIWReferenceMessage) {
      final text = message.text;
      return (text?.isNotEmpty ?? false) ? text! : '[消息]';
    }

    if (message is RCIMIWCombineV2Message ||
        message.messageType == RCIMIWMessageType.combineV2) {
      return '[聊天记录]';
    }

    if (message is RCIMIWTextMessage) {
      final text = message.text;
      return (text?.isNotEmpty ?? false) ? text! : '[空消息]';
    }

    if (message is RCIMIWImageMessage) {
      return '[图片]';
    }

    if (message is RCIMIWVoiceMessage) {
      return '[语音]';
    }

    if (message is RCIMIWSightMessage) {
      return '[视频]';
    }

    if (message is RCIMIWFileMessage) {
      return '[文件]';
    }

    if (message.messageType == RCIMIWMessageType.custom) {
      final model = MessageModel(item: message);
      final content = await model.formatCustomContent();
      return content.isNotEmpty ? content : '[消息]';
    }

    return '[消息]';
  }

  static String messageKeyFor(RCIMIWMessage message) {
    final callSummaryKey = RongCallSummaryParser.stableMessageKey(message);
    if (callSummaryKey != null) return callSummaryKey;

    final messageId = message.messageId;
    if (messageId != null && messageId > 0) return messageId.toString();
    final messageUId = message.messageUId;
    if (messageUId != null && messageUId.isNotEmpty) return messageUId;
    return [
      message.conversationType?.index,
      message.targetId,
      message.channelId,
      message.senderUserId,
      message.sentTime ?? message.receivedTime,
      message.messageType?.index,
    ].join(':');
  }
}
