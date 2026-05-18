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

  /// 邀请进群时传递的用户 IDs
  final List<String>? userIds;

  RCIMIWConversationType conversationType;

  String? channelId;

  String? content;

  CustomMessage({
    required this.targetId,
    required this.customMessageType,
    this.userIds,
    this.conversationType = RCIMIWConversationType.private,
    this.channelId,
    this.content,
  });

  @override
  RCIMIWMessageType get type => RCIMIWMessageType.custom;

  @override
  Future<RCIMIWMessage?> toRCMessage() async {
    final myId = IMEngineManager().currentUserId ?? '';

    final messageID = const Uuid().v4().replaceAll("-", "");

    final model = CustomMessageModel(
      type: customMessageType,
      fromUserId: myId,
      toUserId: targetId,
      content: content,

      /// 新增
      userIds: userIds,
    );

    final msg = await IMEngineManager().engine?.createCustomMessage(
      conversationType,
      targetId,
      channelId,
      RCIMIWCustomMessagePolicy.normal,
      messageID,
      model.toJson(),
    );

    msg?.senderUserId = IMEngineManager().currentUserId;

    msg?.sentTime = DateTime.now().millisecondsSinceEpoch;

    return msg;
  }
}

class ForwardCustomMessage extends ImMessage {
  final RCIMIWConversationType conversationType;
  final String targetId;
  final String? channelId;
  final RCIMIWCustomMessagePolicy policy;
  final String messageIdentifier;
  final Map fields;

  ForwardCustomMessage({
    required this.conversationType,
    required this.targetId,
    required this.messageIdentifier,
    required this.fields,
    this.channelId,
    this.policy = RCIMIWCustomMessagePolicy.normal,
  });

  @override
  RCIMIWMessageType get type => RCIMIWMessageType.custom;

  @override
  Future<RCIMIWMessage?> toRCMessage() async {
    final msg = await IMEngineManager().engine?.createCustomMessage(
      conversationType,
      targetId,
      channelId,
      policy,
      messageIdentifier,
      fields,
    );
    msg?.senderUserId = IMEngineManager().currentUserId;
    msg?.sentTime = DateTime.now().millisecondsSinceEpoch;
    return msg;
  }
}

class TextMessage extends ImMessage {
  final RCIMIWConversationType conversationType;
  final String targetId;
  final String? channelId;
  final String content;
  TextMessage({
    required this.conversationType,
    required this.targetId,
    required this.content,
    this.channelId,
  });

  @override
  RCIMIWMessageType get type => RCIMIWMessageType.text;

  @override
  Future<RCIMIWMessage?> toRCMessage() async {
    final textMsg = await IMEngineManager().engine?.createTextMessage(
      conversationType,
      targetId,
      channelId,
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

class CombineForwardMessage extends ImMessage {
  final RCIMIWConversationType conversationType;
  final String targetId;
  final String? channelId;
  final RCIMIWConversationType originalConversationType;
  final List<String> summaryList;
  final List<String> nameList;
  final List<RCIMIWCombineMsgInfo> msgList;

  CombineForwardMessage({
    required this.conversationType,
    required this.targetId,
    required this.originalConversationType,
    required this.summaryList,
    required this.nameList,
    required this.msgList,
    this.channelId,
  });

  @override
  RCIMIWMessageType get type => RCIMIWMessageType.combineV2;

  @override
  Future<RCIMIWMessage?> toRCMessage() async {
    final combineMsg = await IMEngineManager().engine?.createCombineV2Message(
      conversationType,
      targetId,
      channelId,
      originalConversationType,
      summaryList,
      nameList,
      msgList,
    );
    combineMsg?.senderUserId = IMEngineManager().currentUserId;
    combineMsg?.sentTime = DateTime.now().millisecondsSinceEpoch;
    return combineMsg;
  }
}

class ImageMessage extends ImMessage {
  final RCIMIWConversationType conversationType;
  final String targetId;
  final String? channelId;
  final String path;
  ImageMessage({
    required this.conversationType,
    required this.targetId,
    required this.path,
    this.channelId,
  });

  @override
  RCIMIWMessageType get type => RCIMIWMessageType.image;

  @override
  Future<RCIMIWMessage?> toRCMessage() async {
    final imageMsg = await IMEngineManager().engine?.createImageMessage(
      conversationType,
      targetId,
      channelId,
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
  final String? channelId;
  final String path;
  final int duration;
  final String? remoteUrl;
  final String? coverUrl;
  String thumbnailBase64String;
  VideoMessage({
    required this.conversationType,
    required this.targetId,
    required this.path,
    required this.duration,
    required this.thumbnailBase64String,
    this.remoteUrl,
    this.coverUrl,
    this.channelId,
  });

  @override
  RCIMIWMessageType get type => RCIMIWMessageType.sight;

  @override
  Future<RCIMIWMessage?> toRCMessage() async {
    final videoMsg = await IMEngineManager().engine?.createSightMessage(
      conversationType,
      targetId,
      channelId,
      path,
      duration,
    );
    videoMsg?.thumbnailBase64String = thumbnailBase64String;
    videoMsg?.remote = remoteUrl;
    videoMsg?.senderUserId = IMEngineManager().currentUserId;
    videoMsg?.sentTime = DateTime.now().millisecondsSinceEpoch;
    return videoMsg;
  }
}

class FileMessage extends ImMessage {
  final RCIMIWConversationType conversationType;
  final String targetId;
  final String? channelId;
  final String path;
  final int size;
  final String name;
  FileMessage({
    required this.conversationType,
    required this.targetId,
    required this.path,
    required this.size,
    required this.name,
    this.channelId,
  });

  @override
  RCIMIWMessageType get type => RCIMIWMessageType.file;

  @override
  Future<RCIMIWMessage?> toRCMessage() async {
    final videoMsg = await IMEngineManager().engine?.createFileMessage(
      conversationType,
      targetId,
      channelId,
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
  final String? channelId;
  final String path;
  final int duration;

  VoiceMessage({
    required this.conversationType,
    required this.targetId,
    required this.path,
    required this.duration,
    this.channelId,
  });

  @override
  RCIMIWMessageType get type => RCIMIWMessageType.voice;

  @override
  Future<RCIMIWMessage?> toRCMessage() async {
    final videoMsg = await IMEngineManager().engine?.createVoiceMessage(
      conversationType,
      targetId,
      channelId,
      path,
      duration,
    );
    videoMsg?.senderUserId = IMEngineManager().currentUserId;
    videoMsg?.sentTime = DateTime.now().millisecondsSinceEpoch;
    return videoMsg;
  }
}
