import 'package:flutter_test/flutter_test.dart';
import 'package:lookers/features/cart/data/cart_storage.dart';
import 'package:lookers/features/cart/domain/cart.dart';
import 'package:lookers/features/cart/presentation/cart_controller.dart';

import 'helpers.dart';

void main() {
  group('cart rules', () {
    test('merges the same product and size', () {
      final cart = addLine(addLine([], line()), line(qty: 2));
      expect(cart, hasLength(1));
      expect(cart.first.quantity, 3);
    });
    test('keeps different colours as separate lines', () {
      expect(addLine(addLine([], line()), line(color: 'Red')), hasLength(2));
      expect(
        addLine(addLine([], line(color: 'Red')), line(color: 'Red')),
        hasLength(1),
      );
    });
    test('keeps different sizes as separate lines', () {
      expect(addLine(addLine([], line()), line(size: 'L')), hasLength(2));
    });
    test('caps quantity at 10', () {
      expect(addLine([line(qty: 9)], line(qty: 5)).first.quantity, 10);
    });
    test('removes a line when quantity drops to 0', () {
      expect(setQuantity([line()], 'a', 'M', null, 0), isEmpty);
    });
    test('computes totals', () {
      final cart = [line(qty: 2), line(slug: 'b', price: 500)];
      expect(itemCount(cart), 3);
      expect(subtotalCents(cart), 2500);
      expect(removeLine(cart, 'b', 'M', null), hasLength(1));
    });
    test('ignores tampered or invalid stored carts', () {
      expect(parseStoredCart('not json'), isEmpty);
      expect(parseStoredCart('{"a":1}'), isEmpty);
      expect(parseStoredCart('[{"slug":"a","quantity":999}]'), isEmpty);
      expect(parseStoredCart(encodeCart([line()])), hasLength(1));
      expect(
        parseStoredCart(encodeCart([line(color: 'Red')])).single.color,
        'Red',
      );
    });
  });

  group('CartController', () {
    test('persists and restores through storage', () {
      final storage = MemoryCartStorage();
      final controller = CartController(storage)..add(line());
      expect(controller.count, 1);
      expect(CartController(storage).count, 1);
      controller.clear();
      expect(controller.isEmpty, isTrue);
    });
  });
}
