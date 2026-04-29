import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../manager/im_engine_manager.dart';
import 'base/im_message.dart';

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