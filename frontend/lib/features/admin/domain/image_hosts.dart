/// Hosts product images may come from. They must allow cross-origin image loading (CORS) for
/// the web app to display them. To allow Supabase Storage later, add `<project-ref>.supabase.co`.
const allowedImageHosts = ['images.pexels.com'];

bool isAllowedImageUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null &&
      uri.scheme == 'https' &&
      allowedImageHosts.contains(uri.host);
}
