class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.isAdmin = false,
  });

  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final bool isAdmin;

  String get firstName {
    final name = fullName?.trim();
    if (name == null || name.isEmpty) return 'there';
    return name.split(' ').first;
  }
}
