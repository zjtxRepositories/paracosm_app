
import 'dart:io';

import 'package:flutter/cupertino.dart';

/// ======================
/// MediaType
/// ======================
enum MediaType { image, video }

/// ======================
/// MediaItem
/// ======================
class MediaItem {
  final File? file;        // 本地文件（选择/编辑阶段）
  final String? url;        // 服务端 URL（已发布/已上传）
  final MediaType type;
  final File? coverFile;   // 本地封面
  final String? coverUrl;  // 服务端封面

  MediaItem({
    this.file,
    this.url,
    required this.type,
    this.coverFile,
    this.coverUrl,
  });
}

extension MediaResolver on MediaItem {
  bool get isLocal => file != null;

  String get mediaPath => file?.path ?? url ?? '';

  ImageProvider get imageProvider {
    if (file != null) return FileImage(file!);
    return NetworkImage(url ?? '');
  }

  ImageProvider? get coverProvider {
    if (coverFile != null) return FileImage(coverFile!);
    if (coverUrl != null) return NetworkImage(coverUrl!);
    return null;
  }
}