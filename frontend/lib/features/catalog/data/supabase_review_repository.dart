import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/review.dart';
import '../domain/review_repository.dart';
import 'supabase_error_mapper.dart';

Review? reviewFromRow(Map<String, dynamic> r) {
  try {
    return Review(
      id: r['id'] as String,
      authorName: r['author_name'] as String,
      rating: r['rating'] as int,
      title: (r['title'] as String?) ?? '',
      body: r['body'] as String,
      size: r['size'] as String?,
      color: r['color'] as String?,
      createdAt: DateTime.parse(r['created_at'] as String),
    );
  } on TypeError {
    return null;
  } on FormatException {
    return null;
  }
}

class SupabaseReviewRepository implements ReviewRepository {
  SupabaseReviewRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Review>> listForProduct(String productSlug) async {
    try {
      final rows = await _client
          .from('reviews')
          .select(
            'id, author_name, rating, title, body, size, color, created_at, products!inner(slug)',
          )
          .eq('products.slug', productSlug)
          .order('created_at', ascending: false)
          .limit(50)
          .timeout(const Duration(seconds: 12));
      return rows.map(reviewFromRow).whereType<Review>().toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }
}
