/// Build-time settings, passed with `--dart-define-from-file=env.json` (see env.example.json).
///
/// Everything here is compiled into the public web app: only put values that are safe for
/// anyone to read. The Supabase publishable key is designed for that (Row Level Security
/// protects the data). Secrets such as the Mailgun key live in Supabase, never here.
class AppConfig {
  const AppConfig._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const currency = String.fromEnvironment(
    'CURRENCY',
    defaultValue: 'USD',
  );

  /// Custom URL scheme the Google sign-in returns to on Android and iOS. It must match the Android
  /// intent-filter, the iOS URL type and Supabase's Redirect URLs (docs/SETUP.md, mobile).
  static const mobileAuthRedirect = 'com.lookers.lookers://login-callback';

  /// Without Supabase settings the app runs in preview mode with the bundled sample catalogue.
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
