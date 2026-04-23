import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

class ChatSessionArgs {
  const ChatSessionArgs({
    required this.targetId,
    required this.conversationType,
    required this.name,
    this.channelId,
    this.isGroup = false,
    this.avatar,
  });

  final String targetId;
  final RCIMIWConversationType conversationType;
  final String name;
  final String? channelId;
  final bool isGroup;
  final String? avatar;
}
