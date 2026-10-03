import 'dart:convert';

const maxQtyPerLine = 10;
const maxCartLines = 30;

class CartLine {
  const CartLine({
    required this.slug,
    required this.name,
    required this.imageUrl,
    required this.priceCents,
    required this.size,
    required this.quantity,
    this.color,
  });

  final String slug;
  final String name;
  final String imageUrl;

  /// For display only. The database re-prices every item when the order is placed.
  final int priceCents;
  final String size;
  final int quantity;

  /// Chosen colour variant, or null for products without colour choices.
  final String? color;

  bool sameItem(String otherSlug, String otherSize, String? otherColor) =>
      slug == otherSlug && size == otherSize && color == otherColor;

  CartLine withQuantity(int q) => CartLine(
    slug: slug,
    name: name,
    imageUrl: imageUrl,
    priceCents: priceCents,
    size: size,
    quantity: q,
    color: color,
  );

  Map<String, dynamic> toStorageJson() => {
    'slug': slug,
    'name': name,
    'imageUrl': imageUrl,
    'priceCents': priceCents,
    'size': size,
    'quantity': quantity,
    'color': color,
  };
}

/// Pure cart rules. The cart is immutable: every operation returns a new list.
/// A line is identified by product + size + colour.
List<CartLine> addLine(List<CartLine> cart, CartLine line) {
  final index = cart.indexWhere(
    (l) => l.sameItem(line.slug, line.size, line.color),
  );
  if (index >= 0) {
    final merged = (cart[index].quantity + line.quantity).clamp(
      1,
      maxQtyPerLine,
    );
    return [...cart]..[index] = cart[index].withQuantity(merged);
  }
  if (cart.length >= maxCartLines) return cart;
  return [...cart, line.withQuantity(line.quantity.clamp(1, maxQtyPerLine))];
}

List<CartLine> setQuantity(
  List<CartLine> cart,
  String slug,
  String size,
  String? color,
  int quantity,
) {
  if (quantity <= 0) return removeLine(cart, slug, size, color);
  return [
    for (final l in cart)
      l.sameItem(slug, size, color)
          ? l.withQuantity(quantity.clamp(1, maxQtyPerLine))
          : l,
  ];
}

List<CartLine> removeLine(
  List<CartLine> cart,
  String slug,
  String size,
  String? color,
) => cart.where((l) => !l.sameItem(slug, size, color)).toList();

int itemCount(List<CartLine> cart) => cart.fold(0, (n, l) => n + l.quantity);
int subtotalCents(List<CartLine> cart) =>
    cart.fold(0, (sum, l) => sum + l.priceCents * l.quantity);

/// Stored carts are untrusted (users can edit browser storage): drop anything malformed.
List<CartLine> parseStoredCart(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  try {
    final data = jsonDecode(raw);
    if (data is! List) return const [];
    final lines = <CartLine>[];
    for (final item in data) {
      if (item is! Map) continue;
      final slug = item['slug'];
      final name = item['name'];
      final image = item['imageUrl'];
      final size = item['size'];
      final price = item['priceCents'];
      final qty = item['quantity'];
      final color = item['color'];
      if (slug is String &&
          name is String &&
          image is String &&
          size is String &&
          price is int &&
          qty is int &&
          (color == null || color is String)) {
        if (qty >= 1 && qty <= maxQtyPerLine) {
          lines.add(
            CartLine(
              slug: slug,
              name: name,
              imageUrl: image,
              priceCents: price,
              size: size,
              quantity: qty,
              color: color as String?,
            ),
          );
        }
      }
      if (lines.length >= maxCartLines) break;
    }
    return lines;
  } on FormatException {
    return const [];
  }
}

String encodeCart(List<CartLine> cart) =>
    jsonEncode([for (final l in cart) l.toStorageJson()]);
