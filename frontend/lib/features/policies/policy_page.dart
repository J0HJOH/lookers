import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/ui/async_view.dart';
import '../../core/ui/layout.dart';

const _policies = <String, (String, List<String>)>{
  'shipping-returns': (
    'Shipping & returns',
    [
      'Orders ship within 2 business days. Standard delivery takes 3-7 business days.',
      'Shipping is a flat fee, free on orders over \$250.',
      'Returns are accepted within 30 days for unworn items with tags attached. Contact us to start a return.',
    ],
  ),
  'privacy': (
    'Privacy',
    [
      'We collect the details you give us (name, email, delivery address, phone) to process orders and send confirmations.',
      'Sign-in is handled by Google through Supabase. We never see your Google password.',
      'We don\'t sell your data. Contact us to request a copy or deletion of your data.',
    ],
  ),
  'terms': (
    'Terms of service',
    [
      'By placing an order you agree to provide accurate delivery and contact details.',
      'Prices are shown in the store currency and confirmed when you place your order.',
      'We may cancel orders where stock or pricing errors occur and will tell you promptly.',
    ],
  ),
};

/// Draft policy text. The owner must review it before launch.
class PolicyPage extends StatelessWidget {
  const PolicyPage({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final policy = _policies[slug];
    if (policy == null) {
      return EmptyState(
        title: 'Page not found.',
        actionLabel: 'Back to the shop',
        onAction: () => context.go('/shop'),
      );
    }
    return PageContainer(
      maxWidth: 760,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile(context) ? 20 : 32,
        vertical: 64,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(policy.$1, style: AppText.display(56)),
          const SizedBox(height: 32),
          for (final p in policy.$2)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(p, style: AppText.body(size: 16)),
            ),
          const SizedBox(height: 24),
          Text(
            'Draft text. Have it reviewed before launch.',
            style: AppText.body(size: 12, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}
