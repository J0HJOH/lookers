import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/ui/app_scope.dart';
import '../../../core/ui/async_view.dart';
import '../../../core/ui/layout.dart';
import '../../../core/ui/logo.dart';
import '../../../core/ui/product_image.dart';
import '../domain/category.dart';
import '../domain/product.dart';
import 'product_card.dart';
import '../../../core/ui/neu.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (scope.isPreview) const _PreviewBanner(),
        AsyncView<List<Category>>(
          load: scope.catalog.listCategories,
          builder: (context, categories) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Hero(category: categories.isEmpty ? null : categories.first),
              _CategoryGrid(categories: categories),
            ],
          ),
        ),
        AsyncView<List<Product>>(
          load: scope.catalog.listProducts,
          builder: (context, products) => _Featured(
            products: products.where((p) => p.featured).take(8).toList(),
          ),
        ),
        const _Perks(),
      ],
    );
  }
}

class _PreviewBanner extends StatelessWidget {
  const _PreviewBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryDeep,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        'PREVIEW MODE: SUPABASE ISN\'T CONNECTED YET, SO THIS IS THE BUNDLED SAMPLE CATALOGUE. SEE docs/SETUP.md.',
        textAlign: TextAlign.center,
        style: AppText.eyebrow(
          color: AppColors.onPrimary,
        ).copyWith(letterSpacing: 2),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.category});

  final Category? category;

  @override
  Widget build(BuildContext context) {
    final desktop = isDesktop(context);
    final headline = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('THE NEW COLLECTION', style: AppText.eyebrow()),
        const SizedBox(height: 20),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Dressed with\n'),
              TextSpan(
                text: 'intent.',
                style: AppText.display(
                  desktop ? 88 : 60,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          style: AppText.display(desktop ? 88 : 60),
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Text(
            'Men, women and little ones. Tailoring, knitwear and the finishing pieces, hats, shoes and bags, chosen to be worn and kept.',
            style: AppText.body(size: 16),
          ),
        ),
        const SizedBox(height: 36),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            NeuButton(
              onPressed: () => context.go('/shop'),
              child: const Text('SHOP THE COLLECTION'),
            ),
            NeuButton.secondary(
              onPressed: () => context.go('/shop?category=womens-clothing'),
              child: const Text('WOMEN'),
            ),
          ],
        ),
      ],
    );
    final photo = NeuBox(
      radius: 36,
      padding: const EdgeInsets.all(14),
      child: AspectRatio(
        aspectRatio: desktop ? 3 / 4 : 4 / 5,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (category != null)
              ProductImage(
                url: category!.imageUrl,
                semanticLabel: 'Lookers collection',
                radius: 26,
              )
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
            const Positioned(left: 20, bottom: 20, child: _LogoBadge()),
          ],
        ),
      ),
    );
    return PageContainer(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile(context) ? 20 : 32,
        vertical: desktop ? 56 : 32,
      ),
      child: desktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: headline),
                const SizedBox(width: 64),
                Expanded(child: photo),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [headline, const SizedBox(height: 40), photo],
            ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) => const NeuBox(
    radius: 20,
    depth: 0.6,
    padding: EdgeInsets.all(12),
    child: Logo(size: 38),
  );
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    return PageContainer(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile(context) ? 20 : 32,
        vertical: 56,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Shop by category',
                style: AppText.display(isMobile(context) ? 34 : 48),
              ),
              TextButton(
                onPressed: () => context.go('/shop'),
                child: Text('VIEW ALL', style: AppText.eyebrow()),
              ),
            ],
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, c) {
              final columns = c.maxWidth < 700 ? 2 : 3;
              const gap = 16.0;
              final cell = (c.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final cat in categories)
                    SizedBox(
                      width: cell,
                      height: cell * 1.25,
                      child: _CategoryTile(category: cat),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${category.name}. ${category.tagline}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => context.go('/shop?category=${category.slug}'),
          child: NeuBox(
            radius: 30,
            padding: const EdgeInsets.all(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductImage(url: category.imageUrl, radius: 24),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                        colors: [
                          AppColors.photoScrim,
                          AppColors.photoScrimClear,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          category.name,
                          style: AppText.display(
                            isMobile(context) ? 19 : 32,
                            color: AppColors.onPhoto,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category.tagline.toUpperCase(),
                          maxLines: 2,
                          style: AppText.eyebrow(
                            color: AppColors.onPhoto,
                          ).copyWith(letterSpacing: 1.8),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Featured extends StatelessWidget {
  const _Featured({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    return PageContainer(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile(context) ? 20 : 32,
        vertical: 40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Featured pieces',
            style: AppText.display(isMobile(context) ? 34 : 48),
          ),
          const SizedBox(height: 32),
          ProductGrid(products: products),
        ],
      ),
    );
  }
}

class _Perks extends StatelessWidget {
  const _Perks();

  @override
  Widget build(BuildContext context) {
    const perks = [
      ('Free shipping', 'On orders over \$250.'),
      ('Easy returns', '30 days, unworn, no fuss.'),
      ('Secure checkout', 'Your details stay protected.'),
    ];
    final mobile = isMobile(context);
    final items = [
      for (final p in perks)
        Padding(
          padding: EdgeInsets.symmetric(vertical: mobile ? 16 : 0),
          child: Column(
            children: [
              Text(
                p.$1,
                style: AppText.display(26, color: AppColors.onPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                p.$2,
                style: AppText.body(size: 14, color: AppColors.onPrimary),
              ),
            ],
          ),
        ),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(mobile ? 20 : 32, 56, mobile ? 20 : 32, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1216),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryDeep, AppColors.primary],
              ),
              boxShadow: Neu.raised(),
            ),
            child: mobile
                ? Column(children: items)
                : Row(children: [for (final i in items) Expanded(child: i)]),
          ),
        ),
      ),
    );
  }
}
