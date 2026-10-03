import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/theme/theme_controller.dart';
import 'features/admin/data/supabase_admin_repository.dart';
import 'features/auth/data/supabase_auth_repository.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/cart/data/cart_storage.dart';
import 'features/cart/presentation/cart_controller.dart';
import 'features/catalog/data/preview_catalog_repository.dart';
import 'features/catalog/data/preview_review_repository.dart';
import 'features/catalog/data/supabase_catalog_repository.dart';
import 'features/catalog/data/supabase_review_repository.dart';
import 'features/checkout/data/checkout_draft_storage.dart';
import 'features/orders/data/supabase_order_repository.dart';
import 'features/orders/domain/place_order.dart';

/// Composition root: the only place that chooses concrete implementations.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();
  final cart = CartController(SharedPrefsCartStorage(prefs));
  final theme = ThemeController(prefs);
  final drafts = SharedPrefsCheckoutDraftStorage(prefs);

  if (!AppConfig.isSupabaseConfigured) {
    const orders = UnavailableOrderRepository();
    final auth = AuthController(null);
    runApp(
      LookersApp(
        catalog: const PreviewCatalogRepository(),
        reviews: const PreviewReviewRepository(),
        drafts: drafts,
        orders: orders,
        admin: null,
        auth: auth,
        cart: cart,
        theme: theme,
        placeOrder: const PlaceOrder(orders, NoopConfirmationNotifier()),
        isPreview: true,
      ),
    );
    return;
  }

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
  );
  final client = Supabase.instance.client;
  final auth = AuthController(SupabaseAuthRepository(client));
  await auth.init();
  final orders = SupabaseOrderRepository(client);
  runApp(
    LookersApp(
      catalog: SupabaseCatalogRepository(client),
      reviews: SupabaseReviewRepository(client),
      drafts: drafts,
      orders: orders,
      admin: SupabaseAdminRepository(client),
      auth: auth,
      cart: cart,
      theme: theme,
      placeOrder: PlaceOrder(orders, EdgeFunctionConfirmationNotifier(client)),
      isPreview: false,
    ),
  );
}
