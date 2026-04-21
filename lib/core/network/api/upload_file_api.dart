import 'dart:io';
import 'package:dio/dio.dart';
import '../client/base_client.dart';
import '../config/network_config.dart';

class UploadFileApi {
  static final BaseClient _client = BaseClient(NetworkConfig.defaultApiBaseUrl);
  /// =========================
  /// 单文件上传（安全版）
  /// =========================
  static Future<String?> uploadFileByPath(
      String path, {
        void Function(int, int)? onSendProgress,
      }) async {
    try {
      final file = File(path);
      if (!file.existsSync()) return null;

      final formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          path,
          filename: path.split('/').last,
        ),
      });

      final response = await _client.post(
        "/im-upload/upload/UploadifyServlet",
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: onSendProgress,
      );
      /// 👉 安全解析
      if (response != null &&
          response["url"] != null &&
          response["url"].toString().isNotEmpty) {
        return response["url"];
      }

      return null;
    } on DioException catch (e) {
      print("上传失败(Dio): ${e.message}");
      return null;
    } catch (e) {
      print("上传失败: $e");
      return null;
    }
  }

  /// =========================
  /// 批量上传（推荐🔥）
  /// =========================
  static Future<List<String>> uploadFiles(
      List<String> paths, {
        void Function(int, int)? onSendProgress,
      }) async {
    try {
      final formData = FormData();

      for (var p in paths) {
        formData.files.add(
          MapEntry(
            "files",
            await MultipartFile.fromFile(
              p,
              filename: p.split('/').last,
            ),
          ),
        );
      }

      final response = await _client.post(
        "/im-upload/upload/UploadifyServletBatch",
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: onSendProgress,
      );

      if (response.data["code"] == 200 &&
          response.data["data"] != null) {
        return List<String>.from(response.data["data"]);
      }

      return [];
    } catch (e) {
      print("批量上传失败: $e");
      return [];
    }
  }

  /// =========================
  /// 并发上传（更快🔥）
  /// =========================
  static Future<List<String>> uploadFilesConcurrent(
      List<String> paths,
      ) async {
    final results = await Future.wait(
      paths.map((p) => uploadFileByPath(p)),
    );

    return results.whereType<String>().toList();
  }
}