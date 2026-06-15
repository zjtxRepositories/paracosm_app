import 'package:paracosm/core/models/social_wallet_address.dart';

class SocialCircleRelationModel {
  final String userId;
  final String followUserId;
  final int timestamp;

  const SocialCircleRelationModel({
    required this.userId,
    required this.followUserId,
    required this.timestamp,
  });

  factory SocialCircleRelationModel.fromJson(Map<String, dynamic> json) {
    return SocialCircleRelationModel(
      userId: SocialWalletAddress.normalize(
        (json['user_id'] ?? json['fans_user_id'] ?? json['fan_user_id'])
            ?.toString(),
      ),
      followUserId: SocialWalletAddress.normalize(
        json['follow_user_id']?.toString(),
      ),
      timestamp: _parseInt(json['timestamp']),
    );
  }

  String getFollowingUserId() => followUserId;

  String getFanUserId() => userId;

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
