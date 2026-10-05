import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/ui/app_scope.dart';
import '../../../core/ui/layout.dart';
import '../../../core/ui/logo.dart';
import '../domain/safe_next_path.dart';
import '../../../core/ui/neu.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.next, this.hadError = false});

  final String? next;
  final bool hadError;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _busy = false;
  String? _error;

  Future<void> _signIn() async {
    final scope = AppScope.of(context);
    if (scope.isPreview) {
      setState(() => _error = AppConfig.missingConfigMessage);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await scope.auth.signInWithGoogle(safeNextPath(widget.next));
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
        if (scope.auth.isSignedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go(safeNextPath(widget.next));
          });
        }
        final message =
            _error ??
            (widget.hadError
                ? 'Sign-in didn\'t complete. Please try again.'
                : null);
        return PageContainer(
          maxWidth: 520,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 64),
          child: NeuBox(
            radius: 32,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile(context) ? 24 : 48,
              vertical: 48,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: Logo(size: 72, withWordmark: true)),
                const SizedBox(height: 32),
                Text(
                  'Sign in or sign up',
                  textAlign: TextAlign.center,
                  style: AppText.display(38),
                ),
                const SizedBox(height: 8),
                Text(
                  'One tap with Google. New here? Your account is created automatically.',
                  textAlign: TextAlign.center,
                  style: AppText.body(size: 14, color: AppColors.inkMuted),
                ),
                const SizedBox(height: 32),
                NeuButton.secondary(
                  expand: true,
                  onPressed: _busy ? null : _signIn,
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
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: AppText.body(size: 14, color: AppColors.danger),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  'By continuing you agree to our terms and privacy policy.',
                  textAlign: TextAlign.center,
                  style: AppText.body(size: 12, color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
