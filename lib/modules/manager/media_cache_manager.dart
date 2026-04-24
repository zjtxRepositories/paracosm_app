import 'package:video_player/video_player.dart';

import '../../core/models/media_item.dart';

class MediaCacheManager {
  static final Map<int, VideoPlayerController> _videoCache = {};

  /// 预加载视频（当前 + 前后）
  static Future<void> preload(
      List<MediaItem> list,
      int index,
      ) async {
    for (final i in [index - 1, index, index + 1]) {
      if (i < 0 || i >= list.length) continue;

      final item = list[i];
      if (item.type != MediaType.video) continue;

      if (_videoCache.containsKey(i)) continue;

      final controller = VideoPlayerController.file(item.file!);
      _videoCache[i] = controller;

      try {
        await controller.initialize();
        controller.setLooping(true);
      } catch (_) {}
    }
  }

  static VideoPlayerController? get(int index) {
    return _videoCache[index];
  }

  static void pauseAllExcept(int index) {
    for (final entry in _videoCache.entries) {
      if (entry.key != index) {
        entry.value.pause();
      }
    }
  }

  static void disposeAll() {
    for (final c in _videoCache.values) {
      c.dispose();
    }
    _videoCache.clear();
  }
}