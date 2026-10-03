import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/failure.dart';
import '../../../core/formatting/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/ui/async_view.dart';
import '../../../core/ui/layout.dart';
import '../../../core/ui/product_image.dart';
import '../../catalog/domain/category.dart';
import '../../catalog/domain/product.dart';
import '../domain/product_draft.dart';
import 'admin_shell.dart';

class AdminProductsPage extends StatelessWidget {
  const AdminProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      location: '/admin/products',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Products', style: AppText.display(40)),
              FilledButton(
                onPressed: () => context.go('/admin/products/new'),
                child: const Text('NEW PRODUCT'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AsyncView<List<Product>>(
            load: () => adminOf(context).listProducts(),
            builder: (context, products) {
              if (products.isEmpty) {
                return const EmptyState(
                  title: 'No products yet.',
                  message: 'Run supabase/seed.sql or add one.',
                );
              }
              return Column(
                children: [
                  const Divider(),
                  for (final p in products) ...[
                    InkWell(
                      onTap: () => context.go('/admin/products/${p.id}'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 44,
                              height: 58,
                              child: ProductImage(url: p.imageUrl),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: AppText.body(
                                      color: AppColors.ink,
                                      weight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${p.categoryName} · ${p.active ? 'Visible' : 'Hidden'}${p.featured ? ' · Featured' : ''}',
                                    style: AppText.body(
                                      size: 13,
                                      color: AppColors.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isMobile(context))
                              Padding(
                                padding: const EdgeInsets.only(right: 32),
                                child: Text(
                                  '${p.stock} in stock',
                                  style: AppText.body(
                                    size: 14,
                                    color: p.stock <= lowStockThreshold
                                        ? AppColors.danger
                                        : AppColors.ink,
                                  ),
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
                    const Divider(),
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

/// Create (id == null) or edit a product.
class AdminProductFormPage extends StatelessWidget {
  const AdminProductFormPage({super.key, this.productId});

  final String? productId;

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      location: '/admin/products',
      child: AsyncView<(List<Category>, Product?)>(
        key: ValueKey(productId),
        load: () async {
          final repo = adminOf(context);
          final categories = await repo.listCategories();
          final product = productId == null
              ? null
              : await repo.getProduct(productId!);
          return (categories, product);
        },
        builder: (context, data) {
          final (categories, product) = data;
          if (productId != null && product == null) {
            return EmptyState(
              title: 'Product not found.',
              actionLabel: 'Back',
              onAction: () => context.go('/admin/products'),
            );
          }
          return _ProductForm(categories: categories, product: product);
        },
      ),
    );
  }
}

class _ProductForm extends StatefulWidget {
  const _ProductForm({required this.categories, this.product});

  final List<Category> categories;
  final Product? product;

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  late final _name = TextEditingController(text: widget.product?.name);
  late final _slug = TextEditingController(text: widget.product?.slug);
  late final _description = TextEditingController(
    text: widget.product?.description,
  );
  late final _price = TextEditingController(
    text: widget.product == null
        ? ''
        : (widget.product!.priceCents / 100).toStringAsFixed(2),
  );
  late final _stock = TextEditingController(
    text: '${widget.product?.stock ?? 0}',
  );
  late final _sizes = TextEditingController(
    text: widget.product?.sizes.join(', ') ?? 'S, M, L',
  );
  late final _image = TextEditingController(text: widget.product?.imageUrl);
  late final _colors = TextEditingController(
    text:
        widget.product?.colors.map((c) => '${c.name}:${c.hex}').join(', ') ??
        '',
  );
  late final _gallery = TextEditingController(
    text: widget.product?.images.join('\n') ?? '',
  );
  late String _categoryId = widget.product?.categoryId ?? '';
  late bool _featured = widget.product?.featured ?? false;
  late bool _active = widget.product?.active ?? true;
  Map<String, String> _errors = {};
  String? _message;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [
      _name,
      _slug,
      _description,
      _price,
      _stock,
      _sizes,
      _image,
      _colors,
      _gallery,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final draft = ProductDraft(
      id: widget.product?.id,
      name: _name.text,
      slug: _slug.text,
      description: _description.text,
      price: _price.text,
      categoryId: _categoryId,
      imageUrl: _image.text,
      colors: _colors.text,
      images: _gallery.text,
      sizes: _sizes.text,
      stock: _stock.text,
      featured: _featured,
      active: _active,
    );
    final errors = draft.validate();
    if (errors.isNotEmpty) {
      setState(() {
        _errors = errors;
        _message = 'Please fix the highlighted fields.';
      });
      return;
    }
    setState(() {
      _busy = true;
      _errors = {};
      _message = null;
    });
    try {
      await adminOf(context).saveProduct(draft);
      if (mounted) context.go('/admin/products');
    } on Failure catch (f) {
      setState(() {
        _message = f.message;
        _busy = false;
      });
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(),
        backgroundColor: AppColors.background,
        title: Text('Delete this product?', style: AppText.display(26)),
        content: Text(
          'It will be removed from the shop. Past orders keep their details. To hide it instead, untick "Visible in the shop".',
          style: AppText.body(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'DELETE',
              style: AppText.button().copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await adminOf(context).deleteProduct(widget.product!.id);
      if (mounted) context.go('/admin/products');
    } on Failure catch (f) {
      setState(() => _message = f.message);
    }
  }

  Widget _text(
    TextEditingController c,
    String label,
    String key, {
    int maxLines = 1,
    TextInputType? type,
    String? hint,
  }) => TextField(
    controller: c,
    maxLines: maxLines,
    keyboardType: type,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: _errors[key],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);
    Widget two(Widget a, Widget b) => mobile
        ? Column(children: [a, const SizedBox(height: 16), b])
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: a),
              const SizedBox(width: 16),
              Expanded(child: b),
            ],
          );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.product?.name ?? 'New product',
            style: AppText.display(40),
          ),
          const SizedBox(height: 28),
          _text(_name, 'Name', 'name'),
          const SizedBox(height: 16),
          two(
            _text(_slug, 'Slug (URL)', 'slug', hint: 'noir-leather-jacket'),
            DropdownButtonFormField<String>(
              initialValue: _categoryId.isEmpty ? null : _categoryId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Category',
                errorText: _errors['categoryId'],
              ),
              items: [
                for (final c in widget.categories)
                  DropdownMenuItem(value: c.id, child: Text(c.name)),
              ],
              onChanged: (v) => setState(() => _categoryId = v ?? ''),
            ),
          ),
          const SizedBox(height: 16),
          _text(_description, 'Description', 'description', maxLines: 4),
          const SizedBox(height: 16),
          two(
            _text(
              _price,
              'Price',
              'price',
              type: TextInputType.number,
              hint: '49.99',
            ),
            _text(_stock, 'Stock', 'stock', type: TextInputType.number),
          ),
          const SizedBox(height: 16),
          _text(_sizes, 'Sizes (comma separated)', 'sizes'),
          const SizedBox(height: 16),
          _text(
            _image,
            'Image URL',
            'imageUrl',
            hint: 'https://images.pexels.com/photos/…',
          ),
          const SizedBox(height: 16),
          _text(
            _gallery,
            'More gallery photos (one URL per line, optional)',
            'images',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _text(
            _colors,
            'Colours (Name:#RRGGBB, comma separated, optional)',
            'colors',
            hint: 'Black:#14110F, Ivory:#F3EEE4',
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _featured,
            onChanged: (v) => setState(() => _featured = v ?? false),
            title: Text(
              'Featured on the homepage',
              style: AppText.body(color: AppColors.ink),
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _active,
            onChanged: (v) => setState(() => _active = v ?? true),
            title: Text(
              'Visible in the shop',
              style: AppText.body(color: AppColors.ink),
            ),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  _message!,
                  style: AppText.body(size: 14, color: AppColors.danger),
                ),
              ),
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(
                  _busy
                      ? 'SAVING…'
                      : (widget.product == null
                            ? 'CREATE PRODUCT'
                            : 'SAVE CHANGES'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => context.go('/admin/products'),
                child: const Text('CANCEL'),
              ),
            ],
          ),
          if (widget.product != null) ...[
            const SizedBox(height: 48),
            const Divider(),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _delete,
              child: Text(
                'DELETE PRODUCT',
                style: AppText.button().copyWith(
                  color: AppColors.danger,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
