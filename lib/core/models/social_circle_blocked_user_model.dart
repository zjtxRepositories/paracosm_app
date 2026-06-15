import 'package:paracosm/core/models/social_wallet_address.dart';

class SocialCircleBlockedUserModel {
  final String userId;
  final String blockUserId;
  final int timestamp;

  const SocialCircleBlockedUserModel({
    required this.userId,
    required this.blockUserId,
    required this.timestamp,
  });

  factory SocialCircleBlockedUserModel.fromJson(Map<String, dynamic> json) {
    return SocialCircleBlockedUserModel(
      userId: SocialWalletAddress.normalize(json['user_id']?.toString()),
      blockUserId: SocialWalletAddress.normalize(
        json['block_user_id']?.toString(),
      ),
      timestamp: _parseInt(json['timestamp']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
