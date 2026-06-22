import 'package:paracosm/core/models/user_display_model.dart';
import 'package:paracosm/core/models/social_wallet_address.dart';

class SocialReviewModel {
  SocialReviewModel(
      this.reviewId,
      this.userId,
      this.noteId,
      this.timestamp,
      this.content,
      this.toUserId,
      this.isLike,
      this.likes,
      this.subReviews, {
        this.userFullInfo,
        this.toUserFullInfo,
  });

  final String reviewId;
  final String userId;
  final String noteId;
  final String toUserId;
  final int timestamp;
  final String content;
  bool isLike;
  int likes;

  UserDisplayModel? userFullInfo;
  UserDisplayModel? toUserFullInfo;

  List<SocialReviewModel>? subReviews;

  String get walletAddress {
    final displayAddress = SocialWalletAddress.normalize(userFullInfo?.userId);
    if (displayAddress.isNotEmpty) return displayAddress;
    return SocialWalletAddress.normalize(userId);
  }

  String get toWalletAddress {
    final displayAddress = SocialWalletAddress.normalize(
      toUserFullInfo?.userId,
    );
    if (displayAddress.isNotEmpty) return displayAddress;
    return SocialWalletAddress.normalize(toUserId);
  }

  /// =========================
  /// fromJson
  /// =========================
  factory SocialReviewModel.fromJson(Map<String, dynamic> json) {
    return SocialReviewModel(
      json['review_id'] ?? '',
      json['user_id'] ?? '',
      json['note_id'] ?? '',
      json['timestamp'] ?? 0,
      json['content'] ?? '',
      json['to_user_id'] ?? '',
      json['is_like'] ?? false,
      json['likes'] ?? 0,
      (json['sub_reviews'] as List?)
          ?.map((e) => SocialReviewModel.fromJson(e))
          .toList(),
      userFullInfo: null, // SDK对象通常需要你自己补
      toUserFullInfo: null,
    );
  }

  /// =========================
  /// toJson
  /// =========================
  Map<String, dynamic> toJson() {
    return {
      'review_id': reviewId,
      'user_id': userId,
      'note_id': noteId,
      'to_user_id': toUserId,
      'timestamp': timestamp,
      'is_like': isLike,
      'likes': likes,
      'content': content,
      'sub_reviews': subReviews?.map((e) => e.toJson()).toList(),
      // SDK对象一般不建议直接序列化
    };
  }
}
