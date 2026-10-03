import 'package:flutter/material.dart';

import '../../../core/formatting/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/ui/layout.dart';
import '../../../core/ui/product_image.dart';
import '../../../core/ui/star_rating.dart';
import '../domain/product.dart';
import '../domain/review.dart';
import '../../../core/ui/neu.dart';

/// Rating summary plus the list of reviews. Each review shows what the customer bought and the
/// variety (colour, size) they chose.
class ReviewsSection extends StatelessWidget {
  const ReviewsSection({
    super.key,
    required this.product,
    required this.reviews,
  });

  final Product product;
  final List<Review> reviews;

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);
    final average = reviews.isEmpty
        ? 0.0
        : reviews.fold<int>(0, (s, r) => s + r.rating) / reviews.length;
    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          reviews.isEmpty ? '–' : average.toStringAsFixed(1),
          style: AppText.display(64),
        ),
        StarRating(rating: average, size: 20),
        const SizedBox(height: 6),
        Text(
          '${reviews.length} review${reviews.length == 1 ? '' : 's'}',
          style: AppText.body(size: 14, color: AppColors.inkMuted),
        ),
        const SizedBox(height: 16),
        _Distribution(reviews: reviews),
      ],
    );
    final list = reviews.isEmpty
        ? Text(
            'No reviews yet.',
            style: AppText.body(color: AppColors.inkMuted),
          )
        : Column(
            children: [
              for (final r in reviews) _ReviewTile(review: r, product: product),
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text('Customer reviews', style: AppText.display(mobile ? 32 : 40)),
        const SizedBox(height: 28),
        mobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [summary, const SizedBox(height: 28), list],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 280, child: summary),
                  const SizedBox(width: 56),
                  Expanded(child: list),
                ],
              ),
      ],
    );
  }
}

class _Distribution extends StatelessWidget {
  const _Distribution({required this.reviews});

  final List<Review> reviews;

  @override
  Widget build(BuildContext context) {
    final shares = ratingDistribution(reviews);
    return Column(
      children: [
        for (var star = 5; star >= 1; star--)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '$star ★',
                    style: AppText.body(size: 13, color: AppColors.inkSoft),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: shares[star - 1],
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review, required this.product});

  final Review review;
  final Product product;

  @override
  Widget build(BuildContext context) {
    final initial = review.authorName.isEmpty
        ? '?'
        : review.authorName[0].toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: NeuBox(
        radius: 24,
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.surface,
                  child: Text(
                    initial,
                    style: AppText.body(
                      color: AppColors.ink,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    review.authorName,
                    style: AppText.body(
                      color: AppColors.ink,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  formatDate(review.createdAt),
                  style: AppText.body(size: 13, color: AppColors.inkMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StarRating(rating: review.rating.toDouble()),
            if (review.title.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                review.title,
                style: AppText.body(
                  color: AppColors.ink,
                  weight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(review.body, style: AppText.body(size: 15)),
            const SizedBox(height: 14),
            // What this customer bought, with the variety they chose.
            NeuBox(
              inset: true,
              radius: 16,
              depth: 0.5,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 52,
                    child: ProductImage(url: product.imageUrl, radius: 10),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PURCHASED',
                          style: AppText.eyebrow().copyWith(
                            fontSize: 10,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          product.name,
                          style: AppText.body(
                            size: 14,
                            color: AppColors.ink,
                            weight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          [
                            if (review.color != null) 'Colour: ${review.color}',
                            if (review.size != null) 'Size: ${review.size}',
                          ].join('  ·  '),
                          style: AppText.body(
                            size: 13,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
