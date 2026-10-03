import '../../catalog/domain/category.dart';
import '../../catalog/domain/product.dart';
import '../../orders/domain/order.dart';
import 'admin_models.dart';
import 'product_draft.dart';

/// Admin operations. Every call is also enforced by Row Level Security in the database:
/// hiding the admin screens is a convenience, not the security boundary.
abstract class AdminRepository {
  Future<AdminStats> loadStats();
  Future<List<Product>> listProducts();
  Future<Product?> getProduct(String id);
  Future<List<Category>> listCategories();
  Future<void> saveProduct(ProductDraft draft);
  Future<void> deleteProduct(String id);
  Future<void> updateOrderStatus(String orderId, OrderStatus status);
}
