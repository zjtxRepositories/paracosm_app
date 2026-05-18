enum ChatDetailMessageKind {
  timestamp,
  text,
  image,
  video,
  voice,
  call,
  file,
  contactCard,
  redBag,
  redBagNotice,
  withdrawnNotice,
  combineForward,
  fm,
}

enum MediaSendStatus { sent, sending, failed }

class ChatDetailMessage {
  const ChatDetailMessage({
    required this.kind,
    required this.messageId,
    this.isMe = false,
    this.isUnread = false,
    this.showBubble = true,
    this.sentTime,
    this.text,
    this.imagePath,
    this.duration,
    this.isVideo = false,
    this.fileName,
    this.fileSize,
    this.contactName,
    this.avatarPath,
    this.isClaimed,
    this.noticeName,
    this.thumbnailBase64String,
    this.path,
    this.remote,
    this.extra,
    this.quoteText,
    this.quoteMessageId,
    this.quoteSentTime,
    this.quoteMessageUId,
    this.quoteRawMessageId,
    this.quoteSenderUserId,
    this.quoteMessageType,
    this.combineSummaries,
    this.mediaSendStatus = MediaSendStatus.sent,
    this.mediaSendProgress = 100,
  });
  final String messageId;
  final ChatDetailMessageKind kind;
  final bool isMe;
  final bool isUnread;
  final bool showBubble;
  final int? sentTime;
  final String? text;
  final String? imagePath;
  final String? duration;
  final bool isVideo;
  final String? fileName;
  final String? fileSize;
  final String? contactName;
  final String? avatarPath;
  final bool? isClaimed;
  final String? noticeName;
  final String? thumbnailBase64String;
  final String? path;
  final String? remote;
  final Object? extra;
  final String? quoteText;
  final String? quoteMessageId;
  final int? quoteSentTime;
  final String? quoteMessageUId;
  final int? quoteRawMessageId;
  final String? quoteSenderUserId;
  final int? quoteMessageType;
  final List<String>? combineSummaries;
  final MediaSendStatus mediaSendStatus;
  final int mediaSendProgress;
}
