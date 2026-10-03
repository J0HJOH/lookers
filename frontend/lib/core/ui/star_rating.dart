import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Five stars, filled to [rating] (supports halves).
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.rating, this.size = 16});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${rating.toStringAsFixed(1)} out of 5 stars',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 1; i <= 5; i++)
              Icon(
                rating >= i - 0.25
                    ? Icons.star
                    : (rating >= i - 0.75
                          ? Icons.star_half
                          : Icons.star_border),
                size: size,
                color: AppColors.goldDeep,
              ),
          ],
        ),
      ),
    );
  }
}
