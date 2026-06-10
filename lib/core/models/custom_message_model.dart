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
  groupDisbanded,
  customFace,
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
    case 'group_disbanded':
      return CustomMessageType.groupDisbanded;
    case 'custom_face':
      return CustomMessageType.customFace;
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

  CustomMessageModel({
    required this.type,
    required this.fromUserId,
    required this.toUserId,
    this.content,
    this.userIds,
    this.facePackId,
    this.faceName,
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
    return json;
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
      case CustomMessageType.groupDisbanded:
        return 'group_disbanded';
      case CustomMessageType.customFace:
        return 'custom_face';
      case CustomMessageType.unknown:
        return 'unknown';
    }
  }
}
