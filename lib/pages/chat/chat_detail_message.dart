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
    this.senderUserId,
    this.senderAvatarUrl,
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
    this.showReadReceipt = false,
    this.isRead = false,
    this.groupReadCount = 0,
  });
  final String messageId;
  final ChatDetailMessageKind kind;
  final bool isMe;
  final bool isUnread;
  final bool showBubble;
  final String? senderUserId;
  final String? senderAvatarUrl;
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
  final bool showReadReceipt;
  final bool isRead;
  final int groupReadCount;

  ChatDetailMessage copyWith({
    String? messageId,
    ChatDetailMessageKind? kind,
    bool? isMe,
    bool? isUnread,
    bool? showBubble,
    int? sentTime,
    String? text,
    String? imagePath,
    String? duration,
    bool? isVideo,
    String? fileName,
    String? fileSize,
    String? contactName,
    String? avatarPath,
    bool? isClaimed,
    String? noticeName,
    String? thumbnailBase64String,
    String? path,
    String? remote,
    Object? extra,
    String? quoteText,
    String? quoteMessageId,
    int? quoteSentTime,
    String? quoteMessageUId,
    int? quoteRawMessageId,
    String? quoteSenderUserId,
    int? quoteMessageType,
    List<String>? combineSummaries,
    MediaSendStatus? mediaSendStatus,
    int? mediaSendProgress,
    bool? showReadReceipt,
    bool? isRead,
    int? groupReadCount,
  }) {
    return ChatDetailMessage(
      messageId: messageId ?? this.messageId,
      kind: kind ?? this.kind,
      isMe: isMe ?? this.isMe,
      isUnread: isUnread ?? this.isUnread,
      showBubble: showBubble ?? this.showBubble,
      sentTime: sentTime ?? this.sentTime,
      text: text ?? this.text,
      imagePath: imagePath ?? this.imagePath,
      duration: duration ?? this.duration,
      isVideo: isVideo ?? this.isVideo,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      contactName: contactName ?? this.contactName,
      avatarPath: avatarPath ?? this.avatarPath,
      isClaimed: isClaimed ?? this.isClaimed,
      noticeName: noticeName ?? this.noticeName,
      thumbnailBase64String:
          thumbnailBase64String ?? this.thumbnailBase64String,
      path: path ?? this.path,
      remote: remote ?? this.remote,
      extra: extra ?? this.extra,
      quoteText: quoteText ?? this.quoteText,
      quoteMessageId: quoteMessageId ?? this.quoteMessageId,
      quoteSentTime: quoteSentTime ?? this.quoteSentTime,
      quoteMessageUId: quoteMessageUId ?? this.quoteMessageUId,
      quoteRawMessageId: quoteRawMessageId ?? this.quoteRawMessageId,
      quoteSenderUserId: quoteSenderUserId ?? this.quoteSenderUserId,
      quoteMessageType: quoteMessageType ?? this.quoteMessageType,
      combineSummaries: combineSummaries ?? this.combineSummaries,
      mediaSendStatus: mediaSendStatus ?? this.mediaSendStatus,
      mediaSendProgress: mediaSendProgress ?? this.mediaSendProgress,
      showReadReceipt: showReadReceipt ?? this.showReadReceipt,
      isRead: isRead ?? this.isRead,
      groupReadCount: groupReadCount ?? this.groupReadCount,
      senderUserId: this.senderUserId,
    );
  }
}
