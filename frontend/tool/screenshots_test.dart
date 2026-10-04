// Renders the real screens (with fake data and a fake signed-in admin) to PNG files so the design
// can be reviewed without a live backend.
// Run from frontend/:   SHOTS=/some/dir flutter test tool/screenshots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lookers/app.dart';
import 'package:lookers/core/theme/app_colors.dart';
import 'package:lookers/core/theme/theme_controller.dart';
import 'package:lookers/features/admin/domain/admin_models.dart';
import 'package:lookers/features/admin/domain/admin_repository.dart';
import 'package:lookers/features/admin/domain/product_draft.dart';
import 'package:lookers/features/auth/domain/app_user.dart';
import 'package:lookers/features/auth/domain/auth_repository.dart';
import 'package:lookers/features/auth/presentation/auth_controller.dart';
import 'package:lookers/features/cart/data/cart_storage.dart';
import 'package:lookers/features/cart/domain/cart.dart';
import 'package:lookers/features/cart/presentation/cart_controller.dart';
import 'package:lookers/features/catalog/data/preview_catalog_repository.dart';
import 'package:lookers/features/catalog/data/preview_review_repository.dart';
import 'package:lookers/features/catalog/data/seed_catalog.dart';
import 'package:lookers/features/catalog/domain/category.dart';
import 'package:lookers/features/catalog/domain/product.dart';
import 'package:lookers/features/checkout/data/checkout_draft_storage.dart';
import 'package:lookers/features/checkout/domain/shipping_address.dart';
import 'package:lookers/features/checkout/domain/shipping_rules.dart';
import 'package:lookers/features/orders/domain/order.dart';
import 'package:lookers/features/orders/domain/order_repository.dart';
import 'package:lookers/features/orders/domain/place_order.dart';

const _admin = AppUser(
  id: 'u1',
  email: 'joanuchechi@gmail.com',
  fullName: 'Joan Uchechi',
  isAdmin: true,
);

class _Auth implements AuthRepository {
  @override
  AppUser? get currentUser => _admin;
  @override
  Stream<AppUser?> get userChanges => const Stream.empty();
  @override
  Future<AppUser?> restore() async => _admin;
  @override
  Future<void> signInWithGoogle({required String nextPath}) async {}
  @override
  Future<void> signOut() async {}
}

final _orders = <Order>[
  _order('o1', 'LK-001004', OrderStatus.pending, 29200, 0, [
    (0, 'M', 'Black', 1),
    (5, 'One size', 'Tan', 1),
  ]),
  _order('o2', 'LK-001003', OrderStatus.shipped, 14500, 1500, [
    (15, '42', 'Red', 1),
  ]),
  _order('o3', 'LK-001002', OrderStatus.delivered, 9600, 1500, [
    (8, '3-6M', 'Cream', 2),
  ]),
  _order('o4', 'LK-001001', OrderStatus.cancelled, 48000, 0, [
    (0, 'L', 'Camel', 1),
  ]),
];

Order _order(
  String id,
  String number,
  OrderStatus status,
  int subtotal,
  int shipping,
  List<(int, String, String, int)> lines,
) => Order(
  id: id,
  orderNumber: number,
  status: status,
  email: 'ada@example.com',
  createdAt: DateTime.utc(2026, 10, 2),
  subtotalCents: subtotal,
  shippingCents: shipping,
  totalCents: subtotal + shipping,
  delivery: const DeliveryDetails(
    name: 'Ada Obi',
    phone: '+234 801 234 5678',
    line1: '12 Marina Road',
    line2: 'Flat 4',
    city: 'Lagos',
    region: 'Lagos',
    postalCode: '101233',
    country: 'Nigeria',
  ),
  items: [
    for (final l in lines)
      OrderItem(
        productName: seedProducts[l.$1].name,
        imageUrl: seedProducts[l.$1].imageUrl,
        size: l.$2,
        color: l.$3,
        unitPriceCents: seedProducts[l.$1].priceCents,
        quantity: l.$4,
      ),
  ],
);

class _Orders implements OrderRepository {
  @override
  Future<List<Order>> listOrders({int limit = 100}) async => _orders;
  @override
  Future<Order?> getOrder(String id) async =>
      _orders.firstWhere((o) => o.id == id, orElse: () => _orders.first);
  @override
  Future<PlacedOrder> placeOrder(
    List<CartLine> lines,
    ShippingAddress address,
  ) async => const PlacedOrder(id: 'o1', orderNumber: 'LK-001004');
  @override
  Future<ShippingRules> getShippingRules() async => const ShippingRules();
}

class _AdminRepo implements AdminRepository {
  @override
  Future<AdminStats> loadStats() async => AdminStats(
    orderCount: 4,
    pendingCount: 1,
    revenueCents: 29200 + 14500 + 1500 + 9600 + 1500,
    customerCount: 3,
    lowStock: [for (final p in seedProducts.take(3)) _withStock(p, 2)],
  );
  @override
  Future<List<Product>> listProducts() async => [
    for (final p in seedProducts) _withCategory(p),
  ];
  @override
  Future<Product?> getProduct(String id) async =>
      _withCategory(seedProducts.first);
  @override
  Future<List<Category>> listCategories() async => [
    for (final (i, c) in seedCategories.indexed)
      Category(
        id: 'c$i',
        slug: c.slug,
        name: c.name,
        tagline: c.tagline,
        imageUrl: c.imageUrl,
      ),
  ];
  @override
  Future<void> saveProduct(ProductDraft draft) async {}
  @override
  Future<void> deleteProduct(String id) async {}
  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {}
}

Product _withStock(Product p, int stock) => Product(
  id: p.id,
  slug: p.slug,
  name: p.name,
  description: p.description,
  priceCents: p.priceCents,
  categorySlug: p.categorySlug,
  categoryName: p.categoryName,
  imageUrl: p.imageUrl,
  sizes: p.sizes,
  stock: stock,
  featured: p.featured,
  active: true,
);

Product _withCategory(Product p) {
  final index = seedCategories.indexWhere((c) => c.slug == p.categorySlug);
  return Product(
    id: p.id,
    slug: p.slug,
    name: p.name,
    description: p.description,
    priceCents: p.priceCents,
    categoryId: 'c$index',
    categorySlug: p.categorySlug,
    categoryName: p.categoryName,
    imageUrl: p.imageUrl,
    sizes: p.sizes,
    stock: p.stock,
    featured: p.featured,
    active: p.id != 'preview-3',
    colors: p.colors,
    images: p.images,
    ratingAvg: p.ratingAvg,
    ratingCount: p.ratingCount,
  );
}

Future<void> _loadFonts(WidgetTester tester) async {
  Future<void> load(String family, String path) async {
    final loader = FontLoader(family)
      ..addFont(
        Future.value(ByteData.sublistView(File(path).readAsBytesSync())),
      );
    await tester.runAsync(loader.load);
  }

  await load('Jost', 'assets/fonts/Jost.ttf');
  await load('Pinyon', 'assets/fonts/PinyonScript-Regular.ttf');
  final flutter =
      Platform.environment['FLUTTER_ROOT'] ??
      '${Platform.environment['HOME']}/fvm/versions/3.44.6';
  await load(
    'MaterialIcons',
    '$flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
}

Future<void> _shot(
  WidgetTester tester,
  String name,
  String route, {
  required Size size,
  required bool dark,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  final orders = _Orders();
  final auth = AuthController(_Auth());
  await auth.init();
  final cart = CartController(MemoryCartStorage())
    ..add(
      CartLine(
        slug: seedProducts[0].slug,
        name: seedProducts[0].name,
        imageUrl: seedProducts[0].imageUrl,
        priceCents: seedProducts[0].priceCents,
        size: 'M',
        color: 'Black',
        quantity: 1,
      ),
    )
    ..add(
      CartLine(
        slug: seedProducts[15].slug,
        name: seedProducts[15].name,
        imageUrl: seedProducts[15].imageUrl,
        priceCents: seedProducts[15].priceCents,
        size: '42',
        color: 'Red',
        quantity: 2,
      ),
    );
  final theme = ThemeController(null)
    ..setMode(dark ? AppThemeMode.dark : AppThemeMode.light);
  final key = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: LookersApp(
        catalog: const PreviewCatalogRepository(),
        reviews: const PreviewReviewRepository(),
        drafts: MemoryCheckoutDraftStorage(),
        orders: orders,
        admin: _AdminRepo(),
        auth: auth,
        cart: cart,
        theme: theme,
        placeOrder: PlaceOrder(orders, const _NoMail()),
        isPreview: false,
      ),
    ),
  );
  await tester.pumpAndSettle();
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(route);
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    final dir = Directory(Platform.environment['SHOTS'] ?? '/tmp/lookers_shots')
      ..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(bytes.buffer.asUint8List());
  });
  AppColors.use(Palette.light);
}

class _NoMail implements OrderConfirmationNotifier {
  const _NoMail();
  @override
  Future<void> sendConfirmation(String orderId) async {}
}

void main() {
  const desktop = Size(1280, 1500);
  const phone = Size(390, 1900);
  final routes = <String, String>{
    'account': '/account',
    'order': '/account/orders/o1',
    'success': '/checkout/success?order=o1',
    'admin': '/admin',
    'admin-products': '/admin/products',
    'admin-product-form': '/admin/products/preview-0',
    'admin-orders': '/admin/orders',
    'admin-order': '/admin/orders/o1',
    'cart': '/cart',
    'checkout': '/checkout',
    'login': '/login',
  };
  testWidgets('screenshots', (tester) async {
    addTearDown(tester.view.reset);
    await _loadFonts(tester);
    final only = Platform.environment['ONLY']?.split(',');
    for (final e in routes.entries) {
      if (only != null && !only.contains(e.key)) continue;
      await _shot(
        tester,
        '${e.key}-desktop-light',
        e.value,
        size: desktop,
        dark: false,
      );
      await _shot(
        tester,
        '${e.key}-phone-dark',
        e.value,
        size: phone,
        dark: true,
      );
    }
  });
}
