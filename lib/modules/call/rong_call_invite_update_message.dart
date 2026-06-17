import 'dart:async';

import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

class RongCallInviteUpdate {
  const RongCallInviteUpdate({
    required this.targetId,
    required this.invitedUserIds,
    required this.senderUserId,
    required this.mediaTypeIndex,
    required this.displayName,
    required this.initiatorUserId,
    required this.activeUserIds,
    required this.sentAt,
  });

  final String targetId;
  final List<String> invitedUserIds;
  final String senderUserId;
  final int mediaTypeIndex;
  final String displayName;
  final String initiatorUserId;
  final List<String> activeUserIds;
  final int sentAt;
}

class RongCallInviteUpdateMessage {
  RongCallInviteUpdateMessage._();

  static const String objectName = 'PC:CallInviteUpdate';

  static RongCallInviteUpdate? tryParse(RCIMIWMessage message) {
    if (message is! RCIMIWNativeCustomMessage ||
        message.messageIdentifier != objectName) {
      return null;
    }

    final fields = message.fields;
    if (fields == null) return null;

    final data = Map<String, dynamic>.from(fields);
    final targetId = (data['targetId'] ?? message.targetId ?? '')
        .toString()
        .trim();
    if (targetId.isEmpty) return null;

    final invitedUserIds = _readStringList(data['invitedUserIds']);
    if (invitedUserIds.isEmpty) return null;

    return RongCallInviteUpdate(
      targetId: targetId,
      invitedUserIds: invitedUserIds,
      senderUserId: (message.senderUserId ?? '').trim(),
      mediaTypeIndex: _readInt(data['mediaType']) ?? 0,
      displayName: (data['displayName'] ?? '').toString().trim(),
      initiatorUserId: (data['initiatorUserId'] ?? message.senderUserId ?? '')
          .toString()
          .trim(),
      activeUserIds: _readStringList(data['activeUserIds']),
      sentAt:
          _readInt(data['sentAt']) ??
          message.sentTime ??
          message.receivedTime ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static List<String> _readStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }
}

class RongCallInviteUpdateCenter {
  RongCallInviteUpdateCenter._();

  static final RongCallInviteUpdateCenter _instance =
      RongCallInviteUpdateCenter._();

  factory RongCallInviteUpdateCenter() => _instance;

  final StreamController<RongCallInviteUpdate> _controller =
      StreamController<RongCallInviteUpdate>.broadcast();

  Stream<RongCallInviteUpdate> get stream => _controller.stream;

  bool notifyIfCallInviteUpdate(RCIMIWMessage message) {
    final update = RongCallInviteUpdateMessage.tryParse(message);
    if (update == null) return false;
    _controller.add(update);
    return true;
  }
}
