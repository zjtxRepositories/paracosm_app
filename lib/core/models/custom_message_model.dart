enum CustomMessageType {
  friendAdd,
  groupInvited,
  systemNotice,
  systemEvent,
  recall,
  transfer,
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
    case 'system_event':
      return CustomMessageType.systemEvent;
    case 'recall':
      return CustomMessageType.recall;
    case 'transfer':
      return CustomMessageType.transfer;
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
      case CustomMessageType.systemEvent:
        return 'system_event';
      case CustomMessageType.recall:
        return 'recall';
      case CustomMessageType.transfer:
        return 'transfer';
      case CustomMessageType.unknown:
        return 'unknown';
    }
  }
}