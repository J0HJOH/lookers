import 'package:flutter/material.dart';

import '../error/failure.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'neu.dart';

/// Loads a future and shows loading / error (with Retry) / data states consistently.
class AsyncView<T> extends StatefulWidget {
  const AsyncView({
    super.key,
    required this.load,
    required this.builder,
    this.minHeight = 320,
  });

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;
  final double minHeight;

  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<T> _future = widget.load();

  void _retry() => setState(() => _future = widget.load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            height: widget.minHeight,
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
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          final message = error is Failure
              ? error.message
              : 'Something went wrong. Please try again.';
          return SizedBox(
            height: widget.minHeight,
            child: ErrorState(message: message, onRetry: _retry),
          );
        }
        return widget.builder(context, snapshot.data as T);
      },
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppText.body(color: AppColors.danger),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            NeuButton.secondary(onPressed: onRetry, child: const Text('RETRY')),
          ],
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 72),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.display(34),
            ),
            if (message != null) ...[
              const SizedBox(height: 10),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppText.body(color: AppColors.inkMuted),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 28),
              NeuButton(
                onPressed: onAction,
                child: Text(actionLabel!.toUpperCase()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
