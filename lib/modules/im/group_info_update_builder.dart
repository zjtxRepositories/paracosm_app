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
}
