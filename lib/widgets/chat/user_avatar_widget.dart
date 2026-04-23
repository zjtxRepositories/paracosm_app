import 'package:flutter/material.dart';

class UserAvatarWidget extends StatelessWidget {
  final String? userId;
  final String? avatarUrl;
  final double size;
  final BorderRadius? borderRadius;

  const UserAvatarWidget({
    super.key,
    required this.userId,
    this.avatarUrl,
    this.size = 40,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size / 2);

    return ClipRRect(
      borderRadius: radius,
      child: _buildImage(),
    );
  }

  Widget _buildImage() {
    // ✅ 有网络头像
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return Image.network(
        avatarUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _buildDefaultAvatar();
        },
      );
    }

    // ❌ 没头像 → 默认头像
    return _buildDefaultAvatar();
  }

  /// 默认头像
  Widget _buildDefaultAvatar() {
    final asset = _getDefaultAvatar(userId ?? '');
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }

  /// 👉 你的规则
  String _getDefaultAvatar(String userId) {
    if (userId.isEmpty) return "assets/images/avatar/Avatar (0).png";
    final hash = userId.hashCode;
    final index = hash.abs() % 11;
    return "assets/images/avatar/Avatar ($index).png";
  }
}