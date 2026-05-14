import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/models/custom_message_model.dart';
import '../../manager/im_engine_manager.dart';

abstract class ImMessage {
  RCIMIWMessageType get type;

  Future<RCIMIWMessage?> toRCMessage();
}

class CustomMessage extends ImMessage {
  final String targetId;
  final CustomMessageType customMessageType;
  RCIMIWConversationType conversationType;
  String? content;
  CustomMessage({
    required this.targetId,
    required this.customMessageType,
    this.conversationType = RCIMIWConversationType.private,
    this.content,
  });

  @override
  RCIMIWMessageType get type => RCIMIWMessageType.custom;

  @override
  Future<RCIMIWMessage?> toRCMessage() async {
    final myId = IMEngineManager().currentUserId ?? '';
    String messageID = const Uuid().v4().replaceAll("-", "");
    final model = CustomMessageModel(
      type: customMessageType,
      fromUserId: myId,
      toUserId: targetId,
      content: content,
    );
    final msg = await IMEngineManager().engine?.createCustomMessage(
      conversationType,
      targetId,
      null,
      RCIMIWCustomMessagePolicy.normal,
      messageID,
      model.toJson(),
    );
    msg?.senderUserId = IMEngineManager().currentUserId;
    msg?.sentTime = DateTime.now().millisecondsSinceEpoch;
    return msg;
  }
}

class TextMessage extends ImMessage {
  final RCIMIWConversationType conversationType;
  final String targetId;
  final String content;
  TextMessage({
    required this.conversationType,
    required this.targetId,
    required this.content,
  });

  @override
  RCIMIWMessageType get type => RCIMIWMessageType.text;

  @override
  Future<RCIMIWMessage?> toRCMessage() async {
    final textMsg = await IMEngineManager().engine?.createTextMessage(
      conversationType,
      targetId,
      null,
      content,
    );
    textMsg?.senderUserId = IMEngineManager().currentUserId;
    textMsg?.sentTime = DateTime.now().millisecondsSinceEpoch;
    return textMsg;
  }
}

class ReferenceMessage extends ImMessage {
  final RCIMIWConversationType conversationType;
  final String targetId;
  final String? channelId;
  final RCIMIWMessage referenceMessage;
  final String content;

  ReferenceMessage({
    required this.conversationType,
    required this.targetId,
    required this.referenceMessage,
    required this.content,
    this.channelId,
  });

  @override
  RCIMIWMessageType get type => RCIMIWMessageType.reference;

  @override
  Future<RCIMIWMessage?> toRCMessage() async {
    final referenceMsg = await IMEngineManager().engine?.createReferenceMessage(
      conversationType,
      targetId,
      channelId,
      referenceMessage,
      content,
    );
    referenceMsg?.senderUserId = IMEngineManager().currentUserId;
    referenceMsg?.sentTime = DateTime.now().millisecondsSinceEpoch;
    return referenceMsg;
  }
}

class ImageMessage extends ImMessage {
  final RCIMIWConversationType conversationType;
  final String targetId;
  final String path;
  ImageMessage({
    required this.conversationType,
    required this.targetId,
    required this.path,
  });

  @override
  RCIMIWMessageType get type => RCIMIWMessageType.image;

  @override
  Future<RCIMIWMessage?> toRCMessage() async {
    final imageMsg = await IMEngineManager().engine?.createImageMessage(
      conversationType,
      targetId,
      null,
      path,
    );
    imageMsg?.senderUserId = IMEngineManager().currentUserId;
    imageMsg?.sentTime = DateTime.now().millisecondsSinceEpoch;
    return imageMsg;
  }
}

class VideoMessage extends ImMessage {
  final RCIMIWConversationType conversationType;
  final String targetId;
  final String path;
  final int duration;
  String thumbnailBase64String;
  VideoMessage({
    required this.conversationType,
    required this.targetId,
    required this.path,
    required this.duration,
    required this.thumbnailBase64String,
  });

  @override
  RCIMIWMessageType get type => RCIMIWMessageType.sight;

  @override
  Future<RCIMIWMessage?> toRCMessage() async {
    final videoMsg = await IMEngineManager().engine?.createSightMessage(
      conversationType,
      targetId,
      null,
      path,
      duration,
    );
    videoMsg?.thumbnailBase64String = thumbnailBase64String;
    videoMsg?.senderUserId = IMEngineManager().currentUserId;
    videoMsg?.sentTime = DateTime.now().millisecondsSinceEpoch;
    return videoMsg;
  }
}

class FileMessage extends ImMessage {
  final RCIMIWConversationType conversationType;
  final String targetId;
  final String path;
  final int size;
  final String name;
  FileMessage({
    required this.conversationType,
    required this.targetId,
    required this.path,
    required this.size,
    required this.name,
  });

  @override
  RCIMIWMessageType get type => RCIMIWMessageType.file;

  @override
  Future<RCIMIWMessage?> toRCMessage() async {
    final videoMsg = await IMEngineManager().engine?.createFileMessage(
      conversationType,
      targetId,
      null,
      path,
    );
    videoMsg?.senderUserId = IMEngineManager().currentUserId;
    videoMsg?.sentTime = DateTime.now().millisecondsSinceEpoch;
    return videoMsg;
  }
}

class VoiceMessage extends ImMessage {
  final RCIMIWConversationType conversationType;
  final String targetId;
  final String path;
  final int duration;

  VoiceMessage({
    required this.conversationType,
    required this.targetId,
    required this.path,
    required this.duration,
  });

  @override
  RCIMIWMessageType get type => RCIMIWMessageType.voice;

  @override
  Future<RCIMIWMessage?> toRCMessage() async {
    final videoMsg = await IMEngineManager().engine?.createVoiceMessage(
      conversationType,
      targetId,
      null,
      path,
      duration,
    );
    videoMsg?.senderUserId = IMEngineManager().currentUserId;
    videoMsg?.sentTime = DateTime.now().millisecondsSinceEpoch;
    return videoMsg;
  }
}
