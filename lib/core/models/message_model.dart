import 'package:paracosm/core/models/group_model.dart';
import 'package:paracosm/core/models/user_display_model.dart';
import 'package:paracosm/modules/im/listener/user_display_state_center.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../modules/im/listener/group_state_center.dart';
import '../../modules/im/manager/im_engine_manager.dart';
import 'custom_message_model.dart';

class MessageModel {
  final RCIMIWMessage item;
  String? nikeName;
  String? portraitUri;
  String? content;
  MessageModel({required this.item});

  Future<String> formatCustomContent() async {
    RCIMIWCustomMessage customMessage = RCIMIWCustomMessage.fromJson(
      item.toJson(),
    );
    final data = customMessage.fields;
    if (data == null) return '';
    final message = CustomMessageModel.fromJson(
      Map<String, dynamic>.from(data),
    );
    switch (message.type) {
      case CustomMessageType.friendAdd:
        return AppLocalizations.currentText('chat_friend_added_message');
      case CustomMessageType.groupInvited:
        final group = await _getGroup(message.toUserId);
        final members =
            await _getMemberNames(message.userIds) ?? await group?.memberName;
        final user = await _getUserName(message.fromUserId);
        return AppLocalizations.currentText('chat_invited_members_message', {
          'user': user,
          'members': members,
        });
      case CustomMessageType.groupJoined:
        final user =
            await _getMemberNames(message.userIds) ??
            await _getUserName(message.fromUserId);
        return AppLocalizations.currentText('chat_group_joined_message', {
          'user': user,
        });
      case CustomMessageType.createDao:
        final group = await _getGroup(message.toUserId);
        return '${group?.info.groupName} DAO has been created';
      case CustomMessageType.createClub:
        final group = await _getGroup(message.toUserId);
        return '${group?.name} Club has been created';
      case CustomMessageType.quitGroup:
        final user = await _getUserName(message.fromUserId);
        return AppLocalizations.currentText('chat_user_quit_group_message', {
          'user': user,
        });
      case CustomMessageType.groupRemoved:
        final members = await _getMemberNames(message.userIds);
        return AppLocalizations.currentText('chat_members_removed_message', {
          'members': members ?? '',
        });
      case CustomMessageType.transfer:
        final user = await _getUserName(message.fromUserId);
        final target = await _getUserName(message.userIds?.firstOrNull ?? '');
        return AppLocalizations.currentText('chat_group_transferred_message', {
          'user': user,
          'target': target,
        });
      case CustomMessageType.groupDisbanded:
        final user = await _getUserName(message.fromUserId);
        return AppLocalizations.currentText('chat_group_disbanded_message', {
          'user': user,
        });
      case CustomMessageType.customFace:
        return AppLocalizations.currentText('chat_detail_custom_face');
      case CustomMessageType.momentPost:
        final summary = (message.postContent ?? message.content ?? '').trim();
        return summary.isNotEmpty
            ? summary
            : AppLocalizations.currentText('moments_moment_title');
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
      final name = _isCurrentUser(userId)
          ? AppLocalizations.currentText('chat_me')
          : user?.name ?? '';

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
          return AppLocalizations.currentText('chat_me');
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
    return result.join(AppLocalizations.currentText('common_list_separator'));
  }

  Future<UserDisplayModel?> _getUser(String id) async {
    return UserDisplayStateCenter().getUser(id);
  }

  Future<String> _getUserName(String id) async {
    if (id.isEmpty) return '';
    if (_isCurrentUser(id)) {
      return AppLocalizations.currentText('chat_me');
    }
    final user = await _getUser(id);
    return user?.name.trim() ?? '';
  }

  bool _isCurrentUser(String userId) {
    return userId == IMEngineManager().currentUserId;
  }

  Future<GroupModel?> _getGroup(String id) async {
    final group = await GroupStateCenter().getGroup(id);
    if (group == null) return null;
    return GroupModel(info: group);
  }
}

//
// class MessageResolver {
//   final Map<String, UserModel?> _userCache = {};
//   final Map<String, GroupModel?> _groupCache = {};
//
//   Future<void> resolve(MessageModel model) async {
//     final info = model.item;
//     final targetId = info.targetId;
//     if (targetId == null) return;
//
//     // title + avatar
//     if (info.conversationType == RCIMIWConversationType.private) {
//       final user = await _getUser(targetId);
//       model.nikeName = user?.name ?? '';
//       model.portraitUri = user?.profile.portraitUri ?? '';
//     }
//
//     if (info.conversationType == RCIMIWConversationType.group) {
//       final group = await _getGroup(targetId);
//       model.nikeName = await group?.name;
//       model.portraitUri = group?.info.portraitUri ?? '';
//     }
//
//     model.content = await _format(info);
//   }
//
//   Future<String> _format(RCIMIWMessage message) async{
//     switch (message.messageType) {
//       case RCIMIWMessageType.text:
//         return (message as RCIMIWTextMessage).text ?? '';
//       case RCIMIWMessageType.recall:
//         return '对方撤回了一条消息';
//       case RCIMIWMessageType.custom:
//         RCIMIWCustomMessage customMessage = RCIMIWCustomMessage.fromJson(message.toJson());
//         final data = customMessage.fields;
//         if (data == null) return '';
//         final model = CustomMessageModel.fromJson(
//           Map<String, dynamic>.from(data),
//         );
//         return _formatCustomMessage(model);
//       default:
//         return '';
//     }
//   }
//
//   Future<String> _formatCustomMessage(CustomMessageModel message) async{
//     switch (message.type) {
//       case CustomMessageType.friendAdd:
//         return '我们已成功添加为好友，现在可以开始聊天啦～';
//       case CustomMessageType.groupInvited:
//         final group = await _getGroup(message.toUserId);
//         final members = await group?.memberName;
//         final user = await _getUser(message.fromUserId);
//         return '"${user?.name ?? ''}"邀请$members加入了群聊';
//       default:
//         return _formatContent(message.content ?? '');
//     }
//   }
//
//   Future<String> _formatContent(String content) async {
//     if (content.isEmpty) return content;
//
//     final reg = RegExp(r'\[([^\]]+)\]');
//     final matches = reg.allMatches(content);
//
//     if (matches.isEmpty) return content;
//
//     String result = content;
//
//     for (final match in matches) {
//       final userId = match.group(1);
//       if (userId == null) continue;
//
//       final user = await _getUser(userId);
//       final name = user?.name ?? '';
//
//       result = result.replaceAll('[$userId]', name);
//     }
//
//     return result;
//   }
//
//
//   Future<UserModel?> _getUser(String id) async {
//     return _userCache[id] ??= await _fetchUser(id);
//   }
//
//   Future<GroupModel?> _getGroup(String id) async {
//     return _groupCache[id] ??= await _fetchGroup(id);
//   }
//
//   Future<UserModel?> _fetchUser(String id) async {
//     final users = await ImUserManager().getUserProfiles([id]);
//     if (users == null || users.isEmpty) return null;
//     return UserModel(profile: users.first);
//   }
//
//   Future<GroupModel?> _fetchGroup(String id) async {
//     final groups = await ImGroupManager().getGroupsInfo([id]);
//     if (groups == null || groups.isEmpty) return null;
//     return GroupModel(info: groups.first);
//   }
// }
