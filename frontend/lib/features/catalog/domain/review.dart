/// A customer review. [size] and [color] are the variety the reviewer bought.
class Review {
  const Review({
    required this.id,
    required this.authorName,
    required this.rating,
    required this.title,
    required this.body,
    required this.createdAt,
    this.size,
    this.color,
  });

  final String id;
  final String authorName;
  final int rating;
  final String title;
  final String body;
  final String? size;
  final String? color;
  final DateTime createdAt;
}

/// Share of reviews per star (index 0 = 1 star ... index 4 = 5 stars), as fractions of the total.
List<double> ratingDistribution(List<Review> reviews) {
  if (reviews.isEmpty) return List.filled(5, 0);
  final counts = List.filled(5, 0);
  for (final r in reviews) {
    counts[(r.rating.clamp(1, 5)) - 1]++;
  }
  return [for (final c in counts) c / reviews.length];
}
