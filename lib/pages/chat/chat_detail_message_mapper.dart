import 'package:paracosm/modules/im/manager/im_engine_manager.dart';
import 'package:paracosm/pages/chat/chat_detail_message.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

class ChatDetailMessageMapper {
  ChatDetailMessageMapper._();

  static List<ChatDetailMessage> mapMessages(List<RCIMIWMessage> messages) {
    final result = <ChatDetailMessage>[];
    int? previousTimestamp;

    for (final message in messages) {
      final timestamp = message.sentTime ?? message.receivedTime;
      if (_shouldInsertTimestamp(previousTimestamp, timestamp)) {
        result.add(
          ChatDetailMessage(
            kind: ChatDetailMessageKind.timestamp,
            text: _formatTimestamp(timestamp!),
            sentTime: timestamp,
          ),
        );
      }

      result.add(mapMessage(message));
      previousTimestamp = timestamp;
    }

    return result;
  }

  static ChatDetailMessage mapMessage(RCIMIWMessage message) {
    final isMe = message.senderUserId == IMEngineManager().currentUserId;
    final sentTime = message.sentTime ?? message.receivedTime;

    if (message is RCIMIWTextMessage) {
      return ChatDetailMessage(
        kind: ChatDetailMessageKind.text,
        isMe: isMe,
        text: (message.text?.isNotEmpty ?? false) ? message.text : '[空消息]',
        sentTime: sentTime,
      );
    }

    if (message.messageType == RCIMIWMessageType.recall) {
      return ChatDetailMessage(
        kind: ChatDetailMessageKind.withdrawnNotice,
        sentTime: sentTime,
      );
    }

    return ChatDetailMessage(
      kind: ChatDetailMessageKind.text,
      isMe: isMe,
      text: '[暂不支持的消息类型]',
      sentTime: sentTime,
    );
  }

  static bool _shouldInsertTimestamp(int? previous, int? current) {
    if (current == null) return false;
    if (previous == null) return true;
    return current - previous >= const Duration(minutes: 5).inMilliseconds;
  }

  static String _formatTimestamp(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final month = _monthName(dateTime.month);
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$month $day ${dateTime.year} $hour:$minute';
  }

  static String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month - 1];
  }
}
