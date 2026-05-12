import 'package:paracosm/modules/im/manager/im_user_manager.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../modules/user/model/user_info.dart';

class IMUserProfileResolver {
  final ImUserManager _manager;

  IMUserProfileResolver(this._manager);

  Future<Map<String, RCIMIWUserProfile>> resolveBySocialMap({
    required Map<String, String> socialToImMap,
    String? currentUserId,
  }) async {
    final imUserIds = socialToImMap.values.toSet().toList();
    if (imUserIds.isEmpty) return {};

    final profiles =
        await _manager.getUserProfiles(imUserIds) ?? [];

    final Map<String, RCIMIWUserProfile> profileMap = {};

    for (final p in profiles) {
      if (p.userId != null) {
        profileMap[p.userId!] = p;
      }
    }

    /// 当前用户补充
    if (currentUserId != null &&
        imUserIds.contains(currentUserId)) {
      final me = await _manager.getMyUserProfile();
      if (me?.userId != null) {
        profileMap[me!.userId!] = me;
      }
    }

    return profileMap;
  }

  /// 👉 新增：直接帮你做“social → imProfile”
  Future<Map<String, RCIMIWUserProfile>> resolveFromSocialUsers({
    required List<UserInfo> userInfos,
    String? currentUserId,
  }) async {
    final socialToImMap = {
      for (final u in userInfos)
        u.userId: u.account,
    };

    return resolveBySocialMap(
      socialToImMap: socialToImMap,
      currentUserId: currentUserId,
    );
  }
}