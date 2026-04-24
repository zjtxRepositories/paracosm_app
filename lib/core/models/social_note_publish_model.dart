
import 'package:paracosm/core/models/social_media_model.dart';

class SocialNotePublishModel {
  SocialNotePublishModel({
    required this.userId,
    required this.noteId,
    required this.content,
    required this.quote,
    required this.forward,
    required this.draft,
    required this.authority,
    required this.media,
  });

  final String userId;
  final String noteId;
  final String content;
  final String quote;
  final String forward;
  final bool draft;
  final int authority;
  final List<SocialMediaModel> media;

  /// =========================
  /// 反序列化
  /// =========================
  factory SocialNotePublishModel.fromJson(Map<String, dynamic> json) {
    return SocialNotePublishModel(
      userId: json['user_id'] ?? '',
      noteId: json['note_id'] ?? '',
      content: json['content'] ?? '',
      quote: json['quote'] ?? '',
      forward: json['forward'] ?? '',
      draft: json['draft'] ?? false,
      authority: json['authority'] ?? 0,
      media: (json['media'] as List<dynamic>?)
          ?.map((e) => SocialMediaModel.fromJson(e))
          .toList() ??
          [],
    );
  }

  /// =========================
  /// 序列化
  /// =========================
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'note_id': noteId,
      'content': content,
      'quote': quote,
      'forward': forward,
      'draft': draft,
      'authority': authority,
      'media': media.map((e) => e.toJson()).toList(),
    };
  }
}