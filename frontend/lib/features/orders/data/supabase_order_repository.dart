import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';
import '../../cart/domain/cart.dart';
import '../../catalog/data/supabase_error_mapper.dart';
import '../../checkout/domain/shipping_address.dart';
import '../../checkout/domain/shipping_rules.dart';
import '../domain/order.dart';
import '../domain/order_repository.dart';

const orderColumns =
    'id, order_number, status, email, created_at, subtotal_cents, shipping_cents, total_cents, ship_name, ship_phone, ship_line1, ship_line2, ship_city, ship_region, ship_postal_code, ship_country, order_items(product_name, image_url, size, color, unit_price_cents, quantity)';

/// Parses one order row. Returns null if malformed (e.g. unknown status).
Order? orderFromRow(Map<String, dynamic> r) {
  try {
    final status = OrderStatus.tryParse(r['status']);
    if (status == null) return null;
    return Order(
      id: r['id'] as String,
      orderNumber: r['order_number'] as String,
      status: status,
      email: r['email'] as String,
      createdAt: DateTime.parse(r['created_at'] as String),
      subtotalCents: r['subtotal_cents'] as int,
      shippingCents: r['shipping_cents'] as int,
      totalCents: r['total_cents'] as int,
      delivery: DeliveryDetails(
        name: r['ship_name'] as String,
        phone: r['ship_phone'] as String,
        line1: r['ship_line1'] as String,
        line2: r['ship_line2'] as String?,
        city: r['ship_city'] as String,
        region: r['ship_region'] as String,
        postalCode: r['ship_postal_code'] as String,
        country: r['ship_country'] as String,
      ),
      items: [
        for (final i
            in (r['order_items'] as List<dynamic>).cast<Map<String, dynamic>>())
          OrderItem(
            productName: i['product_name'] as String,
            imageUrl: i['image_url'] as String,
            size: i['size'] as String,
            color: i['color'] as String?,
            unitPriceCents: i['unit_price_cents'] as int,
            quantity: i['quantity'] as int,
          ),
      ],
    );
  } on TypeError {
    return null;
  } on FormatException {
    return null;
  }
}

/// Maps the coded exceptions raised by `place_order()` to messages a shopper can act on.
Failure mapPlaceOrderError(String message) {
  if (message.contains('AUTH_REQUIRED'))
    return const Failure(
      FailureKind.auth,
      'Please sign in to place your order.',
    );
  if (message.contains('OUT_OF_STOCK')) {
    return const Failure(
      FailureKind.outOfStock,
      'One of the items just sold out or has less stock than you asked for. Please review your bag.',
    );
  }
  if (message.contains('PRODUCT_UNAVAILABLE')) {
    return const Failure(
      FailureKind.validation,
      'An item in your bag is no longer available. Please remove it and try again.',
    );
  }
  if (message.contains('INVALID_ADDRESS')) {
    return const Failure(
      FailureKind.validation,
      'Please check your delivery details and try again.',
    );
  }
  if (message.contains('INVALID_SIZE') ||
      message.contains('INVALID_COLOR') ||
      message.contains('INVALID_QUANTITY') ||
      message.contains('INVALID_CART')) {
    return const Failure(
      FailureKind.validation,
      'Your bag has an invalid item. Please review it and try again.',
    );
  }
  return const Failure(
    FailureKind.server,
    'We couldn\'t place your order. Please try again.',
  );
}

class SupabaseOrderRepository implements OrderRepository {
  SupabaseOrderRepository(this._client);

  final SupabaseClient _client;
  static const _timeout = Duration(seconds: 15);

  @override
  Future<List<Order>> listOrders({int limit = 100}) async {
    try {
      final rows = await _client
          .from('orders')
          .select(orderColumns)
          .order('created_at', ascending: false)
          .limit(limit)
          .timeout(_timeout);
      return rows.map(orderFromRow).whereType<Order>().toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<Order?> getOrder(String id) async {
    try {
      final row = await _client
          .from('orders')
          .select(orderColumns)
          .eq('id', id)
          .maybeSingle()
          .timeout(_timeout);
      return row == null ? null : orderFromRow(row);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<PlacedOrder> placeOrder(
    List<CartLine> lines,
    ShippingAddress address,
  ) async {
    try {
      // Only slug, size and quantity are sent. The browser never states a price.
      final items = [
        for (final l in lines)
          {
            'slug': l.slug,
            'size': l.size,
            'color': l.color,
            'quantity': l.quantity,
          },
      ];
      final result = await _client
          .rpc(
            'place_order',
            params: {
              'p_items': items,
              'p_shipping': address.toJson(),
              'p_notes': address.notes.trim(),
            },
          )
          .timeout(_timeout);
      final row = result is List
          ? (result.isEmpty ? null : result.first)
          : result;
      if (row is! Map || row['o_id'] is! String || row['o_number'] is! String) {
        throw const Failure(
          FailureKind.unexpected,
          'We couldn\'t confirm your order. Please check your account.',
        );
      }
      return PlacedOrder(
        id: row['o_id'] as String,
        orderNumber: row['o_number'] as String,
      );
    } on PostgrestException catch (e) {
      throw mapPlaceOrderError(e.message);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<ShippingRules> getShippingRules() async {
    try {
      final row = await _client
          .from('store_settings')
          .select('flat_shipping_cents, free_shipping_threshold_cents')
          .maybeSingle()
          .timeout(_timeout);
      if (row == null) return const ShippingRules();
      return ShippingRules(
        flatShippingCents: row['flat_shipping_cents'] as int,
        freeShippingThresholdCents: row['free_shipping_threshold_cents'] as int,
      );
    } catch (_) {
      // Only a preview of shipping cost; the database applies the real rule when ordering.
      return const ShippingRules();
    }
  }
}

/// Calls the `send-order-confirmation` Edge Function (which holds the Mailgun key).
class EdgeFunctionConfirmationNotifier implements OrderConfirmationNotifier {
  EdgeFunctionConfirmationNotifier(this._client);

  final SupabaseClient _client;

  @override
  Future<void> sendConfirmation(String orderId) async {
    await _client.functions
        .invoke('send-order-confirmation', body: {'orderId': orderId})
        .timeout(const Duration(seconds: 15));
  }
}

/// Preview mode: orders can't be placed, so there is nothing to confirm.
class NoopConfirmationNotifier implements OrderConfirmationNotifier {
  const NoopConfirmationNotifier();

  @override
  Future<void> sendConfirmation(String orderId) async {}
}

/// Preview mode repository: no database, so every call explains that.
class UnavailableOrderRepository implements OrderRepository {
  const UnavailableOrderRepository();

  static const _failure = Failure(
    FailureKind.notConfigured,
    'The store isn\'t connected to its database yet.',
  );

  @override
  Future<List<Order>> listOrders({int limit = 100}) async => const [];

  @override
  Future<Order?> getOrder(String id) async => null;

  @override
  Future<PlacedOrder> placeOrder(
    List<CartLine> lines,
    ShippingAddress address,
  ) async => throw _failure;

  @override
  Future<ShippingRules> getShippingRules() async => const ShippingRules();
}
