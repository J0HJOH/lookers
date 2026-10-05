import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lookers/core/ui/neu.dart';
import 'package:lookers/features/catalog/data/seed_catalog.dart';

import 'helpers.dart';

void useDesktop(WidgetTester tester, {double height = 4200}) {
  tester.view.physicalSize = Size(1280, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> openBag(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.shopping_bag_outlined).first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('home page renders in preview mode with the SHEIN-style header', (
    tester,
  ) async {
    useDesktop(tester);
    await tester.pumpWidget(previewApp());
    await tester.pumpAndSettle();
    expect(find.textContaining('Dressed with'), findsOneWidget);
    expect(find.textContaining('PREVIEW MODE'), findsOneWidget);
    expect(find.text('Search for items'), findsOneWidget);
    expect(find.byTooltip('Sign in or sign up'), findsOneWidget);
    expect(find.text('Shop by category'), findsOneWidget);
  });

  testWidgets('admin pages send signed-out visitors to the login page', (
    tester,
  ) async {
    useDesktop(tester);
    final app = previewApp();
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    // Navigate by URL like a visitor typing /admin.
    final context = tester.element(find.byType(Scaffold).first);
    GoRouter.of(context).go('/admin');
    await tester.pumpAndSettle();
    expect(find.text('Sign in or sign up'), findsOneWidget);
    expect(find.text('CONTINUE WITH GOOGLE'), findsOneWidget);
  });

  testWidgets(
    'a guest can fill the checkout form but must sign in to place the order',
    (tester) async {
      useDesktop(tester);
      final app = previewApp();
      app.cart.add(line());
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      await openBag(tester);
      await tester.tap(find.text('CHECKOUT'));
      await tester.pumpAndSettle();

      // Not redirected: the guest sees the checkout form...
      expect(find.text('Delivery address'), findsOneWidget);
      expect(
        find.textContaining('sign in or sign up with Google'),
        findsOneWidget,
      );
      // ...and the button asks them to sign in instead of placing an order.
      expect(find.text('SIGN IN TO PLACE ORDER'), findsOneWidget);
      expect(find.text('PLACE ORDER'), findsNothing);

      await tester.tap(find.text('SIGN IN TO PLACE ORDER'));
      await tester.pumpAndSettle();
      expect(find.textContaining('no Supabase settings'), findsOneWidget);
    },
  );

  testWidgets('payment screen is display only: card option disables ordering', (
    tester,
  ) async {
    useDesktop(tester);
    final app = previewApp();
    app.cart.add(line());
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    await openBag(tester);
    await tester.tap(find.text('CHECKOUT'));
    await tester.pumpAndSettle();

    expect(find.text('Pay on delivery'), findsOneWidget);
    await tester.tap(find.text('Credit or debit card'));
    await tester.pumpAndSettle();
    expect(find.text('COMING SOON'), findsOneWidget);
    expect(find.text('CARD PAYMENT UNAVAILABLE'), findsOneWidget);
    final button = tester.widget<NeuButton>(
      find.widgetWithText(NeuButton, 'CARD PAYMENT UNAVAILABLE'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets(
    'product page: colour and size are required, reviews show purchased variety, related items appear',
    (tester) async {
      useDesktop(tester, height: 6000);
      final app = previewApp();
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(Scaffold).first);
      GoRouter.of(context).go('/product/noir-leather-jacket');
      await tester.pumpAndSettle();

      // Details, selectors, reviews and related items are all there.
      expect(find.text('Noir Leather Jacket'), findsWidgets);
      expect(find.text('Customer reviews'), findsOneWidget);
      expect(find.text('PURCHASED'), findsWidgets);
      expect(find.textContaining('Colour:'), findsWidgets);
      expect(find.text('More from Men\'s Clothing'), findsOneWidget);

      // Adding without choosing is refused with a message.
      await tester.tap(find.text('ADD TO BAG'));
      await tester.pumpAndSettle();
      expect(find.text('Please choose a colour.'), findsOneWidget);
      expect(app.cart.count, 0);

      final first = seedProducts.firstWhere(
        (p) => p.slug == 'noir-leather-jacket',
      );
      await tester.tap(find.byTooltip(first.colors.first.name));
      await tester.pump();
      await tester.tap(find.widgetWithText(InkWell, 'M'));
      await tester.pump();
      await tester.tap(find.text('ADD TO BAG'));
      await tester.pumpAndSettle();
      expect(app.cart.count, 1);
      expect(app.cart.lines.single.color, first.colors.first.name);
      expect(app.cart.lines.single.size, 'M');
    },
  );

  testWidgets('header search finds items and opens the shop results', (
    tester,
  ) async {
    useDesktop(tester);
    await tester.pumpWidget(previewApp());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'sneaker');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('All pieces'), findsOneWidget);
    expect(find.text('Crimson Runner'), findsOneWidget);
    expect(find.text('Noir Leather Jacket'), findsNothing);
  });
}
