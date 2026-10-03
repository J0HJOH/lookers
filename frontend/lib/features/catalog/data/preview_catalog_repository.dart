import '../domain/catalog_query.dart';
import '../domain/catalog_repository.dart';
import '../domain/category.dart';
import '../domain/product.dart';
import 'seed_catalog.dart';

/// Serves the bundled sample catalogue when Supabase isn't configured, so the design can be
/// previewed. Checkout and accounts need the real database.
class PreviewCatalogRepository implements CatalogRepository {
  const PreviewCatalogRepository();

  @override
  Future<List<Category>> listCategories() async => seedCategories;

  @override
  Future<List<Product>> listProducts([
    CatalogQuery query = const CatalogQuery(),
  ]) async => applyCatalogQuery(seedProducts, query);

  @override
  Future<Product?> getProductBySlug(String slug) async {
    for (final p in seedProducts) {
      if (p.slug == slug) return p;
    }
    return null;
  }
}
