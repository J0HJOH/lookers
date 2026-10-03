import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_orders_page.dart';
import '../../features/admin/presentation/admin_overview_page.dart';
import '../../features/admin/presentation/admin_products_page.dart';
import '../../features/auth/presentation/auth_callback_page.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/require_auth.dart';
import '../../features/cart/presentation/cart_page.dart';
import '../../features/catalog/domain/catalog_query.dart';
import '../../features/catalog/presentation/home_page.dart';
import '../../features/catalog/presentation/product_page.dart';
import '../../features/catalog/presentation/shop_page.dart';
import '../../features/checkout/presentation/checkout_page.dart';
import '../../features/checkout/presentation/success_page.dart';
import '../../features/orders/presentation/account_page.dart';
import '../../features/policies/policy_page.dart';
import '../ui/async_view.dart';
import '../ui/site_shell.dart';

/// Pages that need a signed-in user. This redirect is a convenience: Row Level Security in the
/// database is what actually protects the data.
/// Browsing, the bag and the checkout FORM are open to everyone; placing the order needs an
/// account (the checkout page prompts sign-in). Only the confirmation page is guarded.
bool _isGuarded(String path) =>
    path == '/account' ||
    path.startsWith('/account/') ||
    path == '/checkout/success' ||
    path.startsWith('/admin');

GoRouter buildRouter(AuthController auth) {
  Page<void> page(Widget child, GoRouterState state) =>
      NoTransitionPage<void>(key: state.pageKey, child: child);

  return GoRouter(
    refreshListenable: auth,
    redirect: (context, state) {
      final path = state.uri.path;
      if (!_isGuarded(path) || !auth.ready) return null;
      if (!auth.isSignedIn)
        return '/login?next=${Uri.encodeQueryComponent(state.uri.toString())}';
      if (path.startsWith('/admin') && auth.user?.isAdmin != true) return '/';
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: EmptyState(
        title: 'This page isn\'t in the collection.',
        actionLabel: 'Back to the shop',
        onAction: () => context.go('/shop'),
      ),
    ),
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            SiteShell(pathKey: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/', pageBuilder: (c, s) => page(const HomePage(), s)),
          GoRoute(
            path: '/shop',
            pageBuilder: (c, s) => page(
              ShopPage(
                categorySlug: s.uri.queryParameters['category'],
                search: s.uri.queryParameters['q'],
                sort: SortKey.fromParam(s.uri.queryParameters['sort']),
              ),
              s,
            ),
          ),
          GoRoute(
            path: '/product/:slug',
            pageBuilder: (c, s) =>
                page(ProductPage(slug: s.pathParameters['slug']!), s),
          ),
          GoRoute(
            path: '/cart',
            pageBuilder: (c, s) => page(const CartPage(), s),
          ),
          GoRoute(
            path: '/policies/:slug',
            pageBuilder: (c, s) =>
                page(PolicyPage(slug: s.pathParameters['slug']!), s),
          ),
          GoRoute(
            path: '/login',
            pageBuilder: (c, s) => page(
              LoginPage(
                next: s.uri.queryParameters['next'],
                hadError: s.uri.queryParameters['error'] != null,
              ),
              s,
            ),
          ),
          GoRoute(
            path: '/auth/callback',
            pageBuilder: (c, s) =>
                page(AuthCallbackPage(next: s.uri.queryParameters['next']), s),
          ),
          GoRoute(
            path: '/checkout',
            pageBuilder: (c, s) => page(const CheckoutPage(), s),
          ),
          GoRoute(
            path: '/checkout/success',
            pageBuilder: (c, s) => page(
              RequireAuth(
                child: CheckoutSuccessPage(
                  orderId: s.uri.queryParameters['order'],
                ),
              ),
              s,
            ),
          ),
          GoRoute(
            path: '/account',
            pageBuilder: (c, s) =>
                page(const RequireAuth(child: AccountPage()), s),
          ),
          GoRoute(
            path: '/account/orders/:id',
            pageBuilder: (c, s) => page(
              RequireAuth(
                child: OrderDetailPage(orderId: s.pathParameters['id']!),
              ),
              s,
            ),
          ),
          GoRoute(
            path: '/admin',
            pageBuilder: (c, s) => page(
              const RequireAuth(adminOnly: true, child: AdminOverviewPage()),
              s,
            ),
          ),
          GoRoute(
            path: '/admin/products',
            pageBuilder: (c, s) => page(
              const RequireAuth(adminOnly: true, child: AdminProductsPage()),
              s,
            ),
          ),
          GoRoute(
            path: '/admin/products/new',
            pageBuilder: (c, s) => page(
              const RequireAuth(adminOnly: true, child: AdminProductFormPage()),
              s,
            ),
          ),
          GoRoute(
            path: '/admin/products/:id',
            pageBuilder: (c, s) => page(
              RequireAuth(
                adminOnly: true,
                child: AdminProductFormPage(productId: s.pathParameters['id']),
              ),
              s,
            ),
          ),
          GoRoute(
            path: '/admin/orders',
            pageBuilder: (c, s) => page(
              const RequireAuth(adminOnly: true, child: AdminOrdersPage()),
              s,
            ),
          ),
          GoRoute(
            path: '/admin/orders/:id',
            pageBuilder: (c, s) => page(
              RequireAuth(
                adminOnly: true,
                child: AdminOrderPage(orderId: s.pathParameters['id']!),
              ),
              s,
            ),
          ),
        ],
      ),
    ],
  );
}
