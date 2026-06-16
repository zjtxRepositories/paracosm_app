import 'dart:async';

import 'package:rongcloud_call_wrapper_plugin/rongcloud_call_wrapper_plugin.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

enum RongGroupCallStatusAction { active, ended }

class RongGroupCallStatus {
  const RongGroupCallStatus({
    required this.targetId,
    required this.action,
    required this.mediaType,
    required this.displayName,
    required this.initiatorUserId,
    required this.activeUserIds,
    required this.invitedUserIds,
    required this.sentAt,
  });

  final String targetId;
  final RongGroupCallStatusAction action;
  final RCCallMediaType mediaType;
  final String displayName;
  final String initiatorUserId;
  final List<String> activeUserIds;
  final List<String> invitedUserIds;
  final int sentAt;

  bool get isActive => action == RongGroupCallStatusAction.active;
  bool get isVoice => mediaType == RCCallMediaType.audio;
  int get participantCount => activeUserIds.toSet().length;
}

class RongGroupCallStatusMessage {
  RongGroupCallStatusMessage._();

  static const String objectName = 'PC:GroupCallStatus';

  static RongGroupCallStatus? tryParse(RCIMIWMessage message) {
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

    final actionName = (data['action'] ?? '').toString().trim();
    final action = actionName == 'ended'
        ? RongGroupCallStatusAction.ended
        : RongGroupCallStatusAction.active;
    final mediaTypeIndex = _readInt(data['mediaType']) ?? 0;
    final mediaType = mediaTypeIndex == RCCallMediaType.audio_video.index
        ? RCCallMediaType.audio_video
        : RCCallMediaType.audio;

    return RongGroupCallStatus(
      targetId: targetId,
      action: action,
      mediaType: mediaType,
      displayName: (data['displayName'] ?? '').toString().trim(),
      initiatorUserId: (data['initiatorUserId'] ?? message.senderUserId ?? '')
          .toString()
          .trim(),
      activeUserIds: _readStringList(data['activeUserIds']),
      invitedUserIds: _readStringList(data['invitedUserIds']),
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
          .toSet()
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList();
    }
    return const [];
  }
}

class RongGroupCallStatusCenter {
  RongGroupCallStatusCenter._();

  static final RongGroupCallStatusCenter _instance =
      RongGroupCallStatusCenter._();

  factory RongGroupCallStatusCenter() => _instance;

  final StreamController<RongGroupCallStatus?> _controller =
      StreamController<RongGroupCallStatus?>.broadcast();
  final Map<String, RongGroupCallStatus> _statuses = {};

  Stream<RongGroupCallStatus?> get stream => _controller.stream;

  RongGroupCallStatus? statusFor(String targetId) => _statuses[targetId];

  void updateLocal(RongGroupCallStatus status) {
    _applyStatus(status);
  }

  bool notifyIfGroupCallStatus(RCIMIWMessage message) {
    final status = RongGroupCallStatusMessage.tryParse(message);
    if (status == null) return false;
    _applyStatus(status);
    return true;
  }

  void _applyStatus(RongGroupCallStatus status) {
    final current = _statuses[status.targetId];
    if (current != null && status.sentAt < current.sentAt) return;

    if (status.isActive) {
      _statuses[status.targetId] = status;
      _controller.add(status);
      return;
    }

    _statuses.remove(status.targetId);
    _controller.add(status);
  }
}
