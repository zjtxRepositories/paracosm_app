import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../manager/im_engine_manager.dart';
import 'base/im_message.dart';

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