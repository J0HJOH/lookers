import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';

/// Converts technical errors into user-safe [Failure]s. Never expose the original message.
Failure mapSupabaseError(Object error) {
  if (error is Failure) return error;
  if (error is TimeoutException) {
    return const Failure(
      FailureKind.network,
      'The server took too long to respond. Please try again.',
    );
  }
  if (error is AuthException) {
    return const Failure(FailureKind.auth, 'Please sign in again.');
  }
  if (error is PostgrestException) {
    if (error.code == '42501') {
      return const Failure(
        FailureKind.forbidden,
        'You don\'t have permission to do that.',
      );
    }
    return const Failure(
      FailureKind.server,
      'Something went wrong on our side. Please try again.',
    );
  }
  final text = error.toString();
  if (text.contains('SocketException') ||
      text.contains('ClientException') ||
      text.contains('Failed host lookup')) {
    return const Failure(
      FailureKind.network,
      'We couldn\'t reach the server. Check your connection and try again.',
    );
  }
  return const Failure(
    FailureKind.unexpected,
    'Something unexpected happened. Please try again.',
  );
}
