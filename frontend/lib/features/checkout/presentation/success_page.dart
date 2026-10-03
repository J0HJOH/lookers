import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/ui/app_scope.dart';
import '../../../core/ui/async_view.dart';
import '../../../core/ui/layout.dart';
import '../../orders/domain/order.dart';
import '../../../core/ui/neu.dart';

class CheckoutSuccessPage extends StatelessWidget {
  const CheckoutSuccessPage({super.key, required this.orderId});

  final String? orderId;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final id = orderId;
    return PageContainer(
      maxWidth: 720,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
      child: id == null
          ? EmptyState(
              title: 'Order not found.',
              actionLabel: 'Back to the shop',
              onAction: () => context.go('/shop'),
            )
          : AsyncView<Order?>(
              load: () => scope.orders.getOrder(id),
              builder: (context, order) {
                if (order == null) {
                  return EmptyState(
                    title: 'Order not found.',
                    actionLabel: 'View my orders',
                    onAction: () => context.go('/account'),
                  );
                }
                return Column(
                  children: [
                    Text('ORDER CONFIRMED', style: AppText.eyebrow()),
                    const SizedBox(height: 16),
                    Text(
                      'Thank you.',
                      style: AppText.display(isMobile(context) ? 52 : 68),
                    ),
                    const SizedBox(height: 20),
                    Text.rich(
                      textAlign: TextAlign.center,
                      TextSpan(
                        children: [
                          const TextSpan(text: 'Your order '),
                          TextSpan(
                            text: order.orderNumber,
                            style: AppText.body(
                              color: AppColors.ink,
                              weight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(
                            text:
                                ' is in. A confirmation is on its way to ${order.email}.',
                          ),
                        ],
                      ),
                      style: AppText.body(size: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total ${formatMoney(order.totalCents)} · pay on delivery',
                      style: AppText.body(color: AppColors.inkMuted),
                    ),
                    const SizedBox(height: 40),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        NeuButton(
                          onPressed: () =>
                              context.go('/account/orders/${order.id}'),
                          child: const Text('VIEW ORDER'),
                        ),
                        NeuButton.secondary(
                          onPressed: () => context.go('/shop'),
                          child: const Text('KEEP SHOPPING'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
    );
  }
}
