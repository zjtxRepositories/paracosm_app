import 'package:paracosm/modules/call/rong_call_summary_parser.dart';
import 'package:paracosm/modules/im/listener/user_display_state_center.dart';
import 'package:paracosm/modules/im/manager/im_engine_manager.dart';
import 'package:paracosm/modules/im/message/base/im_message.dart';
import 'package:paracosm/modules/im/message/custom_face_message.dart';
import 'package:paracosm/modules/im/message/moment_post_share_message.dart';
import 'package:paracosm/modules/im/message/recall_message_formatter.dart';
import 'package:paracosm/modules/im/store/red_packet_claim_store.dart';
import 'package:paracosm/pages/chat/chat_detail_message.dart';
import 'package:paracosm/util/string_util.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../core/models/message_model.dart';

class ChatDetailMessageMapper {
  ChatDetailMessageMapper._();

  static Future<List<ChatDetailMessage>> mapMessages(
    List<RCIMIWMessage> messages,
  ) async {
    final result = <ChatDetailMessage>[];
    final pendingNotices = <ChatDetailMessage>[];
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

      final mapped = await mapMessage(message);
      result.add(mapped);
      if (_shouldAppendRedPacketClaimNotice(mapped)) {
        final notice = _buildRedPacketClaimNotice(mapped);
        if (notice != null) {
          pendingNotices.add(notice);
        }
      }
      previousTimestamp = timestamp;
    }

    for (final notice in pendingNotices) {
      _insertBySentTime(result, notice);
    }

    return result;
  }

  static Future<ChatDetailMessage> mapMessage(RCIMIWMessage message) async {
    final isMe = message.senderUserId == IMEngineManager().currentUserId;
    final isSending = isMe && message.sentStatus == RCIMIWSentStatus.sending;
    final sentTime = message.sentTime ?? message.receivedTime;
    final messageKey = messageKeyFor(message);

    if (_isRecallMessage(message)) {
      return ChatDetailMessage(
        messageId: messageKey,
        kind: ChatDetailMessageKind.withdrawnNotice,
        text: await RecallMessageFormatter.format(message),
        sentTime: sentTime,
        extra: message,
      );
    }

    final senderUserInfo = await UserDisplayStateCenter().getUser(
      message.senderUserId ?? '',
    );

    if (message is RCIMIWCombineV2Message) {
      final summaries = message.summaryList ?? const <String>[];
      return ChatDetailMessage(
        messageId: messageKey,
        kind: ChatDetailMessageKind.combineForward,
        isMe: isMe,
        isSending: isSending,
        text: AppLocalizations.currentText('chat_detail_history'),
        combineSummaries: summaries,
        sentTime: sentTime,
        extra: message,
        showReadReceipt: _shouldShowReadReceipt(message, isMe),
        isRead: _isReadReceiptRead(message),
        groupReadCount: _groupReadCount(message),
        senderUserId: message.senderUserId,
        senderAvatarUrl: senderUserInfo?.avatar,
      );
    }

    if (message.messageType == RCIMIWMessageType.combineV2) {
      return ChatDetailMessage(
        messageId: messageKey,
        kind: ChatDetailMessageKind.combineForward,
        isMe: isMe,
        isSending: isSending,
        text: AppLocalizations.currentText('chat_detail_history'),
        sentTime: sentTime,
        extra: message,
        showReadReceipt: _shouldShowReadReceipt(message, isMe),
        isRead: _isReadReceiptRead(message),
        groupReadCount: _groupReadCount(message),
        senderUserId: message.senderUserId,
        senderAvatarUrl: senderUserInfo?.avatar,
      );
    }

    if (message is RCIMIWReferenceMessage) {
      final referenceMessage = message.referenceMessage;
      return ChatDetailMessage(
        messageId: messageKey,
        kind: ChatDetailMessageKind.text,
        isMe: isMe,
        isSending: isSending,
        text: (message.text?.isNotEmpty ?? false)
            ? message.text
            : AppLocalizations.currentText('chat_detail_empty_message'),
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
        showReadReceipt: _shouldShowReadReceipt(message, isMe),
        isRead: _isReadReceiptRead(message),
        groupReadCount: _groupReadCount(message),
        senderUserId: message.senderUserId,
        senderAvatarUrl: senderUserInfo?.avatar,
      );
    }

    final callSummary = RongCallSummaryParser.tryParse(message);
    if (callSummary != null) {
      return ChatDetailMessage(
        messageId: messageKey,
        kind: ChatDetailMessageKind.call,
        isMe: isMe,
        isSending: isSending,
        sentTime: sentTime,
        isVideo: callSummary.isVideo,
        text: callSummary.text,
        extra: message,
        senderUserId: message.senderUserId,
        senderAvatarUrl: senderUserInfo?.avatar,
      );
    }

    if (message is RCIMIWTextMessage) {
      return ChatDetailMessage(
        messageId: messageKey,
        kind: ChatDetailMessageKind.text,
        isMe: isMe,
        isSending: isSending,
        text: (message.text?.isNotEmpty ?? false)
            ? message.text
            : AppLocalizations.currentText('chat_detail_empty_message'),
        sentTime: sentTime,
        extra: message,
        showReadReceipt: _shouldShowReadReceipt(message, isMe),
        isRead: _isReadReceiptRead(message),
        groupReadCount: _groupReadCount(message),
        senderUserId: message.senderUserId,
        senderAvatarUrl: senderUserInfo?.avatar,
      );
    }

    if (message is RCIMIWImageMessage) {
      return ChatDetailMessage(
        messageId: messageKey,
        kind: ChatDetailMessageKind.image,
        isMe: isMe,
        isSending: isSending,
        sentTime: sentTime,
        imagePath: message.local,
        remote: message.remote,
        thumbnailBase64String: message.thumbnailBase64String,
        extra: message,
        showReadReceipt: _shouldShowReadReceipt(message, isMe),
        isRead: _isReadReceiptRead(message),
        groupReadCount: _groupReadCount(message),
        senderUserId: message.senderUserId,
        senderAvatarUrl: senderUserInfo?.avatar,
      );
    }

    if (message is RCIMIWSightMessage) {
      // print('video----${message.duration}---${message.thumbnailBase64String}');
      return ChatDetailMessage(
        messageId: messageKey,
        kind: ChatDetailMessageKind.video,
        isMe: isMe,
        isSending: isSending,
        sentTime: sentTime,
        thumbnailBase64String: message.thumbnailBase64String,
        path: message.local,
        remote: message.remote,
        duration: formatDurationFromMs(message.duration ?? 0),
        extra: message,
        showReadReceipt: _shouldShowReadReceipt(message, isMe),
        isRead: _isReadReceiptRead(message),
        groupReadCount: _groupReadCount(message),
        senderUserId: message.senderUserId,
        senderAvatarUrl: senderUserInfo?.avatar,
      );
    }
    if (message is RCIMIWVoiceMessage) {
      return ChatDetailMessage(
        messageId: messageKey,
        kind: ChatDetailMessageKind.voice,
        isMe: isMe,
        isSending: isSending,
        sentTime: sentTime,
        path: message.local,
        remote: message.remote,
        duration: formatDurationFromMs(message.duration ?? 0),
        extra: message,
        showReadReceipt: _shouldShowReadReceipt(message, isMe),
        isRead: _isReadReceiptRead(message),
        groupReadCount: _groupReadCount(message),
        senderUserId: message.senderUserId,
        senderAvatarUrl: senderUserInfo?.avatar,
      );
    }
    if (message is RCIMIWFileMessage) {
      return ChatDetailMessage(
        messageId: messageKey,
        kind: ChatDetailMessageKind.file,
        isMe: isMe,
        isSending: isSending,
        sentTime: sentTime,
        fileName: message.name,
        fileSize: formatFileSize(message.size ?? 0),
        path: message.local,
        remote: message.remote,
        extra: message,
        showReadReceipt: _shouldShowReadReceipt(message, isMe),
        isRead: _isReadReceiptRead(message),
        groupReadCount: _groupReadCount(message),
        senderUserId: message.senderUserId,
        senderAvatarUrl: senderUserInfo?.avatar,
      );
    }

    if (message.messageType == RCIMIWMessageType.custom) {
      final face = ChatCustomFace.fromMessage(message);
      if (face != null) {
        return ChatDetailMessage(
          messageId: messageKey,
          kind: ChatDetailMessageKind.customFace,
          isMe: isMe,
          isSending: isSending,
          showBubble: false,
          sentTime: sentTime,
          imagePath: face.assetPath,
          text: AppLocalizations.currentText('chat_detail_custom_face'),
          extra: message,
          showReadReceipt: _shouldShowReadReceipt(message, isMe),
          isRead: _isReadReceiptRead(message),
          groupReadCount: _groupReadCount(message),
          senderUserId: message.senderUserId,
          senderAvatarUrl: senderUserInfo?.avatar,
        );
      }
      final momentPost = MomentPostShareData.fromMessage(message);
      if (momentPost != null) {
        return ChatDetailMessage(
          messageId: messageKey,
          kind: ChatDetailMessageKind.momentPost,
          isMe: isMe,
          isSending: isSending,
          sentTime: sentTime,
          text: momentPost.postContent,
          imagePath: momentPost.postCover,
          contactName: momentPost.authorName,
          avatarPath: momentPost.authorAvatar,
          extra: message,
          showReadReceipt: _shouldShowReadReceipt(message, isMe),
          isRead: _isReadReceiptRead(message),
          groupReadCount: _groupReadCount(message),
          senderUserId: message.senderUserId,
          senderAvatarUrl: senderUserInfo?.avatar,
        );
      }
      final redPacket = _redPacketFromMessage(message);
      if (redPacket != null) {
        final senderName = senderUserInfo?.name;
        return ChatDetailMessage(
          messageId: messageKey,
          kind: ChatDetailMessageKind.redBag,
          isMe: isMe,
          isSending: isSending,
          showBubble: false,
          sentTime: sentTime,
          text: redPacket.greeting.isNotEmpty
              ? redPacket.greeting
              : AppLocalizations.currentText('chat_detail_red_packet'),
          isClaimed: redPacket.isClaimed,
          redPacketAmount: redPacket.amount,
          redPacketTokenSymbol: redPacket.tokenSymbol,
          redPacketType: redPacket.packetType,
          extra: message,
          showReadReceipt: _shouldShowReadReceipt(message, isMe),
          isRead: _isReadReceiptRead(message),
          groupReadCount: _groupReadCount(message),
          senderUserId: message.senderUserId,
          senderAvatarUrl: senderUserInfo?.avatar,
          noticeName: senderName,
        );
      }
      MessageModel model = MessageModel(item: message);
      final content = await model.formatCustomContent();
      return ChatDetailMessage(
        messageId: messageKey,
        kind: ChatDetailMessageKind.fm,
        isMe: isMe,
        isSending: isSending,
        sentTime: sentTime,
        text: content,
        extra: message,
      );
    }
    if (message.messageType == RCIMIWMessageType.nativeCustom) {
      final redPacket = _redPacketFromMessage(message);
      if (redPacket != null) {
        final senderName = senderUserInfo?.name;
        return ChatDetailMessage(
          messageId: messageKey,
          kind: ChatDetailMessageKind.redBag,
          isMe: isMe,
          isSending: isSending,
          showBubble: false,
          sentTime: sentTime,
          text: redPacket.greeting.isNotEmpty
              ? redPacket.greeting
              : AppLocalizations.currentText('chat_detail_red_packet'),
          isClaimed: redPacket.isClaimed,
          redPacketAmount: redPacket.amount,
          redPacketTokenSymbol: redPacket.tokenSymbol,
          redPacketType: redPacket.packetType,
          extra: message,
          showReadReceipt: _shouldShowReadReceipt(message, isMe),
          isRead: _isReadReceiptRead(message),
          groupReadCount: _groupReadCount(message),
          senderUserId: message.senderUserId,
          senderAvatarUrl: senderUserInfo?.avatar,
          noticeName: senderName,
        );
      }
      return ChatDetailMessage(
        messageId: messageKey,
        kind: ChatDetailMessageKind.unknown,
        isMe: isMe,
        isSending: isSending,
        text: '',
        sentTime: sentTime,
        extra: message,
      );
    }
    return ChatDetailMessage(
      messageId: messageKey,
      kind: ChatDetailMessageKind.text,
      isMe: isMe,
      isSending: isSending,
      text: AppLocalizations.currentText(
        'chat_detail_unsupported_message_type',
      ),
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

  static bool supportsReadReceiptMessage(RCIMIWMessage message) {
    if (RongCallSummaryParser.tryParse(message) != null) {
      return false;
    }

    return message is RCIMIWTextMessage ||
        message is RCIMIWReferenceMessage ||
        message is RCIMIWImageMessage ||
        message is RCIMIWSightMessage ||
        message is RCIMIWVoiceMessage ||
        message is RCIMIWFileMessage ||
        message is RCIMIWCombineV2Message ||
        message.messageType == RCIMIWMessageType.combineV2 ||
        ChatCustomFace.fromMessage(message) != null ||
        MomentPostShareData.fromMessage(message) != null ||
        _redPacketFromMessage(message) != null;
  }

  static bool supportsReadReceiptKind(ChatDetailMessageKind kind) {
    return kind == ChatDetailMessageKind.text ||
        kind == ChatDetailMessageKind.image ||
        kind == ChatDetailMessageKind.video ||
        kind == ChatDetailMessageKind.voice ||
        kind == ChatDetailMessageKind.file ||
        kind == ChatDetailMessageKind.combineForward ||
        kind == ChatDetailMessageKind.customFace ||
        kind == ChatDetailMessageKind.momentPost ||
        kind == ChatDetailMessageKind.redBag;
  }

  static bool _shouldShowReadReceipt(RCIMIWMessage message, bool isMe) {
    final type = message.conversationType;
    return isMe &&
        (type == RCIMIWConversationType.private ||
            type == RCIMIWConversationType.group) &&
        supportsReadReceiptMessage(message);
  }

  static bool _isReadReceiptRead(RCIMIWMessage message) {
    if (message.conversationType == RCIMIWConversationType.private) {
      return message.sentStatus == RCIMIWSentStatus.read;
    }

    if (message.conversationType == RCIMIWConversationType.group) {
      return _groupReadCount(message) > 0;
    }

    return false;
  }

  static int _groupReadCount(RCIMIWMessage message) {
    return message.groupReadReceiptInfo?.respondUserIds?.length ?? 0;
  }

  static Future<String> quoteSummaryForMessage(RCIMIWMessage? message) async {
    if (message == null || _isRecallMessage(message)) {
      return AppLocalizations.currentText('chat_detail_generic_message');
    }

    final callSummary = RongCallSummaryParser.tryParse(message);
    if (callSummary != null) {
      return callSummary.text;
    }

    if (message is RCIMIWReferenceMessage) {
      final text = message.text;
      return (text?.isNotEmpty ?? false)
          ? text!
          : AppLocalizations.currentText('chat_detail_generic_message');
    }

    if (message is RCIMIWCombineV2Message ||
        message.messageType == RCIMIWMessageType.combineV2) {
      return AppLocalizations.currentText('chat_detail_history');
    }

    final redPacket = _redPacketFromMessage(message);
    if (redPacket != null) {
      return redPacket.greeting.isNotEmpty
          ? redPacket.greeting
          : AppLocalizations.currentText('chat_detail_red_packet');
    }

    if (message is RCIMIWTextMessage) {
      final text = message.text;
      return (text?.isNotEmpty ?? false)
          ? text!
          : AppLocalizations.currentText('chat_detail_empty_message');
    }

    if (message is RCIMIWImageMessage) {
      return AppLocalizations.currentText('chat_image');
    }

    if (message is RCIMIWVoiceMessage) {
      return AppLocalizations.currentText('chat_voice');
    }

    if (message is RCIMIWSightMessage) {
      return AppLocalizations.currentText('chat_video');
    }

    if (message is RCIMIWFileMessage) {
      return AppLocalizations.currentText('chat_file');
    }

    if (message.messageType == RCIMIWMessageType.custom) {
      if (ChatCustomFace.fromMessage(message) != null) {
        return AppLocalizations.currentText('chat_detail_custom_face');
      }
      final momentPost = MomentPostShareData.fromMessage(message);
      if (momentPost != null) {
        return momentPost.postContent.isNotEmpty
            ? momentPost.postContent
            : AppLocalizations.currentText('moments_moment_title');
      }
      final model = MessageModel(item: message);
      final content = await model.formatCustomContent();
      return content.isNotEmpty
          ? content
          : AppLocalizations.currentText('chat_detail_generic_message');
    }

    return AppLocalizations.currentText('chat_detail_generic_message');
  }

  static String messageKeyFor(RCIMIWMessage message) {
    final callSummaryKey = RongCallSummaryParser.stableMessageKey(message);
    if (callSummaryKey != null) return callSummaryKey;

    final mediaKey = _stableMediaMessageKey(message);
    if (mediaKey != null) return mediaKey;

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

  static String? _stableMediaMessageKey(RCIMIWMessage message) {
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

  static bool _shouldAppendRedPacketClaimNotice(ChatDetailMessage message) {
    return message.kind == ChatDetailMessageKind.redBag &&
        message.isClaimed == true;
  }

  static ChatDetailMessage? _buildRedPacketClaimNotice(
    ChatDetailMessage message,
  ) {
    final raw = message.extra;
    if (raw is! RCIMIWMessage) {
      return null;
    }

    final redPacket = _redPacketFromMessage(raw);
    if (redPacket == null || redPacket.redPacketId.isEmpty) {
      return null;
    }

    final claimedUserId = IMEngineManager().currentUserId;
    final claimedAt =
        RedPacketClaimStore.claimedAt(
          redPacket.redPacketId,
          userId: claimedUserId,
        ) ??
        message.sentTime;
    if (claimedAt == null || claimedAt <= 0) {
      return null;
    }

    return ChatDetailMessage(
      messageId: 'red_packet_claim_notice_${message.messageId}',
      kind: ChatDetailMessageKind.redBagNotice,
      showBubble: false,
      text: message.noticeName ?? message.senderUserId ?? '',
      noticeName: message.noticeName ?? message.senderUserId ?? '',
      sentTime: claimedAt,
    );
  }

  static void _insertBySentTime(
    List<ChatDetailMessage> messages,
    ChatDetailMessage item,
  ) {
    final time = item.sentTime ?? 0;
    var index = messages.length;
    for (var i = 0; i < messages.length; i++) {
      final current = messages[i].sentTime ?? 0;
      if (current > time) {
        index = i;
        break;
      }
    }
    messages.insert(index, item);
  }

  static RedPacketData? _redPacketFromMessage(RCIMIWMessage message) {
    return RedPacketData.fromMessage(
      message,
      claimedUserId: IMEngineManager().currentUserId,
    );
  }
}
