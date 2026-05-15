import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';

class ChatTextMessageContent extends StatelessWidget {
  const ChatTextMessageContent({
    super.key,
    required this.message,
    this.quoteText,
    this.onQuoteTap,
  });

  final String message;
  final String? quoteText;
  final VoidCallback? onQuoteTap;

  @override
  Widget build(BuildContext context) {
    final quote = quoteText?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (quote != null && quote.isNotEmpty) ...[
          _ChatQuotePreview(text: quote, onTap: onQuoteTap),
          const SizedBox(height: 8),
        ],
        Text(
          message,
          style: AppTextStyles.body.copyWith(
            color: AppColors.grey900,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _ChatQuotePreview extends StatelessWidget {
  const _ChatQuotePreview({required this.text, this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
        border: const Border(
          left: BorderSide(color: AppColors.grey400, width: 3),
        ),
      ),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.grey500,
          fontSize: 12,
        ),
      ),
    );

    if (onTap == null) {
      return child;
    }

    return GestureDetector(onTap: onTap, child: child);
  }
}

class ChatImageMessageContent extends StatefulWidget {
  const ChatImageMessageContent({
    super.key,
    required this.imagePath,
    this.remoteUrl,
    this.thumbnailBase64String,
  });

  final String imagePath;
  final String? remoteUrl;
  final String? thumbnailBase64String;

  @override
  State<ChatImageMessageContent> createState() =>
      _ChatImageMessageContentState();
}

class _ChatImageMessageContentState extends State<ChatImageMessageContent> {
  static const double _maxSize = 180;
  static const Size _placeholderSize = Size(_maxSize, _maxSize);

  ImageProvider? _provider;
  List<ImageProvider> _providers = const [];
  int _providerIndex = 0;
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;
  Size? _imageSize;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant ChatImageMessageContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.imagePath != widget.imagePath ||
        oldWidget.remoteUrl != widget.remoteUrl ||
        oldWidget.thumbnailBase64String != widget.thumbnailBase64String) {
      _resolveImage();
    }
  }

  @override
  void dispose() {
    _removeImageListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = _provider;
    final size = _imageSize == null
        ? _placeholderSize
        : _fitImageSize(_imageSize!);

    return SizedBox(
      width: size.width,
      height: size.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: provider == null || _loadFailed
            ? _buildError()
            : _imageSize == null
                ? _buildPlaceholder()
                : Image(
                    image: provider,
                    width: size.width,
                    height: size.height,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (context, error, stackTrace) =>
                        _useNextImageProviderInline(),
                  ),
      ),
    );
  }

  void _resolveImage() {
    _removeImageListener();

    final providers = _createImageProviders();
    final provider = providers.isEmpty ? null : providers.first;
    setState(() {
      _providers = providers;
      _providerIndex = 0;
      _provider = provider;
      _imageSize = null;
      _loadFailed = provider == null;
    });

    if (provider == null) {
      return;
    }

    _listenToProvider(provider);
  }

  List<ImageProvider> _createImageProviders() {
    final providers = <ImageProvider>[];

    final localPath = widget.imagePath.trim();
    if (localPath.isNotEmpty) {
      final file = File(localPath);
      if (file.existsSync()) {
        providers.add(FileImage(file));
      }
    }

    final url = widget.remoteUrl?.trim();
    if (url != null &&
        url.isNotEmpty &&
        (url.startsWith('http://') || url.startsWith('https://'))) {
      providers.add(CachedNetworkImageProvider(url));
    }

    final thumbnail = widget.thumbnailBase64String?.trim();
    if (thumbnail != null && thumbnail.isNotEmpty) {
      try {
        providers.add(MemoryImage(base64Decode(thumbnail)));
      } catch (_) {}
    }

    return providers;
  }

  void _useNextImageProvider() {
    if (!mounted) {
      return;
    }

    _removeImageListener();

    final nextIndex = _providerIndex + 1;
    if (nextIndex >= _providers.length) {
      setState(() {
        _provider = null;
        _imageSize = null;
        _loadFailed = true;
      });
      return;
    }

    setState(() {
      _providerIndex = nextIndex;
      _provider = _providers[nextIndex];
      _imageSize = null;
      _loadFailed = false;
    });

    _listenToProvider(_providers[nextIndex]);
  }

  Widget _useNextImageProviderInline() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _useNextImageProvider();
    });

    return _buildPlaceholder();
  }

  Size _fitImageSize(Size imageSize) {
    if (imageSize.width <= 0 || imageSize.height <= 0) {
      return _placeholderSize;
    }

    final ratio = imageSize.width / imageSize.height;
    if (ratio >= 1) {
      return Size(_maxSize, _maxSize / ratio);
    }

    return Size(_maxSize * ratio, _maxSize);
  }

  void _removeImageListener() {
    final stream = _imageStream;
    final listener = _imageStreamListener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    _imageStream = null;
    _imageStreamListener = null;
  }

  void _listenToProvider(ImageProvider provider) {
    final stream = provider.resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener(
      (imageInfo, synchronousCall) {
        final nextSize = Size(
          imageInfo.image.width.toDouble(),
          imageInfo.image.height.toDouble(),
        );
        if (!mounted) {
          return;
        }

        setState(() {
          _imageSize = nextSize;
          _loadFailed = false;
        });
      },
      onError: (error, stackTrace) {
        _useNextImageProvider();
      },
    );

    _imageStream = stream;
    _imageStreamListener = listener;
    stream.addListener(listener);
  }

  Widget _buildPlaceholder() {
    return const ColoredBox(
      color: Color(0xFFF3F4F6),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 1.6),
        ),
      ),
    );
  }

  Widget _buildError() {
    return const ColoredBox(
      color: Color(0xFFF3F4F6),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.grey400,
          size: 28,
        ),
      ),
    );
  }
}

class ChatVideoMessageContent extends StatelessWidget {
  const ChatVideoMessageContent({
    super.key,
    required this.thumbnailBase64String,
    this.duration,
    this.onTap,
  });

  final String thumbnailBase64String;
  final String? duration;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 140, maxHeight: 140),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              /// 🎬 缩略图
              Positioned.fill(
                child: Image.memory(
                  base64Decode(thumbnailBase64String),
                  fit: BoxFit.cover,
                ),
              ),

              /// 🌫️ 遮罩层（增强对比）
              Positioned.fill(
                child: Container(color: Colors.black.withValues(alpha: 0.25)),
              ),

              /// ▶️ 播放按钮
              const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  size: 42,
                  color: Colors.white,
                ),
              ),

              /// ⏱️ 时长（微信风格：右下角）
              if (duration != null)
                Positioned(
                  right: 6,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      duration ?? '0.00',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatVoiceMessageContent extends StatefulWidget {
  const ChatVoiceMessageContent({
    super.key,
    required this.duration,
    this.isPlaying = false,
  });

  final String duration;
  final bool isPlaying;

  @override
  State<ChatVoiceMessageContent> createState() =>
      _ChatVoiceMessageContentState();
}

class _ChatVoiceMessageContentState extends State<ChatVoiceMessageContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scale = Tween<double>(
      begin: 0.9,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacity = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant ChatVoiceMessageContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }

    if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = Image.asset(
      'assets/images/chat/voice.png',
      width: 18,
      height: 28,
      color: AppColors.grey900,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.isPlaying
            ? AnimatedBuilder(
                animation: _controller,
                builder: (_, child) {
                  return Opacity(
                    opacity: _opacity.value,
                    child: Transform.scale(scale: _scale.value, child: child),
                  );
                },
                child: icon,
              )
            : icon,

        const SizedBox(width: 10),

        Text(
          widget.duration,
          style: AppTextStyles.body.copyWith(
            color: AppColors.grey900,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class ChatCallMessageContent extends StatelessWidget {
  const ChatCallMessageContent({
    super.key,
    required this.text,
    required this.isVideo,
    required this.isMe,
  });

  final String text;
  final bool isVideo;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final iconPath = isVideo
        ? 'assets/images/chat/video.png'
        : (isMe
              ? 'assets/images/chat/self-call.png'
              : 'assets/images/chat/other-call.png');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isMe) ...[
          Image.asset(iconPath, width: 18, height: 18),
          const SizedBox(width: 10),
          Text(
            text,
            style: AppTextStyles.body.copyWith(
              color: AppColors.grey900,
              fontSize: 14,
            ),
          ),
        ] else ...[
          Text(
            text,
            style: AppTextStyles.body.copyWith(
              color: AppColors.grey900,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 10),
          Image.asset(
            iconPath,
            width: 18,
            height: 18,
            color: AppColors.grey900,
          ),
        ],
      ],
    );
  }
}

class ChatFileMessageContent extends StatelessWidget {
  const ChatFileMessageContent({
    super.key,
    required this.fileName,
    required this.fileSize,
  });

  final String fileName;
  final String fileSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/chat/file.png',
            width: 36,
            height: 36,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 180,
                child: Text(
                  fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.grey900,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                fileSize,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.grey400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChatCombineMessageContent extends StatelessWidget {
  const ChatCombineMessageContent({
    super.key,
    required this.title,
    required this.summaries,
    this.onTap,
  });

  final String title;
  final List<String> summaries;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final visibleSummaries = summaries.take(4).toList();

    final child = SizedBox(
      width: 230,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.grey900,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (visibleSummaries.isEmpty)
            Text(
              '[聊天记录]',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.grey500,
                fontSize: 12,
              ),
            )
          else
            ...visibleSummaries.map(
              (summary) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.grey500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 6),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 6),
          Text(
            '聊天记录',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.grey400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
  }
}

class ChatContactCardMessageContent extends StatelessWidget {
  const ChatContactCardMessageContent({
    super.key,
    required this.name,
    required this.avatarPath,
    required this.footerLabel,
  });

  final String name;
  final String avatarPath;
  final String footerLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  avatarPath,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.grey900,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 6),
          Text(
            footerLabel,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.grey400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class ChatRedBagMessageContent extends StatelessWidget {
  const ChatRedBagMessageContent({super.key, required this.isClaimed});

  final bool isClaimed;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      isClaimed
          ? 'assets/images/chat/redbag-default.png'
          : 'assets/images/chat/redbag-active.png',
      width: 120,
      height: 180,
      fit: BoxFit.contain,
    );
  }
}
