import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/failure.dart';
import '../../catalog/data/supabase_error_mapper.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client) {
    _subscription = _client.auth.onAuthStateChange.listen((_) => _refresh());
  }

  final SupabaseClient _client;
  late final StreamSubscription<AuthState> _subscription;
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _current;

  @override
  AppUser? get currentUser => _current;

  @override
  Stream<AppUser?> get userChanges => _controller.stream;

  @override
  Future<AppUser?> restore() async {
    await _refresh();
    return _current;
  }

  Future<void> _refresh() async {
    final session = _client.auth.currentSession;
    if (session == null) {
      _emit(null);
      return;
    }
    // Validate against Supabase Auth rather than trusting the stored token.
    try {
      final response = await _client.auth.getUser();
      final user = response.user;
      if (user == null) {
        _emit(null);
        return;
      }
      final profile = await _client
          .from('profiles')
          .select('full_name, avatar_url, role')
          .eq('id', user.id)
          .maybeSingle();
      _emit(
        AppUser(
          id: user.id,
          email: user.email ?? '',
          fullName: profile?['full_name'] as String?,
          avatarUrl: profile?['avatar_url'] as String?,
          isAdmin: profile?['role'] == 'admin',
        ),
      );
    } catch (_) {
      // Network hiccup: keep whatever we had rather than signing the user out.
      _emit(_current);
    }
  }

  void _emit(AppUser? user) {
    _current = user;
    _controller.add(user);
  }

  @override
  Future<void> signInWithGoogle({required String nextPath}) async {
    if (AppConfig.shouldUseNativeGoogle(
      isWeb: kIsWeb,
      platform: defaultTargetPlatform,
      webClientId: AppConfig.googleWebClientId,
      iosClientId: AppConfig.googleIosClientId,
    )) {
      return _signInWithNativeGoogle();
    }
    try {
      // Web returns to our own /auth/callback page. On a phone the system browser returns to the
      // app through its custom URL scheme (a deep link); supabase_flutter completes the sign-in.
      final redirectTo = kIsWeb
          ? '${Uri.base.origin}/auth/callback?next=${Uri.encodeQueryComponent(nextPath)}'
          : AppConfig.mobileAuthRedirect;
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
    } catch (e) {
      final failure = mapSupabaseError(e);
      throw Failure(
        failure.kind,
        'We couldn\'t start Google sign-in. Please try again.',
      );
    }
  }

  bool _googleReady = false;

  /// Phone sign-in: Google's own account picker (no browser, no website), then Supabase verifies
  /// Google's ID token. Cancelling the picker is not an error.
  Future<void> _signInWithNativeGoogle() async {
    try {
      final google = GoogleSignIn.instance;
      if (!_googleReady) {
        await google.initialize(
          clientId: AppConfig.googleIosClientId.isEmpty
              ? null
              : AppConfig.googleIosClientId,
          serverClientId: AppConfig.googleWebClientId,
        );
        _googleReady = true;
      }
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const Failure(
          FailureKind.auth,
          'Google didn\'t return a sign-in token. Please try again.',
        );
      }
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
      // onAuthStateChange fires next, which loads the profile and updates the UI.
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted)
        return;
      throw const Failure(
        FailureKind.auth,
        'Google sign-in didn\'t complete. Please try again.',
      );
    } on Failure {
      rethrow;
    } catch (_) {
      throw const Failure(
        FailureKind.auth,
        'Google sign-in didn\'t complete. Please try again.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    if (_googleReady) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // The Supabase session is what matters; ignore a Google-side sign-out hiccup.
      }
    }
    await _client.auth.signOut();
  }

  void dispose() {
    _subscription.cancel();
    _controller.close();
  }
}
