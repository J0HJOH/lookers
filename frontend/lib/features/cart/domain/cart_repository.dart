import 'cart.dart';

/// A shopping bag stored on the server for a signed-in shopper, shared by all their devices.
/// Implementations throw `Failure` on errors.
abstract class CartRepository {
  Future<List<CartLine>> load();

  /// Adds [line.quantity] to the line (merges with an existing one; capped by the server).
  Future<void> add(CartLine line);

  /// Sets an exact quantity (0 removes the line).
  Future<void> setQuantity(CartLine line, int quantity);
  Future<void> remove(CartLine line);
  Future<void> clear();

  /// Fires whenever the bag changes anywhere: another device, another browser tab, or a checkout.
  /// Listening opens the real-time (WebSocket) connection; cancelling closes it.
  Stream<void> get changes;
}
