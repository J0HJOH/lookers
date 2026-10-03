import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/ui/app_scope.dart';
import '../../../core/ui/async_view.dart';
import '../../../core/ui/layout.dart';
import '../domain/order.dart';
import 'order_details.dart';
import 'status_badge.dart';
import '../../../core/ui/neu.dart';

/// The customer dashboard: greeting, sign out and order history.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final mobile = isMobile(context);
    return PageContainer(
      padding: EdgeInsets.symmetric(horizontal: mobile ? 20 : 32, vertical: 48),
      child: ListenableBuilder(
        listenable: scope.auth,
        builder: (context, _) {
          final user = scope.auth.user;
          if (user == null) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.end,
                runSpacing: 16,
                spacing: 16,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('MY ACCOUNT', style: AppText.eyebrow()),
                      const SizedBox(height: 12),
                      Text(
                        'Hello, ${user.firstName}.',
                        style: AppText.display(mobile ? 44 : 56),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user.email,
                        style: AppText.body(color: AppColors.inkMuted),
                      ),
                    ],
                  ),
                  NeuButton.secondary(
                    onPressed: () async {
                      await scope.auth.signOut();
                      if (context.mounted) context.go('/');
                    },
                    child: const Text('SIGN OUT'),
                  ),
                ],
              ),
              const SizedBox(height: 56),
              Text('Your orders', style: AppText.display(34)),
              const SizedBox(height: 24),
              AsyncView<List<Order>>(
                load: scope.orders.listOrders,
                builder: (context, orders) {
                  if (orders.isEmpty) {
                    return NeuBox(
                      inset: true,
                      radius: 24,
                      child: EmptyState(
                        title: 'No orders yet.',
                        actionLabel: 'Start shopping',
                        onAction: () => context.go('/shop'),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final o in orders) ...[
                        NeuTapCard(
                          onTap: () => context.go('/account/orders/${o.id}'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              runSpacing: 10,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      o.orderNumber,
                                      style: AppText.body(
                                        color: AppColors.ink,
                                        weight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${formatDate(o.createdAt)} · ${o.items.length} item${o.items.length == 1 ? '' : 's'}',
                                      style: AppText.body(
                                        size: 14,
                                        color: AppColors.inkMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    StatusBadge(status: o.status),
                                    const SizedBox(width: 24),
                                    Text(
                                      formatMoney(o.totalCents),
                                      style: AppText.body(
                                        size: 14,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One of the customer's orders. RLS means someone else's id simply returns nothing.
class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({
    super.key,
    required this.orderId,
    this.backTo = '/account',
    this.backLabel = 'ALL ORDERS',
  });

  final String orderId;
  final String backTo;
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return PageContainer(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile(context) ? 20 : 32,
        vertical: 48,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton(
            onPressed: () => context.go(backTo),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Text('← $backLabel', style: AppText.eyebrow()),
          ),
          const SizedBox(height: 16),
          AsyncView<Order?>(
            key: ValueKey(orderId),
            load: () => scope.orders.getOrder(orderId),
            builder: (context, order) => order == null
                ? EmptyState(
                    title: 'Order not found.',
                    actionLabel: 'Back',
                    onAction: () => context.go(backTo),
                  )
                : OrderDetails(order: order),
          ),
        ],
      ),
    );
  }
}
