import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

class GroupInfoUpdateBuilder {
  GroupInfoUpdateBuilder._();

  static RCIMIWGroupInfo build({
    required String groupId,
    required String groupName,
    String? portraitUri,
    String? introduction,
    String? notice,
    Map? extProfile,
  }) {
    return RCIMIWGroupInfo.create(
      groupId: groupId,
      groupName: groupName,
      portraitUri: portraitUri,
      introduction: introduction,
      notice: notice,
      extProfile: extProfile,
    );
  }

  static RCIMIWGroupInfo buildPermissionUpdate({
    required String groupId,
    required String groupName,
    String? portraitUri,
    String? introduction,
    String? notice,
    Map? extProfile,
    RCIMIWGroupJoinPermission? joinPermission,
    RCIMIWGroupOperationPermission? removeMemberPermission,
    RCIMIWGroupOperationPermission? invitePermission,
    RCIMIWGroupInviteHandlePermission? inviteHandlePermission,
    RCIMIWGroupOperationPermission? groupInfoEditPermission,
    RCIMIWGroupMemberInfoEditPermission? memberInfoEditPermission,
  }) {
    return RCIMIWGroupInfo.create(
      groupId: groupId,
      groupName: groupName,
      portraitUri: portraitUri,
      introduction: introduction,
      notice: notice,
      extProfile: extProfile,
      joinPermission: joinPermission,
      removeMemberPermission: removeMemberPermission,
      invitePermission: invitePermission,
      inviteHandlePermission: inviteHandlePermission,
      groupInfoEditPermission: groupInfoEditPermission,
      memberInfoEditPermission: memberInfoEditPermission,
    );
  }

  static void applyToLocal({
    required RCIMIWGroupInfo target,
    required RCIMIWGroupInfo update,
  }) {
    target.groupName = update.groupName;
    target.portraitUri = update.portraitUri;
    target.introduction = update.introduction;
    target.notice = update.notice;
    target.extProfile = update.extProfile;
  }

  static void applyPermissionToLocal({
    required RCIMIWGroupInfo target,
    required RCIMIWGroupInfo update,
  }) {
    target.joinPermission = update.joinPermission;
    target.removeMemberPermission = update.removeMemberPermission;
    target.invitePermission = update.invitePermission;
    target.inviteHandlePermission = update.inviteHandlePermission;
    target.groupInfoEditPermission = update.groupInfoEditPermission;
    target.memberInfoEditPermission = update.memberInfoEditPermission;
  }
}
