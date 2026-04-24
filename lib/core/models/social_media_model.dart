
import 'media_item.dart';

class SocialMediaModel {
  SocialMediaModel(
      this.url,
      this.type,
      this.cover,
      this.id,
      this.width,
      this.height,
      );

  final int id;
  final String url;
  final int type;
  final String cover;
  final int? width;
  final int? height;

  /// =========================
  /// fromJson
  /// =========================
  factory SocialMediaModel.fromJson(Map<String, dynamic> json) {
    return SocialMediaModel(
      json['url'] ?? '',
      json['type'] ?? 0,
      json['cover'] ?? '',
      json['id'] ?? 0,
      json['width'],
      json['height'],
    );
  }

  /// =========================
  /// toJson
  /// =========================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'type': type,
      'cover': cover,
      'width': width,
      'height': height,
    };
  }
}

extension MediaTypeMapper on MediaType {
  int toInt() => this == MediaType.image ? 0 : 1;

  static MediaType fromInt(int value) {
    return value == 1 ? MediaType.video : MediaType.image;
  }
}

extension SocialMediaToItemMapper on SocialMediaModel {
  MediaItem toMediaItem() {
    return MediaItem(
      file: null,
      url: url.isEmpty ? null : url,
      type: MediaTypeMapper.fromInt(type),

      coverFile: null,
      coverUrl: cover.isEmpty ? null : cover,
    );
  }
}

extension SocialMediaListMapper on List<SocialMediaModel> {
  List<MediaItem> toMediaItems() {
    return map((e) => e.toMediaItem()).toList();
  }
}