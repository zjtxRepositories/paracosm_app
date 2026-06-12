import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/core/models/conversation_model.dart';
import 'package:paracosm/modules/im/listener/group_state_center.dart';
import 'package:paracosm/modules/im/listener/user_display_state_center.dart';
import 'package:paracosm/modules/im/manager/im_engine_manager.dart';
import 'package:paracosm/pages/chat/chat_detail_message.dart';
import 'package:paracosm/pages/chat/chat_detail_message_mapper.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    UserDisplayStateCenter().resetForTesting();
    GroupStateCenter().clear();
    await IMEngineManager().connect('', 'current-user');
    await AppLocalizations(const Locale('zh')).load();
  });

  tearDown(() async {
    UserDisplayStateCenter().resetForTesting();
    GroupStateCenter().clear();
    await IMEngineManager().disconnect();
  });

  group('recall message display text', () {
    test('uses self recall text for current user', () async {
      final detail = await ChatDetailMessageMapper.mapMessage(
        _recallMessage(originalSenderUserId: 'current-user'),
      );

      expect(detail.kind, ChatDetailMessageKind.withdrawnNotice);
      expect(detail.text, '你撤回了一条消息');
    });

    test(
      'uses other recall text for private message from other user',
      () async {
        UserDisplayStateCenter().updateFriend(
          RCIMIWFriendInfo.create(userId: 'sender-1', remark: '备注名'),
        );

        final detail = await ChatDetailMessageMapper.mapMessage(
          _recallMessage(originalSenderUserId: 'sender-1'),
        );

        expect(detail.text, '对方撤回了一条消息');
      },
    );

    test(
      'uses friend remark before profile name for group other user',
      () async {
        UserDisplayStateCenter().updateFriend(
          RCIMIWFriendInfo.create(
            userId: 'sender-1',
            name: 'Friend Name',
            remark: '备注名',
          ),
        );
        UserDisplayStateCenter().updateUserProfile(
          RCIMIWUserProfile.create(userId: 'sender-1', name: 'Profile Name'),
        );

        final detail = await ChatDetailMessageMapper.mapMessage(
          _recallMessage(
            conversationType: RCIMIWConversationType.group,
            originalSenderUserId: 'sender-1',
          ),
        );

        expect(detail.text, '备注名撤回了一条消息');
      },
    );

    test('uses profile name when group remark is missing', () async {
      UserDisplayStateCenter().updateUserProfile(
        RCIMIWUserProfile.create(userId: 'sender-2', name: 'Profile Name'),
      );

      final detail = await ChatDetailMessageMapper.mapMessage(
        _recallMessage(
          conversationType: RCIMIWConversationType.group,
          originalSenderUserId: 'sender-2',
        ),
      );

      expect(detail.text, 'Profile Name撤回了一条消息');
    });

    test(
      'falls back to short user id when group user info is missing',
      () async {
        final detail = await ChatDetailMessageMapper.mapMessage(
          _recallMessage(
            conversationType: RCIMIWConversationType.group,
            originalSenderUserId: 'very-long-user-id-1234567890',
          ),
        );

        expect(detail.text, '34567890撤回了一条消息');
      },
    );

    test('formats private conversation last recall message summary', () async {
      UserDisplayStateCenter().updateUserProfile(
        RCIMIWUserProfile.create(userId: 'target-user', name: 'Target User'),
      );
      UserDisplayStateCenter().updateFriend(
        RCIMIWFriendInfo.create(userId: 'sender-3', remark: '会话备注'),
      );

      final model = ConversationModel(
        info: RCIMIWConversation.create(
          conversationType: RCIMIWConversationType.private,
          targetId: 'target-user',
          lastMessage: _recallMessage(originalSenderUserId: 'sender-3'),
        ),
      );

      await ConversationResolver().resolve(model);

      expect(model.subtitle, '对方撤回了一条消息');
    });

    test('formats group conversation last recall message summary', () async {
      UserDisplayStateCenter().updateUserProfile(
        RCIMIWUserProfile.create(userId: 'target-user', name: 'Target User'),
      );
      UserDisplayStateCenter().updateFriend(
        RCIMIWFriendInfo.create(userId: 'sender-3', remark: '会话备注'),
      );
      GroupStateCenter().updateGroupInfo(
        RCIMIWGroupInfo.create(groupId: 'group-1', groupName: 'Group 1'),
      );

      final model = ConversationModel(
        info: RCIMIWConversation.create(
          conversationType: RCIMIWConversationType.group,
          targetId: 'group-1',
          lastMessage: _recallMessage(
            targetId: 'group-1',
            conversationType: RCIMIWConversationType.group,
            originalSenderUserId: 'sender-3',
          ),
        ),
      );

      await ConversationResolver().resolve(model);

      expect(model.subtitle, '会话备注撤回了一条消息');
    });
  });
}

RCIMIWRecallNotificationMessage _recallMessage({
  String targetId = 'target-user',
  RCIMIWConversationType conversationType = RCIMIWConversationType.private,
  required String originalSenderUserId,
}) {
  return RCIMIWRecallNotificationMessage.fromJson({
    'messageId': 2,
    'messageType': RCIMIWMessageType.recall.index,
    'conversationType': conversationType.index,
    'targetId': targetId,
    'senderUserId': originalSenderUserId,
    'sentTime': 2000,
    'originalMessage': {
      'messageId': 1,
      'messageType': RCIMIWMessageType.text.index,
      'conversationType': conversationType.index,
      'targetId': targetId,
      'senderUserId': originalSenderUserId,
      'sentTime': 1000,
      'text': 'hello',
    },
  });
}
