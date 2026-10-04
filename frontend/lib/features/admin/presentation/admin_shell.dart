import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/ui/app_scope.dart';
import '../../../core/ui/async_view.dart';
import '../../../core/ui/layout.dart';
import '../domain/admin_repository.dart';
import '../../../core/ui/neu.dart';

/// Wraps every admin page with the admin navigation, and shows a message if the database
/// isn't connected (preview mode).
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const _links = <(String, String)>[
    ('Overview', '/admin'),
    ('Products', '/admin/products'),
    ('Orders', '/admin/orders'),
  ];

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);
    return PageContainer(
      padding: EdgeInsets.symmetric(horizontal: mobile ? 20 : 32, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text('Admin', style: AppText.display(30)),
                ),
                for (final l in _links)
                  NeuSelectable(
                    selected: l.$2 == '/admin'
                        ? location == '/admin'
                        : location.startsWith(l.$2),
                    semanticLabel: l.$1,
                    radius: 16,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    onTap: () => context.go(l.$2),
                    child: Text(
                      l.$1.toUpperCase(),
                      style: AppText.button(
                        color:
                            (l.$2 == '/admin'
                                ? location == '/admin'
                                : location.startsWith(l.$2))
                            ? AppColors.accent
                            : AppColors.ink,
                      ).copyWith(letterSpacing: 1.8),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (AppScope.of(context).admin == null)
            const ErrorState(
              message: 'The database isn\'t connected yet. See docs/SETUP.md.',
            )
          else
            child,
        ],
      ),
    );
  }
}

AdminRepository adminOf(BuildContext context) => AppScope.of(context).admin!;
