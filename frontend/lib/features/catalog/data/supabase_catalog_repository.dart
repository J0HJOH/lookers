import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/catalog_query.dart';
import '../domain/catalog_repository.dart';
import '../domain/category.dart';
import '../domain/product.dart';
import 'supabase_error_mapper.dart';

const productColumns =
    'id, slug, name, description, price_cents, category_id, image_url, sizes, stock, featured, active, colors, images, rating_avg, rating_count, categories(slug, name)';

/// Parses one database row. Returns null for a malformed row so one bad record
/// can't break a whole page.
Product? productFromRow(Map<String, dynamic> row) {
  try {
    final category = row['categories'] as Map<String, dynamic>?;
    if (category == null) return null;
    return Product(
      id: row['id'] as String,
      slug: row['slug'] as String,
      name: row['name'] as String,
      description: (row['description'] as String?) ?? '',
      priceCents: row['price_cents'] as int,
      categoryId: row['category_id'] as String,
      categorySlug: category['slug'] as String,
      categoryName: category['name'] as String,
      imageUrl: row['image_url'] as String,
      sizes: (row['sizes'] as List<dynamic>).cast<String>(),
      stock: row['stock'] as int,
      featured: row['featured'] as bool,
      active: row['active'] as bool,
      colors: _colorsFrom(row['colors']),
      images: ((row['images'] as List<dynamic>?) ?? const []).cast<String>(),
      ratingAvg: ((row['rating_avg'] as num?) ?? 0).toDouble(),
      ratingCount: (row['rating_count'] as int?) ?? 0,
    );
  } on TypeError {
    return null;
  }
}

List<ProductColor> _colorsFrom(Object? raw) {
  if (raw is! List) return const [];
  return [
    for (final c in raw)
      if (c is Map && c['name'] is String && c['hex'] is String)
        ProductColor(name: c['name'] as String, hex: c['hex'] as String),
  ];
}

class SupabaseCatalogRepository implements CatalogRepository {
  SupabaseCatalogRepository(this._client);

  final SupabaseClient _client;
  static const _timeout = Duration(seconds: 12);

  @override
  Future<List<Category>> listCategories() async {
    try {
      final rows = await _client
          .from('categories')
          .select('id, slug, name, tagline, image_url')
          .order('sort_order', ascending: true)
          .timeout(_timeout);
      return [
        for (final r in rows)
          Category(
            id: r['id'] as String,
            slug: r['slug'] as String,
            name: r['name'] as String,
            tagline: (r['tagline'] as String?) ?? '',
            imageUrl: r['image_url'] as String,
          ),
      ];
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<List<Product>> listProducts([
    CatalogQuery query = const CatalogQuery(),
  ]) async {
    try {
      var request = _client
          .from('products')
          .select(productColumns)
          .eq('active', true);
      final term = query.search?.trim().replaceAll(RegExp(r'[%,()*]'), ' ');
      if (term != null && term.isNotEmpty) {
        request = request.or('name.ilike.%$term%,description.ilike.%$term%');
      }
      final ordered = switch (query.sort) {
        SortKey.priceAsc => request.order('price_cents', ascending: true),
        SortKey.priceDesc => request.order('price_cents', ascending: false),
        SortKey.newest => request.order('created_at', ascending: false),
      };
      final rows = await ordered.timeout(_timeout);
      final products = rows.map(productFromRow).whereType<Product>().toList();
      return query.categorySlug == null
          ? products
          : products
                .where((p) => p.categorySlug == query.categorySlug)
                .toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<Product?> getProductBySlug(String slug) async {
    try {
      final row = await _client
          .from('products')
          .select(productColumns)
          .eq('slug', slug)
          .eq('active', true)
          .maybeSingle()
          .timeout(_timeout);
      return row == null ? null : productFromRow(row);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }
}
