import 'package:flutter/foundation.dart';

import '../data/cart_storage.dart';
import '../domain/cart.dart';

/// The shopping bag. Business rules live in `cart.dart`; this only holds state and persists it.
class CartController extends ChangeNotifier {
  CartController(this._storage) : _lines = parseStoredCart(_storage.read());

  final CartStorage _storage;
  List<CartLine> _lines;

  List<CartLine> get lines => _lines;
  int get count => itemCount(_lines);
  int get subtotal => subtotalCents(_lines);
  bool get isEmpty => _lines.isEmpty;

  void add(CartLine line) => _set(addLine(_lines, line));
  void setQty(CartLine line, int quantity) =>
      _set(setQuantity(_lines, line.slug, line.size, line.color, quantity));
  void remove(CartLine line) =>
      _set(removeLine(_lines, line.slug, line.size, line.color));
  void clear() => _set(const []);

  void _set(List<CartLine> next) {
    _lines = next;
    notifyListeners();
    // Best effort: if storage is blocked the bag still works for this session.
    _storage.write(encodeCart(next)).catchError((Object _) {});
  }
}
