import 'package:image_picker/image_picker.dart';

class ImagePickerUtil {
  static final ImagePicker _picker = ImagePicker();

  /// 📷 拍照
  static Future<String?> pickFromCamera({
    int imageQuality = 80,
  }) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
      );

      if (file == null) return null;

      return file.path;
    } catch (e) {
      print('❌ pickFromCamera error: $e');
      return null;
    }
  }

  /// 🖼 相册
  static Future<String?> pickFromGallery({
    int imageQuality = 80,
  }) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
      );

      if (file == null) return null;

      return file.path;
    } catch (e) {
      print('❌ pickFromGallery error: $e');
      return null;
    }
  }

  /// 📦 统一入口（推荐🔥）
  static Future<String?> pick({
    required bool fromCamera,
    int imageQuality = 80,
  }) {
    return fromCamera
        ? pickFromCamera(imageQuality: imageQuality)
        : pickFromGallery(imageQuality: imageQuality);
  }
}