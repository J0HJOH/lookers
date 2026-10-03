/// Only same-site relative paths are allowed after sign-in, so a `?next=` value can't become
/// an open redirect to another website.
String safeNextPath(String? next, {String fallback = '/account'}) {
  if (next == null ||
      !next.startsWith('/') ||
      next.startsWith('//') ||
      next.contains('\\'))
    return fallback;
  return next;
}
