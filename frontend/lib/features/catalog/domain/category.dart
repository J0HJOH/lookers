class Category {
  const Category({
    required this.slug,
    required this.name,
    required this.tagline,
    required this.imageUrl,
    this.id = '',
  });

  final String id;
  final String slug;
  final String name;
  final String tagline;
  final String imageUrl;
}
