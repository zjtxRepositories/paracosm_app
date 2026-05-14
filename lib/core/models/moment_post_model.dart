import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:paracosm/core/models/social_Invitation_model.dart';
import 'package:paracosm/core/models/user_display_model.dart';
import 'package:paracosm/core/network/api/get_uer_info_api.dart';
import 'package:paracosm/modules/im/manager/im_engine_manager.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../modules/im/manager/im_user_manager.dart';

class MomentPostModel {
  SocialInvitationModel item;

  MomentPostModel({
    required this.item,
  });

  UserDisplayModel? user;
}

class MomentsResolver {
  final ImUserManager _manager = ImUserManager();

  /// 内存缓存
  final Map<String, UserDisplayModel> _cache = {};

  /// 批量解析
  Future<void> resolve(List<MomentPostModel> models) async {
    if (models.isEmpty) return;

    try {
      /// 1. 收集所有 userId
      final socialUserIds = models
          .map((e) => e.item.userId)
          .where((e) => e.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      /// 2. 过滤缓存
      final needLoadIds = socialUserIds
          .where((e) => !_cache.containsKey(e))
          .toList();

      /// 3. 批量获取业务用户信息
      ///
      /// 假设返回：
      /// List<UserInfo>
      ///
      final userInfos =
      await GetUerInfoApi.getList(needLoadIds);

      /// socialId -> imId
      final Map<String, String> socialToImMap = {};

      for (final item in userInfos) {
        socialToImMap[item.userId] = item.account;
      }
      print('socialToImMap---$socialToImMap');
      final currentUserId =
          IMEngineManager().currentUserId;

      /// 4. 收集 IM userId
      final imUserIds = socialToImMap.values.toSet().toList();

      /// 5. 批量获取 IM 用户资料
      final profiles =
          await _manager.getUserProfiles(imUserIds) ?? [];

      /// imId -> profile
      final Map<String, RCIMIWUserProfile> profileMap = {};

      for (final profile in profiles) {
        if (profile.userId != null) {
          profileMap[profile.userId!] = profile;
        }
      }

      /// 6. 当前用户特殊处理
      if (imUserIds.contains(currentUserId)) {
        final myProfile =
        await _manager.getMyUserProfile();

        if (myProfile != null &&
            myProfile.userId != null) {
          profileMap[myProfile.userId!] = myProfile;
        }
      }

      /// 7. 构建缓存
      socialToImMap.forEach((socialId, imId) {
        final profile = profileMap[imId];

        if (profile != null) {
          _cache[socialId] =
              UserDisplayModel(profile: profile);
        }
      });

      /// 8. 回填数据
      for (final model in models) {
        final socialId = model.item.userId;
        model.user = _cache[socialId];

      }
    } catch (e) {
      debugPrint("MomentsResolver resolve error: $e");
    }
  }

  void clearCache() {
    _cache.clear();
  }
}