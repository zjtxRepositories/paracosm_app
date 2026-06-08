import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserAvatarWidget extends StatelessWidget {
  final String? userId;
  final String? avatarUrl;
  final double size;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const UserAvatarWidget({
    super.key,
    required this.userId,
    this.avatarUrl,
    this.size = 40,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = width ?? size;
    final effectiveHeight = height ?? size;
    final radius =
        borderRadius ??
        BorderRadius.circular(
          (effectiveWidth < effectiveHeight
                  ? effectiveWidth
                  : effectiveHeight) /
              2,
        );

    return ClipRRect(
      borderRadius: radius,
      child: _buildImage(width: effectiveWidth, height: effectiveHeight),
    );
  }

  Widget _buildImage({required double width, required double height}) {
    // ✅ 有网络头像
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: avatarUrl!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorWidget: (context, error, stackTrace) =>
            _buildDefaultAvatar(width: width, height: height),
      );
    }

    // ❌ 没头像 → 默认头像
    return _buildDefaultAvatar(width: width, height: height);
  }

  /// 默认头像
  Widget _buildDefaultAvatar({required double width, required double height}) {
    final asset = _getDefaultAvatar(userId ?? '');
    return Image.asset(asset, width: width, height: height, fit: BoxFit.cover);
  }

  /// 👉 你的规则
  String _getDefaultAvatar(String userId) {
    if (userId.isEmpty) return "assets/images/avatar/Avatar (0).png";
    final hash = userId.hashCode;
    final index = hash.abs() % 11;
    return "assets/images/avatar/Avatar ($index).png";
  }
}
