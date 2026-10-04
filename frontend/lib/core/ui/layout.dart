import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

bool isMobile(BuildContext context) =>
    MediaQuery.sizeOf(context).width < AppSizes.mobileBreakpoint;
bool isDesktop(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= AppSizes.desktopBreakpoint;

/// Centres content to the max width with responsive side padding.
class PageContainer extends StatelessWidget {
  const PageContainer({
    super.key,
    required this.child,
    this.maxWidth = AppSizes.maxContentWidth,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final side = isMobile(context) ? 20.0 : 32.0;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        // Fill the allowed width: a Column inside would otherwise shrink to its content and
        // sit as a narrow strip in the middle of the page.
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: padding ?? EdgeInsets.symmetric(horizontal: side),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Number of product columns for the available width.
int gridColumns(double width) => width < 520 ? 2 : (width < 900 ? 3 : 4);
