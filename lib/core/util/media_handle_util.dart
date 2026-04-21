import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:video_compress/video_compress.dart';

import '../network/api/upload_file_api.dart';
import '../network/models/social_media_model.dart';
import 'package:image/image.dart' as img;

/// =========================
/// 视频压缩结果模型
/// =========================
class CompressMediaFile {
  final MediaInfo? video;
  final File? thumbnail;

  CompressMediaFile({
    this.video,
    this.thumbnail,
  });
}

/// =========================
/// 媒体处理工具（生产级🔥）
/// =========================
class MediaHandleUtil {
  /// =========================
  /// 图片压缩（优化版）
  /// =========================
  static Future<String> compressedImageQuality(String filePath) async {
    try {
      final file = File(filePath);

      /// 小于 1MB 不压缩
      final size = await file.length();
      if (size < 1024 * 1024) return filePath;

      final dir = await getTemporaryDirectory();
      final ext = path.extension(filePath).toLowerCase();

      /// PNG 转 JPG（关键优化🔥）
      final targetExt = ext == ".png" ? ".jpg" : ext;

      final targetPath =
          "${dir.path}/${const Uuid().v4()}$targetExt";

      final result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        targetPath,
        quality: 70,
        format: CompressFormat.jpeg,
      );

      return result?.path ?? filePath;
    } catch (e) {
      return filePath;
    }
  }

  /// =========================
  /// 视频压缩（生产级🔥）
  /// =========================
  static Future<CompressMediaFile?> video(File file) async {
    try {
      final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
        frameRate: 25,
      );

      if (mediaInfo == null || mediaInfo.path == null) {
        return null;
      }

      final File rawThumb = await VideoCompress.getFileThumbnail(
        file.path,
        quality: 80,
        position: -1,
      );

      /// 👉 关键修复：持久化
      final dir = await getTemporaryDirectory();
      final fixedThumb = await rawThumb.copy(
        '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      return CompressMediaFile(
        video: mediaInfo,
        thumbnail: fixedThumb,
      );
    } catch (e) {
      print("视频压缩异常: $e");
      return null;
    }
  }

  /// =========================
  /// 获取视频封面
  /// =========================
  static Future<String> getVideoCover(String filePath) async {
    try {
      final file = await VideoCompress.getFileThumbnail(
        filePath,
        quality: 60,
        position: -1,
      );
      return file.path;
    } catch (e) {
      return "";
    }
  }

  /// =========================
  /// 清理缓存
  /// =========================
  static Future<void> clearCache() async {
    try {
      await VideoCompress.deleteAllCache();
    } catch (_) {}
  }

  /// =========================
  /// 🚀 核心：统一构建 MediaModel（强烈推荐🔥）
  /// =========================
  static Future<List<SocialMediaModel>> buildMediaModels(
      List<File> files,
      ) async {
    final List<SocialMediaModel> result = [];

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final filePath = file.path.toLowerCase();

      /// ================= 图片 =================
      if (filePath.endsWith(".jpg") ||
          filePath.endsWith(".jpeg") ||
          filePath.endsWith(".png")) {
        final compressedPath = await compressedImageQuality(file.path);

        final url =
        await UploadFileApi.uploadFileByPath(compressedPath);
        final bytes = await File(compressedPath).readAsBytes();
        final image = img.decodeImage(bytes);

        if (url != null) {
          result.add(
            SocialMediaModel(
              url,
              0,
              "",
              i,
              image?.width,
              image?.height,
            ),
          );
        }
      }

      /// ================= 视频 =================
      else if (filePath.endsWith(".mp4") ||
          filePath.endsWith(".mov")) {
        final compressResult = await video(file);

        if (compressResult == null) continue;

        final videoUrl = await UploadFileApi.uploadFileByPath(
          compressResult.video!.path!,
        );

        final coverUrl = await UploadFileApi.uploadFileByPath(
          compressResult.thumbnail!.path,
        );

        final bytes = await compressResult.thumbnail!.readAsBytes();
        final image = img.decodeImage(bytes);

        if (videoUrl != null && coverUrl != null) {
          result.add(
            SocialMediaModel(
              videoUrl,
              1,
              coverUrl,
              i,
              image?.width,
              image?.height,
            ),
          );
        }
      }
    }

    return result;
  }
}