import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/ui/app_scope.dart';
import '../../../core/ui/async_view.dart';
import '../../../core/ui/layout.dart';
import '../../orders/domain/order.dart';
import '../../orders/presentation/status_badge.dart';
import '../domain/admin_models.dart';
import 'admin_shell.dart';

class AdminOverviewPage extends StatelessWidget {
  const AdminOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AdminShell(
      location: '/admin',
      child: AsyncView<(AdminStats, List<Order>)>(
        load: () async {
          final stats = await adminOf(context).loadStats();
          final recent = await scope.orders.listOrders(limit: 6);
          return (stats, recent);
        },
        builder: (context, data) {
          final (stats, recent) = data;
          final tiles = [
            ('Revenue', formatMoney(stats.revenueCents)),
            ('Orders', '${stats.orderCount}'),
            ('Pending', '${stats.pendingCount}'),
            ('Customers', '${stats.customerCount}'),
          ];
          final recentList = _Section(
            title: 'Recent orders',
            empty: 'No orders yet.',
            children: [
              for (final o in recent)
                _Row(
                  onTap: () => context.go('/admin/orders/${o.id}'),
                  left: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: o.orderNumber,
                          style: AppText.body(
                            color: AppColors.ink,
                            weight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: '  ${formatDate(o.createdAt)}',
                          style: AppText.body(
                            size: 13,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  right: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusBadge(status: o.status),
                      const SizedBox(width: 16),
                      Text(
                        formatMoney(o.totalCents),
                        style: AppText.body(size: 14, color: AppColors.ink),
                      ),
                    ],
                  ),
                ),
            ],
          );
          final lowStock = _Section(
            title: 'Low stock',
            empty: 'Everything is well stocked.',
            children: [
              for (final p in stats.lowStock)
                _Row(
                  onTap: () => context.go('/admin/products/${p.id}'),
                  left: Text(p.name, style: AppText.body(color: AppColors.ink)),
                  right: Text(
                    p.stock == 0 ? 'Sold out' : '${p.stock} left',
                    style: AppText.body(
                      size: 14,
                      color: p.stock == 0 ? AppColors.danger : AppColors.ink,
                    ),
                  ),
                ),
            ],
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, c) {
                  final columns = c.maxWidth < 600 ? 2 : 4;
                  const gap = 16.0;
                  final w = (c.maxWidth - gap * (columns - 1)) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final t in tiles)
                        Container(
                          width: w,
                          color: AppColors.surface,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.$1.toUpperCase(),
                                style: AppText.eyebrow(),
                              ),
                              const SizedBox(height: 12),
                              Text(t.$2, style: AppText.display(40)),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 48),
              isDesktop(context)
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: recentList),
                        const SizedBox(width: 48),
                        Expanded(child: lowStock),
                      ],
                    )
                  : Column(
                      children: [
                        recentList,
                        const SizedBox(height: 40),
                        lowStock,
                      ],
                    ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.empty,
    required this.children,
  });

  final String title;
  final String empty;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.display(28)),
        const SizedBox(height: 16),
        if (children.isEmpty)
          Text(empty, style: AppText.body(color: AppColors.inkMuted))
        else ...[
          const Divider(),
          ...children,
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.left, required this.right, required this.onTap});

  final Widget left;
  final Widget right;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: left),
                const SizedBox(width: 12),
                right,
              ],
            ),
          ),
        ),
        const Divider(),
      ],
    );
  }
}
