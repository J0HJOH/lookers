import 'package:flutter/foundation.dart' show TargetPlatform;

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

  /// Google "Web application" client id (the same one configured in Supabase). Phones use it to ask Google
  /// for an ID token that Supabase can verify. Public, not a secret.
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  /// Google "iOS" client id (iPhone only). Public, not a secret.
  static const googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );

  /// Phones sign in with Google's own account picker (no browser, no website) when the client ids exist:
  /// Android needs the web id; iOS needs the web id and the iOS id. Otherwise the app falls back to the
  /// browser flow. Pure so it can be tested.
  static bool shouldUseNativeGoogle({
    required bool isWeb,
    required TargetPlatform platform,
    required String webClientId,
    required String iosClientId,
  }) {
    if (isWeb || webClientId.isEmpty) return false;
    return switch (platform) {
      TargetPlatform.android => true,
      TargetPlatform.iOS => iosClientId.isNotEmpty,
      _ => false,
    };
  }

  /// Shown wherever sign-in or checkout is attempted without Supabase settings.
  static const missingConfigMessage =
      'This build has no Supabase settings, so sign-in is off. Run the app with '
      '--dart-define-from-file=env.json (see docs/SETUP.md).';

  /// Without Supabase settings the app runs in preview mode with the bundled sample catalogue.
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
