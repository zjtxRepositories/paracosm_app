

import 'package:paracosm/core/models/group_model.dart';
import 'package:paracosm/core/models/user_model.dart';
import 'package:paracosm/modules/im/manager/im_group_manager.dart';
import 'package:paracosm/modules/im/manager/im_user_manager.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import 'custom_message_model.dart';
class MessageModel {
  final RCIMIWMessage item;
  String? nikeName;
  String? portraitUri;
  String? content;
  MessageModel({required this.item});
}

class MessageResolver {
  final Map<String, UserModel?> _userCache = {};
  final Map<String, GroupModel?> _groupCache = {};

  Future<void> resolve(MessageModel model) async {
    final info = model.item;
    final targetId = info.targetId;
    if (targetId == null) return;

    // title + avatar
    if (info.conversationType == RCIMIWConversationType.private) {
      final user = await _getUser(targetId);
      model.nikeName = user?.name ?? '';
      model.portraitUri = user?.profile.portraitUri ?? '';
    }

    if (info.conversationType == RCIMIWConversationType.group) {
      final group = await _getGroup(targetId);
      model.nikeName = await group?.name;
      model.portraitUri = group?.info.portraitUri ?? '';
    }

    model.content = await _format(info);
  }

  Future<String> _format(RCIMIWMessage message) async{
    switch (message.messageType) {
      case RCIMIWMessageType.text:
        return (message as RCIMIWTextMessage).text ?? '';
      case RCIMIWMessageType.recall:
        return '对方撤回了一条消息';
      case RCIMIWMessageType.custom:
        RCIMIWCustomMessage customMessage = RCIMIWCustomMessage.fromJson(message.toJson());
        final data = customMessage.fields;
        if (data == null) return '';
        final model = CustomMessageModel.fromJson(
          Map<String, dynamic>.from(data),
        );
        return _formatCustomMessage(model);
      default:
        return '';
    }
  }

  Future<String> _formatCustomMessage(CustomMessageModel message) async{
    switch (message.type) {
      case CustomMessageType.friendAdd:
        return '我们已成功添加为好友，现在可以开始聊天啦～';
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


  Future<UserModel?> _getUser(String id) async {
    return _userCache[id] ??= await _fetchUser(id);
  }

  Future<GroupModel?> _getGroup(String id) async {
    return _groupCache[id] ??= await _fetchGroup(id);
  }

  Future<UserModel?> _fetchUser(String id) async {
    final users = await ImUserManager().getUserProfiles([id]);
    if (users == null || users.isEmpty) return null;
    return UserModel(profile: users.first);
  }

  Future<GroupModel?> _fetchGroup(String id) async {
    final groups = await ImGroupManager().getGroupsInfo([id]);
    if (groups == null || groups.isEmpty) return null;
    return GroupModel(info: groups.first);
  }
}