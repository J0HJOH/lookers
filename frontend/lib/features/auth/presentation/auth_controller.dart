import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

/// Holds the signed-in user for the UI and for router redirects.
class AuthController extends ChangeNotifier {
  /// Pass a null [repository] in preview mode (no Supabase): nobody can sign in.
  AuthController(this._repository) : _ready = _repository == null {
    _subscription = _repository?.userChanges.listen((user) {
      _user = user;
      _ready = true;
      notifyListeners();
    });
  }

  final AuthRepository? _repository;
  StreamSubscription<AppUser?>? _subscription;
  AppUser? _user;
  bool _ready;

  AppUser? get user => _user;

  /// Resolves the initial auth state. Call once at startup, before the first route is shown.
  Future<void> init() async {
    final repository = _repository;
    if (repository == null) return;
    try {
      _user = await repository.restore();
    } catch (_) {
      // Treated as signed out; the user can sign in again.
    }
    _ready = true;
    notifyListeners();
  }

  bool get isSignedIn => _user != null;

  /// False until the first auth state is known (so guarded pages don't flash a redirect).
  bool get ready => _ready;

  String? _returnTo;

  bool get hasReturnTo => _returnTo != null;

  /// Where to go once the sign-in that was started from there completes (mobile: the browser hands
  /// control back to the app through a deep link, which lands on the home route). Taken once.
  String? takeReturnTo() {
    final path = _returnTo;
    _returnTo = null;
    return path;
  }

  Future<void> signInWithGoogle(String nextPath) {
    _returnTo = nextPath;
    return _repository!.signInWithGoogle(nextPath: nextPath);
  }

  Future<void> signOut() async {
    await _repository?.signOut();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
