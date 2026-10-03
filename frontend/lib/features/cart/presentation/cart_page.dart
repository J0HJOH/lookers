import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/ui/app_scope.dart';
import '../../../core/ui/async_view.dart';
import '../../../core/ui/layout.dart';
import '../../../core/ui/product_image.dart';
import '../../checkout/domain/shipping_rules.dart';
import '../domain/cart.dart';
import '../../../core/ui/neu.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final mobile = isMobile(context);
    return PageContainer(
      padding: EdgeInsets.symmetric(horizontal: mobile ? 20 : 32, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your bag', style: AppText.display(mobile ? 44 : 56)),
          const SizedBox(height: 32),
          ListenableBuilder(
            listenable: scope.cart,
            builder: (context, _) {
              if (scope.cart.isEmpty) {
                return EmptyState(
                  title: 'Your bag is empty.',
                  message: 'Find something you love.',
                  actionLabel: 'Continue shopping',
                  onAction: () => context.go('/shop'),
                );
              }
              return AsyncView<ShippingRules>(
                minHeight: 120,
                load: scope.orders.getShippingRules,
                builder: (context, rules) => _CartContent(rules: rules),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CartContent extends StatelessWidget {
  const _CartContent({required this.rules});

  final ShippingRules rules;

  @override
  Widget build(BuildContext context) {
    final cart = AppScope.of(context).cart;
    final lines = Column(
      children: [for (final line in cart.lines) _LineRow(line: line)],
    );
    final summary = OrderSummaryCard(
      subtotal: cart.subtotal,
      rules: rules,
      action: NeuButton(
        onPressed: () => context.go('/checkout'),
        child: const Text('CHECKOUT'),
      ),
      footnote: 'Final prices are confirmed at checkout.',
    );
    if (isDesktop(context)) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: lines),
          const SizedBox(width: 48),
          SizedBox(width: 380, child: summary),
        ],
      );
    }
    return Column(children: [lines, const SizedBox(height: 32), summary]);
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line});

  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final cart = AppScope.of(context).cart;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: NeuBox(
        radius: 26,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => context.go('/product/${line.slug}'),
              child: SizedBox(
                width: 100,
                height: 134,
                child: ProductImage(
                  url: line.imageUrl,
                  semanticLabel: line.name,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: SizedBox(
                height: 134,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(line.name, style: AppText.display(22)),
                        ),
                        Text(
                          formatMoney(line.priceCents * line.quantity),
                          style: AppText.body(size: 14, color: AppColors.ink),
                        ),
                      ],
                    ),
                    Text(
                      '${line.color == null ? '' : 'Colour ${line.color}  ·  '}Size ${line.size}',
                      style: AppText.body(size: 14, color: AppColors.inkMuted),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        NeuBox(
                          inset: true,
                          radius: 14,
                          depth: 0.5,
                          child: Row(
                            children: [
                              IconButton(
                                tooltip: 'Decrease quantity of ${line.name}',
                                icon: const Icon(Icons.remove, size: 18),
                                onPressed: () =>
                                    cart.setQty(line, line.quantity - 1),
                              ),
                              Semantics(
                                liveRegion: true,
                                child: SizedBox(
                                  width: 28,
                                  child: Text(
                                    '${line.quantity}',
                                    textAlign: TextAlign.center,
                                    style: AppText.body(color: AppColors.ink),
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Increase quantity of ${line.name}',
                                icon: const Icon(Icons.add, size: 18),
                                onPressed: line.quantity >= maxQtyPerLine
                                    ? null
                                    : () =>
                                          cart.setQty(line, line.quantity + 1),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => cart.remove(line),
                          child: Text(
                            'REMOVE',
                            style: AppText.eyebrow().copyWith(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Totals panel used by the bag and checkout pages.
class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({
    super.key,
    required this.subtotal,
    required this.rules,
    this.action,
    this.footnote,
    this.lines,
  });

  final int subtotal;
  final ShippingRules rules;
  final Widget? action;
  final String? footnote;
  final List<CartLine>? lines;

  @override
  Widget build(BuildContext context) {
    final shipping = rules.shippingFor(subtotal);
    final toFree = (rules.freeShippingThresholdCents - subtotal).clamp(
      0,
      1 << 31,
    );
    Widget row(String label, String value, {bool big = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppText.body(size: big ? 17 : 14, color: AppColors.ink),
          ),
          Text(
            value,
            style: AppText.body(size: big ? 17 : 14, color: AppColors.ink),
          ),
        ],
      ),
    );
    return NeuBox(
      radius: 28,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            lines == null ? 'Order summary' : 'Your order',
            style: AppText.display(26),
          ),
          const SizedBox(height: 16),
          if (lines != null) ...[
            for (final l in lines!)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 56,
                      height: 74,
                      child: ProductImage(url: l.imageUrl),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.name,
                            style: AppText.body(
                              size: 14,
                              color: AppColors.ink,
                              weight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${l.color == null ? '' : '${l.color} · '}Size ${l.size} · Qty ${l.quantity}',
                            style: AppText.body(
                              size: 13,
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatMoney(l.priceCents * l.quantity),
                      style: AppText.body(size: 14, color: AppColors.ink),
                    ),
                  ],
                ),
              ),
            const Divider(),
            const SizedBox(height: 8),
          ],
          row('Subtotal', formatMoney(subtotal)),
          row('Shipping', shipping == 0 ? 'Free' : formatMoney(shipping)),
          const Divider(),
          row('Total', formatMoney(subtotal + shipping), big: true),
          if (toFree > 0 && subtotal > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Add ${formatMoney(toFree)} more for free shipping.',
                style: AppText.body(size: 13, color: AppColors.inkMuted),
              ),
            ),
          if (action != null) ...[const SizedBox(height: 24), action!],
          if (footnote != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                footnote!,
                textAlign: TextAlign.center,
                style: AppText.body(size: 12, color: AppColors.inkMuted),
              ),
            ),
        ],
      ),
    );
  }
}
