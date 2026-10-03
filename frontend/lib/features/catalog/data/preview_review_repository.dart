import '../domain/review.dart';
import '../domain/review_repository.dart';
import 'seed_catalog.dart';

class PreviewReviewRepository implements ReviewRepository {
  const PreviewReviewRepository();

  @override
  Future<List<Review>> listForProduct(String productSlug) async =>
      [...?seedReviewsBySlug[productSlug]]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}
