import 'dart:io';

import 'package:video_player/video_player.dart';

import '../../core/models/media_item.dart';

class MediaCacheManager {
  static final Map<int, VideoPlayerController> _videoCache = {};
  static final Set<int> _failedIndexes = {};

  /// 预加载视频（当前 + 前后）
  static Future<void> preload(List<MediaItem> list, int index) async {
    for (final i in [index - 1, index, index + 1]) {
      if (i < 0 || i >= list.length) continue;

      final item = list[i];
      if (item.type != MediaType.video) continue;

      if (_videoCache.containsKey(i)) continue;
      if (_failedIndexes.contains(i)) continue;

      final controller = _createController(item);
      if (controller == null) {
        _failedIndexes.add(i);
        continue;
      }

      _videoCache[i] = controller;

      try {
        await controller.initialize();
        controller.setLooping(true);
        _failedIndexes.remove(i);
      } catch (_) {
        await controller.dispose();
        _videoCache.remove(i);
        _failedIndexes.add(i);
      }
    }
  }

  static VideoPlayerController? get(int index) {
    return _videoCache[index];
  }

  static bool hasError(int index) {
    return _failedIndexes.contains(index);
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
    _failedIndexes.clear();
  }

  static VideoPlayerController? _createController(MediaItem item) {
    final file = _existingLocalMediaFile(item.file);
    if (file != null) {
      return VideoPlayerController.file(file);
    }

    final url = item.url?.trim();
    if (url == null ||
        url.isEmpty ||
        (!url.startsWith('http://') && !url.startsWith('https://'))) {
      return null;
    }

    return VideoPlayerController.networkUrl(Uri.parse(url));
  }

  static File? _existingLocalMediaFile(File? source) {
    if (source == null) {
      return null;
    }

    final uri = Uri.tryParse(source.path);
    final path = uri != null && uri.scheme == 'file'
        ? uri.toFilePath()
        : source.path;
    final file = File(path);

    return file.existsSync() ? file : null;
  }
}
