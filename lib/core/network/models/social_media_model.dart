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