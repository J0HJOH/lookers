import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Neumorphism ("soft UI") building blocks. Surfaces share the page colour and are lifted (raised)
/// or pressed in (inset) using a light shadow from the top-left and a dark one to the bottom-right.
class Neu {
  const Neu._();

  static const radius = 20.0;
  static const smallRadius = 14.0;

  /// Two-sided soft shadow. [depth] scales distance and blur (1 = cards, 0.5 = chips).
  static List<BoxShadow> raised({double depth = 1}) => [
    BoxShadow(
      color: AppColors.shadowDark,
      offset: Offset(6 * depth, 6 * depth),
      blurRadius: 16 * depth,
    ),
    BoxShadow(
      color: AppColors.shadowLight,
      offset: Offset(-6 * depth, -6 * depth),
      blurRadius: 16 * depth,
    ),
  ];
}

/// A neumorphic surface: raised (default) or inset (pressed in).
class NeuBox extends StatelessWidget {
  const NeuBox({
    super.key,
    required this.child,
    this.radius = Neu.radius,
    this.padding = EdgeInsets.zero,
    this.inset = false,
    this.depth = 1,
    this.color,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool inset;
  final double depth;

  /// Fill override (e.g. the purple of a primary button). Defaults to the page colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fill = color ?? (inset ? AppColors.surface : AppColors.background);
    if (inset) {
      return CustomPaint(
        painter: _InsetPainter(
          radius: radius,
          fill: fill,
          dark: AppColors.shadowDark,
          light: AppColors.shadowLight,
          depth: depth,
        ),
        child: Padding(padding: padding, child: child),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: Neu.raised(depth: depth),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Paints a pressed-in surface: a dark shadow along the top-left edges and a light one along the
/// bottom-right, clipped to the shape (Flutter has no built-in inset shadow).
class _InsetPainter extends CustomPainter {
  _InsetPainter({
    required this.radius,
    required this.fill,
    required this.dark,
    required this.light,
    required this.depth,
  });

  final double radius;
  final Color fill;
  final Color dark;
  final Color light;
  final double depth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(shape, Paint()..color = fill);
    canvas.save();
    canvas.clipRRect(shape);
    void shadow(Color color, Offset offset) {
      // A big rectangle with the (shifted) shape cut out, filled even-odd: the part that remains
      // inside the clip is a thin edge strip, which the blur softens. (Path.combine is avoided on
      // purpose: it misbehaves on the web renderer and flooded the whole field.)
      final cast = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(rect.inflate(60))
        ..addRRect(shape.shift(offset));
      canvas.drawPath(
        cast,
        Paint()
          ..color = color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * depth),
      );
    }

    shadow(dark, Offset(4 * depth, 4 * depth));
    shadow(light, Offset(-4 * depth, -4 * depth));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_InsetPainter old) =>
      old.radius != radius ||
      old.fill != fill ||
      old.dark != dark ||
      old.light != light ||
      old.depth != depth;
}

/// A tappable neumorphic button. Primary = purple, raised. Secondary = surface-coloured, raised,
/// purple text. Pressing sinks it in. Same call shape as FilledButton/OutlinedButton.
class NeuButton extends StatefulWidget {
  const NeuButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.primary = true,
    this.expand = false,
  });

  /// Secondary style (outlined-button replacement).
  const NeuButton.secondary({
    super.key,
    required this.onPressed,
    required this.child,
    this.expand = false,
  }) : primary = false;

  final VoidCallback? onPressed;
  final Widget child;
  final bool primary;

  /// Fill the available width.
  final bool expand;

  @override
  State<NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<NeuButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final textColor = !enabled
        ? AppColors.inkMuted
        : (widget.primary ? AppColors.onPrimary : AppColors.accent);
    final fill = !enabled
        ? AppColors.surface
        : (widget.primary ? AppColors.primary : AppColors.background);
    const radius = 16.0;
    final label = DefaultTextStyle.merge(
      style: AppText.button(color: textColor),
      child: IconTheme.merge(
        data: IconThemeData(color: textColor, size: 18),
        child: Center(widthFactor: 1, child: widget.child),
      ),
    );
    final body = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        child: label,
      ),
    );

    final Widget surface;
    if (!enabled) {
      surface = NeuBox(
        radius: radius,
        color: fill,
        inset: true,
        depth: 0.5,
        child: body,
      );
    } else if (_pressed) {
      surface = NeuBox(
        radius: radius,
        color: widget.primary ? AppColors.primaryDeep : null,
        inset: !widget.primary,
        depth: 0.7,
        child: body,
      );
    } else {
      surface = NeuBox(radius: radius, color: fill, depth: 0.8, child: body);
    }

    return Semantics(
      button: true,
      enabled: enabled,
      child: SizedBox(
        width: widget.expand ? double.infinity : null,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onPressed,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            borderRadius: BorderRadius.circular(radius),
            splashColor: AppColors.clear,
            highlightColor: AppColors.clear,
            hoverColor: AppColors.accentSoft.withValues(alpha: 0.12),
            focusColor: AppColors.accentSoft.withValues(alpha: 0.2),
            child: surface,
          ),
        ),
      ),
    );
  }
}

/// A selectable chip (size, colour swatch, payment option). Raised when idle, pressed in when selected.
class NeuSelectable extends StatelessWidget {
  const NeuSelectable({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    this.radius = Neu.smallRadius,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    this.semanticLabel,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: AppColors.clear,
          highlightColor: AppColors.clear,
          hoverColor: AppColors.accentSoft.withValues(alpha: 0.12),
          child: NeuBox(
            radius: radius,
            inset: selected,
            depth: selected ? 0.6 : 0.5,
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Round raised icon button for the header.
class NeuIconButton extends StatelessWidget {
  const NeuIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badge = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            splashColor: AppColors.clear,
            highlightColor: AppColors.clear,
            hoverColor: AppColors.accentSoft.withValues(alpha: 0.12),
            child: NeuBox(
              radius: 24,
              depth: 0.45,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Badge(
                  isLabelVisible: badge > 0,
                  label: Text('$badge'),
                  backgroundColor: AppColors.primary,
                  textColor: AppColors.onPrimary,
                  child: Center(
                    child: Icon(icon, size: 21, color: AppColors.ink),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A text field sunk into the surface. The label sits above, the error below the box.
class NeuTextField extends StatefulWidget {
  const NeuTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.autofillHints,
    this.onSubmitted,
    this.onChanged,
    this.prefixIcon,
    this.suffix,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Widget? prefixIcon;
  final Widget? suffix;

  @override
  State<NeuTextField> createState() => _NeuTextFieldState();
}

class _NeuTextFieldState extends State<NeuTextField> {
  late final FocusNode _ownFocus = FocusNode();
  FocusNode get _focus => widget.focusNode ?? _ownFocus;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() => setState(() => _focused = _focus.hasFocus);

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _ownFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final outline = hasError
        ? AppColors.danger
        : (_focused ? AppColors.accent : AppColors.clear);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppText.body(size: 13, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 8),
        ],
        DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Neu.smallRadius),
            border: Border.all(color: outline, width: 1.5),
          ),
          child: NeuBox(
            inset: true,
            radius: Neu.smallRadius,
            depth: 0.6,
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              enabled: widget.enabled,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              maxLines: widget.maxLines,
              maxLength: widget.maxLength,
              autofillHints: widget.autofillHints,
              onSubmitted: widget.onSubmitted,
              onChanged: widget.onChanged,
              style: AppText.body(
                color: widget.enabled ? AppColors.ink : AppColors.inkMuted,
              ),
              cursorColor: AppColors.accent,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppText.body(color: AppColors.inkMuted),
                counterText: '',
                prefixIcon: widget.prefixIcon,
                suffixIcon: widget.suffix,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: widget.maxLines > 1 ? 14 : 15,
                ),
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              widget.errorText!,
              style: AppText.body(size: 12, color: AppColors.danger),
            ),
          ),
      ],
    );
  }
}

/// A raised, tappable list row (orders, admin lists). Add vertical padding in [child].
class NeuTapCard extends StatelessWidget {
  const NeuTapCard({super.key, required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          splashColor: AppColors.clear,
          highlightColor: AppColors.clear,
          hoverColor: AppColors.accentSoft.withValues(alpha: 0.10),
          child: NeuBox(
            radius: 22,
            depth: 0.7,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A dropdown sunk into the surface, matching [NeuTextField] (label above, error below).
class NeuDropdown<T> extends StatelessWidget {
  const NeuDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.hint,
    this.errorText,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? label;
  final String? hint;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppText.body(size: 13, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 8),
        ],
        DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Neu.smallRadius),
            border: Border.all(
              color: hasError ? AppColors.danger : AppColors.clear,
              width: 1.5,
            ),
          ),
          child: NeuBox(
            inset: true,
            radius: Neu.smallRadius,
            depth: 0.6,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                items: items,
                onChanged: onChanged,
                hint: hint == null
                    ? null
                    : Text(
                        hint!,
                        style: AppText.body(color: AppColors.inkMuted),
                      ),
                borderRadius: BorderRadius.circular(16),
                dropdownColor: AppColors.background,
                iconEnabledColor: AppColors.accent,
                style: AppText.body(color: AppColors.ink),
                itemHeight: 52,
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              errorText!,
              style: AppText.body(size: 12, color: AppColors.danger),
            ),
          ),
      ],
    );
  }
}
