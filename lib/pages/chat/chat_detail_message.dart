enum ChatDetailMessageKind {
  timestamp,
  text,
  image,
  voice,
  call,
  file,
  contactCard,
  redBag,
  redBagNotice,
  withdrawnNotice,
  fm,
}

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
}
