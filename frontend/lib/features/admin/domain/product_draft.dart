import 'image_hosts.dart';

/// Product form values as typed by the admin, with the same rules the database enforces.
class ProductDraft {
  const ProductDraft({
    this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.imageUrl,
    required this.sizes,
    required this.stock,
    required this.featured,
    required this.active,
    this.colors = '',
    this.images = '',
  });

  final String? id;
  final String name;
  final String slug;
  final String description;
  final String price;
  final String categoryId;
  final String imageUrl;
  final String sizes;
  final String stock;
  final bool featured;
  final bool active;

  /// One per line or comma separated: `Name:#RRGGBB`.
  final String colors;

  /// Extra gallery photo URLs, one per line.
  final String images;

  static final _slug = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');
  static final _price = RegExp(r'^\d{1,7}(\.\d{1,2})?$');
  static final _stock = RegExp(r'^\d{1,6}$');
  static final _hex = RegExp(r'^#[0-9a-fA-F]{6}$');

  int? get priceCents => _price.hasMatch(price.trim())
      ? (double.parse(price.trim()) * 100).round()
      : null;
  List<String> get sizeList =>
      sizes.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  /// Parsed colour variants. Entries that don't match `Name:#RRGGBB` are skipped here and
  /// reported by [validate].
  List<({String name, String hex})> get colorList => [
    for (final part in colors.split(RegExp(r'[\n,]')))
      if (part.trim().isNotEmpty && part.contains(':'))
        if (_hex.hasMatch(part.split(':').last.trim()))
          (
            name: part.split(':').first.trim(),
            hex: part.split(':').last.trim().toUpperCase(),
          ),
  ];

  List<String> get imageList => images
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  Map<String, String> validate() {
    final e = <String, String>{};
    if (name.trim().isEmpty) e['name'] = 'Name is required.';
    if (name.trim().length > 120) e['name'] = 'Name is too long.';
    if (!_slug.hasMatch(slug.trim().toLowerCase()))
      e['slug'] = 'Use lowercase letters, numbers and hyphens.';
    if (description.trim().length > 2000)
      e['description'] = 'Description is too long.';
    if (priceCents == null) e['price'] = 'Enter a price like 49.99.';
    if (categoryId.isEmpty) e['categoryId'] = 'Choose a category.';
    if (!isAllowedImageUrl(imageUrl.trim())) {
      e['imageUrl'] =
          'Image must be an https URL from: ${allowedImageHosts.join(', ')}.';
    }
    final list = sizeList;
    if (list.isEmpty) {
      e['sizes'] = 'Add at least one size.';
    } else if (list.length > 15 || list.any((s) => s.length > 20)) {
      e['sizes'] = 'Up to 15 sizes, each at most 20 characters.';
    }
    if (!_stock.hasMatch(stock.trim()))
      e['stock'] = 'Stock must be a whole number.';
    final rawColors = colors
        .split(RegExp(r'[\n,]'))
        .where((s) => s.trim().isNotEmpty)
        .length;
    if (rawColors != colorList.length ||
        rawColors > 12 ||
        colorList.any((c) => c.name.isEmpty || c.name.length > 30)) {
      e['colors'] =
          'Use Name:#RRGGBB, for example Black:#14110F (up to 12 colours).';
    }
    if (imageList.length > 8 || imageList.any((u) => !isAllowedImageUrl(u))) {
      e['images'] =
          'Up to 8 https image URLs from: ${allowedImageHosts.join(', ')}. One per line.';
    }
    return e;
  }

  Map<String, dynamic> toRow() => {
    'name': name.trim(),
    'slug': slug.trim().toLowerCase(),
    'description': description.trim(),
    'price_cents': priceCents,
    'category_id': categoryId,
    'image_url': imageUrl.trim(),
    'sizes': sizeList,
    'stock': int.parse(stock.trim()),
    'featured': featured,
    'active': active,
    'colors': [
      for (final c in colorList) {'name': c.name, 'hex': c.hex},
    ],
    'images': imageList,
  };
}
