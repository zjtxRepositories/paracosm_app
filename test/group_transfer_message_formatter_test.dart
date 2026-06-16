import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/core/models/conversation_model.dart';
import 'package:paracosm/core/models/message_model.dart';
import 'package:paracosm/modules/im/listener/group_state_center.dart';
import 'package:paracosm/modules/im/listener/user_display_state_center.dart';
import 'package:paracosm/modules/im/manager/im_engine_manager.dart';
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

  group('group transfer message formatter', () {
    test('formats transfer message from my perspective', () async {
      UserDisplayStateCenter().updateFriend(
        RCIMIWFriendInfo.create(
          userId: 'target-user',
          remark: '目标备注',
          name: '目标昵称',
        ),
      );

      final message = _transferMessage(
        fromUserId: 'current-user',
        targetUserId: 'target-user',
      );

      final text = await MessageModel(item: message).formatCustomContent();

      expect(text, '你将群主转让给目标备注');
    });

    test('uses cached remark when displayed target id is shortened', () async {
      UserDisplayStateCenter().updateFriend(
        RCIMIWFriendInfo.create(
          userId: '0xc51c59fc18cfada23f932fa1a286ecaf5284c3f3',
          remark: '目标备注',
          name: '目标昵称',
        ),
      );

      final message = _transferMessage(
        fromUserId: 'current-user',
        targetUserId: '284c3f3]',
      );

      final text = await MessageModel(item: message).formatCustomContent();

      expect(text, '你将群主转让给目标备注');
    });

    test('formats transfer message from target user perspective', () async {
      UserDisplayStateCenter().updateFriend(
        RCIMIWFriendInfo.create(
          userId: 'operator-user',
          remark: '转让人备注',
          name: '转让人昵称',
        ),
      );

      final message = _transferMessage(
        fromUserId: 'operator-user',
        targetUserId: 'current-user',
      );

      final text = await MessageModel(item: message).formatCustomContent();

      expect(text, '转让人备注将群主转让给你');
    });

    test('matches current user id case insensitively', () async {
      await IMEngineManager().disconnect();
      await IMEngineManager().connect('', '0xABCDEF1234567890');
      UserDisplayStateCenter().updateFriend(
        RCIMIWFriendInfo.create(
          userId: 'operator-user',
          remark: '转让人备注',
        ),
      );

      final message = _transferMessage(
        fromUserId: 'operator-user',
        targetUserId: '0xabcdef1234567890',
      );

      final text = await MessageModel(item: message).formatCustomContent();

      expect(text, '转让人备注将群主转让给你');
    });

    test('matches current user id when message target has suffix bracket', () async {
      await IMEngineManager().disconnect();
      await IMEngineManager().connect('', '0xa4f3eab5103ff2ff9d611268763bc1a37fd16dcf');

      final message = _transferMessage(
        fromUserId: '0xc51c59fc18cfada23f932fa1a286ecaf5284c3f3',
        targetUserId: '0xa4f3eab5103ff2ff9d611268763bc1a37fd16dcf]',
      );

      final text = await MessageModel(item: message).formatCustomContent();

      expect(text, '5284c3f3将群主转让给你');
    });

    test('uses third-person text when current user is not transfer target', () async {
      await IMEngineManager().disconnect();
      await IMEngineManager().connect('', '0x00000000000000000000000000000000deadbeef');

      final message = _transferMessage(
        fromUserId: '0xc51c59fc18cfada23f932fa1a286ecaf5284c3f3',
        targetUserId: '0xa4f3eab5103ff2ff9d611268763bc1a37fd16dcf]',
      );

      final text = await MessageModel(item: message).formatCustomContent();

      expect(text, '5284c3f3将群主转让给fd16dcf]');
    });

    test('formats transfer message for other group members', () async {
      UserDisplayStateCenter().updateFriend(
        RCIMIWFriendInfo.create(
          userId: 'operator-user',
          remark: '转让人备注',
          name: '转让人昵称',
        ),
      );
      UserDisplayStateCenter().updateUserProfile(
        RCIMIWUserProfile.create(userId: 'target-user', name: '被转让昵称'),
      );
      GroupStateCenter().updateGroupInfo(
        RCIMIWGroupInfo.create(groupId: 'group-1', groupName: '群聊'),
      );

      final message = _transferMessage(
        fromUserId: 'operator-user',
        targetUserId: 'target-user',
      );

      final model = ConversationModel(
        info: RCIMIWConversation.create(
          conversationType: RCIMIWConversationType.group,
          targetId: 'group-1',
          lastMessage: message,
        ),
      );

      await ConversationResolver().resolve(model);

      expect(model.subtitle, '转让人备注将群主转让给被转让昵称');
    });

    test('keeps message detail and conversation summary consistent', () async {
      UserDisplayStateCenter().updateFriend(
        RCIMIWFriendInfo.create(userId: 'operator-user', remark: '转让人备注'),
      );
      UserDisplayStateCenter().updateFriend(
        RCIMIWFriendInfo.create(userId: 'target-user', remark: '目标备注'),
      );
      GroupStateCenter().updateGroupInfo(
        RCIMIWGroupInfo.create(groupId: 'group-1', groupName: '群聊'),
      );

      final message = _transferMessage(
        fromUserId: 'operator-user',
        targetUserId: 'target-user',
      );
      final detailText = await MessageModel(item: message).formatCustomContent();
      final conversation = ConversationModel(
        info: RCIMIWConversation.create(
          conversationType: RCIMIWConversationType.group,
          targetId: 'group-1',
          lastMessage: message,
        ),
      );

      await ConversationResolver().resolve(conversation);

      expect(conversation.subtitle, detailText);
      expect(detailText, '转让人备注将群主转让给目标备注');
    });

    test('falls back to short id when user display info is missing', () async {
      final message = _transferMessage(
        fromUserId: 'operator-user-1234567890',
        targetUserId: 'target-user-1234567890',
      );

      final text = await MessageModel(item: message).formatCustomContent();

      expect(text, '34567890将群主转让给34567890');
    });
  });
}

RCIMIWCustomMessage _transferMessage({
  required String fromUserId,
  required String targetUserId,
}) {
  return RCIMIWCustomMessage.fromJson({
    'messageId': 1001,
    'messageType': RCIMIWMessageType.custom.index,
    'conversationType': RCIMIWConversationType.group.index,
    'senderUserId': fromUserId,
    'fields': {
      'type': 'transfer',
      'fromUserId': fromUserId,
      'toUserId': 'group-1',
      'userIds': [targetUserId],
    },
  });
}
