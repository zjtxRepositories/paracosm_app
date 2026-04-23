
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

class UserModel {
  RCIMIWUserProfile profile;

  String get name => (profile.name ?? '').isNotEmpty ? profile.name!
      : (profile.userId!.length > 8 ? profile.userId!.substring(profile.userId!.length - 8) : profile.userId!);

  UserModel({
    required this.profile,
  });

}
