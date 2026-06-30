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
  groupBanEnabled,
  groupBanDisabled,
  customFace,
  momentPost,
  redPacket,
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
    case 'group_ban_enabled':
      return CustomMessageType.groupBanEnabled;
    case 'group_ban_disabled':
      return CustomMessageType.groupBanDisabled;
    case 'custom_face':
      return CustomMessageType.customFace;
    case 'moment_post':
      return CustomMessageType.momentPost;
    case 'red_packet':
      return CustomMessageType.redPacket;
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
  final String? redPacketId;
  final String? redPacketAmount;
  final String? redPacketTokenSymbol;
  final String? redPacketChainId;
  final String? redPacketType;
  final String? redPacketAssetId;
  final int? redPacketCount;
  final int? redPacketExpireTime;
  final bool? redPacketClaimed;

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
    this.redPacketId,
    this.redPacketAmount,
    this.redPacketTokenSymbol,
    this.redPacketChainId,
    this.redPacketType,
    this.redPacketAssetId,
    this.redPacketCount,
    this.redPacketExpireTime,
    this.redPacketClaimed,
  });

  bool get isNotification {
    switch (type) {
      case CustomMessageType.friendAdd:
      case CustomMessageType.groupInvited:
      case CustomMessageType.groupJoined:
      case CustomMessageType.systemNotice:
      case CustomMessageType.createDao:
      case CustomMessageType.createClub:
      case CustomMessageType.recall:
      case CustomMessageType.transfer:
      case CustomMessageType.quitGroup:
      case CustomMessageType.groupRemoved:
      case CustomMessageType.groupManagerSet:
      case CustomMessageType.groupDisbanded:
      case CustomMessageType.groupBanEnabled:
      case CustomMessageType.groupBanDisabled:
        return true;
      case CustomMessageType.customFace:
      case CustomMessageType.momentPost:
      case CustomMessageType.redPacket:
      case CustomMessageType.unknown:
        return false;
    }
  }

  /// =========================
  /// fromJson
  /// =========================
  factory CustomMessageModel.fromJson(Map<String, dynamic> json) {
    return CustomMessageModel(
      type: _typeFromString(json['type']),
      fromUserId: json['fromUserId'] ?? '',
      toUserId: json['toUserId'] ?? '',
      content: json['content'] ?? '',
      userIds: _parseUserIds(json['userIds']),
      facePackId: json['facePackId']?.toString(),
      faceName: json['faceName']?.toString(),
      noteId: json['noteId']?.toString(),
      postContent: json['postContent']?.toString(),
      postCover: json['postCover']?.toString(),
      authorId: json['authorId']?.toString(),
      authorName: json['authorName']?.toString(),
      authorAvatar: json['authorAvatar']?.toString(),
      mediaType: _parseInt(json['mediaType']),
      redPacketId: json['redPacketId']?.toString(),
      redPacketAmount: json['redPacketAmount']?.toString(),
      redPacketTokenSymbol: json['redPacketTokenSymbol']?.toString(),
      redPacketChainId: json['redPacketChainId']?.toString(),
      redPacketType: json['redPacketType']?.toString(),
      redPacketAssetId: json['redPacketAssetId']?.toString(),
      redPacketCount: _parseInt(json['redPacketCount']),
      redPacketExpireTime: _parseInt(json['redPacketExpireTime']),
      redPacketClaimed: _parseBool(json['redPacketClaimed']),
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
    if (redPacketId != null) {
      json['redPacketId'] = redPacketId;
    }
    if (redPacketAmount != null) {
      json['redPacketAmount'] = redPacketAmount;
    }
    if (redPacketTokenSymbol != null) {
      json['redPacketTokenSymbol'] = redPacketTokenSymbol;
    }
    if (redPacketChainId != null) {
      json['redPacketChainId'] = redPacketChainId;
    }
    if (redPacketType != null) {
      json['redPacketType'] = redPacketType;
    }
    if (redPacketAssetId != null) {
      json['redPacketAssetId'] = redPacketAssetId;
    }
    if (redPacketCount != null) {
      json['redPacketCount'] = redPacketCount;
    }
    if (redPacketExpireTime != null) {
      json['redPacketExpireTime'] = redPacketExpireTime;
    }
    if (redPacketClaimed != null) {
      json['redPacketClaimed'] = redPacketClaimed;
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

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'true':
        case '1':
          return true;
        case 'false':
        case '0':
          return false;
      }
    }
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
      case CustomMessageType.groupBanEnabled:
        return 'group_ban_enabled';
      case CustomMessageType.groupBanDisabled:
        return 'group_ban_disabled';
      case CustomMessageType.customFace:
        return 'custom_face';
      case CustomMessageType.momentPost:
        return 'moment_post';
      case CustomMessageType.redPacket:
        return 'red_packet';
      case CustomMessageType.unknown:
        return 'unknown';
    }
  }
}

List<String>? _parseUserIds(dynamic value) {
  if (value == null) return null;

  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }

  if (value is String) {
    return [value];
  }

  return null;
}
