import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/ui/app_scope.dart';
import '../domain/safe_next_path.dart';

/// Landing page after Google. supabase_flutter exchanges the `?code=` for a session at startup;
/// this page waits for the session, then forwards to the (validated) `next` path.
class AuthCallbackPage extends StatefulWidget {
  const AuthCallbackPage({super.key, this.next});

  final String? next;

  @override
  State<AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends State<AuthCallbackPage> {
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    _timeout = Timer(const Duration(seconds: 10), () {
      if (mounted) context.go('/login?error=1');
    });
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        if (auth.isSignedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go(safeNextPath(widget.next));
          });
        }
        return SizedBox(
          height: 420,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 20),
                Text('Signing you in…', style: AppText.body()),
              ],
            ),
          ),
        );
      },
    );
  }
}
