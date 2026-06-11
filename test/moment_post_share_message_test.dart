import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/core/models/custom_message_model.dart';
import 'package:paracosm/modules/im/listener/user_display_state_center.dart';
import 'package:paracosm/modules/im/message/moment_post_share_message.dart';
import 'package:paracosm/pages/chat/chat_detail_message.dart';
import 'package:paracosm/pages/chat/chat_detail_message_mapper.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

void main() {
  group('CustomMessageModel moment post', () {
    test('serializes and parses moment_post fields', () {
      final model = CustomMessageModel(
        type: CustomMessageType.momentPost,
        fromUserId: 'sender',
        toUserId: 'target',
        content: 'post summary',
        noteId: 'note-1',
        postContent: 'post summary',
        postCover: 'https://example.com/cover.jpg',
        authorId: 'author-1',
        authorName: 'Alice',
        authorAvatar: 'https://example.com/avatar.jpg',
        mediaType: 0,
      );

      final parsed = CustomMessageModel.fromJson(model.toJson());

      expect(parsed.type, CustomMessageType.momentPost);
      expect(parsed.noteId, 'note-1');
      expect(parsed.postContent, 'post summary');
      expect(parsed.postCover, 'https://example.com/cover.jpg');
      expect(parsed.authorId, 'author-1');
      expect(parsed.authorName, 'Alice');
      expect(parsed.authorAvatar, 'https://example.com/avatar.jpg');
      expect(parsed.mediaType, 0);
    });

    test('keeps old custom messages compatible', () {
      final parsed = CustomMessageModel.fromJson({
        'type': 'custom_face',
        'fromUserId': 'u1',
        'toUserId': 'u2',
        'content': 'asset.png',
      });

      expect(parsed.type, CustomMessageType.customFace);
      expect(parsed.noteId, isNull);
      expect(parsed.postContent, isNull);
    });
  });

  group('MomentPostShareData', () {
    test('truncates content summary to 80 chars', () {
      final summary = MomentPostShareData.summaryFromContent(
        '${List.filled(40, 'a').join()}\n${List.filled(60, 'b').join()}',
      );

      expect(summary.length, 83);
      expect(summary.endsWith('...'), true);
      expect(summary.contains('\n'), false);
    });
  });

  group('ChatDetailMessageMapper moment post behavior', () {
    test('maps moment_post custom message to moment post card', () async {
      UserDisplayStateCenter().updateUserProfile(
        RCIMIWUserProfile.create(userId: 'sender-1'),
      );
      final message = RCIMIWCustomMessage.fromJson({
        'messageId': 2001,
        'messageType': RCIMIWMessageType.custom.index,
        'identifier': MomentPostShareMessage.messageIdentifier,
        'conversationType': RCIMIWConversationType.private.index,
        'senderUserId': 'sender-1',
        'fields': {
          'type': 'moment_post',
          'fromUserId': 'sender-1',
          'toUserId': 'target-1',
          'content': 'shared post',
          'noteId': 'note-1',
          'postContent': 'shared post',
          'postCover': 'https://example.com/cover.jpg',
          'authorName': 'Alice',
          'authorAvatar': 'https://example.com/avatar.jpg',
        },
      });

      final detail = await ChatDetailMessageMapper.mapMessage(message);

      expect(detail.kind, ChatDetailMessageKind.momentPost);
      expect(detail.text, 'shared post');
      expect(detail.imagePath, 'https://example.com/cover.jpg');
      expect(detail.contactName, 'Alice');
    });

    test(
      'uses moment post summary for quote and read receipt support',
      () async {
        final message = RCIMIWCustomMessage.fromJson({
          'messageType': RCIMIWMessageType.custom.index,
          'identifier': MomentPostShareMessage.messageIdentifier,
          'conversationType': RCIMIWConversationType.private.index,
          'fields': {
            'type': 'moment_post',
            'fromUserId': 'sender-1',
            'toUserId': 'target-1',
            'noteId': 'note-1',
            'postContent': 'shared post',
          },
        });

        expect(
          await ChatDetailMessageMapper.quoteSummaryForMessage(message),
          'shared post',
        );
        expect(
          ChatDetailMessageMapper.supportsReadReceiptMessage(message),
          true,
        );
      },
    );
  });
}
