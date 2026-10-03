import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_scope.dart';
import 'layout.dart';
import 'logo.dart';
import 'site_header.dart';

/// Header + scrollable page + footer, shared by every route.
class SiteShell extends StatelessWidget {
  const SiteShell({super.key, required this.pathKey, required this.child});

  final String pathKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: isMobile(context) ? const _NavDrawer() : null,
      body: Column(
        children: [
          const SiteHeader(),
          Expanded(
            child: SingleChildScrollView(
              // A new key per route resets the scroll position on navigation.
              key: ValueKey(pathKey),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 420),
                    child: child,
                  ),
                  const _Footer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavDrawer extends StatelessWidget {
  const _NavDrawer();

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    void go(String location) {
      Navigator.of(context).pop();
      context.go(location);
    }

    return Drawer(
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: ListenableBuilder(
          listenable: scope.auth,
          builder: (context, _) {
            final user = scope.auth.user;
            final items = <(String, String)>[
              ...navLinks,
              if (user?.isAdmin == true) ('Admin', '/admin'),
              (
                user == null ? 'Sign in' : 'Account',
                user == null ? '/login' : '/account',
              ),
            ];
            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 24, left: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Logo(size: 52),
                  ),
                ),
                for (final item in items)
                  ListTile(
                    title: Text(
                      item.$1.toUpperCase(),
                      style: AppText.button().copyWith(color: AppColors.ink),
                    ),
                    onTap: () => go(item.$2),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);
    Widget column(String title, List<(String, String)> links) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: AppText.eyebrow()),
        const SizedBox(height: 10),
        for (final l in links)
          InkWell(
            onTap: () => context.go(l.$2),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(l.$1, style: AppText.body(size: 14)),
            ),
          ),
      ],
    );

    final brand = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Logo(size: 60, withWordmark: true),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Text(
            'Considered clothing for men, women and little ones, with the hats, shoes and bags to finish every look.',
            style: AppText.body(size: 14, color: AppColors.inkMuted),
          ),
        ),
      ],
    );
    final shop = column('Shop', const [
      ('Men', '/shop?category=mens-clothing'),
      ('Women', '/shop?category=womens-clothing'),
      ('Baby', '/shop?category=baby-clothing'),
      ('Shoes', '/shop?category=shoes'),
    ]);
    final help = column('Help', const [
      ('Shipping & returns', '/policies/shipping-returns'),
      ('Privacy', '/policies/privacy'),
      ('Terms', '/policies/terms'),
    ]);

    return Container(
      margin: const EdgeInsets.only(top: 96),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        children: [
          PageContainer(
            padding: EdgeInsets.symmetric(
              horizontal: mobile ? 20 : 32,
              vertical: 56,
            ),
            child: mobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      brand,
                      const SizedBox(height: 32),
                      shop,
                      const SizedBox(height: 24),
                      help,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: brand),
                      Expanded(child: shop),
                      Expanded(child: help),
                    ],
                  ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              '© ${DateTime.now().year} LOOKERS. ALL RIGHTS RESERVED.',
              style: AppText.eyebrow().copyWith(letterSpacing: 2.4),
            ),
          ),
        ],
      ),
    );
  }
}
