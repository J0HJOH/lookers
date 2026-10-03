import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/ui/app_scope.dart';
import '../../../core/ui/async_view.dart';
import '../../../core/ui/layout.dart';
import '../domain/catalog_query.dart';
import '../domain/category.dart';
import '../domain/product.dart';
import 'product_card.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({
    super.key,
    this.categorySlug,
    this.search,
    this.sort = SortKey.newest,
  });

  final String? categorySlug;
  final String? search;
  final SortKey sort;

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  late final _searchController = TextEditingController(text: widget.search);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigate({String? category, String? search, SortKey? sort}) {
    final params = <String, String>{
      'category': ?category,
      if ((search ?? '').trim().isNotEmpty) 'q': search!.trim(),
      if (sort != null && sort != SortKey.newest) 'sort': sort.param,
    };
    context.go(
      Uri(
        path: '/shop',
        queryParameters: params.isEmpty ? null : params,
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final query = CatalogQuery(
      categorySlug: widget.categorySlug,
      search: widget.search,
      sort: widget.sort,
    );
    final mobile = isMobile(context);

    return PageContainer(
      padding: EdgeInsets.symmetric(horizontal: mobile ? 20 : 32, vertical: 48),
      child: AsyncView<List<Category>>(
        load: scope.catalog.listCategories,
        builder: (context, categories) {
          Category? active;
          for (final c in categories) {
            if (c.slug == widget.categorySlug) active = c;
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                active == null ? 'COLLECTION' : 'CATEGORY',
                style: AppText.eyebrow(),
              ),
              const SizedBox(height: 12),
              Text(
                active?.name ?? 'All pieces',
                style: AppText.display(mobile ? 44 : 60),
              ),
              if (active != null) ...[
                const SizedBox(height: 10),
                Text(
                  active.tagline,
                  style: AppText.body(color: AppColors.inkMuted),
                ),
              ],
              const SizedBox(height: 32),
              Container(
                decoration: const BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(color: AppColors.line),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: mobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _categoryLinks(categories),
                          const SizedBox(height: 16),
                          _controls(true),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: _categoryLinks(categories)),
                          _controls(false),
                        ],
                      ),
              ),
              const SizedBox(height: 40),
              AsyncView<List<Product>>(
                // A new key re-runs the query whenever the filters change.
                key: ValueKey(
                  '${widget.categorySlug}|${widget.search}|${widget.sort.param}',
                ),
                load: () => scope.catalog.listProducts(query),
                builder: (context, products) => products.isEmpty
                    ? EmptyState(
                        title: 'Nothing found.',
                        message: 'Try another category or search.',
                        actionLabel: 'Clear filters',
                        onAction: () => context.go('/shop'),
                      )
                    : ProductGrid(products: products),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _categoryLinks(List<Category> categories) {
    Widget link(String label, String? slug) {
      final selected = widget.categorySlug == slug;
      return Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: () => _navigate(
            category: slug,
            search: widget.search,
            sort: widget.sort,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              label.toUpperCase(),
              style: AppText.button().copyWith(
                color: selected ? AppColors.goldDeep : AppColors.inkSoft,
                letterSpacing: 2.2,
              ),
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 24,
      runSpacing: 4,
      children: [
        link('All', null),
        for (final c in categories) link(c.name, c.slug),
      ],
    );
  }

  Widget _controls(bool mobile) {
    final search = SizedBox(
      width: mobile ? double.infinity : 200,
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(hintText: 'Search', isDense: true),
        textInputAction: TextInputAction.search,
        onSubmitted: (v) => _navigate(
          category: widget.categorySlug,
          search: v,
          sort: widget.sort,
        ),
      ),
    );
    final sort = SizedBox(
      width: mobile ? double.infinity : 210,
      child: DropdownButtonFormField<SortKey>(
        key: ValueKey(widget.sort),
        initialValue: widget.sort,
        isDense: true,
        isExpanded: true,
        decoration: const InputDecoration(isDense: true),
        items: [
          for (final s in SortKey.values)
            DropdownMenuItem(
              value: s,
              child: Text(
                s.label,
                style: AppText.body(size: 14, color: AppColors.ink),
              ),
            ),
        ],
        onChanged: (s) => _navigate(
          category: widget.categorySlug,
          search: _searchController.text,
          sort: s,
        ),
      ),
    );
    return mobile
        ? Column(children: [search, const SizedBox(height: 12), sort])
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [search, const SizedBox(width: 12), sort],
          );
  }
}
