import '../../../core/error/failure.dart';
import '../../cart/domain/cart.dart';
import '../../checkout/domain/shipping_address.dart';
import 'order.dart';
import 'order_repository.dart';

/// Use case: validate the address, place the order, then email a confirmation (best effort).
class PlaceOrder {
  const PlaceOrder(this._orders, this._notifier);

  final OrderRepository _orders;
  final OrderConfirmationNotifier _notifier;

  /// Throws [Failure] with kind `validation` for bad input (see [ValidationFailure]).
  Future<PlacedOrder> call(
    List<CartLine> lines,
    ShippingAddress address,
  ) async {
    if (lines.isEmpty)
      throw const Failure(FailureKind.validation, 'Your bag is empty.');
    final errors = address.validate();
    if (errors.isNotEmpty) throw FieldErrors(errors);
    final placed = await _orders.placeOrder(lines, address);
    try {
      await _notifier.sendConfirmation(placed.id);
    } catch (_) {
      // Documented best-effort call: the order is already placed, so an email problem is not an error.
    }
    return placed;
  }
}

/// Thrown by [PlaceOrder] when fields are invalid. Carries per-field messages for the form.
class FieldErrors extends Failure {
  FieldErrors(this.fields)
    : super(FailureKind.validation, 'Please check the highlighted fields.');

  final Map<String, String> fields;
}
