import 'package:flutter/material.dart';

import '../theme/star_colors.dart';

/// Бейдж с текущим балансом звёзд (валюта — фиолетовая).
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
    final iconSize = compact ? 18.0 : 22.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: iconSize,
            color: StarColors.currency,
          ),
          const SizedBox(width: 4),
          Text(
            '$stars',
            style:
                (compact
                        ? Theme.of(context).textTheme.titleSmall
                        : Theme.of(context).textTheme.titleMedium)
                    ?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: StarColors.currency,
                    ),
          ),
        ],
      ),
    );
  }
}

/// Цена в звёздах (фиолетовая иконка).
class StarPriceLabel extends StatelessWidget {
  const StarPriceLabel({
    super.key,
    required this.amount,
    this.suffix,
    this.prefix,
    this.fontSize,
    this.dense = false,
  });

  final int amount;
  final String? suffix;
  final String? prefix;
  final double? fontSize;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: StarColors.currency,
          fontWeight: FontWeight.w800,
          fontSize: fontSize,
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (prefix != null) Text(prefix!, style: style),
        Text('$amount', style: style),
        SizedBox(width: dense ? 2 : 4),
        Icon(
          Icons.star_rounded,
          size: dense ? 16 : 18,
          color: StarColors.currency,
        ),
        if (suffix != null) Text(suffix!, style: style),
      ],
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
