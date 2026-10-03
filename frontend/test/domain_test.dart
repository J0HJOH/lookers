import 'package:flutter_test/flutter_test.dart';
import 'package:lookers/features/admin/domain/product_draft.dart';
import 'package:lookers/features/auth/domain/safe_next_path.dart';
import 'package:lookers/features/catalog/data/seed_catalog.dart';
import 'package:lookers/features/catalog/data/supabase_catalog_repository.dart';
import 'package:lookers/features/catalog/domain/catalog_query.dart';
import 'package:lookers/features/catalog/domain/product.dart';
import 'package:lookers/features/catalog/domain/review.dart';
import 'package:lookers/features/orders/data/supabase_order_repository.dart';
import 'package:lookers/features/orders/domain/order.dart';
import 'package:lookers/core/formatting/money.dart';

ProductDraft draft({
  String slug = 'noir-jacket',
  String price = '49.99',
  String image = 'https://images.pexels.com/photos/1/x.jpeg',
  String sizes = 'S, M',
  String stock = '4',
  String category = 'c1',
}) => ProductDraft(
  name: 'Noir Jacket',
  slug: slug,
  description: '',
  price: price,
  categoryId: category,
  imageUrl: image,
  sizes: sizes,
  stock: stock,
  featured: false,
  active: true,
);

void main() {
  variantTests();
  test('safeNextPath allows same-site paths and blocks open redirects', () {
    expect(safeNextPath('/checkout'), '/checkout');
    for (final bad in [
      'https://evil.com',
      '//evil.com',
      r'/\evil.com',
      'evil',
      '',
      null,
    ]) {
      expect(safeNextPath(bad), '/account');
    }
  });

  test(
    'formatMoney shows currency from cents',
    () => expect(formatMoney(11500, currency: 'USD'), r'$115.00'),
  );

  group('catalog query', () {
    test('filters by category and search', () {
      final shoes = applyCatalogQuery(
        seedProducts,
        const CatalogQuery(categorySlug: 'shoes'),
      );
      expect(shoes, isNotEmpty);
      expect(shoes.every((p) => p.categorySlug == 'shoes'), isTrue);
      final found = applyCatalogQuery(
        seedProducts,
        const CatalogQuery(search: 'LEATHER'),
      );
      expect(
        found.every(
          (p) => (p.name + p.description).toLowerCase().contains('leather'),
        ),
        isTrue,
      );
    });
    test('sorts by price', () {
      final asc = applyCatalogQuery(
        seedProducts,
        const CatalogQuery(sort: SortKey.priceAsc),
      ).map((p) => p.priceCents).toList();
      expect(asc, [...asc]..sort());
    });
    test('every seed category has products', () {
      for (final c in seedCategories) {
        expect(
          seedProducts.any((p) => p.categorySlug == c.slug),
          isTrue,
          reason: c.slug,
        );
      }
    });
    test('stock levels', () {
      Product withStock(int s) => seedProducts.first.copyWithStock(s);
      expect(withStock(0).stockLevel, StockLevel.soldOut);
      expect(withStock(3).stockLevel, StockLevel.low);
      expect(withStock(30).stockLevel, StockLevel.inStock);
    });
  });

  group('ProductDraft', () {
    test('accepts a valid product and converts price to cents', () {
      final d = draft();
      expect(d.validate(), isEmpty);
      expect(d.toRow()['price_cents'], 4999);
      expect(d.toRow()['sizes'], ['S', 'M']);
    });
    test('rejects bad slug, price, stock and foreign image hosts', () {
      expect(draft(slug: 'Bad Slug').validate().keys, contains('slug'));
      expect(draft(price: '-5').validate().keys, contains('price'));
      expect(draft(price: '1e3').validate().keys, contains('price'));
      expect(draft(stock: '1.5').validate().keys, contains('stock'));
      expect(
        draft(image: 'http://images.pexels.com/x.jpg').validate().keys,
        contains('imageUrl'),
      );
      expect(
        draft(image: 'https://evil.example/x.jpg').validate().keys,
        contains('imageUrl'),
      );
      expect(draft(category: '').validate().keys, contains('categoryId'));
      expect(draft(sizes: ' , ').validate().keys, contains('sizes'));
    });
  });

  group('row parsing', () {
    test('productFromRow drops malformed rows instead of throwing', () {
      expect(productFromRow({'id': 1}), isNull);
      expect(
        productFromRow({
          'id': 'p',
          'slug': 's',
          'name': 'N',
          'description': 'd',
          'price_cents': 100,
          'category_id': 'c',
          'image_url': 'u',
          'sizes': ['M'],
          'stock': 1,
          'featured': false,
          'active': true,
          'categories': {'slug': 'x', 'name': 'X'},
        }),
        isNotNull,
      );
    });
    test('orderFromRow rejects unknown statuses', () {
      expect(orderFromRow({'status': 'weird'}), isNull);
      expect(OrderStatus.tryParse('shipped'), OrderStatus.shipped);
    });
  });
}

extension on Product {
  Product copyWithStock(int stock) => Product(
    id: id,
    slug: slug,
    name: name,
    description: description,
    priceCents: priceCents,
    categorySlug: categorySlug,
    categoryName: categoryName,
    imageUrl: imageUrl,
    sizes: sizes,
    stock: stock,
    featured: featured,
    active: active,
  );
}

void variantTests() {
  group('variants, reviews and ratings', () {
    test('every seed product has colours, a gallery and 2-3 dummy reviews', () {
      for (final p in seedProducts) {
        expect(p.colors, isNotEmpty, reason: p.slug);
        expect(p.gallery.length, greaterThan(1), reason: p.slug);
        final n = seedReviewsBySlug[p.slug]!.length;
        expect(n, inInclusiveRange(2, 3), reason: p.slug);
        expect(p.ratingCount, n, reason: p.slug);
        expect(p.ratingAvg, inInclusiveRange(1, 5));
      }
    });
    test('each review shows a variety the product really offers', () {
      for (final p in seedProducts) {
        for (final r in seedReviewsBySlug[p.slug]!) {
          expect(p.sizes, contains(r.size), reason: p.slug);
          expect(
            p.colors.map((c) => c.name),
            contains(r.color),
            reason: p.slug,
          );
        }
      }
    });
    test('rating distribution sums to 1 and handles no reviews', () {
      expect(ratingDistribution(const []), everyElement(0));
      final shares = ratingDistribution(
        seedReviewsBySlug[seedProducts.first.slug]!,
      );
      expect(shares.reduce((a, b) => a + b), closeTo(1, 1e-9));
    });
    test('draft colours and gallery are parsed and validated', () {
      final ok = draft().copyForVariants(
        colors: 'Black:#14110F, Ivory:#F3EEE4',
        images: 'https://images.pexels.com/photos/2/x.jpeg',
      );
      expect(ok.validate(), isEmpty);
      expect(ok.toRow()['colors'], [
        {'name': 'Black', 'hex': '#14110F'},
        {'name': 'Ivory', 'hex': '#F3EEE4'},
      ]);
      expect(
        draft().copyForVariants(colors: 'Black:red').validate().keys,
        contains('colors'),
      );
      expect(
        draft()
            .copyForVariants(images: 'https://evil.example/x.jpg')
            .validate()
            .keys,
        contains('images'),
      );
    });
  });
}

extension on ProductDraft {
  ProductDraft copyForVariants({String colors = '', String images = ''}) =>
      ProductDraft(
        name: name,
        slug: slug,
        description: description,
        price: price,
        categoryId: categoryId,
        imageUrl: imageUrl,
        sizes: sizes,
        stock: stock,
        featured: featured,
        active: active,
        colors: colors,
        images: images,
      );
}
