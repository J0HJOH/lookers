import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_scope.dart';

/// Shows [child] only for signed-in users (and admins when [adminOnly]). The router redirects
/// everyone else; this widget covers the moment before the auth state is known.
/// It is a convenience: the database (RLS) is the real access control.
class RequireAuth extends StatelessWidget {
  const RequireAuth({super.key, required this.child, this.adminOnly = false});

  final Widget child;
  final bool adminOnly;

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final allowed = auth.isSignedIn && (!adminOnly || auth.user!.isAdmin);
        if (allowed) return child;
        return SizedBox(
          height: 420,
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accent,
              ),
            ),
          ),
        );
      },
    );
  }
}
