/// Application-level failures. The data layer converts technical errors (network, SQL, HTTP)
/// into these; users only ever see [message], never raw exceptions or server text.
enum FailureKind {
  validation,
  notFound,
  network,
  auth,
  forbidden,
  outOfStock,
  server,
  unexpected,
  notConfigured,
}

class Failure implements Exception {
  const Failure(this.kind, this.message);

  final FailureKind kind;
  final String message;

  @override
  String toString() => 'Failure($kind): $message';
}
