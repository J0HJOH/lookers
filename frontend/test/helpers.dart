import 'package:lookers/features/admin/domain/admin_repository.dart';
import 'package:lookers/features/auth/presentation/auth_controller.dart';
import 'package:lookers/features/cart/data/cart_storage.dart';
import 'package:lookers/features/cart/domain/cart.dart';
import 'package:lookers/features/cart/presentation/cart_controller.dart';
import 'package:lookers/features/catalog/data/preview_catalog_repository.dart';
import 'package:lookers/features/catalog/data/preview_review_repository.dart';
import 'package:lookers/features/checkout/data/checkout_draft_storage.dart';
import 'package:lookers/features/orders/data/supabase_order_repository.dart';
import 'package:lookers/features/orders/domain/place_order.dart';
import 'package:lookers/app.dart';

CartLine line({
  String slug = 'a',
  String size = 'M',
  int price = 1000,
  int qty = 1,
  String? color,
}) => CartLine(
  slug: slug,
  name: slug.toUpperCase(),
  imageUrl: 'https://images.pexels.com/x.jpg',
  priceCents: price,
  size: size,
  quantity: qty,
  color: color,
);

LookersApp previewApp({AdminRepository? admin}) {
  const orders = UnavailableOrderRepository();
  return LookersApp(
    catalog: const PreviewCatalogRepository(),
    reviews: const PreviewReviewRepository(),
    drafts: MemoryCheckoutDraftStorage(),
    orders: orders,
    admin: admin,
    auth: AuthController(null),
    cart: CartController(MemoryCartStorage()),
    placeOrder: const PlaceOrder(orders, NoopConfirmationNotifier()),
    isPreview: true,
  );
}
