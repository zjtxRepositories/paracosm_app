import 'package:flutter/material.dart';
import '../../util/image_picker_util.dart';

class ImagePickerSheet {
  /// 🎯 对外统一入口
  static Future<String?> show(BuildContext context) async {
    return await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ImagePickerContent(),
    );
  }
}

class _ImagePickerContent extends StatelessWidget {
  const _ImagePickerContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// 主操作区
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildItem(context, '拍照', true),
                const Divider(height: 1),
                _buildItem(context, '从手机相册选择', false),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// 取消
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '取消',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, String text, bool isCamera) {
    return GestureDetector(
      onTap: () async {
        final path =
        await ImagePickerUtil.pick(fromCamera: isCamera);
        print('path:---$path');
        if (path != null && context.mounted) {
          Navigator.pop(context, path); // 返回结果
        }
      },
      child: Container(
        height: 50,
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}