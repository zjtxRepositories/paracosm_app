import 'package:paracosm/core/models/social_media_model.dart';
import 'package:paracosm/core/models/social_review_model.dart';
import 'package:paracosm/modules/user/model/user_info.dart';

class SocialInvitationModel {
  SocialInvitationModel(
    this.noteId,
    this.userId,
    this.timestamp,
    this.content,
    this.quote,
    this.forward,
    this.draft,
    this.authority,
    this.media,
    this.likes,
    this.reviews,
    this.collects,
    this.shares,
    this.forwards,
    this.isLike,
    this.isCollect,
    this.reviewInfo, {
    this.forwardInvitation,
    this.quoteInvitation,
    this.userInfoModel,
  });

  final String noteId;
  final String userId;
  UserInfo? userInfoModel;
  final int timestamp;
  final String content;
  final String quote;
  SocialInvitationModel? quoteInvitation;
  final String forward;
  SocialInvitationModel? forwardInvitation;
  final bool draft;
  final int authority;
  final List<SocialMediaModel> media;
  int likes;
  int reviews;
  int collects;
  int shares;
  int forwards;
  bool isLike;
  bool isCollect;
  List<SocialReviewModel> reviewInfo;

  /// =========================
  /// fromJson
  /// =========================
  factory SocialInvitationModel.fromJson(Map<String, dynamic> json) {
    return SocialInvitationModel(
      json['note_id'] ?? '',
      json['user_id'] ?? '',
      json['timestamp'] ?? 0,
      json['content'] ?? '',
      json['quote'] ?? '',
      json['forward'] ?? '',
      json['draft'] ?? false,
      json['authority'] ?? 0,
      (json['media'] as List? ?? [])
          .map((e) => SocialMediaModel.fromJson(e))
          .toList(),
      _parseInt(json['likes']),
      _parseInt(json['reviews']),
      _parseInt(json['collects']),
      _parseInt(json['shares']),
      _parseInt(json['forwards']),
      _parseBool(
        json['isLike'] ??
            json['is_like'] ??
            json['is_liked'] ??
            json['liked'] ??
            json['has_like'],
      ),
      _parseBool(
        json['isCollect'] ??
            json['is_collect'] ??
            json['is_collected'] ??
            json['collected'] ??
            json['has_collect'],
      ),
      (json['review_info'] as List? ?? [])
          .map((e) => SocialReviewModel.fromJson(e))
          .toList(),
      forwardInvitation: json['forward_invitation'] != null
          ? SocialInvitationModel.fromJson(json['forward_invitation'])
          : null,
      quoteInvitation: json['quote_invitation'] != null
          ? SocialInvitationModel.fromJson(json['quote_invitation'])
          : null,
      userInfoModel: json['user_info'] != null
          ? UserInfo.fromJson(json['user_info'])
          : null,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }

  /// =========================
  /// toJson
  /// =========================
  Map<String, dynamic> toJson() {
    return {
      'note_id': noteId,
      'user_id': userId,
      'timestamp': timestamp,
      'content': content,
      'quote': quote,
      'forward': forward,
      'draft': draft,
      'authority': authority,
      'media': media.map((e) => e.toJson()).toList(),
      'likes': likes,
      'reviews': reviews,
      'collects': collects,
      'shares': shares,
      'forwards': forwards,
      'is_like': isLike,
      'is_collect': isCollect,
      'review_info': reviewInfo.map((e) => e.toJson()).toList(),
      'forward_invitation': forwardInvitation?.toJson(),
      'quote_invitation': quoteInvitation?.toJson(),
      'user_info': userInfoModel?.toJson(),
    };
  }
}
