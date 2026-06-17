import 'dart:async';

import 'package:rongcloud_call_wrapper_plugin/rongcloud_call_wrapper_plugin.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

class RongCallJoinRequest {
  const RongCallJoinRequest({
    required this.targetId,
    required this.mediaType,
    required this.displayName,
    required this.requesterUserId,
    required this.sentAt,
  });

  final String targetId;
  final RCCallMediaType mediaType;
  final String displayName;
  final String requesterUserId;
  final int sentAt;
}

class RongCallJoinRequestMessage {
  RongCallJoinRequestMessage._();

  static const String objectName = 'PC:CallJoinRequest';

  static RongCallJoinRequest? tryParse(RCIMIWMessage message) {
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
    final requesterUserId =
        (data['requesterUserId'] ?? message.senderUserId ?? '')
            .toString()
            .trim();
    if (targetId.isEmpty || requesterUserId.isEmpty) return null;

    final mediaTypeIndex = _readInt(data['mediaType']) ?? 0;
    final mediaType = mediaTypeIndex == RCCallMediaType.audio_video.index
        ? RCCallMediaType.audio_video
        : RCCallMediaType.audio;

    return RongCallJoinRequest(
      targetId: targetId,
      mediaType: mediaType,
      displayName: (data['displayName'] ?? '').toString().trim(),
      requesterUserId: requesterUserId,
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
}

class RongCallJoinRequestCenter {
  RongCallJoinRequestCenter._();

  static final RongCallJoinRequestCenter _instance =
      RongCallJoinRequestCenter._();

  factory RongCallJoinRequestCenter() => _instance;

  final StreamController<RongCallJoinRequest> _controller =
      StreamController<RongCallJoinRequest>.broadcast();

  Stream<RongCallJoinRequest> get stream => _controller.stream;

  bool notifyIfCallJoinRequest(RCIMIWMessage message) {
    final request = RongCallJoinRequestMessage.tryParse(message);
    if (request == null) return false;
    _controller.add(request);
    return true;
  }
}
