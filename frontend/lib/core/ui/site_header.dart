import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/catalog/domain/catalog_query.dart';
import '../../features/catalog/domain/product.dart';
import '../formatting/money.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_scope.dart';
import 'layout.dart';
import 'logo.dart';
import 'neu.dart';
import 'product_image.dart';

/// Category navigation, shared by the header row and the mobile drawer.
const navLinks = <(String, String)>[
  ('New in', '/shop'),
  ('Men', '/shop?category=mens-clothing'),
  ('Women', '/shop?category=womens-clothing'),
  ('Baby', '/shop?category=baby-clothing'),
  ('Hats', '/shop?category=hats'),
  ('Shoes', '/shop?category=shoes'),
  ('Bags', '/shop?category=bags-accessories'),
];

/// Announcement strip, then logo + search + account + bag + theme toggle, then (desktop) the
/// category rail. Search is prominent and the bag shows a live count.
class SiteHeader extends StatelessWidget {
  const SiteHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);
    return Material(
      color: AppColors.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDeep, AppColors.primary],
              ),
            ),
            child: Text(
              mobile
                  ? 'FREE SHIPPING OVER \$250 · 30-DAY RETURNS'
                  : 'FREE SHIPPING ON ORDERS OVER \$250   ·   30-DAY RETURNS   ·   SIGN IN TO CHECK OUT',
              textAlign: TextAlign.center,
              style: AppText.eyebrow(
                color: AppColors.onPrimary,
              ).copyWith(fontSize: 10, letterSpacing: 2.2),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowDark.withValues(alpha: 0.6),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: mobile ? const _MobileHeader() : const _DesktopHeader(),
          ),
        ],
      ),
    );
  }
}

/// Sun / moon button: flips between light and dark mode (remembered on the device).
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppScope.of(context).theme;
    return ListenableBuilder(
      listenable: theme,
      builder: (context, _) => NeuIconButton(
        icon: theme.isDark
            ? Icons.light_mode_outlined
            : Icons.dark_mode_outlined,
        tooltip: theme.isDark ? 'Switch to light mode' : 'Switch to dark mode',
        onPressed: theme.toggle,
      ),
    );
  }
}

class _BagButton extends StatelessWidget {
  const _BagButton();

  @override
  Widget build(BuildContext context) {
    final cart = AppScope.of(context).cart;
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) => NeuIconButton(
        icon: Icons.shopping_bag_outlined,
        tooltip: 'Bag, ${cart.count} items',
        badge: cart.count,
        onPressed: () => context.go('/cart'),
      ),
    );
  }
}

class _AccountButton extends StatelessWidget {
  const _AccountButton();

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final user = auth.user;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (user?.isAdmin == true)
              TextButton(
                onPressed: () => context.go('/admin'),
                child: Text(
                  'ADMIN',
                  style: AppText.button(color: AppColors.accent),
                ),
              ),
            NeuIconButton(
              icon: Icons.person_outline,
              tooltip: user == null ? 'Sign in or sign up' : 'My account',
              onPressed: () => context.go(user == null ? '/login' : '/account'),
            ),
          ],
        );
      },
    );
  }
}

class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageContainer(
          child: SizedBox(
            height: 88,
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: 'Lookers home',
                  child: InkWell(
                    onTap: () => context.go('/'),
                    child: const Logo(size: 48),
                  ),
                ),
                const SizedBox(width: 40),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: const HeaderSearch(),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                const _AccountButton(),
                const SizedBox(width: 12),
                const _BagButton(),
                const SizedBox(width: 12),
                const ThemeToggleButton(),
              ],
            ),
          ),
        ),
        PageContainer(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 14),
          child: Row(
            children: [
              for (final l in navLinks)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: TextButton(
                    onPressed: () => context.go(l.$2),
                    child: Text(
                      l.$1.toUpperCase(),
                      style: AppText.button(
                        color: AppColors.ink,
                      ).copyWith(letterSpacing: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 68,
          child: PageContainer(
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Builder(
                      builder: (context) => NeuIconButton(
                        icon: Icons.menu,
                        tooltip: 'Menu',
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Lookers home',
                  child: InkWell(
                    onTap: () => context.go('/'),
                    child: const Logo(size: 40),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        _AccountIcon(),
                        SizedBox(width: 10),
                        _BagButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const PageContainer(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: HeaderSearch(),
        ),
      ],
    );
  }
}

class _AccountIcon extends StatelessWidget {
  const _AccountIcon();

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) => NeuIconButton(
        icon: Icons.person_outline,
        tooltip: auth.isSignedIn ? 'My account' : 'Sign in or sign up',
        onPressed: () => context.go(auth.isSignedIn ? '/account' : '/login'),
      ),
    );
  }
}

/// Search box with live suggestions. Enter searches the whole shop; tapping a suggestion opens the item.
class HeaderSearch extends StatefulWidget {
  const HeaderSearch({super.key});

  @override
  State<HeaderSearch> createState() => _HeaderSearchState();
}

class _HeaderSearchState extends State<HeaderSearch> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<Iterable<Product>> _suggest(TextEditingValue value) async {
    final query = value.text.trim();
    if (query.length < 2) return const [];
    // Wait for a pause in typing, then ignore the result if the text moved on.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted || _controller.text.trim() != query) return const [];
    try {
      final results = await AppScope.of(
        context,
      ).catalog.listProducts(CatalogQuery(search: query));
      return results.take(6);
    } catch (_) {
      // Suggestions are a convenience; pressing Enter still searches (and shows real errors).
      return const [];
    }
  }

  void _search(String text) {
    final query = text.trim();
    _focus.unfocus();
    context.go(
      query.isEmpty
          ? '/shop'
          : Uri(path: '/shop', queryParameters: {'q': query}).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<Product>(
      textEditingController: _controller,
      focusNode: _focus,
      optionsBuilder: _suggest,
      displayStringForOption: (p) => p.name,
      onSelected: (p) {
        _focus.unfocus();
        context.go('/product/${p.slug}');
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
          NeuTextField(
            controller: controller,
            focusNode: focusNode,
            hint: 'Search for items',
            textInputAction: TextInputAction.search,
            onSubmitted: _search,
            prefixIcon: Icon(Icons.search, color: AppColors.inkMuted),
            suffix: IconButton(
              tooltip: 'Search',
              icon: const Icon(Icons.arrow_forward, size: 18),
              onPressed: () => _search(controller.text),
            ),
          ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620, maxHeight: 400),
            child: NeuBox(
              radius: 20,
              padding: const EdgeInsets.all(8),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  for (final p in options)
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => onSelected(p),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 44,
                              height: 56,
                              child: ProductImage(url: p.imageUrl, radius: 10),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.body(
                                      color: AppColors.ink,
                                      weight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    p.categoryName,
                                    style: AppText.body(
                                      size: 12,
                                      color: AppColors.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              formatMoney(p.priceCents),
                              style: AppText.body(
                                size: 14,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
