import 'app_user.dart';

abstract class AuthRepository {
  /// Emits whenever the signed-in user changes (including the initial state).
  Stream<AppUser?> get userChanges;
  AppUser? get currentUser;

  /// Resolves the initial state at startup (restores a stored or just-returned Google session).
  Future<AppUser?> restore();

  /// Starts Google sign-in; the browser leaves the site and returns to `/auth/callback`.
  Future<void> signInWithGoogle({required String nextPath});
  Future<void> signOut();
}
