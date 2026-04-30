import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';

class ChatTextMessageContent extends StatelessWidget {
  const ChatTextMessageContent({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: AppTextStyles.body.copyWith(
        color: AppColors.grey900,
        fontSize: 16,
      ),
    );
  }
}

class ChatImageMessageContent extends StatelessWidget {
  const ChatImageMessageContent({
    super.key,
    required this.imagePath,
  });

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 140, maxHeight: 140),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(imagePath, fit: BoxFit.cover),
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
      constraints: const BoxConstraints(
        maxWidth: 140,
        maxHeight: 140,
      ),
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
                child: Container(
                  color: Colors.black.withOpacity(0.25),
                ),
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
                      color: Colors.black.withOpacity(0.6),
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

class _ChatVoiceMessageContentState
    extends State<ChatVoiceMessageContent>
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

    _scale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacity = Tween<double>(begin: 1.0, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
              child: Transform.scale(
                scale: _scale.value,
                child: child,
              ),
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
              SizedBox(width: 180,
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
  const ChatRedBagMessageContent({
    super.key,
    required this.isClaimed,
  });

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
