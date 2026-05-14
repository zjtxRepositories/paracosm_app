import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

class UserDisplayModel {
  final RCIMIWUserProfile? profile;
  final RCIMIWFriendInfo? friend;

  UserDisplayModel({
    this.friend,
    this.profile,
  });

  /// =========================
  /// userId（统一入口）
  /// =========================
  String get userId {
    return friend?.userId ??
        profile?.userId ??
        '';
  }

  /// =========================
  /// name（核心：优先级逻辑）
  /// =========================
  String get name {
    final remark = friend?.remark;
    if (remark != null && remark.trim().isNotEmpty) {
      return remark.trim();
    }

    final profileName = profile?.name;
    if (profileName != null && profileName.trim().isNotEmpty) {
      return profileName.trim();
    }

    final friendName = friend?.name;
    if (friendName != null && friendName.trim().isNotEmpty) {
      return friendName.trim();
    }

    return _fallbackName(userId);
  }

  /// =========================
  /// avatar
  /// =========================
  String get avatar {
    final friendAvatar = friend?.portrait;
    if (friendAvatar != null && friendAvatar.isNotEmpty) {
      return friendAvatar;
    }

    final profileAvatar = profile?.portraitUri;
    if (profileAvatar != null && profileAvatar.isNotEmpty) {
      return profileAvatar;
    }

    return '';
  }

  /// =========================
  /// fallback name
  /// =========================
  String _fallbackName(String id) {
    if (id.isEmpty) return '';
    if (id.length <= 8) return id;
    return id.substring(id.length - 8);
  }

  /// =========================
  /// helper
  /// =========================
  bool get isFriend => friend != null;

  factory UserDisplayModel.empty(String userId) {
    return UserDisplayModel(
      profile: RCIMIWUserProfile.create(userId: userId),
      friend: null,
    );
  }
}

extension UserDisplayModelCopyWith on UserDisplayModel {
  UserDisplayModel copyWith({
    dynamic friend,
    dynamic profile,
  }) {
    return UserDisplayModel(
      friend: friend ?? this.friend,
      profile: profile ?? this.profile,
    );
  }
}