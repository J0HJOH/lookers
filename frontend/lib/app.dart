import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/ui/app_scope.dart';
import 'features/admin/domain/admin_repository.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/cart/domain/cart_repository.dart';
import 'features/cart/presentation/cart_controller.dart';
import 'features/catalog/domain/catalog_repository.dart';
import 'features/catalog/domain/review_repository.dart';
import 'features/checkout/data/checkout_draft_storage.dart';
import 'features/orders/domain/order_repository.dart';
import 'features/orders/domain/place_order.dart';

class LookersApp extends StatefulWidget {
  const LookersApp({
    super.key,
    required this.catalog,
    required this.reviews,
    required this.drafts,
    required this.orders,
    required this.admin,
    required this.auth,
    required this.cart,
    required this.theme,
    required this.placeOrder,
    required this.isPreview,
    this.cartRemote,
  });

  final CatalogRepository catalog;
  final ReviewRepository reviews;
  final CheckoutDraftStorage drafts;
  final OrderRepository orders;
  final AdminRepository? admin;
  final AuthController auth;
  final CartController cart;
  final ThemeController theme;
  final PlaceOrder placeOrder;
  final bool isPreview;

  /// Builds the server-side bag for a signed-in shopper (null in preview mode: the bag stays local).
  final CartRepository Function(String userId)? cartRemote;

  @override
  State<LookersApp> createState() => _LookersAppState();
}

class _LookersAppState extends State<LookersApp> {
  late final GoRouter _router = buildRouter(widget.auth);

  @override
  void initState() {
    super.initState();
    widget.auth.addListener(_returnAfterSignIn);
    widget.auth.addListener(_syncCart);
    _syncCart();
  }

  String? _boundUserId;

  /// Signed in: the bag moves to the server and follows the shopper across devices (real time).
  /// Signed out: back to the device bag.
  void _syncCart() {
    final id = widget.auth.user?.id;
    if (id == _boundUserId) return;
    _boundUserId = id;
    final factory = widget.cartRemote;
    widget.cart.bindRemote(id == null || factory == null ? null : factory(id));
  }

  /// After Google sign-in on a phone, bring the shopper back to the page they started from
  /// (for example the checkout), not the home page the deep link opened.
  void _returnAfterSignIn() {
    if (widget.auth.isSignedIn && widget.auth.hasReturnTo) {
      final path = widget.auth.takeReturnTo();
      if (path != null) _router.go(path);
    }
  }

  @override
  void dispose() {
    widget.auth.removeListener(_returnAfterSignIn);
    widget.auth.removeListener(_syncCart);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      catalog: widget.catalog,
      reviews: widget.reviews,
      drafts: widget.drafts,
      orders: widget.orders,
      admin: widget.admin,
      auth: widget.auth,
      cart: widget.cart,
      theme: widget.theme,
      placeOrder: widget.placeOrder,
      isPreview: widget.isPreview,
      child: ListenableBuilder(
        listenable: widget.theme,
        builder: (context, _) => MaterialApp.router(
          title: 'Lookers',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(widget.theme.palette),
          // Colours are read from the active palette and switch instantly; no cross-fade.
          themeAnimationDuration: Duration.zero,
          routerConfig: _router,
        ),
      ),
    );
  }
}
