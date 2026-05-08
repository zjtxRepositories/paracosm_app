import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/modules/call/rong_call_summary_parser.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

void main() {
  group('RongCallSummaryParser', () {
    test('parses native custom summary fields', () {
      final message = RCIMIWNativeCustomMessage.fromJson({
        'messageType': RCIMIWMessageType.nativeCustom.index,
        'messageIdentifier': RongCallSummaryParser.objectName,
        'fields': {'duration': 65000, 'mediaType': 2, 'callId': 'call-1'},
      });

      final summary = RongCallSummaryParser.tryParse(message);

      expect(summary, isNotNull);
      expect(summary!.isVideo, isTrue);
      expect(summary.text, '通话时长 01:05');
      expect(summary.conversationText, '[视频通话] 通话时长 01:05');
      expect(RongCallSummaryParser.stableMessageKey(message), 'call:call-1');
    });

    test('parses nested JSON summary payload', () {
      final message = RCIMIWNativeCustomMessage.fromJson({
        'messageType': RCIMIWMessageType.nativeCustom.index,
        'messageIdentifier': RongCallSummaryParser.objectName,
        'fields': {
          'content': jsonEncode({'hangupReason': 12, 'mediaType': 'audio'}),
        },
      });

      final summary = RongCallSummaryParser.tryParse(message);

      expect(summary, isNotNull);
      expect(summary!.isVideo, isFalse);
      expect(summary.text, '已拒绝');
      expect(summary.conversationText, '[语音通话] 已拒绝');
    });

    test('parses base64 unknown summary raw data', () {
      final rawData = base64Encode(
        utf8.encode(jsonEncode({'reason': 15, 'mediaType': 'video'})),
      );
      final message = RCIMIWUnknownMessage.fromJson({
        'messageType': RCIMIWMessageType.unknown.index,
        'objectName': RongCallSummaryParser.objectName,
        'rawData': rawData,
      });

      final summary = RongCallSummaryParser.tryParse(message);

      expect(summary, isNotNull);
      expect(summary!.isVideo, isTrue);
      expect(summary.text, '未接听');
    });
  });
}
