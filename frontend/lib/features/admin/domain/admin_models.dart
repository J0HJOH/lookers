import '../../catalog/domain/product.dart';

class AdminStats {
  const AdminStats({
    required this.orderCount,
    required this.pendingCount,
    required this.revenueCents,
    required this.customerCount,
    required this.lowStock,
  });

  final int orderCount;
  final int pendingCount;
  final int revenueCents;
  final int customerCount;
  final List<Product> lowStock;
}
