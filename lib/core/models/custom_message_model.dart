enum CustomMessageType {
  friendAdd,
  groupInvited,
  systemNotice,
  createDao,
  createClub,
  recall,
  transfer,
  quitGroup,
  unknown,
}
CustomMessageType _typeFromString(String? type) {
  switch (type) {
    case 'friend_add':
      return CustomMessageType.friendAdd;
    case 'group_invited':
      return CustomMessageType.groupInvited;
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
    default:
      return CustomMessageType.unknown;
  }
}

class CustomMessageModel {
  final CustomMessageType type;
  final String fromUserId;
  final String toUserId;
  String? content;

  CustomMessageModel({
    required this.type,
    required this.fromUserId,
    required this.toUserId,
    this.content,
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
    );
  }

  /// =========================
  /// toJson
  /// =========================
  Map<String, dynamic> toJson() {
    return {
      'type': _typeToString(type),
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'content': content,
    };
  }


  String _typeToString(CustomMessageType type) {
    switch (type) {
      case CustomMessageType.friendAdd:
        return 'friend_add';
      case CustomMessageType.groupInvited:
        return 'group_invited';
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
      case CustomMessageType.unknown:
        return 'unknown';
    }
  }
}