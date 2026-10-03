import 'product.dart';

enum SortKey {
  newest('newest', 'Newest'),
  priceAsc('price-asc', 'Price: low to high'),
  priceDesc('price-desc', 'Price: high to low');

  const SortKey(this.param, this.label);
  final String param;
  final String label;

  static SortKey fromParam(String? value) => SortKey.values.firstWhere(
    (s) => s.param == value,
    orElse: () => SortKey.newest,
  );
}

class CatalogQuery {
  const CatalogQuery({
    this.categorySlug,
    this.search,
    this.sort = SortKey.newest,
  });

  final String? categorySlug;
  final String? search;
  final SortKey sort;
}

/// Pure filter + sort, used for the preview catalogue (Supabase does the same in SQL).
List<Product> applyCatalogQuery(List<Product> products, CatalogQuery query) {
  final term = query.search?.trim().toLowerCase();
  final result = products.where((p) {
    if (!p.active) return false;
    if (query.categorySlug != null && p.categorySlug != query.categorySlug)
      return false;
    if (term != null && term.isNotEmpty) {
      return p.name.toLowerCase().contains(term) ||
          p.description.toLowerCase().contains(term);
    }
    return true;
  }).toList();
  switch (query.sort) {
    case SortKey.priceAsc:
      result.sort((a, b) => a.priceCents.compareTo(b.priceCents));
    case SortKey.priceDesc:
      result.sort((a, b) => b.priceCents.compareTo(a.priceCents));
    case SortKey.newest:
      break;
  }
  return result;
}
