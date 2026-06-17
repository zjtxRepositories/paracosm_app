import 'dart:async';
import 'dart:convert';

import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';

import '../../util/string_util.dart';

class RongCallSummary {
  const RongCallSummary({
    required this.isVideo,
    required this.text,
    required this.conversationText,
    this.duration,
    this.reason,
  });

  final bool isVideo;
  final String text;
  final String conversationText;
  final int? duration;
  final int? reason;
}

class RongCallSummaryEvent {
  const RongCallSummaryEvent({
    required this.targetId,
    required this.senderUserId,
    required this.callId,
    required this.sessionId,
    required this.isGroupCall,
    required this.reason,
    required this.reasonName,
    required this.connectedTime,
  });

  final String targetId;
  final String senderUserId;
  final String callId;
  final String sessionId;
  final bool isGroupCall;
  final int? reason;
  final String reasonName;
  final int connectedTime;
}

class RongCallSummaryParser {
  RongCallSummaryParser._();

  static const String objectName = 'PC:VCSummary';
  static const String legacyObjectName = 'RC:VCSummary';

  static bool isCallSummaryIdentifier(String? value) {
    return value == objectName || value == legacyObjectName;
  }

  static RongCallSummary? tryParse(RCIMIWMessage message) {
    final data = _callSummaryData(message);
    if (data == null) return null;

    final duration = _readInt(data['duration']);
    final reason = _readInt(data['hangupReason']) ?? _readInt(data['reason']);
    final connectedTime = _readInt(data['connectedTime']) ?? 0;
    final isVideo = _isVideoCall(data['mediaType']);
    final text = _formatText(
      duration: duration,
      reason: reason,
      connectedTime: connectedTime,
    );
    final prefix = isVideo
        ? AppLocalizations.currentText('call_video_prefix')
        : AppLocalizations.currentText('call_audio_prefix');

    return RongCallSummary(
      isVideo: isVideo,
      text: text,
      conversationText: '$prefix $text',
      duration: duration,
      reason: reason,
    );
  }

  static RongCallSummaryEvent? tryParseEvent(RCIMIWMessage message) {
    final data = _callSummaryData(message);
    if (data == null) return null;

    return RongCallSummaryEvent(
      targetId: (message.targetId ?? '').trim(),
      senderUserId: (message.senderUserId ?? '').trim(),
      callId: _readString(data['callId']) ?? '',
      sessionId: _readString(data['sessionId']) ?? '',
      isGroupCall: message.conversationType == RCIMIWConversationType.group,
      reason: _readInt(data['hangupReason']) ?? _readInt(data['reason']),
      reasonName: _readString(data['reasonName']) ?? '',
      connectedTime: _readInt(data['connectedTime']) ?? 0,
    );
  }

  static String? stableMessageKey(RCIMIWMessage message) {
    final data = _callSummaryData(message);
    if (data == null) return null;

    final callId = _readString(data['callId']);
    if (callId != null) return 'call:$callId';

    final sessionId = _readString(data['sessionId']);
    if (sessionId != null) return 'call:$sessionId';

    return [
      'call',
      message.conversationType?.index ?? -1,
      message.targetId ?? '',
      message.senderUserId ?? '',
      _readInt(data['startTime']) ?? '',
      _readInt(data['connectedTime']) ?? '',
      _readInt(data['endTime']) ?? '',
      _readInt(data['mediaType']) ?? data['mediaType'] ?? '',
      _readInt(data['hangupReason']) ?? _readInt(data['reason']) ?? '',
    ].join(':');
  }

  static Map<String, dynamic>? _callSummaryData(RCIMIWMessage message) {
    if (message is RCIMIWUnknownMessage &&
        isCallSummaryIdentifier(message.objectName)) {
      return _decodeDynamic(message.rawData);
    }

    if (message is RCIMIWNativeCustomMessage &&
        isCallSummaryIdentifier(message.messageIdentifier)) {
      return _decodeDynamic(message.fields);
    }

    if (message is RCIMIWCustomMessage &&
        isCallSummaryIdentifier(message.identifier)) {
      return _decodeDynamic(message.fields);
    }

    return null;
  }

  static Map<String, dynamic>? _decodeDynamic(dynamic value) {
    if (value == null) return null;

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      return _unwrapPayload(map) ?? map;
    }

    if (value is String) {
      return _decodeString(value);
    }

    return null;
  }

  static Map<String, dynamic>? _decodeString(String value) {
    if (value.isEmpty) return null;

    Map<String, dynamic>? decodeJson(String source) {
      final decoded = jsonDecode(source);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return null;
    }

    try {
      return decodeJson(value);
    } catch (_) {
      try {
        return decodeJson(utf8.decode(base64Decode(value)));
      } catch (_) {
        return null;
      }
    }
  }

  static Map<String, dynamic>? _unwrapPayload(Map<String, dynamic> value) {
    for (final key in const ['content', 'data', 'payload', 'rawData']) {
      final nested = _decodeDynamic(value[key]);
      if (nested != null) return nested;
    }
    return null;
  }

  static bool _isVideoCall(dynamic mediaType) {
    if (mediaType is num) return mediaType.toInt() == 2;
    if (mediaType is String) {
      final normalized = mediaType.toLowerCase();
      return normalized == '2' ||
          normalized == 'video' ||
          normalized == 'audio_video';
    }
    return false;
  }

  static String _formatText({
    required int? duration,
    required int? reason,
    required int connectedTime,
  }) {
    if (connectedTime > 0 && duration != null && duration > 0) {
      return AppLocalizations.currentText('call_duration', {
        'duration': formatDurationFromMs(duration),
      });
    }

    switch (reason) {
      case 0 when connectedTime <= 0:
      case 1:
      case 10:
      case 11:
        return AppLocalizations.currentText('call_canceled');
      case 2:
      case 12:
        return AppLocalizations.currentText('call_rejected');
      case 4:
      case 14:
        return AppLocalizations.currentText('call_busy');
      case 5:
      case 15:
        return AppLocalizations.currentText('call_unanswered');
      case 7:
      case 16:
        return AppLocalizations.currentText('call_network_error');
      default:
        return AppLocalizations.currentText('call_ended');
    }
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String? _readString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}

class RongCallSummaryCenter {
  RongCallSummaryCenter._();

  static final RongCallSummaryCenter _instance = RongCallSummaryCenter._();

  factory RongCallSummaryCenter() => _instance;

  final StreamController<RongCallSummaryEvent> _controller =
      StreamController<RongCallSummaryEvent>.broadcast();

  Stream<RongCallSummaryEvent> get stream => _controller.stream;

  bool notifyIfCallSummary(RCIMIWMessage message) {
    final event = RongCallSummaryParser.tryParseEvent(message);
    if (event == null) return false;
    _controller.add(event);
    return true;
  }
}
