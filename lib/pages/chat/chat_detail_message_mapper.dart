import 'package:paracosm/modules/call/rong_call_summary_parser.dart';
import 'package:paracosm/modules/im/manager/im_engine_manager.dart';
import 'package:paracosm/pages/chat/chat_detail_message.dart';
import 'package:paracosm/util/string_util.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../core/models/message_model.dart';

class ChatDetailMessageMapper {
  ChatDetailMessageMapper._();

  static Future<List<ChatDetailMessage>> mapMessages(List<RCIMIWMessage> messages) async {
    final result = <ChatDetailMessage>[];
    int? previousTimestamp;
    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      final timestamp = message.sentTime ?? message.receivedTime;
      if (_shouldInsertTimestamp(i, previousTimestamp, timestamp)) {
        result.add(
          ChatDetailMessage(
            messageId: message.messageId.toString(),
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

    final callSummary = RongCallSummaryParser.tryParse(message);
    if (callSummary != null) {
      return ChatDetailMessage(
        messageId: message.messageId.toString(),
        kind: ChatDetailMessageKind.call,
        isMe: isMe,
        sentTime: sentTime,
        isVideo: callSummary.isVideo,
        text: callSummary.text,
      );
    }

    if (message is RCIMIWTextMessage) {
      return ChatDetailMessage(
        messageId: message.messageId.toString(),
        kind: ChatDetailMessageKind.text,
        isMe: isMe,
        text: (message.text?.isNotEmpty ?? false) ? message.text : '[空消息]',
        sentTime: sentTime,
      );
    }

    if (message is RCIMIWImageMessage) {
      return ChatDetailMessage(
        messageId: message.messageId.toString(),
        kind: ChatDetailMessageKind.image,
        isMe: isMe,
        sentTime: sentTime,
        imagePath: message.local,
      );
    }

    if (message is RCIMIWSightMessage) {
      // print('video----${message.duration}---${message.thumbnailBase64String}');
      return ChatDetailMessage(
        messageId: message.messageId.toString(),
        kind: ChatDetailMessageKind.video,
        isMe: isMe,
        sentTime: sentTime,
        thumbnailBase64String: message.thumbnailBase64String,
        path: message.local,
        duration: formatDurationFromMs(message.duration ?? 0),
      );
    }
    if (message is RCIMIWVoiceMessage) {
      return ChatDetailMessage(
        messageId: message.messageId.toString(),
        kind: ChatDetailMessageKind.voice,
        isMe: isMe,
        sentTime: sentTime,
        path: message.local,
        remote: message.remote,
        duration: formatDurationFromMs(message.duration ?? 0),
      );
    }
    if (message is RCIMIWFileMessage) {
      return ChatDetailMessage(
        messageId: message.messageId.toString(),
        kind: ChatDetailMessageKind.file,
        isMe: isMe,
        sentTime: sentTime,
        fileName: message.name,
        fileSize: formatFileSize(message.size ?? 0),
        path: message.local,
      );
    }
    if (message.messageType == RCIMIWMessageType.recall) {
      return ChatDetailMessage(
        messageId: message.messageId.toString(),
        kind: ChatDetailMessageKind.withdrawnNotice,
        sentTime: sentTime,
      );
    }

    if (message.messageType == RCIMIWMessageType.custom) {
      MessageModel model = MessageModel(item: message);
     final content = await model.formatCustomContent();
      return ChatDetailMessage(
          messageId: message.messageId.toString(),
          kind: ChatDetailMessageKind.fm,
          sentTime: sentTime,
          text: content
      );
    }

    return ChatDetailMessage(
      messageId: message.messageId.toString(),
      kind: ChatDetailMessageKind.text,
      isMe: isMe,
      text: '[暂不支持的消息类型]',
      sentTime: sentTime,
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
}
