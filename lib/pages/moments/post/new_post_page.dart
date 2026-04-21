
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:paracosm/pages/moments/post/social_post_controller.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_button.dart';


class NewPostPage extends StatefulWidget {
  final bool isRetweet;

  const NewPostPage({
    super.key,
    this.isRetweet = false,
  });

  @override
  State<NewPostPage> createState() => _NewPostPageState();
}

class _NewPostPageState extends State<NewPostPage> {
  late SocialPostController controller;

  @override
  void initState() {
    super.initState();
    controller = SocialPostController(isRetweet: widget.isRetweet);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isRetweet ? 'Retweet a post' : 'New Post';

    return AppPage(
      title: title,
      backgroundColor: Colors.white,
      navBackgroundColor: Colors.white,
      showNavBorder: true,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // =========================
                        // 输入框
                        // =========================
                        TextField(
                          controller: controller.textController,
                          minLines: 1,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.grey900,
                            fontSize: 14,
                          ),
                          onChanged: (_) => _refresh(),
                          decoration: InputDecoration(
                            hintText: 'Thoughts at this moment...',
                            hintStyle: AppTextStyles.body.copyWith(
                              color: AppColors.grey400,
                            ),
                            border: InputBorder.none,
                          ),
                        ),

                        const SizedBox(height: 20),

                        buildMediaRow(controller,context),
                        const SizedBox(height: 16),

                        // =========================
                        // retweet
                        // =========================
                        if (widget.isRetweet &&
                            controller.showRetweetPreview) ...[
                          GestureDetector(
                            onLongPress: () {
                              controller.showDeleteBar();
                              _refresh();
                            },
                            child: _RetweetPreviewCard(),
                          ),
                        ],

                        const SizedBox(height: 20),

                        const Divider(color: AppColors.grey100),

                        const SizedBox(height: 12),

                        // =========================
                        // 隐私设置
                        // =========================
                        Row(
                          children: [
                            const Icon(Icons.person, size: 16),
                            const SizedBox(width: 8),
                            const Text('Who can see'),

                            const Spacer(),

                            GestureDetector(
                              onTap: () {
                                _showPrivacySheet();
                              },
                              child: Row(
                                children: [
                                  Text(
                                    controller.visibilityTitle,
                                    style: const TextStyle(
                                      color: AppColors.grey400,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_ios, size: 14),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // =========================
                // 发布按钮
                // =========================
                AppButton(
                  text: 'Release',
                  onPressed: controller.isSubmitting || controller.textController.text.isEmpty
                      ? null
                      : () async {
                    final ok = await controller.publish();
                    if (ok && mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ),

          // =========================
          // 删除 retweet bar
          // =========================
          if (controller.showRetweetDeleteBar)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: GestureDetector(
                  onTap: () {
                    controller.deleteRetweetPreview();
                    _refresh();
                  },
                  child: Container(
                    height: 80,
                    color: Colors.red,
                    child: const Center(
                      child: Text(
                        "Delete Retweet",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =========================
  // 隐私选择
  // =========================
  void _showPrivacySheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("Public"),
              onTap: () {
                controller.setPrivacy(0, "Public");
                _refresh();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("Private"),
              onTap: () {
                controller.setPrivacy(1, "Private");
                _refresh();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("Friends"),
              onTap: () {
                controller.setPrivacy(2, "Friends");
                _refresh();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}

// =========================
// UI组件
// =========================
Widget buildMediaRow(SocialPostController controller,BuildContext context) {
  return Obx(() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...controller.assetList.asMap().entries.map((e) {
          final index = e.key;
          final item = e.value;
          return _ImagePreview(
            file: item.file,
            isVideo: item.type == MediaType.video,
            coverFile: item.coverFile,
            onDelete: () => controller.removeMedia(index),
          );
        }),

        if (controller.assetList.length < 9)
          GestureDetector(
            onTap: () => controller.pickMedia(context),
            child: _UploadTile(),
          ),
      ],
    );
  });
}

class _ImagePreview extends StatelessWidget {
  final File file;
  final File? coverFile;
  final bool isVideo;
  final VoidCallback? onDelete;

  const _ImagePreview({
    required this.file,
    this.coverFile,
    this.isVideo = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// ======================
        /// 图片 / 视频封面
        /// ======================
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            isVideo && coverFile != null ? coverFile! : file,
            width: 61,
            height: 61,
            fit: BoxFit.cover,
          ),
        ),

        /// ======================
        /// 视频播放按钮
        /// ======================
        if (isVideo)
          Positioned.fill(
            child: Center(
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),

        /// ======================
        /// 删除
        /// ======================
        Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UploadTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey[200],
      child: const Icon(Icons.add),
    );
  }
}

class _RetweetPreviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
      child: const Text("Retweet content preview"),
    );
  }
}