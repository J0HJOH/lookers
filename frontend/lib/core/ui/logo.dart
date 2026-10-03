import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Lookers monogram: a large cursive "L" with a "K" tucked beneath it, optionally with the wordmark.
class Logo extends StatelessWidget {
  const Logo({
    super.key,
    this.size = 56,
    this.withWordmark = false,
    this.color = AppColors.ink,
  });

  final double size;
  final bool withWordmark;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox(
      width: size * 1.05,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: -size * 0.26,
            child: Text(
              'L',
              style: TextStyle(
                fontFamily: AppText.scriptFamily,
                fontSize: size * 1.25,
                height: 1.2,
                color: color,
              ),
            ),
          ),
          Positioned(
            left: size * 0.34,
            top: size * 0.12,
            child: Text(
              'K',
              style: TextStyle(
                fontFamily: AppText.scriptFamily,
                fontSize: size * 0.9,
                height: 1.2,
                color: AppColors.goldDeep,
              ),
            ),
          ),
        ],
      ),
    );
    return Semantics(
      label: 'Lookers',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            mark,
            if (withWordmark) ...[
              const SizedBox(height: 6),
              Text(
                'LOOKERS',
                style: AppText.display(
                  size * 0.22,
                  color: color,
                ).copyWith(letterSpacing: size * 0.09, height: 1.2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
