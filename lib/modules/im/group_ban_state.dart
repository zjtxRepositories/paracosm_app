import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

const String groupMuteAllExtKey = 'ext_isMuteAll';

bool isGroupMuteAll(RCIMIWGroupInfo? groupInfo) {
  final value = groupInfo?.extProfile?[groupMuteAllExtKey];
  if (value is bool) return value;
  if (value is num) return value.toInt() == 1;
  final text = value?.toString().trim().toLowerCase();
  return text == '1' || text == 'true';
}

Map<dynamic, dynamic> groupExtProfileWithMuteAll(
  Map? extProfile, {
  required bool banned,
}) {
  return <dynamic, dynamic>{...?extProfile, groupMuteAllExtKey: banned ? '1 ': '0'};
}
