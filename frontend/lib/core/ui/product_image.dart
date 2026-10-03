import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Network photo with a calm placeholder while loading and a quiet fallback on error.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.semanticLabel,
    this.radius = 16,
  });

  final String url;
  final BoxFit fit;
  final String? semanticLabel;

  /// Corner radius. Neumorphic surfaces are soft, so photos are rounded too.
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: ColoredBox(
        color: AppColors.surface,
        child: Image.network(
          url,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          semanticLabel: semanticLabel,
          excludeFromSemantics: semanticLabel == null,
          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
          frameBuilder: (context, child, frame, wasSync) {
            if (wasSync) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 400),
              child: child,
            );
          },
          errorBuilder: (context, error, stack) => Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: AppColors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}
