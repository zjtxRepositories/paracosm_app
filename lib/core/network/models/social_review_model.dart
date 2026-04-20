import 'package:paracosm/modules/user/model/user_info.dart';

class SocialReviewModel {
  SocialReviewModel(
      this.reviewId,
      this.userId,
      this.noteId,
      this.timestamp,
      this.content,
      this.toUserId,
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

  UserInfo? userFullInfo;
  UserInfo? toUserFullInfo;

  List<SocialReviewModel>? subReviews;

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
      'content': content,
      'sub_reviews': subReviews?.map((e) => e.toJson()).toList(),
      // SDK对象一般不建议直接序列化
    };
  }
}