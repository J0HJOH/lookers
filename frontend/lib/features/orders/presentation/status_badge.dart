import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../domain/order.dart';

/// Status is always a word as well as a colour, never colour alone.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color border, Color? fill, Color text) = switch (status) {
      OrderStatus.pending => (AppColors.accent, null, AppColors.accent),
      OrderStatus.confirmed => (AppColors.ink, null, AppColors.ink),
      OrderStatus.shipped => (AppColors.success, null, AppColors.success),
      OrderStatus.delivered => (
        AppColors.success,
        AppColors.success,
        AppColors.onPrimary,
      ),
      OrderStatus.cancelled => (AppColors.danger, null, AppColors.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: AppText.eyebrow(
          color: text,
        ).copyWith(fontSize: 10, letterSpacing: 2),
      ),
    );
  }
}
