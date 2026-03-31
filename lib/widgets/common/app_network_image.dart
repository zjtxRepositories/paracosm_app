import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AppNetworkImage extends StatelessWidget {
  final String? url;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width = 40,
    this.height = 40,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  bool get _isValidUrl {
    return url != null && url!.isNotEmpty && url!.startsWith('http');
  }

  @override
  Widget build(BuildContext context) {
    Widget image;

    /// ❗无效URL直接走兜底（避免请求空URL）
    if (!_isValidUrl) {
      image = _buildError();
    } else {
      image = CachedNetworkImage(
        imageUrl: url!,
        width: width,
        height: height,
        fit: fit,

        /// 加载中
        placeholder: (_, __) =>
        placeholder ?? _defaultPlaceholder(),

        /// 加载失败
        errorWidget: (_, __, ___) => _buildError(),
      );
    }

    /// 圆角处理
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.all(Radius.circular((width/2))),
      child: image,
    );

    return image;
  }

  /// 默认加载中
  Widget _defaultPlaceholder() {
    return SizedBox(
      width: width,
      height: height,
      child: const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      ),
    );
  }

  /// 默认错误图
  Widget _buildError() {
    return errorWidget ??
        SizedBox(
          width: width,
          height: height,
          child: const Icon(
            Icons.image_not_supported,
            size: 20,
            color: Colors.grey,
          ),
        );
  }
}