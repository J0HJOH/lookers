import 'package:flutter/material.dart';

import '../../../core/formatting/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/ui/layout.dart';
import '../../../core/ui/product_image.dart';
import '../domain/order.dart';
import 'status_badge.dart';

class OrderDetails extends StatelessWidget {
  const OrderDetails({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final d = order.delivery;
    final items = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          children: [
            Text(order.orderNumber, style: AppText.display(34)),
            StatusBadge(status: order.status),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Placed ${formatDate(order.createdAt)}',
          style: AppText.body(size: 14, color: AppColors.inkMuted),
        ),
        const SizedBox(height: 24),
        const Divider(),
        for (final i in order.items) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 64,
                  height: 84,
                  child: ProductImage(url: i.imageUrl),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i.productName,
                        style: AppText.body(
                          color: AppColors.ink,
                          weight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${i.color == null ? '' : '${i.color} · '}Size ${i.size} · Qty ${i.quantity}',
                        style: AppText.body(
                          size: 14,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatMoney(i.unitPriceCents * i.quantity),
                  style: AppText.body(size: 14, color: AppColors.ink),
                ),
              ],
            ),
          ),
          const Divider(),
        ],
      ],
    );

    Widget line(String a, String b, {bool big = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            a,
            style: AppText.body(size: big ? 16 : 14, color: AppColors.ink),
          ),
          Text(
            b,
            style: AppText.body(size: big ? 16 : 14, color: AppColors.ink),
          ),
        ],
      ),
    );
    final side = Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DELIVERING TO', style: AppText.eyebrow()),
          const SizedBox(height: 8),
          SelectableText(
            [
              d.name,
              d.line1,
              if ((d.line2 ?? '').isNotEmpty) d.line2!,
              '${d.city}, ${d.region} ${d.postalCode}',
              d.country,
              d.phone,
            ].join('\n'),
            style: AppText.body(size: 14, color: AppColors.ink),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          line('Subtotal', formatMoney(order.subtotalCents)),
          line(
            'Shipping',
            order.shippingCents == 0
                ? 'Free'
                : formatMoney(order.shippingCents),
          ),
          line('Total', formatMoney(order.totalCents), big: true),
          const SizedBox(height: 12),
          Text(
            'Payment: pay on delivery',
            style: AppText.body(size: 12, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
    return isDesktop(context)
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: items),
              const SizedBox(width: 48),
              SizedBox(width: 340, child: side),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [items, const SizedBox(height: 32), side],
          );
  }
}
