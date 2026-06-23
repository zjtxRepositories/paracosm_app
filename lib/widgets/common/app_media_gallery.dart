import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';

import '../../core/models/media_item.dart';
import '../../modules/manager/media_cache_manager.dart';
import 'app_action_sheet.dart';

typedef MediaGalleryAction =
    Future<void> Function(int index, MediaItem mediaItem);

class AppMediaGallery extends StatefulWidget {
  final List<MediaItem> list;
  final int initialIndex;
  final MediaGalleryAction? onSave;
  final MediaGalleryAction? onForward;

  const AppMediaGallery({
    super.key,
    required this.list,
    this.initialIndex = 0,
    this.onSave,
    this.onForward,
  });

  @override
  State<AppMediaGallery> createState() => _AppMediaGalleryState();
}

class _AppMediaGalleryState extends State<AppMediaGallery> {
  late PageController _controller;
  late int _index;
  final Map<int, double> _dragPositions = {};
  bool _isSeeking = false;

  @override
  void initState() {
    super.initState();
    final maxIndex = widget.list.isEmpty ? 0 : widget.list.length - 1;
    _index = widget.initialIndex.clamp(0, maxIndex).toInt();
    _controller = PageController(initialPage: _index);

    _preloadAround(_index);
  }

  void _onPageChanged(int index) {
    setState(() {
      _index = index;
    });

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
      return _buildImageViewer(item, index);
    }

    final controller = MediaCacheManager.get(index);
    final hasError = MediaCacheManager.hasError(index);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _toggleVideo(index),
      onLongPress: () => _showMediaActions(index, item),
      child: Stack(
        alignment: Alignment.center,
        children: [
          /// 封面（防闪）
          Positioned.fill(
            child: item.coverProvider != null
                ? Image(image: item.coverProvider!, fit: BoxFit.contain)
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
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.videocam_off_outlined,
                    size: 42,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.commonVideoPreviewUnavailable,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

          if (controller != null && controller.value.isInitialized)
            _VideoPlayButton(controller: controller),

          if (controller != null && controller.value.isInitialized)
            Positioned(
              left: 16,
              right: 16,
              bottom: 28,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: _buildVideoControls(index, controller),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageViewer(MediaItem item, int index) {
    return _DismissibleImageViewer(
      item: item,
      onLongPress: () => _showMediaActions(index, item),
    );
  }

  Widget _buildVideoControls(int index, VideoPlayerController controller) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final duration = value.duration;
        final durationMs = duration.inMilliseconds;
        final currentMs =
            (_dragPositions[index] ??
                    value.position.inMilliseconds
                        .clamp(0, durationMs)
                        .toDouble())
                .clamp(0.0, durationMs.toDouble());
        final currentPosition = Duration(milliseconds: currentMs.round());
        final canSeek = durationMs > 0;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.46),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: () => _toggleVideo(index),
                  ),
                ),
                Text(
                  _formatDuration(currentPosition),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                      overlayColor: Colors.white24,
                    ),
                    child: Slider(
                      min: 0,
                      max: canSeek ? durationMs.toDouble() : 1,
                      value: canSeek ? currentMs : 0,
                      onChangeStart: !canSeek
                          ? null
                          : (next) {
                              setState(() {
                                _isSeeking = true;
                                _dragPositions[index] = next;
                              });
                            },
                      onChanged: !canSeek
                          ? null
                          : (next) {
                              setState(() {
                                _dragPositions[index] = next;
                              });
                            },
                      onChangeEnd: !canSeek
                          ? null
                          : (next) async {
                              try {
                                await controller.seekTo(
                                  Duration(milliseconds: next.round()),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isSeeking = false;
                                    _dragPositions.remove(index);
                                  });
                                }
                              }
                            },
                    ),
                  ),
                ),
                Text(
                  _formatDuration(duration),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showMediaActions(int index, MediaItem item) {
    final actions = <AppActionSheetItem>[];
    final l10n = AppLocalizations.of(context)!;

    if (widget.onSave != null) {
      actions.add(
        AppActionSheetItem(
          label: l10n.commonSave,
          onTap: () => widget.onSave!(index, item),
        ),
      );
    }

    if (widget.onForward != null) {
      actions.add(
        AppActionSheetItem(
          label: l10n.commonForward,
          onTap: () => widget.onForward!(index, item),
        ),
      );
    }

    if (actions.isEmpty) {
      return;
    }

    AppActionSheet.show(context, items: actions);
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
            physics: _isSeeking
                ? const NeverScrollableScrollPhysics()
                : const PageScrollPhysics(),
            itemCount: widget.list.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (_, i) => _build(widget.list[i], i),
          ),

          if (widget.list.isEmpty)
            Center(
              child: Text(
                AppLocalizations.of(context)!.commonNoPreviewContent,
                style: const TextStyle(color: Colors.white),
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

class _VideoPlayButton extends StatelessWidget {
  const _VideoPlayButton({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        return AnimatedOpacity(
          opacity: value.isPlaying ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Icon(
              value.isPlaying ? Icons.pause : Icons.play_arrow,
              size: 34,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

class _DismissibleImageViewer extends StatefulWidget {
  const _DismissibleImageViewer({
    required this.item,
    required this.onLongPress,
  });

  final MediaItem item;
  final VoidCallback onLongPress;

  @override
  State<_DismissibleImageViewer> createState() =>
      _DismissibleImageViewerState();
}

class _DismissibleImageViewerState extends State<_DismissibleImageViewer> {
  final TransformationController _transformationController =
      TransformationController();

  double _dismissDragOffset = 0;
  bool _isDraggingToDismiss = false;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _handleInteractionUpdate(ScaleUpdateDetails details) {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final isZooming = details.pointerCount > 1 || details.scale != 1.0;
    if (isZooming || scale > 1.02) {
      if (_dismissDragOffset != 0 || _isDraggingToDismiss) {
        setState(() {
          _dismissDragOffset = 0;
          _isDraggingToDismiss = false;
        });
      }
      return;
    }

    final delta = details.focalPointDelta;
    if (delta.dy.abs() <= delta.dx.abs() && _dismissDragOffset == 0) {
      return;
    }

    setState(() {
      _isDraggingToDismiss = true;
      _dismissDragOffset = (_dismissDragOffset + delta.dy).clamp(0.0, 600.0);
    });
  }

  void _handleInteractionEnd(ScaleEndDetails details) {
    if (!_isDraggingToDismiss) {
      return;
    }

    final velocity = details.velocity.pixelsPerSecond.dy;
    if (_dismissDragOffset > 120 || velocity > 700) {
      Navigator.of(context).maybePop();
      return;
    }

    setState(() {
      _dismissDragOffset = 0;
      _isDraggingToDismiss = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final opacity = (1 - _dismissDragOffset / 360).clamp(0.35, 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: widget.onLongPress,
      child: AnimatedOpacity(
        opacity: opacity,
        duration: _isDraggingToDismiss
            ? Duration.zero
            : const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: _isDraggingToDismiss
              ? Duration.zero
              : const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _dismissDragOffset, 0),
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 1,
            maxScale: 4,
            onInteractionUpdate: _handleInteractionUpdate,
            onInteractionEnd: _handleInteractionEnd,
            child: Image(image: widget.item.imageProvider, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
