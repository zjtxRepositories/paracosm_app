import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/models/media_item.dart';
import '../../modules/manager/media_cache_manager.dart';

class AppMediaGallery extends StatefulWidget {
  final List<MediaItem> list;
  final int initialIndex;

  const AppMediaGallery({
    super.key,
    required this.list,
    this.initialIndex = 0,
  });

  @override
  State<AppMediaGallery> createState() => _AppMediaGalleryState();
}

class _AppMediaGalleryState extends State<AppMediaGallery> {
  late PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    final maxIndex = widget.list.isEmpty ? 0 : widget.list.length - 1;
    _index = widget.initialIndex.clamp(0, maxIndex).toInt();
    _controller = PageController(initialPage: _index);

    _preloadAround(_index);
  }

  void _onPageChanged(int index) {
    setState(() => _index = index);

    _preloadAround(index);
    MediaCacheManager.pauseAllExcept(index);
  }

  Future<void> _preloadAround(int index) async {
    await MediaCacheManager.preload(widget.list, index);
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleVideo(int index) {
    final c = MediaCacheManager.get(index);
    if (c == null) return;

    setState(() {
      c.value.isPlaying ? c.pause() : c.play();
    });
  }

  Widget _build(MediaItem item, int index) {
    if (item.type == MediaType.image) {
      return InteractiveViewer(
        child: Image(
          image: item.imageProvider,
          fit: BoxFit.contain,
        ),
      );
    }

    final controller = MediaCacheManager.get(index);
    final hasError = MediaCacheManager.hasError(index);

    return GestureDetector(
      onTap: () => _toggleVideo(index),
      child: Stack(
        alignment: Alignment.center,
        children: [
          /// 封面（防闪）
          Positioned.fill(
            child: item.coverProvider != null
                ? Image(
              image: item.coverProvider!,
              fit: BoxFit.contain,
            )
                : const ColoredBox(color: Colors.black),
          ),

          /// 视频
          if (controller != null && controller.value.isInitialized)
            AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),

          if (controller == null && !hasError)
            const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),

          if (hasError)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.videocam_off_outlined,
                    size: 42,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '视频暂不可预览',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

          /// 播放按钮
          if (controller != null)
            AnimatedOpacity(
              opacity: controller.value.isPlaying ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Icon(
                  controller.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    MediaCacheManager.disposeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// ======================
          /// PageView 核心
          /// ======================
          PageView.builder(
            controller: _controller,
            itemCount: widget.list.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (_, i) => _build(widget.list[i], i),
          ),

          if (widget.list.isEmpty)
            const Center(
              child: Text(
                '暂无可预览内容',
                style: TextStyle(color: Colors.white),
              ),
            ),

          /// 顶部 UI
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                if (widget.list.length > 1)
                  Text(
                    "${_index + 1}/${widget.list.length}",
                    style: const TextStyle(color: Colors.white),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
