import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/catalog/domain/catalog_query.dart';
import '../../features/catalog/domain/product.dart';
import '../formatting/money.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'app_scope.dart';
import 'layout.dart';
import 'logo.dart';
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

/// Announcement strip, then logo + search + account + bag, then (desktop) the category row.
/// Layout follows the familiar fast-fashion pattern: prominent search, bag count, category rail.
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
            color: AppColors.ink,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Text(
              mobile
                  ? 'FREE SHIPPING OVER \$250 · 30-DAY RETURNS'
                  : 'FREE SHIPPING ON ORDERS OVER \$250   ·   30-DAY RETURNS   ·   SIGN IN TO CHECK OUT',
              textAlign: TextAlign.center,
              style: AppText.eyebrow(
                color: AppColors.background,
              ).copyWith(fontSize: 10, letterSpacing: 2.4),
            ),
          ),
          mobile ? const _MobileHeader() : const _DesktopHeader(),
        ],
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
      builder: (context, _) {
        final count = cart.count;
        return Semantics(
          button: true,
          label: 'Bag, $count items',
          child: InkWell(
            onTap: () => context.go('/cart'),
            child: SizedBox(
              height: AppSizes.minTouchTarget,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Badge(
                      isLabelVisible: count > 0,
                      label: Text('$count'),
                      backgroundColor: AppColors.goldDeep,
                      textColor: AppColors.paper,
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: AppColors.ink,
                      ),
                    ),
                    if (!isMobile(context)) ...[
                      const SizedBox(width: 8),
                      Text(
                        'BAG',
                        style: AppText.button().copyWith(
                          color: AppColors.ink,
                          letterSpacing: 2.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
                  style: AppText.button().copyWith(
                    color: AppColors.goldDeep,
                    letterSpacing: 2.2,
                  ),
                ),
              ),
            Semantics(
              button: true,
              label: user == null ? 'Sign in or sign up' : 'My account',
              child: InkWell(
                onTap: () => context.go(user == null ? '/login' : '/account'),
                child: SizedBox(
                  height: AppSizes.minTouchTarget,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, color: AppColors.ink),
                        const SizedBox(width: 8),
                        Text(
                          user == null ? 'SIGN IN' : 'ACCOUNT',
                          style: AppText.button().copyWith(
                            color: AppColors.ink,
                            letterSpacing: 2.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
            height: 84,
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
                const _BagButton(),
              ],
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.line),
              bottom: BorderSide(color: AppColors.line),
            ),
          ),
          child: PageContainer(
            child: Row(
              children: [
                for (final l in navLinks)
                  TextButton(
                    onPressed: () => context.go(l.$2),
                    child: Text(
                      l.$1.toUpperCase(),
                      style: AppText.button().copyWith(
                        color: AppColors.ink,
                        letterSpacing: 2.2,
                      ),
                    ),
                  ),
              ],
            ),
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
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 60,
            child: PageContainer(
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Builder(
                        builder: (context) => IconButton(
                          tooltip: 'Menu',
                          icon: const Icon(Icons.menu),
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
                  const Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [_AccountIcon(), _BagButton()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const PageContainer(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: HeaderSearch(),
          ),
        ],
      ),
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
      builder: (context, _) => IconButton(
        tooltip: auth.isSignedIn ? 'My account' : 'Sign in or sign up',
        icon: const Icon(Icons.person_outline),
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
          TextField(
            controller: controller,
            focusNode: focusNode,
            textInputAction: TextInputAction.search,
            onSubmitted: _search,
            style: AppText.body(color: AppColors.ink),
            decoration: InputDecoration(
              hintText: 'Search for items',
              isDense: true,
              prefixIcon: const Icon(Icons.search, color: AppColors.inkMuted),
              suffixIcon: IconButton(
                tooltip: 'Search',
                icon: const Icon(Icons.arrow_forward, size: 18),
                onPressed: () => _search(controller.text),
              ),
            ),
          ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          color: AppColors.paper,
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: AppColors.line),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620, maxHeight: 380),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final p in options)
                  InkWell(
                    onTap: () => onSelected(p),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 44,
                            height: 58,
                            child: ProductImage(url: p.imageUrl),
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
                            style: AppText.body(size: 14, color: AppColors.ink),
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
    );
  }
}
