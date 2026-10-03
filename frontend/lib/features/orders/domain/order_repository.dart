import '../../cart/domain/cart.dart';
import '../../checkout/domain/shipping_address.dart';
import '../../checkout/domain/shipping_rules.dart';
import 'order.dart';

abstract class OrderRepository {
  /// Orders visible to the signed-in user (their own; admins see all). Newest first.
  Future<List<Order>> listOrders({int limit = 100});
  Future<Order?> getOrder(String id);

  /// Creates the order in one database transaction. The database decides prices, stock and shipping.
  Future<PlacedOrder> placeOrder(List<CartLine> lines, ShippingAddress address);

  Future<ShippingRules> getShippingRules();
}

/// Sends the confirmation email. Best effort: a failure must never undo or hide an order.
abstract class OrderConfirmationNotifier {
  Future<void> sendConfirmation(String orderId);
}
