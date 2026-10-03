import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/ui/layout.dart';
import '../../../core/ui/product_image.dart';
import '../../../core/ui/star_rating.dart';
import '../domain/product.dart';

class ProductCard extends StatefulWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  /// Height of the text block under the 3:4 photo.
  static const textHeight = 118.0;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final badge = switch (p.stockLevel) {
      StockLevel.soldOut => 'Sold out',
      StockLevel.low => 'Few left',
      StockLevel.inStock => null,
    };
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Semantics(
        button: true,
        label:
            '${p.name}, ${formatMoney(p.priceCents)}${badge == null ? '' : ', $badge'}',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.go('/product/${p.slug}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 3 / 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRect(
                      child: AnimatedScale(
                        scale: _hover ? 1.05 : 1,
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        child: ProductImage(url: p.imageUrl),
                      ),
                    ),
                    if (badge != null)
                      Positioned(
                        left: 12,
                        top: 12,
                        child: Container(
                          color: AppColors.paper,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          child: Text(
                            badge.toUpperCase(),
                            style: AppText.eyebrow(
                              color: AppColors.ink,
                            ).copyWith(fontSize: 10, letterSpacing: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                height: ProductCard.textHeight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.categoryName.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.eyebrow().copyWith(
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.display(
                                isMobile(context) ? 19 : 22,
                              ),
                            ),
                            if (p.ratingCount > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  StarRating(rating: p.ratingAvg, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${p.ratingAvg.toStringAsFixed(1)} (${p.ratingCount})',
                                    style: AppText.body(
                                      size: 12,
                                      color: AppColors.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          formatMoney(p.priceCents),
                          style: AppText.body(size: 14, color: AppColors.ink),
                        ),
                      ),
                    ],
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

/// Responsive grid of product cards (2 / 3 / 4 columns).
class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key, required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = gridColumns(constraints.maxWidth);
        const gap = 16.0;
        final cellWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: gap,
            mainAxisSpacing: 32,
            mainAxisExtent: cellWidth * 4 / 3 + ProductCard.textHeight,
          ),
          itemBuilder: (context, i) => ProductCard(product: products[i]),
        );
      },
    );
  }
}
