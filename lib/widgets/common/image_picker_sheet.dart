import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import '../../util/image_picker_util.dart';

class ImagePickerSheet {
  /// 🎯 对外统一入口
  static Future<String?> show(BuildContext context) async {
    final fromCamera = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => const _ImagePickerContent(),
    );
    if (fromCamera == null) return null;

    await SchedulerBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return ImagePickerUtil.pick(fromCamera: fromCamera);
  }
}

class _ImagePickerContent extends StatelessWidget {
  const _ImagePickerContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                _buildItem(context, l10n.commonTakePhoto, true),
                const Divider(height: 1),
                _buildItem(context, l10n.commonChooseFromAlbum, false),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// 取消
          GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.commonCancel,
                style: const TextStyle(
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
      onTap: () => Navigator.pop(context, isCamera),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
