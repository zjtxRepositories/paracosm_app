enum CustomMessageType {
  friendAdd,
  groupInvited,
  groupJoined,
  systemNotice,
  createDao,
  createClub,
  recall,
  transfer,
  quitGroup,
  groupRemoved,
  groupManagerSet,
  groupDisbanded,
  customFace,
  momentPost,
  unknown,
}

CustomMessageType _typeFromString(String? type) {
  switch (type) {
    case 'friend_add':
      return CustomMessageType.friendAdd;
    case 'group_invited':
      return CustomMessageType.groupInvited;
    case 'group_joined':
      return CustomMessageType.groupJoined;
    case 'system_notice':
      return CustomMessageType.systemNotice;
    case 'create_dao':
      return CustomMessageType.createDao;
    case 'create_club':
      return CustomMessageType.createClub;
    case 'recall':
      return CustomMessageType.recall;
    case 'transfer':
      return CustomMessageType.transfer;
    case 'group_quit':
      return CustomMessageType.quitGroup;
    case 'group_removed':
      return CustomMessageType.groupRemoved;
    case 'group_manager_set':
      return CustomMessageType.groupManagerSet;
    case 'group_disbanded':
      return CustomMessageType.groupDisbanded;
    case 'custom_face':
      return CustomMessageType.customFace;
    case 'moment_post':
      return CustomMessageType.momentPost;
    default:
      return CustomMessageType.unknown;
  }
}

class CustomMessageModel {
  final CustomMessageType type;
  final String fromUserId;
  final String toUserId;
  String? content;
  final List<String>? userIds;
  final String? facePackId;
  final String? faceName;
  final String? noteId;
  final String? postContent;
  final String? postCover;
  final String? authorId;
  final String? authorName;
  final String? authorAvatar;
  final int? mediaType;

  CustomMessageModel({
    required this.type,
    required this.fromUserId,
    required this.toUserId,
    this.content,
    this.userIds,
    this.facePackId,
    this.faceName,
    this.noteId,
    this.postContent,
    this.postCover,
    this.authorId,
    this.authorName,
    this.authorAvatar,
    this.mediaType,
  });

  /// =========================
  /// fromJson
  /// =========================
  factory CustomMessageModel.fromJson(Map<String, dynamic> json) {
    return CustomMessageModel(
      type: _typeFromString(json['type']),
      fromUserId: json['fromUserId'] ?? '',
      toUserId: json['toUserId'] ?? '',
      content: json['content'] ?? '',
      userIds: (json['userIds'] as List?)?.map((e) => e.toString()).toList(),
      facePackId: json['facePackId']?.toString(),
      faceName: json['faceName']?.toString(),
      noteId: json['noteId']?.toString(),
      postContent: json['postContent']?.toString(),
      postCover: json['postCover']?.toString(),
      authorId: json['authorId']?.toString(),
      authorName: json['authorName']?.toString(),
      authorAvatar: json['authorAvatar']?.toString(),
      mediaType: _parseInt(json['mediaType']),
    );
  }

  /// =========================
  /// toJson
  /// =========================
  Map<String, dynamic> toJson() {
    final json = {
      'type': _typeToString(type),
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'content': content,
      'userIds': userIds,
    };
    if (facePackId != null) {
      json['facePackId'] = facePackId;
    }
    if (faceName != null) {
      json['faceName'] = faceName;
    }
    if (noteId != null) {
      json['noteId'] = noteId;
    }
    if (postContent != null) {
      json['postContent'] = postContent;
    }
    if (postCover != null) {
      json['postCover'] = postCover;
    }
    if (authorId != null) {
      json['authorId'] = authorId;
    }
    if (authorName != null) {
      json['authorName'] = authorName;
    }
    if (authorAvatar != null) {
      json['authorAvatar'] = authorAvatar;
    }
    if (mediaType != null) {
      json['mediaType'] = mediaType;
    }
    return json;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String _typeToString(CustomMessageType type) {
    switch (type) {
      case CustomMessageType.friendAdd:
        return 'friend_add';
      case CustomMessageType.groupInvited:
        return 'group_invited';
      case CustomMessageType.groupJoined:
        return 'group_joined';
      case CustomMessageType.systemNotice:
        return 'system_notice';
      case CustomMessageType.createDao:
        return 'create_dao';
      case CustomMessageType.createClub:
        return 'create_club';
      case CustomMessageType.recall:
        return 'recall';
      case CustomMessageType.transfer:
        return 'transfer';
      case CustomMessageType.quitGroup:
        return 'group_quit';
      case CustomMessageType.groupRemoved:
        return 'group_removed';
      case CustomMessageType.groupManagerSet:
        return 'group_manager_set';
      case CustomMessageType.groupDisbanded:
        return 'group_disbanded';
      case CustomMessageType.customFace:
        return 'custom_face';
      case CustomMessageType.momentPost:
        return 'moment_post';
      case CustomMessageType.unknown:
        return 'unknown';
    }
  }
}
