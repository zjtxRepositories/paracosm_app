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
      type: CustomMessageType.friendAdd,
      fromUserId: myId,
      toUserId: targetId,
      content: content,
    );
    final imageMsg = await IMEngineManager().engine?.createCustomMessage(
        conversationType,
        targetId,
        null,
        RCIMIWCustomMessagePolicy.normal,
        messageID,
        model.toJson()
    );
    return imageMsg;
  }
}

class TextMessage extends ImMessage {
  final RCIMIWConversationType conversationType;
  final String targetId;
  final String content;
  TextMessage({required this.conversationType, required this.targetId,required this.content});

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

class ImageMessage extends ImMessage {
  final RCIMIWConversationType conversationType;
  final String targetId;
  final String path;
  ImageMessage({required this.conversationType, required this.targetId,required this.path});

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
      duration
    );
    videoMsg?.thumbnailBase64String = thumbnailBase64String;
    videoMsg?.senderUserId = IMEngineManager().currentUserId;
    videoMsg?.sentTime = DateTime.now().millisecondsSinceEpoch;
    return videoMsg;
  }
}