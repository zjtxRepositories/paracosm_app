enum MomentMessageAction { like, collect, review, follow, unknown }

class MomentMessageModel {
  const MomentMessageModel({
    required this.messageId,
    required this.type,
    required this.action,
    required this.noteId,
    required this.reviewId,
    required this.content,
    required this.fromUserId,
    required this.toUserId,
    required this.isRead,
    required this.readTimestamp,
    required this.createTimestamp,
  });

  final String messageId;
  final int type;
  final MomentMessageAction action;
  final String noteId;
  final String reviewId;
  final String content;
  final String fromUserId;
  final String toUserId;
  final bool isRead;
  final int readTimestamp;
  final int createTimestamp;

  String get cacheKey {
    if (messageId.isNotEmpty) return messageId;
    return [
      type,
      action.name,
      noteId,
      reviewId,
      fromUserId,
      toUserId,
      content,
      createTimestamp,
    ].join('|');
  }

  factory MomentMessageModel.fromJson(Map<String, dynamic> json) {
    final type = _asInt(json['type']);
    return MomentMessageModel(
      messageId: _asString(json['message_id']),
      type: type,
      action: _parseAction(json, type),
      noteId: _asString(json['note_id']),
      reviewId: _asString(json['review_id']),
      content: _asString(json['content']),
      fromUserId: _asString(json['from']),
      toUserId: _asString(json['to']),
      isRead: _asBool(json['read']),
      readTimestamp: _asInt(json['read_timestamp']),
      createTimestamp: _asInt(json['create_timestamp']),
    );
  }

  static MomentMessageAction _parseAction(Map<String, dynamic> json, int type) {
    final data = json['data'];
    final dataAction = data is Map ? data['action'] : data;
    final rawAction = _asString(json['action']).isNotEmpty
        ? _asString(json['action'])
        : _asString(dataAction);

    switch (rawAction.toLowerCase()) {
      case 'like':
        return MomentMessageAction.like;
      case 'collect':
        return MomentMessageAction.collect;
      case 'review':
        return MomentMessageAction.review;
      case 'follow':
        return MomentMessageAction.follow;
    }

    return switch (type) {
      1 => MomentMessageAction.like,
      2 => MomentMessageAction.collect,
      3 => MomentMessageAction.review,
      4 => MomentMessageAction.follow,
      _ => MomentMessageAction.unknown,
    };
  }

  static String _asString(dynamic value) => value?.toString().trim() ?? '';

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return value?.toString().toLowerCase() == 'true';
  }
}
