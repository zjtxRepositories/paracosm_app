

import 'package:paracosm/core/models/group_model.dart';
import 'package:paracosm/core/models/user_model.dart';
import 'package:paracosm/modules/im/manager/im_group_manager.dart';
import 'package:paracosm/modules/im/manager/im_user_manager.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
class ConversationModel {
  final RCIMIWConversation info;

  String? title;
  String? subtitle;
  String? portraitUri;

  ConversationModel({required this.info});
}

class ConversationResolver {
  final Map<String, UserModel?> _userCache = {};
  final Map<String, GroupModel?> _groupCache = {};

  Future<void> resolve(ConversationModel model) async {
    final info = model.info;
    final targetId = info.targetId;
    if (targetId == null) return;

    // title + avatar
    if (info.conversationType == RCIMIWConversationType.private) {
      final user = await _getUser(targetId);
      model.title = user?.name ?? '';
      model.portraitUri = user?.profile.portraitUri ?? '';
    }

    if (info.conversationType == RCIMIWConversationType.group) {
      final group = await _getGroup(targetId);
      model.title = await group?.name;
      model.portraitUri = group?.info.portraitUri ?? '';
    }

    if (info.conversationType == RCIMIWConversationType.system) {
      model.title = '通知';
    }

    // subtitle
    final msg = info.lastMessage;
    if (msg != null) {
      final content = _format(msg);

      if (info.conversationType == RCIMIWConversationType.group) {
        final group = await _getGroup(targetId);
        model.subtitle = '${group?.name ?? ''}：$content';
      } else {
        model.subtitle = content;
      }
    }
  }

  String _format(RCIMIWMessage message) {
    switch (message.messageType) {
      case RCIMIWMessageType.text:
        return (message as RCIMIWTextMessage).text ?? '';
      case RCIMIWMessageType.image:
        return '[图片]';
      case RCIMIWMessageType.voice:
        return '[语音]';
      case RCIMIWMessageType.sight:
        return '[视频]';
      case RCIMIWMessageType.recall:
        return '对方撤回了一条消息';
      default:
        return '[消息]';
    }
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