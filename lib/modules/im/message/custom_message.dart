
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/custom_message_model.dart';
import '../manager/im_engine_manager.dart';
import 'base/im_message.dart';

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