import 'dart:async';

import 'package:paracosm/modules/im/manager/im_engine_manager.dart';
import 'package:paracosm/modules/im/manager/im_send_manager.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

class RedPacketStatus {
  const RedPacketStatus({
    required this.targetId,
    required this.packetNo,
    required this.receiver,
    required this.display,
    required this.symbol,
    required this.sentAt,
    this.amount = '',
  });

  final String targetId;
  final String packetNo;
  final String receiver;
  final String display;
  final String symbol;
  final String amount;
  final int sentAt;
}

class RedPacketStatusMessage {
  RedPacketStatusMessage._();

  static const String objectName = 'PC:RedPacketStatus';

  static RedPacketStatus? tryParse(RCIMIWMessage message) {
    if (message is! RCIMIWNativeCustomMessage ||
        message.messageIdentifier != objectName) {
      return null;
    }

    final fields = message.fields;
    if (fields == null) return null;

    final data = Map<String, dynamic>.from(fields);
    final packetNo = (data['packetNo'] ?? data['packet_no'] ?? '')
        .toString()
        .trim();
    if (packetNo.isEmpty) return null;

    final targetId = (data['targetId'] ?? message.targetId ?? '')
        .toString()
        .trim();
    if (targetId.isEmpty) return null;

    return RedPacketStatus(
      targetId: targetId,
      packetNo: packetNo,
      receiver: (data['receiver'] ?? message.senderUserId ?? '')
          .toString()
          .trim()
          .toLowerCase(),
      display: (data['display'] ?? '').toString().trim(),
      amount: (data['amount'] ?? '').toString().trim(),
      symbol: (data['symbol'] ?? '').toString().trim(),
      sentAt:
          _readInt(data['sentAt']) ??
          message.sentTime ??
          message.receivedTime ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<void> send({
    required RCIMIWConversationType conversationType,
    required String targetId,
    required String packetNo,
    required String display,
    required String symbol,
    String amount = '',
    String? channelId,
  }) async {
    try {
      final engine = IMEngineManager().engine;
      final currentUserId = IMEngineManager().currentUserId ?? '';
      if (engine == null ||
          targetId.trim().isEmpty ||
          packetNo.trim().isEmpty) {
        return;
      }

      final message = await engine.createNativeCustomMessage(
        conversationType,
        targetId,
        channelId,
        objectName,
        {
          'targetId': targetId,
          'packetNo': packetNo,
          'receiver': currentUserId,
          'display': display,
          'amount': amount,
          'symbol': symbol,
          'sentAt': DateTime.now().millisecondsSinceEpoch,
        },
      );
      if (message == null) return;
      message.senderUserId = currentUserId;

      unawaited(
        ImSendManager.instance
            .sendMessage(message, pushSavedMessage: false)
            .catchError((_) => false),
      );
    } catch (_) {}
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class RedPacketStatusCenter {
  RedPacketStatusCenter._();

  static final RedPacketStatusCenter _instance = RedPacketStatusCenter._();

  factory RedPacketStatusCenter() => _instance;

  final StreamController<RedPacketStatus> _controller =
      StreamController<RedPacketStatus>.broadcast();

  Stream<RedPacketStatus> get stream => _controller.stream;

  bool notifyIfRedPacketStatus(RCIMIWMessage message) {
    final status = RedPacketStatusMessage.tryParse(message);
    if (status == null) return false;
    _controller.add(status);
    return true;
  }
}
