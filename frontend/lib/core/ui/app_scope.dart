import 'package:flutter/widgets.dart';

import '../../features/admin/domain/admin_repository.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/cart/presentation/cart_controller.dart';
import '../../features/catalog/domain/catalog_repository.dart';
import '../../features/catalog/domain/review_repository.dart';
import '../../features/checkout/data/checkout_draft_storage.dart';
import '../../features/orders/domain/order_repository.dart';
import '../../features/orders/domain/place_order.dart';

/// Dependencies for the whole app, created once in `main.dart` (the composition root).
/// Widgets read them from here and never construct repositories or clients themselves.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.catalog,
    required this.reviews,
    required this.drafts,
    required this.orders,
    required this.admin,
    required this.auth,
    required this.cart,
    required this.placeOrder,
    required this.isPreview,
    required super.child,
  });

  final CatalogRepository catalog;
  final ReviewRepository reviews;
  final CheckoutDraftStorage drafts;
  final OrderRepository orders;
  final AdminRepository? admin;
  final AuthController auth;
  final CartController cart;
  final PlaceOrder placeOrder;

  /// True when Supabase isn't configured (sample catalogue, no sign-in or checkout).
  final bool isPreview;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing above this widget');
    return scope!;
  }

  /// Like [of] but safe in `initState` (doesn't register a dependency; the scope never changes).
  static AppScope read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope old) => false;
}
