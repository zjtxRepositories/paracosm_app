import 'package:flutter/widgets.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../../core/models/custom_message_model.dart';
import '../manager/im_engine_manager.dart';
import 'base/im_message.dart';

class ChatCustomFace {
  const ChatCustomFace({
    required this.packId,
    required this.name,
    required this.assetPath,
  });

  final String packId;
  final String name;
  final String assetPath;

  Map<String, dynamic> toFields({
    required String fromUserId,
    required String toUserId,
  }) {
    return CustomMessageModel(
      type: CustomMessageType.customFace,
      fromUserId: fromUserId,
      toUserId: toUserId,
      content: assetPath,
      facePackId: packId,
      faceName: name,
    ).toJson();
  }

  static ChatCustomFace? fromFields(Map? fields) {
    if (fields == null) return null;

    final model = CustomMessageModel.fromJson(
      fields.map((key, value) => MapEntry(key.toString(), value)),
    );
    if (model.type != CustomMessageType.customFace) {
      return null;
    }

    final assetPath = model.content?.trim();
    final packId = model.facePackId?.trim();
    final name = model.faceName?.trim();
    if (assetPath == null ||
        assetPath.isEmpty ||
        packId == null ||
        packId.isEmpty ||
        name == null ||
        name.isEmpty) {
      return null;
    }

    return ChatCustomFace(packId: packId, name: name, assetPath: assetPath);
  }

  static ChatCustomFace? fromMessage(RCIMIWMessage message) {
    if (message is! RCIMIWCustomMessage) return null;
    return fromFields(message.fields);
  }
}

class ChatCustomFacePack {
  const ChatCustomFacePack({
    required this.id,
    required this.menuAssetPath,
    required this.faces,
  });

  final String id;
  final String menuAssetPath;
  final List<ChatCustomFace> faces;
}

class ChatCustomFaceCatalog {
  ChatCustomFaceCatalog._();

  static const List<String> packIds = ['4350', '4351', '4352'];

  static const Map<String, String> _prefixByPackId = {
    '4350': 'yz',
    '4351': 'ys',
    '4352': 'gcs',
  };

  static const Map<String, int> _countByPackId = {
    '4350': 18,
    '4351': 16,
    '4352': 17,
  };

  static List<ChatCustomFacePack> packs() {
    return packIds.map(_pack).toList(growable: false);
  }

  static ChatCustomFacePack _pack(String packId) {
    final prefix = _prefixByPackId[packId]!;
    final count = _countByPackId[packId]!;
    return ChatCustomFacePack(
      id: packId,
      menuAssetPath: 'assets/images/chat/custom_face/$packId/menu@2x.png',
      faces: List<ChatCustomFace>.generate(count, (index) {
        final name = '$prefix${index.toString().padLeft(2, '0')}@2x.png';
        return ChatCustomFace(
          packId: packId,
          name: name,
          assetPath: 'assets/images/chat/custom_face/$packId/$name',
        );
      }, growable: false),
    );
  }
}

class CustomFaceMessage extends ImMessage {
  CustomFaceMessage({
    required this.conversationType,
    required this.targetId,
    required this.face,
    this.channelId,
    super.destructDuration,
  });

  static const messageIdentifier = 'PARA:CustomFace';

  final RCIMIWConversationType conversationType;
  final String targetId;
  final String? channelId;
  final ChatCustomFace face;

  @override
  RCIMIWMessageType get type => RCIMIWMessageType.custom;

  @override
  Future<RCIMIWMessage?> toRCMessage() async {
    final currentUserId = IMEngineManager().currentUserId ?? '';
    final msg = await IMEngineManager().engine?.createCustomMessage(
      conversationType,
      targetId,
      channelId,
      RCIMIWCustomMessagePolicy.normal,
      messageIdentifier,
      face.toFields(fromUserId: currentUserId, toUserId: targetId),
    );

    msg?.senderUserId = currentUserId;
    msg?.sentTime = DateTime.now().millisecondsSinceEpoch;
    applyMessageOptions(msg);
    return msg;
  }
}

class ChatEmojiInputEditor {
  ChatEmojiInputEditor._();

  static void insert(TextEditingController controller, String value) {
    final text = controller.text;
    final selection = controller.selection;
    final normalized = _normalizedRange(selection, text.length);
    final nextText = text.replaceRange(normalized.start, normalized.end, value);
    final nextOffset = normalized.start + value.length;

    controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextOffset),
    );
  }

  static void deletePreviousCharacter(TextEditingController controller) {
    final text = controller.text;
    if (text.isEmpty) return;

    final selection = controller.selection;
    final normalized = _normalizedRange(selection, text.length);
    if (!normalized.isCollapsed) {
      final nextText = text.replaceRange(normalized.start, normalized.end, '');
      controller.value = TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(offset: normalized.start),
      );
      return;
    }

    if (normalized.start <= 0) return;

    final deleteStart = _previousGraphemeStart(text, normalized.start);
    final nextText = text.replaceRange(deleteStart, normalized.start, '');
    controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: deleteStart),
    );
  }

  static TextRange _normalizedRange(TextSelection selection, int textLength) {
    if (!selection.isValid) {
      return TextRange(start: textLength, end: textLength);
    }

    final start = selection.start.clamp(0, textLength).toInt();
    final end = selection.end.clamp(0, textLength).toInt();
    return TextRange(
      start: start <= end ? start : end,
      end: start <= end ? end : start,
    );
  }

  static int _previousGraphemeStart(String text, int cursor) {
    var index = cursor - 1;
    while (index > 0 && _isCombiningCodeUnit(text.codeUnitAt(index))) {
      index--;
    }
    while (index > 0 && _isLowSurrogate(text.codeUnitAt(index))) {
      index--;
    }

    // Delete common joined emoji sequences as one visible character.
    while (index >= 2 && text.codeUnitAt(index - 1) == 0x200D) {
      index -= 2;
      while (index > 0 && _isLowSurrogate(text.codeUnitAt(index))) {
        index--;
      }
      while (index > 0 && _isCombiningCodeUnit(text.codeUnitAt(index))) {
        index--;
      }
    }

    return index;
  }

  static bool _isCombiningCodeUnit(int codeUnit) {
    return (codeUnit >= 0x0300 && codeUnit <= 0x036F) ||
        (codeUnit >= 0xFE00 && codeUnit <= 0xFE0F);
  }

  static bool _isLowSurrogate(int codeUnit) {
    return codeUnit >= 0xDC00 && codeUnit <= 0xDFFF;
  }
}
