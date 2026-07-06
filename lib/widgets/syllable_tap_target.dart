import 'package:flutter/material.dart';

import '../app/app_theme.dart';

/// Крупная зона нажатия; срабатывает на [PointerDownEvent], чтобы успевать
/// при движении слога (бегущая строка, падающие блоки).
class SyllableTapTarget extends StatelessWidget {
  const SyllableTapTarget({
    super.key,
    required this.onActivated,
    required this.child,
    this.enabled = true,
    this.hitPadding = hitSlop,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.splashColor,
    this.highlightColor,
  });

  static const hitSlop = 14.0;

  final VoidCallback onActivated;
  final Widget child;
  final bool enabled;
  final double hitPadding;
  final BorderRadius borderRadius;
  final Color? splashColor;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: borderRadius,
          splashColor: splashColor ?? colors.primary.withValues(alpha: 0.18),
          highlightColor: highlightColor ?? colors.primary.withValues(alpha: 0.08),
          onTapDown: enabled ? (_) => onActivated() : null,
          child: Padding(
            padding: EdgeInsets.all(hitPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: AppTheme.minTouchTarget - hitPadding * 2,
                minHeight: AppTheme.minTouchTarget - hitPadding * 2,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
