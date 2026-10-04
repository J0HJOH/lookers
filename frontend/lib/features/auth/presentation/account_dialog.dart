import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/ui/app_scope.dart';
import '../../../core/ui/logo.dart';
import '../../../core/ui/neu.dart';
import '../domain/safe_next_path.dart';

/// The profile popup. Signed out: sign in or sign up with Google, without leaving the page.
/// Signed in: who you are, your account, admin (if allowed) and sign out.
Future<void> showAccountDialog(BuildContext context) {
  // Where to come back to after Google (the page the shopper is on right now).
  final here = GoRouter.of(context).routeInformationProvider.value.uri;
  final returnTo = safeNextPath(
    here.hasQuery ? '${here.path}?${here.query}' : here.path,
    fallback: '/',
  );
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.photoScrim,
    builder: (_) => _AccountDialog(returnTo: returnTo),
  );
}

class _AccountDialog extends StatefulWidget {
  const _AccountDialog({required this.returnTo});

  final String returnTo;

  @override
  State<_AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<_AccountDialog> {
  bool _busy = false;
  String? _error;
  bool _startedSignedOut = false;

  @override
  void initState() {
    super.initState();
    _startedSignedOut = !AppScope.read(context).auth.isSignedIn;
  }

  Future<void> _signIn() async {
    final scope = AppScope.of(context);
    if (scope.isPreview) {
      setState(() => _error = 'Sign-in isn\'t set up yet. See docs/SETUP.md.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await scope.auth.signInWithGoogle(widget.returnTo);
      // The browser leaves for Google (web) or opens beside the app (phones); the dialog stays
      // until sign-in completes and closes itself below.
    } on Failure catch (f) {
      if (mounted) {
        setState(() {
          _error = f.message;
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: scope.auth,
      builder: (context, _) {
        final user = scope.auth.user;
        if (user != null && _startedSignedOut) {
          // Signing in finished (phones return to the app): close the popup.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && Navigator.of(context).canPop())
              Navigator.of(context).pop();
          });
        }
        return Dialog(
          backgroundColor: AppColors.clear,
          elevation: 0,
          insetPadding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: NeuBox(
              radius: 32,
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Close',
                      icon: Icon(Icons.close, color: AppColors.inkMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  if (user == null)
                    ..._signedOut()
                  else
                    ..._signedIn(
                      context,
                      scope,
                      user.firstName,
                      user.email,
                      user.isAdmin,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _signedOut() => [
    const Center(child: Logo(size: 64, withWordmark: true)),
    const SizedBox(height: 24),
    Text(
      'Sign in or sign up',
      textAlign: TextAlign.center,
      style: AppText.display(30),
    ),
    const SizedBox(height: 10),
    Text(
      'One tap with Google. New here? Your account is created automatically. Your bag follows you to every device.',
      textAlign: TextAlign.center,
      style: AppText.body(size: 14, color: AppColors.inkMuted),
    ),
    const SizedBox(height: 28),
    NeuButton.secondary(
      expand: true,
      onPressed: _busy ? null : _signIn,
      // Shrinks slightly instead of overflowing on narrow phones.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_circle_outlined, size: 20),
            const SizedBox(width: 10),
            Text(_busy ? 'REDIRECTING…' : 'CONTINUE WITH GOOGLE'),
          ],
        ),
      ),
    ),
    if (_error != null)
      Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Semantics(
          liveRegion: true,
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: AppText.body(size: 14, color: AppColors.danger),
          ),
        ),
      ),
    const SizedBox(height: 18),
    Text(
      'By continuing you agree to our terms and privacy policy.',
      textAlign: TextAlign.center,
      style: AppText.body(size: 12, color: AppColors.inkMuted),
    ),
  ];

  List<Widget> _signedIn(
    BuildContext context,
    AppScope scope,
    String firstName,
    String email,
    bool isAdmin,
  ) {
    void go(String location) {
      Navigator.of(context).pop();
      context.go(location);
    }

    return [
      Center(
        child: CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.surface,
          child: Text(
            firstName.isEmpty ? '?' : firstName[0].toUpperCase(),
            style: AppText.display(28, color: AppColors.accent),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text(
        'Hello, $firstName.',
        textAlign: TextAlign.center,
        style: AppText.display(28),
      ),
      const SizedBox(height: 4),
      Text(
        email,
        textAlign: TextAlign.center,
        style: AppText.body(size: 14, color: AppColors.inkMuted),
      ),
      const SizedBox(height: 24),
      NeuButton(
        expand: true,
        onPressed: () => go('/account'),
        child: const Text('MY ACCOUNT & ORDERS'),
      ),
      if (isAdmin) ...[
        const SizedBox(height: 14),
        NeuButton.secondary(
          expand: true,
          onPressed: () => go('/admin'),
          child: const Text('ADMIN DASHBOARD'),
        ),
      ],
      const SizedBox(height: 14),
      NeuButton.secondary(
        expand: true,
        onPressed: () async {
          final navigator = Navigator.of(context);
          final router = GoRouter.of(context);
          await scope.auth.signOut();
          navigator.pop();
          router.go('/');
        },
        child: const Text('SIGN OUT'),
      ),
    ];
  }
}
