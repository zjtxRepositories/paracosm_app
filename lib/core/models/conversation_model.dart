import 'package:flutter/cupertino.dart';
import 'package:paracosm/core/models/group_model.dart';
import 'package:paracosm/core/models/user_display_model.dart';
import 'package:paracosm/modules/call/rong_call_summary_parser.dart';
import 'package:paracosm/modules/im/listener/group_state_center.dart';
import 'package:paracosm/modules/im/listener/user_display_state_center.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../modules/im/manager/im_engine_manager.dart';
import 'custom_message_model.dart';

class ConversationModel extends ChangeNotifier {
  RCIMIWConversation info;

  String? title;
  String? subtitle;
  String? portraitUri;

  ConversationModel({required this.info});

  int get time => info.operationTime ?? info.lastMessage?.sentTime ?? 0;

  void updateConversation(RCIMIWConversation value) {
    info = value;

    notifyListeners();
  }

  void update({String? title, String? subtitle, String? portraitUri}) {
    this.title = title ?? this.title;
    this.subtitle = subtitle ?? this.subtitle;
    this.portraitUri = portraitUri ?? this.portraitUri;

    notifyListeners();
  }
}

class ConversationResolver {
  ConversationResolver._();

  static final ConversationResolver _instance = ConversationResolver._();

  factory ConversationResolver() {
    return _instance;
  }

  Future<void> resolve(ConversationModel model) async {
    final info = model.info;
    final lastMessage = info.lastMessage;
    final expectedTargetId = info.targetId;
    final expectedMessageId = lastMessage?.messageId;
    final expectedMessageUId = lastMessage?.messageUId;
    final expectedSentTime = lastMessage?.sentTime;

    String? title;
    String? subtitle;
    String? portraitUri;

    final targetId = info.targetId;
    if (targetId == null) return;

    // title + avatar
    if (info.conversationType == RCIMIWConversationType.private) {
      final user = await _getUser(targetId);
      title = user?.name ?? '';
      portraitUri = user?.avatar;
    }

    if (info.conversationType == RCIMIWConversationType.group) {
      final group = await _getGroup(targetId);
      title = await group?.name;

      portraitUri = group?.info.portraitUri ?? '';
    }

    if (info.conversationType == RCIMIWConversationType.system) {
      title = '通知';
    }

    // subtitle
    final msg = lastMessage;
    if (msg != null) {
      final content = await _format(msg);
      if (info.conversationType == RCIMIWConversationType.group &&
          msg.messageType != RCIMIWMessageType.custom) {
        final user = await _getUser(msg.senderUserId ?? '');
        subtitle = '${user?.name ?? ''}：$content';
      } else {
        subtitle = content;
      }
    }

    final currentMessage = model.info.lastMessage;
    if (model.info.targetId != expectedTargetId ||
        currentMessage?.messageId != expectedMessageId ||
        currentMessage?.messageUId != expectedMessageUId ||
        currentMessage?.sentTime != expectedSentTime) {
      return;
    }

    model.update(title: title, subtitle: subtitle, portraitUri: portraitUri);
  }

  Future<String> _format(RCIMIWMessage message) async {
    final callSummary = RongCallSummaryParser.tryParse(message);
    if (callSummary != null) {
      return callSummary.conversationText;
    }

    switch (message.messageType) {
      case RCIMIWMessageType.text:
        return (message as RCIMIWTextMessage).text ?? '';
      case RCIMIWMessageType.image:
        return '[图片]';
      case RCIMIWMessageType.voice:
        return '[语音]';
      case RCIMIWMessageType.sight:
        return '[视频]';
      case RCIMIWMessageType.file:
        return '[文件]';
      case RCIMIWMessageType.recall:
        return '撤回了一条消息';
      case RCIMIWMessageType.reference:
        return message is RCIMIWReferenceMessage
            ? (message.text?.isNotEmpty ?? false ? message.text! : '[消息]')
            : '[消息]';
      case RCIMIWMessageType.combineV2:
        return '[聊天记录]';
      case RCIMIWMessageType.custom:
        RCIMIWCustomMessage customMessage = RCIMIWCustomMessage.fromJson(
          message.toJson(),
        );
        final data = customMessage.fields;
        if (data == null) return '';
        final model = CustomMessageModel.fromJson(
          Map<String, dynamic>.from(data),
        );
        return _formatCustomMessage(model);
      default:
        return '[消息]';
    }
  }

  Future<String> _formatCustomMessage(CustomMessageModel message) async {
    switch (message.type) {
      case CustomMessageType.friendAdd:
        return '我们已成功添加为好友，现在可以开始聊天啦～';
      case CustomMessageType.groupInvited:
        final group = await _getGroup(message.toUserId);
        final members = await _getMemberNames(message.userIds) ?? await group?.memberName;
        final user = await _getUser(message.fromUserId);
        return '"${user?.name ?? ''}"邀请$members加入了群聊';
      case CustomMessageType.createDao:
        final group = await _getGroup(message.toUserId);
        return '${group?.info.groupName} DAO has been created';
      case CustomMessageType.createClub:
        final group = await _getGroup(message.toUserId);
        return '${group?.name} Club has been created';
      case CustomMessageType.quitGroup:
        final user = await _getUser(message.fromUserId);
        return '${user?.name} 退出了群聊';
      case CustomMessageType.groupRemoved:
        final members = await _getMemberNames(message.userIds);
        return '$members 被移出了群聊';
      default:
        return _formatContent(message.content ?? '');
    }
  }

  Future<String> _formatContent(String content) async {
    if (content.isEmpty) return content;

    final reg = RegExp(r'\[([^\]]+)\]');
    final matches = reg.allMatches(content);

    if (matches.isEmpty) return content;

    String result = content;

    for (final match in matches) {
      final userId = match.group(1);
      if (userId == null) continue;

      final user = await _getUser(userId);
      final name = user?.name ?? '';

      result = result.replaceAll('[$userId]', name);
    }

    return result;
  }

  Future<String?> _getMemberNames(List<String>? userIds) async {
    if (userIds == null || userIds.isEmpty) {
      return null;
    }
    final currentUserId = IMEngineManager().currentUserId;
    final names = await Future.wait(
      userIds.map((userId) async {
        if (userId == currentUserId) {
          return '我';
        }
        final user = await UserDisplayStateCenter().getUser(userId);
        final name = user?.name.trim();
        if (name == null || name.isEmpty) {
          return null;
        }
        return name;
      }),
    );
    final result = names.whereType<String>().toList();
    if (result.isEmpty) {
      return null;
    }
    return result.join('、');
  }

  Future<UserDisplayModel?> _getUser(String id) async {
    return UserDisplayStateCenter().getUser(id);
  }

  Future<GroupModel?> _getGroup(String id) async {
    final group = await GroupStateCenter().getGroup(id);
    if (group == null) return null;
    return GroupModel(info: group);
  }
}
