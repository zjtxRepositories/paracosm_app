import 'dart:io';

import 'package:hive/hive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/core/models/custom_message_model.dart';
import 'package:paracosm/core/network/api/red_packet_api.dart';
import 'package:paracosm/modules/im/listener/user_display_state_center.dart';
import 'package:paracosm/modules/im/manager/im_engine_manager.dart';
import 'package:paracosm/modules/im/message/base/im_message.dart';
import 'package:paracosm/modules/im/message/red_packet_status_message.dart';
import 'package:paracosm/modules/im/store/red_packet_claim_store.dart';
import 'package:paracosm/pages/chat/chat_detail_message.dart';
import 'package:paracosm/pages/chat/chat_detail_message_mapper.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('red_packet_claim_test');
    Hive.init(tempDir.path);
    await Hive.openBox(RedPacketClaimStore.boxName);
  });

  tearDown(() {
    IMEngineManager().setCurrentUserIdForTesting(null);
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('CustomMessageModel red packet', () {
    test('serializes and parses red_packet fields', () {
      final model = CustomMessageModel(
        type: CustomMessageType.redPacket,
        fromUserId: 'sender',
        toUserId: 'target',
        content: 'Lucky day',
        redPacketId: 'packet-1',
        redPacketAmount: '8.88',
        redPacketTokenSymbol: 'PCOSM',
        redPacketChainId: '1',
        redPacketType: 'lucky',
        redPacketClaimed: true,
        userIds: const ['recipient-1'],
      );

      final parsed = CustomMessageModel.fromJson(model.toJson());

      expect(parsed.type, CustomMessageType.redPacket);
      expect(parsed.content, 'Lucky day');
      expect(parsed.redPacketId, 'packet-1');
      expect(parsed.redPacketAmount, '8.88');
      expect(parsed.redPacketTokenSymbol, 'PCOSM');
      expect(parsed.redPacketChainId, '1');
      expect(parsed.redPacketType, 'lucky');
      expect(parsed.redPacketClaimed, true);
      expect(parsed.userIds, ['recipient-1']);
    });
  });

  group('RedPacketData', () {
    test('creates red packet data from fields', () {
      final redPacket = RedPacketData.fromFields({
        'type': 'red_packet',
        'fromUserId': 'sender',
        'toUserId': 'target',
        'content': 'Best wishes',
        'redPacketId': 'packet-2',
        'redPacketAmount': '6.66',
        'redPacketTokenSymbol': 'ETH',
        'redPacketType': 'normal',
        'redPacketClaimed': 1,
        'userIds': ['recipient-2'],
      });

      expect(redPacket, isNotNull);
      expect(redPacket!.redPacketId, 'packet-2');
      expect(redPacket.greeting, 'Best wishes');
      expect(redPacket.amount, '6.66');
      expect(redPacket.tokenSymbol, 'ETH');
      expect(redPacket.packetType, 'normal');
      expect(redPacket.recipientUserId, 'recipient-2');
      expect(redPacket.isClaimed, true);
    });

    test('creates red packet data from server pushed fields', () {
      final redPacket = RedPacketData.fromFields({
        'packetNo': 'rp_abc',
        'sender': 'sender',
        'assetId': 'bsc-usdt',
        'symbol': 'USDT',
        'mode': 'lucky',
        'count': 10,
        'greeting': '恭喜发财',
      });

      expect(redPacket, isNotNull);
      expect(redPacket!.redPacketId, 'rp_abc');
      expect(redPacket.greeting, '恭喜发财');
      expect(redPacket.tokenSymbol, 'USDT');
      expect(redPacket.packetType, 'lucky');
      expect(redPacket.assetId, 'bsc-usdt');
      expect(redPacket.count, 10);
    });

    test('serializes exclusive recipient user id', () {
      final fields = const RedPacketData(
        redPacketId: 'packet-exclusive',
        recipientUserId: 'recipient-3',
      ).toFields(fromUserId: 'sender', toUserId: 'group-1');

      expect(fields['userIds'], ['recipient-3']);
    });

    test(
      'restores claimed state from local cache when fields are stale',
      () async {
        await RedPacketClaimStore.markClaimed('packet-5', userId: 'user-a');

        final redPacket = RedPacketData.fromFields({
          'type': 'red_packet',
          'fromUserId': 'sender',
          'toUserId': 'target',
          'redPacketId': 'packet-5',
          'redPacketClaimed': false,
        }, claimedUserId: 'user-a');

        expect(redPacket, isNotNull);
        expect(redPacket!.isClaimed, true);
      },
    );
  });

  group('ChatDetailMessageMapper red packet behavior', () {
    test('maps red_packet custom message to red bag card', () async {
      UserDisplayStateCenter().updateUserProfile(
        RCIMIWUserProfile.create(userId: 'sender-1'),
      );
      final message = RCIMIWCustomMessage.fromJson({
        'messageId': 3001,
        'messageType': RCIMIWMessageType.custom.index,
        'identifier': RedPacketMessage.messageIdentifier,
        'conversationType': RCIMIWConversationType.private.index,
        'senderUserId': 'sender-1',
        'fields': {
          'type': 'red_packet',
          'fromUserId': 'sender-1',
          'toUserId': 'target-1',
          'content': 'Lucky day',
          'redPacketId': 'packet-3',
          'redPacketAmount': '8.88',
          'redPacketTokenSymbol': 'PCOSM',
          'redPacketType': 'exclusive',
          'redPacketClaimed': false,
        },
      });

      final detail = await ChatDetailMessageMapper.mapMessage(message);

      expect(detail.kind, ChatDetailMessageKind.redBag);
      expect(detail.showBubble, false);
      expect(detail.text, 'Lucky day');
      expect(detail.redPacketAmount, '8.88');
      expect(detail.redPacketTokenSymbol, 'PCOSM');
      expect(detail.redPacketType, 'exclusive');
      expect(detail.isClaimed, false);
    });

    test(
      'maps server pushed red packet native message to red bag card',
      () async {
        UserDisplayStateCenter().updateUserProfile(
          RCIMIWUserProfile.create(userId: 'sender-server'),
        );
        final message = RCIMIWNativeCustomMessage.fromJson({
          'messageId': 3003,
          'messageType': RCIMIWMessageType.nativeCustom.index,
          'messageIdentifier': RedPacketMessage.serverMessageIdentifier,
          'conversationType': RCIMIWConversationType.group.index,
          'senderUserId': 'sender-server',
          'fields': {
            'packetNo': 'rp_server',
            'sender': 'sender-server',
            'assetId': 'bsc-usdt',
            'symbol': 'USDT',
            'display': '2',
            'mode': 'lucky',
            'count': 2,
            'greeting': '财源滚滚，万事如意',
          },
        });

        final detail = await ChatDetailMessageMapper.mapMessage(message);

        expect(detail.kind, ChatDetailMessageKind.redBag);
        expect(detail.showBubble, false);
        expect(detail.text, '财源滚滚，万事如意');
        expect(detail.redPacketAmount, '2');
        expect(detail.redPacketTokenSymbol, 'USDT');
        expect(detail.redPacketType, 'lucky');
      },
    );

    test(
      'restores server red packet claimed state for current IM user',
      () async {
        IMEngineManager().setCurrentUserIdForTesting('target-1');
        await RedPacketClaimStore.markClaimed(
          'rp_server_claimed',
          userId: 'target-1',
          claimedAt: 1_700_000_000_000,
        );
        final message = RCIMIWNativeCustomMessage.fromJson({
          'messageId': 3004,
          'messageType': RCIMIWMessageType.nativeCustom.index,
          'messageIdentifier': RedPacketMessage.serverMessageIdentifier,
          'conversationType': RCIMIWConversationType.group.index,
          'senderUserId': 'sender-server',
          'fields': {
            'packetNo': 'rp_server_claimed',
            'sender': 'sender-server',
            'toUserId': 'group-1',
            'assetId': 'bsc-usdt',
            'symbol': 'USDT',
            'display': '2',
            'mode': 'lucky',
            'count': 2,
          },
        });

        final detail = await ChatDetailMessageMapper.mapMessage(message);

        expect(detail.kind, ChatDetailMessageKind.redBag);
        expect(detail.isClaimed, true);
      },
    );

    test('parses red packet status notification message', () {
      final message = RCIMIWNativeCustomMessage.fromJson({
        'messageId': 3006,
        'messageType': RCIMIWMessageType.nativeCustom.index,
        'messageIdentifier': RedPacketStatusMessage.objectName,
        'conversationType': RCIMIWConversationType.group.index,
        'targetId': 'group-1',
        'senderUserId': 'target-1',
        'fields': {
          'targetId': 'group-1',
          'packetNo': 'rp_status',
          'receiver': 'target-1',
          'display': '0.1234',
          'amount': '123400000000000000',
          'symbol': 'USDT',
          'sentAt': 1_700_000_000_000,
        },
      });

      final status = RedPacketStatusMessage.tryParse(message);

      expect(status, isNotNull);
      expect(status!.packetNo, 'rp_status');
      expect(status.receiver, 'target-1');
      expect(status.display, '0.1234');
      expect(status.symbol, 'USDT');
    });

    test('adds a claim notice after claimed red packet messages', () async {
      IMEngineManager().setCurrentUserIdForTesting('target-1');
      UserDisplayStateCenter().updateUserProfile(
        RCIMIWUserProfile.create(userId: 'sender-2', name: 'Alice'),
      );
      await RedPacketClaimStore.markClaimed(
        'packet-6',
        userId: 'target-1',
        claimedAt: 1_700_000_000_000,
      );
      final message = RCIMIWCustomMessage.fromJson({
        'messageId': 3002,
        'messageType': RCIMIWMessageType.custom.index,
        'identifier': RedPacketMessage.messageIdentifier,
        'conversationType': RCIMIWConversationType.private.index,
        'senderUserId': 'sender-2',
        'fields': {
          'type': 'red_packet',
          'fromUserId': 'sender-2',
          'toUserId': 'target-1',
          'content': 'Lucky day',
          'redPacketId': 'packet-6',
          'redPacketClaimed': true,
        },
      });

      final details = await ChatDetailMessageMapper.mapMessages([message]);

      expect(details.length, 2);
      expect(details[0].kind, ChatDetailMessageKind.redBag);
      expect(details[0].isClaimed, true);
      expect(details[1].kind, ChatDetailMessageKind.redBagNotice);
      expect(details[1].noticeName, 'Alice');
      expect(details[1].sentTime, 1_700_000_000_000);
    });

    test(
      'uses red packet summary for quote and read receipt support',
      () async {
        final message = RCIMIWCustomMessage.fromJson({
          'messageType': RCIMIWMessageType.custom.index,
          'identifier': RedPacketMessage.messageIdentifier,
          'conversationType': RCIMIWConversationType.private.index,
          'fields': {
            'type': 'red_packet',
            'fromUserId': 'sender-1',
            'toUserId': 'target-1',
            'redPacketId': 'packet-4',
          },
        });

        expect(
          await ChatDetailMessageMapper.quoteSummaryForMessage(message),
          'chat_detail_red_packet',
        );
        expect(
          ChatDetailMessageMapper.supportsReadReceiptMessage(message),
          true,
        );
      },
    );
  });

  group('red packet amount formatting', () {
    test('converts decimal amount to smallest unit', () {
      expect(redPacketDecimalToUnits('1', 18), '1000000000000000000');
      expect(redPacketDecimalToUnits('0.01', 18), '10000000000000000');
      expect(redPacketDecimalToUnits('1.23', 6, multiplier: 2), '2460000');
    });
  });
}
