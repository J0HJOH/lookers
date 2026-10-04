import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lookers/core/error/failure.dart';
import 'package:lookers/features/auth/domain/app_user.dart';
import 'package:lookers/features/auth/domain/auth_repository.dart';
import 'package:lookers/features/auth/presentation/auth_controller.dart';
import 'package:lookers/features/cart/data/cart_storage.dart';
import 'package:lookers/features/cart/domain/cart.dart';
import 'package:lookers/features/cart/domain/cart_repository.dart';
import 'package:lookers/features/cart/presentation/cart_controller.dart';
import 'package:lookers/features/catalog/data/preview_catalog_repository.dart';
import 'package:lookers/features/catalog/data/preview_review_repository.dart';
import 'package:lookers/features/checkout/data/checkout_draft_storage.dart';
import 'package:lookers/features/orders/data/supabase_order_repository.dart';
import 'package:lookers/features/orders/domain/place_order.dart';
import 'package:lookers/app.dart';
import 'package:lookers/core/theme/theme_controller.dart';

import 'helpers.dart';

/// An in-memory stand-in for the server: one bag per user, and a "real-time" change notice sent to
/// every connected device of that user whenever the bag changes (like Supabase Realtime does).
class FakeCartServer {
  final bags = <String, List<CartLine>>{};
  final _streams = <String, StreamController<void>>{};

  StreamController<void> streamFor(String user) =>
      _streams.putIfAbsent(user, () => StreamController<void>.broadcast());

  void changed(String user) => streamFor(user).add(null);
}

class FakeCartRepository implements CartRepository {
  FakeCartRepository(this.server, this.user);

  final FakeCartServer server;
  final String user;
  bool failWrites = false;
  bool failLoad = false;

  List<CartLine> get _bag => server.bags.putIfAbsent(user, () => []);

  @override
  Stream<void> get changes => server.streamFor(user).stream;

  @override
  Future<List<CartLine>> load() async {
    if (failLoad) throw const Failure(FailureKind.network, 'offline');
    return List.of(_bag);
  }

  Future<void> _write(List<CartLine> next) async {
    if (failWrites) throw const Failure(FailureKind.server, 'boom');
    server.bags[user] = next;
    server.changed(user);
  }

  @override
  Future<void> add(CartLine line) => _write(addLine(_bag, line));
  @override
  Future<void> setQuantity(CartLine line, int quantity) =>
      _write(setQuantity_(line, quantity));
  List<CartLine> setQuantity_(CartLine line, int q) =>
      setQuantityOf(_bag, line, q);
  @override
  Future<void> remove(CartLine line) =>
      _write(removeLine(_bag, line.slug, line.size, line.color));
  @override
  Future<void> clear() => _write(const []);
}

List<CartLine> setQuantityOf(List<CartLine> cart, CartLine line, int q) =>
    setQuantity(cart, line.slug, line.size, line.color, q);

Future<void> settle() =>
    Future<void>.delayed(const Duration(milliseconds: 400));

void main() {
  group('synced bag (real time, two devices)', () {
    late FakeCartServer server;
    late CartController web;
    late CartController phone;
    late FakeCartRepository webRepo;
    late FakeCartRepository phoneRepo;

    setUp(() async {
      server = FakeCartServer();
      web = CartController(MemoryCartStorage());
      phone = CartController(MemoryCartStorage());
      webRepo = FakeCartRepository(server, 'joan');
      phoneRepo = FakeCartRepository(server, 'joan');
      await web.bindRemote(webRepo);
      await phone.bindRemote(phoneRepo);
    });

    tearDown(() {
      web.dispose();
      phone.dispose();
    });

    test('an item added on the web appears on the phone', () async {
      web.add(line(slug: 'jacket', color: 'Black', size: 'M'));
      expect(web.count, 1); // instantly on the device that did it
      await settle();
      expect(phone.lines.single.slug, 'jacket');
      expect(phone.lines.single.color, 'Black');
    });

    test('quantity changes, removals and clearing all propagate', () async {
      web.add(line(slug: 'a'));
      web.add(line(slug: 'b'));
      await settle();
      expect(phone.count, 2);

      phone.setQty(phone.lines.first, 4);
      await settle();
      expect(web.lines.first.quantity, 4);

      phone.remove(phone.lines.first);
      await settle();
      expect(web.lines.map((l) => l.slug), ['b']);

      web.clear();
      await settle();
      expect(phone.isEmpty, isTrue);
    });

    test(
      'adding on both devices at once counts both (no lost update)',
      () async {
        web.add(line(slug: 'a', qty: 1));
        phone.add(line(slug: 'a', qty: 2));
        await settle();
        expect(web.lines.single.quantity, 3);
        expect(phone.lines.single.quantity, 3);
      },
    );

    test(
      'the device that made a change is not double-counted by the echo',
      () async {
        web.add(line(slug: 'a', qty: 2));
        await settle();
        expect(web.lines.single.quantity, 2);
      },
    );

    test('a different account never sees this bag', () async {
      final other = CartController(MemoryCartStorage());
      addTearDown(other.dispose);
      await other.bindRemote(FakeCartRepository(server, 'someone-else'));
      web.add(line(slug: 'a'));
      await settle();
      expect(other.isEmpty, isTrue);
    });

    test('a refused change is undone by reloading the server bag', () async {
      web.add(line(slug: 'a'));
      await settle();
      webRepo.failWrites = true;
      web.add(line(slug: 'b'));
      expect(web.count, 2); // optimistic
      await settle();
      expect(web.lines.map((l) => l.slug), ['a']); // restored
      expect(web.syncError, isNotNull);
    });
  });

  group('signing in and out', () {
    test(
      'the device bag is merged into the account on sign-in and the device copy is cleared',
      () async {
        final server = FakeCartServer();
        final storage = MemoryCartStorage();
        final controller = CartController(storage)
          ..add(line(slug: 'a', qty: 2));
        addTearDown(controller.dispose);
        server.bags['joan'] = [line(slug: 'a', qty: 1), line(slug: 'b')];

        await controller.bindRemote(FakeCartRepository(server, 'joan'));
        expect(controller.isSynced, isTrue);
        expect(controller.lines.firstWhere((l) => l.slug == 'a').quantity, 3);
        expect(controller.lines.map((l) => l.slug), containsAll(['a', 'b']));
        expect(parseStoredCart(storage.read()), isEmpty);
      },
    );

    test(
      'signing out returns to an empty device bag; the account bag stays on the server',
      () async {
        final server = FakeCartServer();
        final controller = CartController(MemoryCartStorage());
        addTearDown(controller.dispose);
        await controller.bindRemote(FakeCartRepository(server, 'joan'));
        controller.add(line(slug: 'a'));
        await settle();

        await controller.bindRemote(null);
        expect(controller.isSynced, isFalse);
        expect(controller.isEmpty, isTrue);
        expect(server.bags['joan'], hasLength(1));

        await controller.bindRemote(FakeCartRepository(server, 'joan'));
        expect(controller.lines.single.slug, 'a');
      },
    );

    test(
      'if the server is unreachable the bag stays on the device and says so',
      () async {
        final controller = CartController(MemoryCartStorage())
          ..add(line(slug: 'a'));
        addTearDown(controller.dispose);
        final repo = FakeCartRepository(FakeCartServer(), 'joan')
          ..failLoad = true;
        await controller.bindRemote(repo);
        expect(controller.isSynced, isFalse);
        expect(controller.lines.single.slug, 'a');
        expect(controller.syncError, isNotNull);
      },
    );
  });

  group('profile popup', () {
    Future<void> openApp(WidgetTester tester, LookersApp app) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
    }

    testWidgets(
      'signed out: the profile button opens a popup and stays on the same page',
      (tester) async {
        await openApp(tester, previewApp());
        await tester.tap(find.byTooltip('Sign in or sign up'));
        await tester.pumpAndSettle();
        expect(find.text('CONTINUE WITH GOOGLE'), findsOneWidget);
        expect(find.text('Sign in or sign up'), findsOneWidget);
        // Still on the home page behind the popup: no navigation to a login screen.
        expect(find.textContaining('Dressed with'), findsOneWidget);

        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();
        expect(find.text('CONTINUE WITH GOOGLE'), findsNothing);
        expect(find.textContaining('Dressed with'), findsOneWidget);
      },
    );

    testWidgets(
      'in preview mode the popup explains that sign-in is not set up',
      (tester) async {
        await openApp(tester, previewApp());
        await tester.tap(find.byTooltip('Sign in or sign up'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUE WITH GOOGLE'));
        await tester.pumpAndSettle();
        expect(find.textContaining('isn\'t set up yet'), findsOneWidget);
      },
    );

    testWidgets(
      'signed in: the popup shows the account and sign out, with admin for admins',
      (tester) async {
        const orders = UnavailableOrderRepository();
        final auth = AuthController(
          _FakeAuth(
            const AppUser(
              id: 'u',
              email: 'joan@example.com',
              fullName: 'Joan Uchechi',
              isAdmin: true,
            ),
          ),
        );
        await auth.init();
        final app = LookersApp(
          catalog: const PreviewCatalogRepository(),
          reviews: const PreviewReviewRepository(),
          drafts: MemoryCheckoutDraftStorage(),
          orders: orders,
          admin: null,
          auth: auth,
          cart: CartController(MemoryCartStorage()),
          theme: ThemeController(null),
          placeOrder: const PlaceOrder(orders, NoopConfirmationNotifier()),
          isPreview: true,
        );
        await openApp(tester, app);
        await tester.tap(find.byTooltip('My account'));
        await tester.pumpAndSettle();
        expect(find.text('Hello, Joan.'), findsOneWidget);
        expect(find.text('MY ACCOUNT & ORDERS'), findsOneWidget);
        expect(find.text('ADMIN DASHBOARD'), findsOneWidget);
        expect(find.text('SIGN OUT'), findsOneWidget);
        expect(find.text('CONTINUE WITH GOOGLE'), findsNothing);
      },
    );
  });
}

class _FakeAuth implements AuthRepository {
  _FakeAuth(this._user);
  final AppUser _user;
  @override
  AppUser? get currentUser => _user;
  @override
  Stream<AppUser?> get userChanges => const Stream.empty();
  @override
  Future<AppUser?> restore() async => _user;
  @override
  Future<void> signInWithGoogle({required String nextPath}) async {}
  @override
  Future<void> signOut() async {}
}
