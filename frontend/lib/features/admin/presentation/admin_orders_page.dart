import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/failure.dart';
import '../../../core/formatting/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/ui/app_scope.dart';
import '../../../core/ui/async_view.dart';
import '../../orders/domain/order.dart';
import '../../orders/presentation/order_details.dart';
import '../../orders/presentation/status_badge.dart';
import 'admin_shell.dart';
import '../../../core/ui/neu.dart';

class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AdminShell(
      location: '/admin/orders',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Orders', style: AppText.display(40)),
          const SizedBox(height: 24),
          AsyncView<List<Order>>(
            load: () => scope.orders.listOrders(limit: 200),
            builder: (context, orders) {
              if (orders.isEmpty)
                return const EmptyState(title: 'No orders yet.');
              return Column(
                children: [
                  for (final o in orders) ...[
                    NeuTapCard(
                      onTap: () => context.go('/admin/orders/${o.id}'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runSpacing: 8,
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
                                  '${formatDate(o.createdAt)} · ${o.delivery.name} · ${o.email}',
                                  style: AppText.body(
                                    size: 13,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                StatusBadge(status: o.status),
                                const SizedBox(width: 20),
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
      ),
    );
  }
}

class AdminOrderPage extends StatefulWidget {
  const AdminOrderPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<AdminOrderPage> createState() => _AdminOrderPageState();
}

class _AdminOrderPageState extends State<AdminOrderPage> {
  int _version = 0; // bump to reload after a status change
  OrderStatus? _selected;
  String? _message;
  bool _busy = false;

  Future<void> _save(Order order) async {
    final status = _selected ?? order.status;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await adminOf(context).updateOrderStatus(order.id, status);
      setState(() {
        _version++;
        _selected = null;
        _busy = false;
        _message = 'Status updated. Customers see it in their account.';
      });
    } on Failure catch (f) {
      setState(() {
        _busy = false;
        _message = f.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AdminShell(
      location: '/admin/orders',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton(
            onPressed: () => context.go('/admin/orders'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Text('← ALL ORDERS', style: AppText.eyebrow()),
          ),
          const SizedBox(height: 16),
          AsyncView<Order?>(
            key: ValueKey('${widget.orderId}-$_version'),
            load: () => scope.orders.getOrder(widget.orderId),
            builder: (context, order) {
              if (order == null)
                return EmptyState(
                  title: 'Order not found.',
                  actionLabel: 'Back',
                  onAction: () => context.go('/admin/orders'),
                );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NeuBox(
                    inset: true,
                    radius: 22,
                    padding: const EdgeInsets.all(20),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<OrderStatus>(
                            initialValue: _selected ?? order.status,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Update status',
                            ),
                            items: [
                              for (final s in OrderStatus.values)
                                DropdownMenuItem(
                                  value: s,
                                  child: Text(s.label),
                                ),
                            ],
                            onChanged: (s) => setState(() => _selected = s),
                          ),
                        ),
                        NeuButton(
                          onPressed: _busy ? null : () => _save(order),
                          child: Text(_busy ? 'SAVING…' : 'SAVE'),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            _message ??
                                'Cancelling does not restock items yet; adjust stock on the product.',
                            style: AppText.body(
                              size: 12,
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  OrderDetails(order: order),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
