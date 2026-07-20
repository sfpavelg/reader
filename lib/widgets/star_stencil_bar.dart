import 'package:flutter/material.dart';

import '../theme/star_colors.dart';

/// Пять трафаретных звёзд прогресса к следующей награде.
class StarStencilBar extends StatelessWidget {
  const StarStencilBar({
    super.key,
    required this.filled,
    this.shatterIndex,
  });

  /// Жёлтый цвет прогресса (левые звёзды).
  static const brightOrange = StarColors.progress;
  static const paleYellow = StarColors.progress;
  static const stencilCount = 5;

  final int filled;
  final int? shatterIndex;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < stencilCount; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Icon(
              i < filled && shatterIndex != i
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              size: 22,
              color: i < filled && shatterIndex != i
                  ? StarColors.progress
                  : colors.onPrimaryContainer.withValues(alpha: 0.45),
            ),
          ],
        ],
      ),
    );
  }
}
