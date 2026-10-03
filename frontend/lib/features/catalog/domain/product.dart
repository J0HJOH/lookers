const lowStockThreshold = 5;

enum StockLevel { inStock, low, soldOut }

/// A colour variant, shown as a swatch. [hex] is product data (e.g. `#14110F`), not a theme colour.
class ProductColor {
  const ProductColor({required this.name, required this.hex});

  final String name;
  final String hex;
}

class Product {
  const Product({
    required this.id,
    required this.slug,
    required this.name,
    required this.description,
    required this.priceCents,
    required this.categorySlug,
    required this.categoryName,
    required this.imageUrl,
    required this.sizes,
    required this.stock,
    required this.featured,
    required this.active,
    this.categoryId = '',
    this.colors = const [],
    this.images = const [],
    this.ratingAvg = 0,
    this.ratingCount = 0,
  });

  final String id;
  final String slug;
  final String name;
  final String description;
  final int priceCents;
  final String categoryId;
  final String categorySlug;
  final String categoryName;
  final String imageUrl;
  final List<String> sizes;
  final int stock;
  final bool featured;
  final bool active;

  /// Colour variants. Empty means the product has no colour choice.
  final List<ProductColor> colors;

  /// Extra gallery photos after [imageUrl].
  final List<String> images;
  final double ratingAvg;
  final int ratingCount;

  /// Main photo first, then the extras.
  List<String> get gallery => [imageUrl, ...images];

  StockLevel get stockLevel => stock <= 0
      ? StockLevel.soldOut
      : stock <= lowStockThreshold
      ? StockLevel.low
      : StockLevel.inStock;
}
