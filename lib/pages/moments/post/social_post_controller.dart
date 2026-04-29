import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:paracosm/widgets/common/app_toast.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:image/image.dart' as img;

import 'package:paracosm/core/network/api/upload_file_api.dart';
import 'package:paracosm/core/network/api/social_circle_note_api.dart';
import 'package:paracosm/core/models/social_note_publish_model.dart';
import 'package:paracosm/widgets/common/app_loading.dart';
import 'package:paracosm/util/media_handle_util.dart';
import '../../../core/models/media_item.dart';
import '../../../core/models/social_media_model.dart';
import '../../../modules/account/manager/account_manager.dart';


/// ======================
/// Controller
/// ======================
class SocialPostController extends GetxController {
  SocialPostController({this.isRetweet = false});

  final bool isRetweet;

  final TextEditingController textController = TextEditingController();

  /// ======================
  /// 状态
  /// ======================
  final RxList<MediaItem> assetList = <MediaItem>[].obs;

  bool isSubmitting = false;

  bool showRetweetPreview = true;
  bool showRetweetDeleteBar = false;

  int privacyLevel = 0;
  String visibilityTitle = "Public";

  /// ======================
  /// 隐私设置
  /// ======================
  void setPrivacy(int level, String title) {
    privacyLevel = level;
    visibilityTitle = title;
    update();
  }

  /// ======================
  /// 转发 UI
  /// ======================
  void showDeleteBar() {
    showRetweetDeleteBar = true;
    update();
  }

  void hideDeleteBar() {
    showRetweetDeleteBar = false;
    update();
  }

  void deleteRetweetPreview() {
    showRetweetPreview = false;
    showRetweetDeleteBar = false;
    update();
  }

  /// ======================
  /// 选择媒体（核心）
  /// ======================
  Future<void> pickMedia(BuildContext context) async {
    final List<AssetEntity>? result = await AssetPicker.pickAssets(
      context,
      pickerConfig: const AssetPickerConfig(),
    );

    if (result == null) return;

    assetList.clear();

    for (final e in result) {
      final file = await e.file;
      if (file == null) continue;

      if (e.type == AssetType.video) {
        /// 👉 生成封面
        final thumb = await e.thumbnailDataWithSize(
          const ThumbnailSize(200, 200),
        );

        File? coverFile;

        if (thumb != null) {
          final temp = File('${file.path}_cover.jpg');
          await temp.writeAsBytes(thumb);
          coverFile = temp;
        }

        assetList.add(
          MediaItem(
            file: file,
            type:MediaType.video,
            coverFile: coverFile,
          ),
        );
      } else {
        assetList.add(
          MediaItem(file: file, type: MediaType.image),
        );
      }
    }
  }

  /// ======================
  /// 删除媒体
  /// ======================
  void removeMedia(int index) {
    assetList.removeAt(index);
  }

  /// ======================
  /// 构建上传媒体
  /// ======================
  Future<List<SocialMediaModel>> buildMediaList() async {
    final List<SocialMediaModel> list = [];

    for (int i = 0; i < assetList.length; i++) {
      final item = assetList[i];

      /// ======================
      /// 图片
      /// ======================
      if (item.type == MediaType.image) {
        final compressed =
        await MediaHandleUtil.compressedImageQuality(item.file!.path);

        final url = await UploadFileApi.uploadFileByPath(compressed);
        if (url == null) continue;

        final image = img.decodeImage(File(compressed).readAsBytesSync());

        list.add(
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

      /// ======================
      /// 视频
      /// ======================
      if (item.type == MediaType.video) {
        final result = await MediaHandleUtil.compressedVideoQuality(item.file!);
        if (result == null) continue;

        final videoUrl =
        await UploadFileApi.uploadFileByPath(result.video?.path ?? "");

        final coverUrl =
        await UploadFileApi.uploadFileByPath(result.thumbnail?.path ?? "");

        final image =
        img.decodeImage(result.thumbnail!.readAsBytesSync());

        list.add(
          SocialMediaModel(
            videoUrl ?? "",
            1,
            coverUrl ?? "",
            i,
            image?.width,
            image?.height,
          ),
        );
      }
    }

    return list;
  }

  /// ======================
  /// 发布（核心）
  /// ======================
  Future<bool> publish({
    String noteId = "",
    String quote = "",
  }) async {
    if (isSubmitting) return false;
    isSubmitting = true;
    AppLoading.show();

    try {
      final mediaList = await buildMediaList();

      final model = SocialNotePublishModel(
        userId: AccountManager().currentAccount?.userId.toLowerCase() ?? '',
        noteId: noteId,
        content: textController.text.trim(),
        quote: quote,
        forward: isRetweet ? "1" : "",
        draft: false,
        authority: privacyLevel,
        media: mediaList,
      );

      return await SocialCircleNoteApi.socialCircleNotePublish(model);
    } catch (e) {
      debugPrint("publish error: $e");
      AppToast.show('发布帖子失败：${e.toString()}');
      return false;
    } finally {
      AppLoading.dismiss();
      isSubmitting = false;
    }
  }

  /// ======================
  /// 生命周期
  /// ======================
  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }
}