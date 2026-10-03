import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/ui/app_scope.dart';
import 'features/admin/domain/admin_repository.dart';
import 'features/auth/presentation/auth_controller.dart';
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

  @override
  State<LookersApp> createState() => _LookersAppState();
}

class _LookersAppState extends State<LookersApp> {
  late final GoRouter _router = buildRouter(widget.auth);

  @override
  void dispose() {
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
