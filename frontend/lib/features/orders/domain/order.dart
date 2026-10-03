enum OrderStatus {
  pending('Pending'),
  confirmed('Confirmed'),
  shipped('Shipped'),
  delivered('Delivered'),
  cancelled('Cancelled');

  const OrderStatus(this.label);
  final String label;

  static OrderStatus? tryParse(Object? value) {
    for (final s in OrderStatus.values) {
      if (s.name == value) return s;
    }
    return null;
  }
}

class OrderItem {
  const OrderItem({
    required this.productName,
    required this.imageUrl,
    required this.size,
    required this.unitPriceCents,
    required this.quantity,
    this.color,
  });

  final String productName;
  final String imageUrl;
  final String size;
  final String? color;
  final int unitPriceCents;
  final int quantity;
}

class DeliveryDetails {
  const DeliveryDetails({
    required this.name,
    required this.phone,
    required this.line1,
    this.line2,
    required this.city,
    required this.region,
    required this.postalCode,
    required this.country,
  });

  final String name;
  final String phone;
  final String line1;
  final String? line2;
  final String city;
  final String region;
  final String postalCode;
  final String country;
}

class Order {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.email,
    required this.createdAt,
    required this.subtotalCents,
    required this.shippingCents,
    required this.totalCents,
    required this.delivery,
    required this.items,
  });

  final String id;
  final String orderNumber;
  final OrderStatus status;
  final String email;
  final DateTime createdAt;
  final int subtotalCents;
  final int shippingCents;
  final int totalCents;
  final DeliveryDetails delivery;
  final List<OrderItem> items;
}

class PlacedOrder {
  const PlacedOrder({required this.id, required this.orderNumber});

  final String id;
  final String orderNumber;
}
