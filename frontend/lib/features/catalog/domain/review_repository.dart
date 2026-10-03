import 'review.dart';

abstract class ReviewRepository {
  /// Newest first. Implementations throw `Failure` on errors.
  Future<List<Review>> listForProduct(String productSlug);
}
