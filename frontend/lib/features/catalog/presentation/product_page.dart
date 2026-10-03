import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/ui/app_scope.dart';
import '../../../core/ui/async_view.dart';
import '../../../core/ui/layout.dart';
import '../../../core/ui/product_image.dart';
import '../../../core/ui/star_rating.dart';
import '../../cart/domain/cart.dart';
import '../domain/catalog_query.dart';
import '../domain/product.dart';
import '../domain/review.dart';
import 'product_card.dart';
import 'reviews_section.dart';

class ProductPage extends StatelessWidget {
  const ProductPage({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AsyncView<Product?>(
      key: ValueKey(slug),
      load: () => scope.catalog.getProductBySlug(slug),
      builder: (context, product) {
        if (product == null) {
          return EmptyState(
            title: 'This piece isn\'t in the collection.',
            actionLabel: 'Back to the shop',
            onAction: () => context.go('/shop'),
          );
        }
        return _ProductView(product: product);
      },
    );
  }
}

class _ProductView extends StatefulWidget {
  const _ProductView({required this.product});

  final Product product;

  @override
  State<_ProductView> createState() => _ProductViewState();
}

class _ProductViewState extends State<_ProductView> {
  final _reviewsKey = GlobalKey();
  int _imageIndex = 0;
  late String? _color = widget.product.colors.length == 1
      ? widget.product.colors.first.name
      : null;
  late String? _size = widget.product.sizes.length == 1
      ? widget.product.sizes.first
      : null;
  String? _error;
  bool _added = false;

  Product get product => widget.product;

  void _scrollToReviews() {
    final ctx = _reviewsKey.currentContext;
    if (ctx != null)
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
  }

  void _add({required bool goToBag}) {
    if (product.colors.isNotEmpty && _color == null) {
      setState(() => _error = 'Please choose a colour.');
      return;
    }
    if (_size == null) {
      setState(() => _error = 'Please choose a size.');
      return;
    }
    AppScope.of(context).cart.add(
      CartLine(
        slug: product.slug,
        name: product.name,
        imageUrl: product.imageUrl,
        priceCents: product.priceCents,
        size: _size!,
        color: _color,
        quantity: 1,
      ),
    );
    setState(() {
      _error = null;
      _added = true;
    });
    if (goToBag) context.go('/cart');
  }

  @override
  Widget build(BuildContext context) {
    final desktop = isDesktop(context);
    final mobile = isMobile(context);
    return PageContainer(
      padding: EdgeInsets.symmetric(horizontal: mobile ? 20 : 32, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Breadcrumb(product: product),
          const SizedBox(height: 20),
          desktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 11, child: _gallery(desktop: true)),
                    const SizedBox(width: 56),
                    Expanded(flex: 10, child: _details()),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _gallery(desktop: false),
                    const SizedBox(height: 28),
                    _details(),
                  ],
                ),
          const SizedBox(height: 56),
          Container(
            key: _reviewsKey,
            child: _ReviewsLoader(product: product),
          ),
          const SizedBox(height: 72),
          _Related(product: product),
        ],
      ),
    );
  }

  Widget _gallery({required bool desktop}) {
    final images = product.gallery;
    final index = _imageIndex.clamp(0, images.length - 1);
    final main = AspectRatio(
      aspectRatio: 4 / 5,
      child: ProductImage(url: images[index], semanticLabel: product.name),
    );
    Widget thumb(int i, double size) => Semantics(
      button: true,
      selected: i == index,
      label: 'Photo ${i + 1} of ${images.length}',
      child: InkWell(
        onTap: () => setState(() => _imageIndex = i),
        child: Container(
          width: size,
          height: size * 1.25,
          decoration: BoxDecoration(
            border: Border.all(
              color: i == index ? AppColors.ink : AppColors.line,
              width: i == index ? 2 : 1,
            ),
          ),
          child: ProductImage(url: images[i]),
        ),
      ),
    );
    if (desktop && images.length > 1) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              for (var i = 0; i < images.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: thumb(i, 72),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(child: main),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        main,
        if (images.length > 1) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [for (var i = 0; i < images.length; i++) thumb(i, 64)],
          ),
        ],
      ],
    );
  }

  Widget _details() {
    final soldOut = product.stockLevel == StockLevel.soldOut;
    final mobile = isMobile(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(product.categoryName.toUpperCase(), style: AppText.eyebrow()),
        const SizedBox(height: 10),
        Text(product.name, style: AppText.display(mobile ? 38 : 52)),
        const SizedBox(height: 14),
        if (product.ratingCount > 0)
          InkWell(
            onTap: _scrollToReviews,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StarRating(rating: product.ratingAvg),
                const SizedBox(width: 8),
                Text(
                  '${product.ratingAvg.toStringAsFixed(1)} · ${product.ratingCount} review${product.ratingCount == 1 ? '' : 's'}',
                  style: AppText.body(
                    size: 14,
                    color: AppColors.inkSoft,
                  ).copyWith(decoration: TextDecoration.underline),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Text(
          formatMoney(product.priceCents),
          style: AppText.body(
            size: 26,
            color: AppColors.ink,
            weight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 28),
        const Divider(),
        if (product.colors.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'COLOUR  ', style: AppText.eyebrow()),
                TextSpan(
                  text: _color ?? 'Select a colour',
                  style: AppText.body(
                    size: 14,
                    color: AppColors.ink,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final c in product.colors)
                _Swatch(
                  color: c,
                  selected: _color == c.name,
                  onTap: () => setState(() {
                    _color = c.name;
                    _error = null;
                    _added = false;
                  }),
                ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        if (product.sizes.length > 1) ...[
          Text('SIZE', style: AppText.eyebrow()),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in product.sizes)
                Semantics(
                  button: true,
                  selected: _size == s,
                  label: 'Size $s',
                  child: InkWell(
                    onTap: () => setState(() {
                      _size = s;
                      _error = null;
                      _added = false;
                    }),
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 52,
                        minHeight: 48,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: _size == s ? AppColors.ink : AppColors.paper,
                        border: Border.all(
                          color: _size == s ? AppColors.ink : AppColors.line,
                        ),
                      ),
                      child: Align(
                        widthFactor: 1,
                        heightFactor: 1,
                        child: Text(
                          s,
                          style: AppText.body(
                            size: 14,
                            color: _size == s
                                ? AppColors.background
                                : AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
        if (product.stockLevel == StockLevel.low)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              'Only ${product.stock} left.',
              style: AppText.body(size: 14, color: AppColors.danger),
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: AppText.body(size: 14, color: AppColors.danger),
              ),
            ),
          ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 230,
              child: FilledButton(
                onPressed: soldOut ? null : () => _add(goToBag: false),
                child: Text(soldOut ? 'SOLD OUT' : 'ADD TO BAG'),
              ),
            ),
            SizedBox(
              width: 230,
              child: OutlinedButton(
                onPressed: soldOut ? null : () => _add(goToBag: true),
                child: const Text('BUY NOW'),
              ),
            ),
          ],
        ),
        Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _added ? 'Added to your bag.' : '',
              style: AppText.body(size: 14, color: AppColors.success),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _Info(
          title: 'Description',
          initiallyExpanded: true,
          child: Text(product.description, style: AppText.body(size: 15)),
        ),
        _Info(
          title: 'Product details',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Detail('Category', product.categoryName),
              if (product.colors.isNotEmpty)
                _Detail(
                  'Colours',
                  product.colors.map((c) => c.name).join(', '),
                ),
              _Detail('Sizes', product.sizes.join(', ')),
            ],
          ),
        ),
        _Info(
          title: 'Shipping & returns',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Free shipping on orders over \$250. Standard delivery takes 3-7 business days.',
                style: AppText.body(size: 15),
              ),
              const SizedBox(height: 8),
              Text(
                '30-day returns on unworn items with tags attached.',
                style: AppText.body(size: 15),
              ),
              TextButton(
                onPressed: () => context.go('/policies/shipping-returns'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                child: Text(
                  'Full policy',
                  style: AppText.body(size: 14, color: AppColors.goldDeep),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    Widget link(String label, String to) => TextButton(
      onPressed: () => context.go(to),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 32),
      ),
      child: Text(label.toUpperCase(), style: AppText.eyebrow()),
    );
    return Row(
      children: [
        link('Shop', '/shop'),
        Text(' / ', style: AppText.eyebrow()),
        link(product.categoryName, '/shop?category=${product.categorySlug}'),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final ProductColor color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Colour ${color.name}',
      child: Tooltip(
        message: color.name,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.ink : AppColors.line,
                width: selected ? 2 : 1,
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.fromHex(color.hex),
                border: Border.all(color: AppColors.line),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  final String title;
  final Widget child;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: AppColors.line),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 16),
        expandedAlignment: Alignment.centerLeft,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: AppColors.ink,
        collapsedIconColor: AppColors.ink,
        title: Text(
          title.toUpperCase(),
          style: AppText.button().copyWith(
            color: AppColors.ink,
            letterSpacing: 2.2,
          ),
        ),
        children: [child],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: AppText.body(size: 14, color: AppColors.inkMuted),
          ),
          TextSpan(
            text: value,
            style: AppText.body(size: 14, color: AppColors.ink),
          ),
        ],
      ),
    ),
  );
}

class _ReviewsLoader extends StatelessWidget {
  const _ReviewsLoader({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AsyncView<List<Review>>(
      key: ValueKey('reviews-${product.slug}'),
      minHeight: 160,
      load: () => scope.reviews.listForProduct(product.slug),
      builder: (context, reviews) =>
          ReviewsSection(product: product, reviews: reviews),
    );
  }
}

/// More from the same category (excludes the current item).
class _Related extends StatelessWidget {
  const _Related({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AsyncView<List<Product>>(
      key: ValueKey('related-${product.slug}'),
      minHeight: 120,
      load: () => scope.catalog.listProducts(
        CatalogQuery(categorySlug: product.categorySlug),
      ),
      builder: (context, all) {
        final related = all
            .where((p) => p.slug != product.slug)
            .take(8)
            .toList();
        if (related.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    'More from ${product.categoryName}',
                    style: AppText.display(isMobile(context) ? 30 : 38),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      context.go('/shop?category=${product.categorySlug}'),
                  child: Text('VIEW ALL', style: AppText.eyebrow()),
                ),
              ],
            ),
            const SizedBox(height: 28),
            ProductGrid(products: related),
          ],
        );
      },
    );
  }
}
