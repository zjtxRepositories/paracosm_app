import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:paracosm/core/models/social_Invitation_model.dart';
import 'package:paracosm/core/models/social_media_model.dart';
import 'package:paracosm/core/models/user_display_model.dart';
import 'package:paracosm/modules/im/listener/user_display_state_center.dart';

class MomentPostModel {
  SocialInvitationModel item;

  MomentPostModel({required this.item});

  UserDisplayModel? user;
}

class MomentsResolver {
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

      /// 3. 朋友圈 user_id 直接作为 IM userId 获取资料
      await Future.wait(
        needLoadIds.map((userId) async {
          final user = await UserDisplayStateCenter().getUser(userId);
          if (user != null) {
            _cache[userId] = user;
          }
        }),
      );

      /// 4. 回填数据
      for (final model in models) {
        final userId = model.item.userId;
        model.user = _cache[userId];
      }
    } catch (e) {
      debugPrint("MomentsResolver resolve error: $e");
    }
  }

  void clearCache() {
    _cache.clear();
  }
}

class MomentDynamicModel {
  MomentDynamicModel({
    required this.noteId,
    required this.content,
    required this.media,
  });

  final String noteId;
  final String content;
  final List<SocialMediaModel> media;

  /// =========================
  /// fromJson
  /// =========================
  factory MomentDynamicModel.fromJson(Map<String, dynamic> json) {
    return MomentDynamicModel(
      noteId: json['noteId'] ?? '',
      content: json['content'] ?? '',
      media: (json['media'] as List? ?? [])
          .map((e) => SocialMediaModel.fromJson(e))
          .toList(),
    );
  }

  /// =========================
  /// toJson
  /// =========================
  Map<String, dynamic> toJson() {
    return {
      'noteId': noteId,
      'content': content,
      'media': media.map((e) => e.toJson()).toList(),
    };
  }
}
