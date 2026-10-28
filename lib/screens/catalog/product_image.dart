import 'package:flutter/material.dart';

/// Network image with a neutral placeholder when the URL is missing or fails.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.maxWidth = 600,
  });

  /// Logical width the image is decoded at (not the full-size original).
  final double maxWidth;

  final String? url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.checkroom,
        size: 40,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
    final u = url;
    if (u == null || u.isEmpty) return placeholder;
    return Image.network(
      u,
      fit: fit,
      cacheWidth: (maxWidth * MediaQuery.devicePixelRatioOf(context)).round(),
      errorBuilder: (_, _, _) => placeholder,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : placeholder,
    );
  }
}
