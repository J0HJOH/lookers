import 'catalog_query.dart';
import 'category.dart';
import 'product.dart';

/// Read access to the shop catalogue. Implementations throw `Failure` on errors.
abstract class CatalogRepository {
  Future<List<Category>> listCategories();
  Future<List<Product>> listProducts([
    CatalogQuery query = const CatalogQuery(),
  ]);
  Future<Product?> getProductBySlug(String slug);
}
