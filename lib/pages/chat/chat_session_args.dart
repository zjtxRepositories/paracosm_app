import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

class ChatSessionArgs {
  const ChatSessionArgs({
    required this.targetId,
    required this.conversationType,
    required this.name,
    this.channelId,
    this.isGroup = false,
    this.avatar,
    this.anchorSentTime,
    this.anchorMessageId,
    this.searchKeyword,
  });

  final String targetId;
  final RCIMIWConversationType conversationType;
  final String name;
  final String? channelId;
  final bool isGroup;
  final String? avatar;
  final int? anchorSentTime;
  final String? anchorMessageId;
  final String? searchKeyword;

  ChatSessionArgs copyWith({
    String? targetId,
    RCIMIWConversationType? conversationType,
    String? name,
    String? channelId,
    bool? isGroup,
    String? avatar,
    int? anchorSentTime,
    String? anchorMessageId,
    String? searchKeyword,
  }) {
    return ChatSessionArgs(
      targetId: targetId ?? this.targetId,
      conversationType: conversationType ?? this.conversationType,
      name: name ?? this.name,
      channelId: channelId ?? this.channelId,
      isGroup: isGroup ?? this.isGroup,
      avatar: avatar ?? this.avatar,
      anchorSentTime: anchorSentTime ?? this.anchorSentTime,
      anchorMessageId: anchorMessageId ?? this.anchorMessageId,
      searchKeyword: searchKeyword ?? this.searchKeyword,
    );
  }
}
