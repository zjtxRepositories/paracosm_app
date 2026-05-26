import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/core/models/custom_message_model.dart';
import 'package:paracosm/modules/im/listener/user_display_state_center.dart';
import 'package:paracosm/modules/im/message/custom_face_message.dart';
import 'package:paracosm/pages/chat/chat_detail_message.dart';
import 'package:paracosm/pages/chat/chat_detail_message_mapper.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

void main() {
  group('CustomMessageModel custom face', () {
    test('serializes and parses custom_face fields', () {
      final model = CustomMessageModel(
        type: CustomMessageType.customFace,
        fromUserId: 'u1',
        toUserId: 'u2',
        content: 'assets/images/chat/custom_face/4350/yz00@2x.png',
        facePackId: '4350',
        faceName: 'yz00@2x.png',
      );

      final parsed = CustomMessageModel.fromJson(model.toJson());

      expect(parsed.type, CustomMessageType.customFace);
      expect(parsed.content, 'assets/images/chat/custom_face/4350/yz00@2x.png');
      expect(parsed.facePackId, '4350');
      expect(parsed.faceName, 'yz00@2x.png');
    });

    test('creates custom face data from fields', () {
      final face = ChatCustomFace.fromFields({
        'type': 'custom_face',
        'fromUserId': 'u1',
        'toUserId': 'u2',
        'content': 'assets/images/chat/custom_face/4351/ys03@2x.png',
        'facePackId': '4351',
        'faceName': 'ys03@2x.png',
      });

      expect(face, isNotNull);
      expect(face!.packId, '4351');
      expect(face.name, 'ys03@2x.png');
      expect(face.assetPath, 'assets/images/chat/custom_face/4351/ys03@2x.png');
    });
  });

  group('ChatCustomFaceCatalog', () {
    test('builds stable packs without menu images in face grid', () {
      final packs = ChatCustomFaceCatalog.packs();

      expect(packs.map((pack) => pack.id), ['4350', '4351', '4352']);
      expect(packs[0].faces.first.name, 'yz00@2x.png');
      expect(packs[0].faces.last.name, 'yz17@2x.png');
      expect(packs[1].faces.length, 16);
      expect(packs[2].faces.length, 17);
      expect(
        packs.expand((pack) => pack.faces).map((face) => face.name),
        isNot(contains('menu@2x.png')),
      );
    });
  });

  group('ChatDetailMessageMapper custom face behavior', () {
    test('maps custom face without chat bubble', () async {
      UserDisplayStateCenter().updateUserProfile(
        RCIMIWUserProfile.create(userId: 'sender-1'),
      );
      final message = RCIMIWCustomMessage.fromJson({
        'messageId': 1001,
        'messageType': RCIMIWMessageType.custom.index,
        'identifier': CustomFaceMessage.messageIdentifier,
        'conversationType': RCIMIWConversationType.private.index,
        'senderUserId': 'sender-1',
        'fields': {
          'type': 'custom_face',
          'fromUserId': 'sender-1',
          'toUserId': 'u2',
          'content': 'assets/images/chat/custom_face/4350/yz00@2x.png',
          'facePackId': '4350',
          'faceName': 'yz00@2x.png',
        },
      });

      final detail = await ChatDetailMessageMapper.mapMessage(message);

      expect(detail.kind, ChatDetailMessageKind.customFace);
      expect(detail.showBubble, false);
      expect(
        detail.imagePath,
        'assets/images/chat/custom_face/4350/yz00@2x.png',
      );
    });

    test(
      'uses custom face summary for quote and read receipt support',
      () async {
        final message = RCIMIWCustomMessage.fromJson({
          'messageType': RCIMIWMessageType.custom.index,
          'identifier': CustomFaceMessage.messageIdentifier,
          'conversationType': RCIMIWConversationType.private.index,
          'fields': {
            'type': 'custom_face',
            'fromUserId': 'u1',
            'toUserId': 'u2',
            'content': 'assets/images/chat/custom_face/4350/yz00@2x.png',
            'facePackId': '4350',
            'faceName': 'yz00@2x.png',
          },
        });

        expect(
          await ChatDetailMessageMapper.quoteSummaryForMessage(message),
          'chat_detail_custom_face',
        );
        expect(
          ChatDetailMessageMapper.supportsReadReceiptMessage(message),
          true,
        );
      },
    );
  });

  group('ChatEmojiInputEditor', () {
    test('inserts emoji at cursor', () {
      final controller = TextEditingController(text: 'ab');
      controller.selection = const TextSelection.collapsed(offset: 1);

      ChatEmojiInputEditor.insert(controller, '😀');

      expect(controller.text, 'a😀b');
      expect(controller.selection.baseOffset, 'a😀'.length);
    });

    test('replaces selected text when inserting emoji', () {
      final controller = TextEditingController(text: 'hello');
      controller.selection = const TextSelection(
        baseOffset: 1,
        extentOffset: 4,
      );

      ChatEmojiInputEditor.insert(controller, '👍');

      expect(controller.text, 'h👍o');
    });

    test('deletes a surrogate pair emoji as one character', () {
      final controller = TextEditingController(text: 'a😀b');
      controller.selection = TextSelection.collapsed(offset: 'a😀'.length);

      ChatEmojiInputEditor.deletePreviousCharacter(controller);

      expect(controller.text, 'ab');
      expect(controller.selection.baseOffset, 1);
    });

    test('deletes a joined emoji sequence as one character', () {
      final emoji = '👨‍👩‍👧';
      final controller = TextEditingController(text: 'a${emoji}b');
      controller.selection = TextSelection.collapsed(offset: 'a$emoji'.length);

      ChatEmojiInputEditor.deletePreviousCharacter(controller);

      expect(controller.text, 'ab');
      expect(controller.selection.baseOffset, 1);
    });
  });
}
