import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'image_proxy.dart';

class SafeNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildPlaceholder();
    }

    // On web, CDN photos come through the API (see ImageProxy), at about twice the
    // displayed width so they stay sharp on high-density screens.
    final url = ImageProxy.resolve(
      imageUrl,
      width: ((width ?? 400) * 2).round(),
    );

    // On Web, use Image.network to avoid CORS issues with cached_network_image
    // and leverage browser caching.
    if (const bool.fromEnvironment('dart.library.js_util')) {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey.shade100,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading image $imageUrl: $error');
          return _buildPlaceholder();
        },
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Container(
        color: Colors.grey.shade100,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade100,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Colors.grey.shade400,
        size: 32,
      ),
    );
  }
}
