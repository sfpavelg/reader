import 'package:flutter/material.dart';

/// Бейдж с текущим балансом звёзд.
class StarsBalanceChip extends StatelessWidget {
  const StarsBalanceChip({
    super.key,
    required this.stars,
    this.compact = false,
  });

  final int stars;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '⭐ $stars',
        style:
            (compact
                    ? Theme.of(context).textTheme.titleSmall
                    : Theme.of(context).textTheme.titleMedium)
                ?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.onPrimaryContainer,
                ),
      ),
    );
  }
}

/// Панель звёзд вверху игрового экрана.
class TrainerStarsBar extends StatelessWidget {
  const TrainerStarsBar({super.key, required this.stars, this.title});

  final int stars;
  final String? title;

  @override
  Widget build(BuildContext context) {
    if (title == null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [StarsBalanceChip(stars: stars)],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(title!, style: Theme.of(context).textTheme.headlineSmall),
        ),
        StarsBalanceChip(stars: stars),
      ],
    );
  }
}
