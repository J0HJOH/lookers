import 'package:flutter_test/flutter_test.dart';
import 'package:lookers/core/error/failure.dart';
import 'package:lookers/features/checkout/domain/shipping_address.dart';
import 'package:lookers/features/checkout/domain/shipping_rules.dart';
import 'package:lookers/features/orders/data/supabase_order_repository.dart';
import 'package:lookers/features/orders/domain/order.dart';
import 'package:lookers/features/orders/domain/order_repository.dart';
import 'package:lookers/features/orders/domain/place_order.dart';
import 'package:lookers/features/cart/domain/cart.dart';

import 'helpers.dart';

ShippingAddress address({
  String email = 'ada@example.com',
  String phone = '+234 801 234 5678',
  String city = 'Lagos',
}) => ShippingAddress(
  fullName: 'Ada Obi',
  email: email,
  phone: phone,
  line1: '12 Marina Road',
  city: city,
  region: 'Lagos',
  postalCode: '101233',
  country: 'Nigeria',
);

class _FakeOrders implements OrderRepository {
  int placed = 0;
  @override
  Future<PlacedOrder> placeOrder(
    List<CartLine> lines,
    ShippingAddress address,
  ) async {
    placed++;
    return const PlacedOrder(id: 'o1', orderNumber: 'LK-001001');
  }

  @override
  Future<Order?> getOrder(String id) async => null;
  @override
  Future<List<Order>> listOrders({int limit = 100}) async => [];
  @override
  Future<ShippingRules> getShippingRules() async => const ShippingRules();
}

class _ThrowingNotifier implements OrderConfirmationNotifier {
  @override
  Future<void> sendConfirmation(String orderId) async =>
      throw Exception('mailgun down');
}

void main() {
  group('shipping rule', () {
    const rules = ShippingRules();
    test('is free for an empty bag and at the threshold', () {
      expect(rules.shippingFor(0), 0);
      expect(rules.shippingFor(25000), 0);
    });
    test(
      'charges the flat fee below the threshold',
      () => expect(rules.shippingFor(24999), 1500),
    );
  });

  group('ShippingAddress.validate', () {
    test(
      'accepts a valid address',
      () => expect(address().validate(), isEmpty),
    );
    test('rejects bad email and phone', () {
      expect(address(email: 'nope').validate().keys, contains('email'));
      expect(address(phone: 'abc').validate().keys, contains('phone'));
    });
    test(
      'rejects whitespace-only fields',
      () => expect(address(city: '   ').validate().keys, contains('city')),
    );
  });

  group('PlaceOrder use case', () {
    test('does not call the database when the address is invalid', () async {
      final orders = _FakeOrders();
      final useCase = PlaceOrder(orders, _ThrowingNotifier());
      await expectLater(
        useCase([line()], address(email: 'bad')),
        throwsA(isA<FieldErrors>()),
      );
      expect(orders.placed, 0);
    });
    test('rejects an empty bag', () async {
      final useCase = PlaceOrder(_FakeOrders(), _ThrowingNotifier());
      await expectLater(useCase([], address()), throwsA(isA<Failure>()));
    });
    test('an email failure never fails or hides the order', () async {
      final orders = _FakeOrders();
      final placed = await PlaceOrder(orders, _ThrowingNotifier())([
        line(),
      ], address());
      expect(placed.orderNumber, 'LK-001001');
      expect(orders.placed, 1);
    });
  });

  group('mapPlaceOrderError', () {
    test(
      'turns coded database errors into friendly messages without leaking internals',
      () {
        expect(
          mapPlaceOrderError('OUT_OF_STOCK:noir-leather-jacket').kind,
          FailureKind.outOfStock,
        );
        expect(
          mapPlaceOrderError('PRODUCT_UNAVAILABLE:x').kind,
          FailureKind.validation,
        );
        expect(mapPlaceOrderError('AUTH_REQUIRED').kind, FailureKind.auth);
        final unknown = mapPlaceOrderError('relation "orders" does not exist');
        expect(unknown.kind, FailureKind.server);
        expect(unknown.message, isNot(contains('relation')));
      },
    );
  });
}
